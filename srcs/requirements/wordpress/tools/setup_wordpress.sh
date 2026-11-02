#!/bin/bash
set -e

WP_PATH="/var/www/html"

# Ler senhas a partir dos Docker Secrets
DB_PASS=$(cat /run/secrets/db_password)
WP_ADMIN_PASS=$(sed -n '1p' /run/secrets/credentials)
WP_USER_PASS=$(sed -n '2p' /run/secrets/credentials)

# Garantir diretório de runtime do PHP-FPM
mkdir -p /run/php
chown -R www-data:www-data /run/php "$WP_PATH"

echo "Aguardando o MariaDB aceitar conexões na rede..."
until mysqladmin ping -h mariadb -u "${MYSQL_USER}" -p"${DB_PASS}" --silent >/dev/null 2>&1; do
    sleep 2
done
echo "MariaDB conectado com sucesso!"

cd "$WP_PATH"

# Instalar e configurar o WordPress apenas se ainda não estiver configurado no volume
if [ ! -f "$WP_PATH/wp-config.php" ]; then
    echo "Baixando arquivos base do WordPress via WP-CLI..."
    wp core download --allow-root

    echo "Gerando wp-config.php..."
    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${DB_PASS}" \
        --dbhost="mariadb:3306" \
        --allow-root

    echo "Instalando o WordPress e criando usuário Administrador (${WP_ADMIN_USER})..."
    wp core install \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASS}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root

    echo "Criando o segundo usuário obrigatório (${WP_USER})..."
    wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
        --role="${WP_USER_ROLE}" \
        --user_pass="${WP_USER_PASS}" \
        --allow-root

    chown -R www-data:www-data "$WP_PATH"
    echo "Configuração do WordPress concluída com sucesso!"
else
    echo "WordPress já está instalado e configurado no volume. Pulando etapa."
fi

echo "Iniciando PHP-FPM 8.2 em foreground como PID 1..."
exec /usr/sbin/php-fpm8.2 -F
