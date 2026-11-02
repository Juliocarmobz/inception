# Inception - User Guide

Este documento lista os comandos automatizados via `Makefile` e os comandos essenciais do Docker para testes e depuração da infraestrutura.

## Comandos do Makefile

A orquestração principal é feita na raiz do projeto (`~/inception/`):

| Comando | Descrição |
| :--- | :--- |
| `make all` ou `make` | Cria os diretórios de dados, constrói as imagens e sobe os contêineres em *background* (`-d`). |
| `make build` | Apenas cria os diretórios de dados e constrói as imagens locais definidas no `docker-compose.yml`. |
| `make up` | Sobe os contêineres utilizando as imagens já construídas. |
| `make down` | Para os contêineres e remove a rede, mas **preserva os volumes de dados**. |
| `make clean` | Para os contêineres e limpa imagens e contêineres órfãos/não utilizados do sistema. |
| `make fclean` | Executa o `clean`, remove todos os volumes do Docker e apaga fisicamente os dados em `/home/jvenanci/data`. (Pode solicitar senha do `sudo`). |
| `make re` | Executa um `fclean` seguido de um `all` (Wipe total e recriação do zero). |

## Comandos Essenciais do Docker (Cheatsheet)

### Monitoramento e Logs
* **Listar contêineres ativos:** `docker ps`
* **Listar todos os contêineres (ativos e parados):** `docker ps -a`
* **Ver os logs de um serviço:** `docker logs <nome_do_conteiner>` (ex: `docker logs mariadb`)
* **Acompanhar logs em tempo real:** `docker logs -f <nome_do_conteiner>`
* **Monitorar uso de CPU/Memória:** `docker stats`

### Inspeção de Rede e Volumes
* **Listar redes do Docker:** `docker network ls`
* **Inspecionar a rede do projeto:** `docker network inspect inception`
* **Listar volumes:** `docker volume ls`
* **Inspecionar um volume:** `docker volume inspect mariadb_data`

### Depuração (Acesso Interno)
Para investigar problemas ou validar configurações, você pode abrir um terminal dentro do contêiner em execução:
* **Acessar o MariaDB:** `docker exec -it mariadb bash`
* **Testar conexão com o banco:** `docker exec -it mariadb mysqladmin ping -u root -p`
* **Verificar portas abertas no NGINX:** `docker exec -it nginx ss -tuln`
* **Testar sintaxe do NGINX:** `docker exec -it nginx nginx -t`
