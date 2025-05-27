#!/bin/bash

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${vermelho}Este script precisa ser executado como root${reset}"
    echo -e "${amarelo}Use: sudo bash install-yt-dlp.sh${reset}"
    exit 1
fi

# Cores
verde="\e[32m"
vermelho="\e[31m"
amarelo="\e[33m"
azul="\e[34m"
reset="\e[0m"

echo -e "\n    Xpop Digital  |  Instalador yt-dlp com virtualenv  |  Criado por Rafael S Pereira\n"

listar_containers() {
    echo -e "${azul}Containers n8n disponíveis:${reset}"
    docker ps --format "{{.Names}}" | grep n8n | nl
    echo ""
}

instalar_yt_dlp() {
    local container_id=$1
    echo -e "${azul}Iniciando instalação do yt-dlp no container $container_id...${reset}"

    if docker exec $container_id sh -c "command -v yt-dlp" >/dev/null 2>&1; then
        echo -e "${verde}yt-dlp já está instalado neste container!${reset}"
        return
    fi

    echo -e "${amarelo}Instalando dependências...${reset}"
    docker exec --user root $container_id sh -c "apk add --no-cache python3 py3-pip py3-virtualenv"

    echo -e "${amarelo}Criando ambiente virtual para yt-dlp...${reset}"
    docker exec --user root $container_id sh -c "python3 -m venv /opt/yt-dlp-venv"

    echo -e "${amarelo}Instalando yt-dlp dentro do virtualenv...${reset}"
    docker exec --user root $container_id sh -c "/opt/yt-dlp-venv/bin/pip install --no-cache-dir yt-dlp"

    echo -e "${amarelo}Criando link simbólico para facilitar execução...${reset}"
    docker exec --user root $container_id sh -c "ln -sf /opt/yt-dlp-venv/bin/yt-dlp /usr/local/bin/yt-dlp"

    if docker exec $container_id sh -c "command -v yt-dlp" >/dev/null 2>&1; then
        echo -e "${verde}yt-dlp instalado com sucesso no container!${reset}"
    else
        echo -e "${vermelho}Erro: yt-dlp não encontrado após instalação.${reset}"
    fi
}

listar_containers

if ! docker ps --format "{{.Names}}" | grep -q n8n; then
    echo -e "${vermelho}Nenhum container n8n encontrado!${reset}"
    exit 1
fi

num_containers=$(docker ps --format "{{.Names}}" | grep n8n | wc -l)

if [ "$num_containers" -eq 1 ]; then
    container_name=$(docker ps --format "{{.Names}}" | grep n8n | head -n 1)
    container_id=$(docker ps -q -f name=$container_name)
    echo -e "${amarelo}Container selecionado automaticamente: $container_name${reset}"
else
    echo -e "${amarelo}Digite o número do container onde deseja instalar o yt-dlp (ou 'q' para sair):${reset}"
    read -p "> " opcao

    if [[ "$opcao" =~ ^[Qq]$ ]]; then
        echo -e "${amarelo}Saindo...${reset}"
        exit 0
    fi

    if ! [[ "$opcao" =~ ^[0-9]+$ ]]; then
        echo -e "${vermelho}Opção inválida!${reset}"
        exit 1
    fi

    container_name=$(docker ps --format "{{.Names}}" | grep n8n | sed -n "${opcao}p")
    if [ -z "$container_name" ]; then
        echo -e "${vermelho}Container não encontrado!${reset}"
        exit 1
    fi
    container_id=$(docker ps -q -f name=$container_name)
fi

echo -e "${amarelo}Você selecionou o container: $container_name${reset}"
echo -e "${amarelo}Deseja instalar o yt-dlp neste container? (s/n)${reset}"
read -p "> " confirmacao

if [[ "$confirmacao" =~ ^[Ss]$ ]]; then
    instalar_yt_dlp $container_id
else
    echo -e "${amarelo}Operação cancelada.${reset}"
fi
