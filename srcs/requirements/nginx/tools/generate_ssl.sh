#!/bin/bash
set -e

mkdir -p /etc/nginx/ssl

: "${DOMAIN_NAME:=jvenanci.42.fr}"

if [ ! -f /etc/nginx/ssl/nginx.crt ]; then
    echo "Gerando certificado SSL autoassinado para ${DOMAIN_NAME}..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/C=BR/ST=RJ/L=RioDeJaneiro/O=42Rio/OU=42/CN=${DOMAIN_NAME}"

    chmod 600 /etc/nginx/ssl/nginx.key
    chmod 644 /etc/nginx/ssl/nginx.crt
    echo "Certificado SSL gerado com sucesso!"
fi

# Caso o DOMAIN_NAME no .env seja alterado, garante que o server_name no nginx.conf acompanhe a variável
sed -i "s/server_name .*/server_name ${DOMAIN_NAME};/" /etc/nginx/nginx.conf

echo "Testando configuração do NGINX..."
nginx -t

echo "Iniciando NGINX em foreground como PID 1..."
exec nginx -g "daemon off;"
