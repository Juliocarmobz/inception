# Inception - Developer Documentation

Este documento detalha as decisões técnicas, a arquitetura e as configurações internas aplicadas no projeto Inception.

## Arquitetura Geral
O projeto implementa uma stack LEMP conteinerizada, composta por três serviços independentes:
1.  **NGINX:** Atua como proxy reverso, terminador SSL e servidor web.
2.  **WordPress (PHP-FPM):** Processa as requisições PHP dinâmicas.
3.  **MariaDB:** Servidor de banco de dados relacional isolado.

### Política de Contêineres
- Nenhuma imagem pronta do Docker Hub (como `nginx:latest` ou `mariadb:latest`) é utilizada.
- Todas as imagens são construídas a partir do zero usando a penúltima versão estável do Debian (`debian:bookworm`), através de `Dockerfiles` customizados.
- O daemon do Docker é orquestrado através do `docker-compose.yml`.

## Isolamento e Rede (Network)
- O projeto utiliza uma rede em modo `bridge` nomeada `inception`.
- Apenas o contêiner do NGINX tem a porta `443` mapeada para o host.
- As portas do MariaDB (`3306`) e do WordPress (`9000`) estão expostas **apenas** dentro da rede interna, garantindo que o banco de dados não sofra acessos externos diretos.

## Armazenamento de Dados (Volumes)
Para garantir a persistência dos dados entre reinicializações, são utilizados dois **Volumes Nomeados** (Named Volumes) do tipo *bind mount*:
- `mariadb_data`: Mapeia os dados do banco para `/home/jvenanci/data/mariadb`.
- `wordpress_data`: Mapeia os arquivos estáticos do WordPress para `/home/jvenanci/data/wordpress`.

## Gestão de Segredos (Secrets)
Para evitar o vazamento de credenciais via `docker inspect`, as senhas não são injetadas no `docker-compose.yml` usando variáveis de ambiente puras em texto claro. Foram utilizados ficheiros de segredo simulados na pasta `secrets/` do host, que são lidos em tempo de execução pelos *entrypoints* (ex: `/run/secrets/db_password`).

## Detalhes por Serviço

### NGINX
- **Segurança SSL/TLS:** A porta 80 está desativada. O NGINX escuta apenas na porta 443 com protocolos rigorosamente restritos ao `TLSv1.2` e `TLSv1.3`.
- **Certificado:** Um script de inicialização (`generate_ssl.sh`) cria um certificado X.509 autoassinado antes do NGINX iniciar.
- **Processamento:** Como um contêiner deve ter apenas um serviço principal rodando, o NGINX é iniciado em foreground (`daemon off;`) e assume o **PID 1**, garantindo que receba corretamente os sinais do sistema operacional (como `SIGTERM` e `SIGKILL`).
- **Comunicação PHP:** Requisições para arquivos `.php` são enviadas para o serviço do WordPress através do módulo `fastcgi_pass wordpress:9000`.

### WordPress (PHP-FPM)
- O serviço não contém servidor web interno (sem Apache ou NGINX).
- A instalação e configuração do WordPress são totalmente automatizadas pelo `wp-cli` no script de inicialização (`setup_wordpress.sh`). O script aguarda o MariaDB estar disponível antes de executar a instalação e configurar o administrador e o segundo utilizador.
- Roda no porto 9000 recebendo requisições FastCGI do NGINX.

### MariaDB
- Inicializado através do script `init_db.sh`.
- O banco de dados é inicializado em *bootstrap mode* para criar a base do WordPress, o utilizador do banco e configurar os privilégios.
- Reiniciado em seguida com o comando `exec mysqld_safe` (ou `mysqld`) para rodar em foreground como PID 1 e escutar na interface de rede (`bind-address=0.0.0.0`), aguardando conexões do WordPress.