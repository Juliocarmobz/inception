#!/bin/bash

set -e

echo "Inicializando MariaDB"

# Ler senhas a partir dos Docker Secrets
DB_ROOT_PASS=$(cat /run/secrets/db_root_password)
DB_USER_PASS=$(cat /run/secrets/db_password)

# Garantir que o diretório do socket e o diretório de dados pertençam ao usuário mysql
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld /var/lib/mysql

# Inicializar o diretório base do MySQL caso o volume esteja vazio
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Inicializando diretório de dados do MariaDB..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null
fi

# Configurar o banco e o usuário do WordPress apenas na primeira execução
if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
    echo "Iniciando servidor MariaDB temporário para configuração..."
    mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking --socket=/run/mysqld/mysqld.sock &
    pid="$!"

    echo "Aguardando o MariaDB ficar pronto..."
    until mysqladmin --socket=/run/mysqld/mysqld.sock ping >/dev/null 2>&1; do
        sleep 1
    done

    echo "Criando banco de dados e configurando usuários..."
    mysql --socket=/run/mysqld/mysqld.sock -u root << SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_USER_PASS}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
SQL

    echo "Desligando servidor temporário..."
    mysqladmin --socket=/run/mysqld/mysqld.sock -u root -p"${DB_ROOT_PASS}" shutdown
    wait "$pid" || true
    echo "Configuração inicial do MariaDB concluída!"
else
    echo "Banco de dados '${MYSQL_DATABASE}' já existe no volume. Pulando configuração inicial."
fi

echo "Iniciando MariaDB como PID 1..."
exec mysqld --user=mysql --datadir=/var/lib/mysql --socket=/run/mysqld/mysqld.sock
