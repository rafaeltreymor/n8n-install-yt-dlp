#!/bin/bash

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${vermelho}Este script precisa ser executado como root${reset}"
    echo -e "${amarelo}Use: sudo bash install-yt-dlp.sh${reset}"
    exit 1
fi

# Cores para output
verde="\e[32m"
vermelho="\e[31m"
amarelo="\e[33m"
azul="\e[34m"
reset="\e[0m"

# Banner
echo -e "\n    Xpop Digital  |  Instalador yt-dlp para n8n  |  Criado por Rafael S Pereira\n"

# Função para listar containers n8n
listar_containers() {
    echo -e "${azul}Containers n8n disponíveis:${reset}"
    docker ps --format "{{.Names}}" | grep n8n | nl
    echo ""
}

# Função para instalar yt-dlp via pipx
instalar_yt_dlp() {
    local container_id=$1
    echo -e "${azul}Iniciando instalação do yt-dlp no container $container_id...${reset}"

    # Verifica se o yt-dlp já está instalado
    if docker exec $container_id sh -c "command -v yt-dlp" >/dev/null 2>&1; then
        echo -e "${verde}yt-dlp já está instalado neste container!${reset}"
        echo -e "${amarelo}O que você deseja fazer?${reset}"
        echo -e "1) Atualizar yt-dlp"
        echo -e "2) Desinstalar yt-dlp"
        echo -e "3) Escolher outro container"
        echo -e "4) Sair"
        read -p "> " opcao

        case $opcao in
            1)
                echo -e "${amarelo}Atualizando yt-dlp...${reset}"
                docker exec --user root $container_id sh -c "pipx upgrade yt-dlp"
                if [ $? -eq 0 ]; then
                    echo -e "${verde}yt-dlp atualizado com sucesso!${reset}"
                else
                    echo -e "${vermelho}Erro durante a atualização. Verifique os logs acima.${reset}"
                fi
