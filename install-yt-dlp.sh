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
roxo="\e[35m"
reset="\e[0m"

# Banner
echo -e "\n    XpoDigitl  |  Instalador yt-dlp para n8n  |  Criado por Rafael S Pereira\n"

# Função para listar containers n8n
listar_containers() {
    echo -e "${azul}Containers n8n disponíveis:${reset}"
    docker ps --format "{{.Names}}" | grep n8n | nl
    echo ""
}

# Função para instalar yt-dlp
instalar_yt_dlp() {
    local container_id=$1
    echo -e "${azul}Iniciando instalação do yt-dlp no container $container_id...${reset}"
    
    # Verifica se o yt-dlp já está instalado
    if docker exec $container_id which yt-dlp >/dev/null 2>&1; then
        echo -e "${verde}yt-dlp já está instalado neste container!${reset}"
        echo -e "${amarelo}O que você deseja fazer?${reset}"
        echo -e "1) Atualizar yt-dlp"
        echo -e "2) Desinstalar yt-dlp"
        echo -e "3) Escolher outro container"
        echo -e "4) Sair"
        if [ -t 0 ]; then
            read -p "> " opcao
        else
            if [ -e /dev/tty ]; then
                read -p "> " opcao < /dev/tty
            else
                opcao="4"
            fi
        fi

        case $opcao in
            1)
                echo -e "${amarelo}Atualizando yt-dlp...${reset}"
                docker exec --user root --privileged -w / $container_id sh -c "pip3 install -U yt-dlp"
                if [ $? -eq 0 ]; then
                    echo -e "${verde}yt-dlp atualizado com sucesso!${reset}"
                else
                    echo -e "${vermelho}Erro durante a atualização. Verifique os logs acima.${reset}"
                fi
                ;;
            2)
                echo -e "${amarelo}Desinstalando yt-dlp...${reset}"
                docker exec --user root --privileged -w / $container_id sh -c "pip3 uninstall -y yt-dlp"
                if [ $? -eq 0 ]; then
                    echo -e "${verde}yt-dlp desinstalado com sucesso!${reset}"
                else
                    echo -e "${vermelho}Erro durante a desinstalação. Verifique os logs acima.${reset}"
                fi
                ;;
            3)
                echo -e "${amarelo}Retornando à seleção de containers...${reset}"
                return 2
                ;;
            4)
                echo -e "${amarelo}Saindo...${reset}"
                exit 0
                ;;
            *)
                echo -e "${vermelho}Opção inválida! Saindo...${reset}"
                exit 1
                ;;
        esac
        return 0
    fi

    # Instala as dependências
    echo -e "${amarelo}Instalando dependências...${reset}"
    docker exec --user root --privileged -w / $container_id sh -c "apk update && apk add --no-cache python3 py3-pip curl"

    # Instala yt-dlp
    echo -e "${amarelo}Instalando yt-dlp via pip...${reset}"
    docker exec --user root --privileged -w / $container_id sh -c "pip3 install yt-dlp"

    if [ $? -eq 0 ]; then
        echo -e "${verde}yt-dlp instalado com sucesso!${reset}"
    else
        echo -e "${vermelho}Erro durante a instalação. Verifique os logs acima.${reset}"
    fi
}

# Lista os containers disponíveis
listar_containers

# Verifica se existem containers n8n
if ! docker ps --format "{{.Names}}" | grep -q n8n; then
    echo -e "${vermelho}Nenhum container n8n encontrado!${reset}"
    echo -e "${amarelo}Certifique-se de que o stack n8n está em execução:${reset}"
    echo -e "${verde}docker stack deploy -c docker-compose.yml n8n${reset}"
    exit 1
fi

# Conta o número de containers n8n
num_containers=$(docker ps --format "{{.Names}}" | grep n8n | wc -l)

# Se houver apenas um container, seleciona automaticamente
if [ "$num_containers" -eq 1 ]; then
    container_name=$(docker ps --format "{{.Names}}" | grep n8n | head -n 1)
    container_id=$(docker ps -q -f name=$container_name)
    echo -e "${amarelo}Container selecionado automaticamente: $container_name${reset}"
else
    # Se houver múltiplos containers, permite a seleção
    echo -e "${amarelo}Digite o número do container onde deseja instalar o yt-dlp (ou 'q' para sair):${reset}"
    if [ -t 0 ]; then
        read -p "> " opcao
    else
        if [ -e /dev/tty ]; then
            read -p "> " opcao < /dev/tty
        else
            echo -e "${amarelo}Por favor, execute o script diretamente:${reset}"
            echo -e "${verde}sudo bash install-yt-dlp.sh${reset}"
            exit 1
        fi
    fi

    if [[ "$opcao" =~ ^[Qq]$ ]]; then
        echo -e "${amarelo}Saindo...${reset}"
        exit 0
    fi

    if ! [[ "$opcao" =~ ^[0-9]+$ ]]; then
        echo -e "${vermelho}Opção inválida! Digite um número válido ou 'q' para sair.${reset}"
        exit 1
    fi

    container_name=$(docker ps --format "{{.Names}}" | grep n8n | sed -n "${opcao}p")

    if [ -z "$container_name" ]; then
        echo -e "${vermelho}Container não encontrado!${reset}"
        exit 1
    fi

    container_id=$(docker ps -q -f name=$container_name)
fi

# Confirma a instalação
echo -e "${amarelo}Você selecionou o container: $container_name${reset}"
echo -e "${amarelo}Deseja instalar o yt-dlp neste container? (s/n)${reset}"
if [ -t 0 ]; then
    read -p "> " confirmacao
else
    if [ -e /dev/tty ]; then
        read -p "> " confirmacao < /dev/tty
    else
        confirmacao="n"
    fi
fi

if [[ "$confirmacao" =~ ^[Ss]$ ]]; then
    while true; do
        instalar_yt_dlp $container_id
        if [ $? -eq 2 ]; then
            listar_containers
            echo -e "${amarelo}Digite o número do container onde deseja instalar o yt-dlp (ou 'q' para sair):${reset}"
            if [ -t 0 ]; then
                read -p "> " opcao
            else
                if [ -e /dev/tty ]; then
                    read -p "> " opcao < /dev/tty
                else
                    echo -e "${amarelo}Por favor, execute o script diretamente:${reset}"
                    echo -e "${verde}sudo bash install-yt-dlp.sh${reset}"
                    exit 1
                fi
            fi

            if [[ "$opcao" =~ ^[Qq]$ ]]; then
                echo -e "${amarelo}Saindo...${reset}"
                exit 0
            fi

            if ! [[ "$opcao" =~ ^[0-9]+$ ]]; then
                echo -e "${vermelho}Opção inválida! Digite um número válido ou 'q' para sair.${reset}"
                exit 1
            fi

            container_name=$(docker ps --format "{{.Names}}" | grep n8n | sed -n "${opcao}p")
            if [ -z "$container_name" ]; then
                echo -e "${vermelho}Container não encontrado!${reset}"
                exit 1
            fi
            container_id=$(docker ps -q -f name=$container_name)
            echo -e "${amarelo}Você selecionou o container: $container_name${reset}"
            echo -e "${amarelo}Deseja instalar o yt-dlp neste container? (s/n)${reset}"
            if [ -t 0 ]; then
                read -p "> " confirmacao
            else
                if [ -e /dev/tty ]; then
                    read -p "> " confirmacao < /dev/tty
                else
                    confirmacao="n"
                fi
            fi
            if [[ "$confirmacao" =~ ^[Ss]$ ]]; then
                continue
            else
                echo -e "${amarelo}Operação cancelada.${reset}"
                exit 0
            fi
        else
            break
        fi
    done
else
    echo -e "${amarelo}Operação cancelada.${reset}"
fi
