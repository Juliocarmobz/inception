LOGIN = jvenanci
DATA_DIR = /home/$(LOGIN)/data
COMPOSE_FILE = srcs/docker-compose.yml


all: build up

build:
	@echo "Criando diretórios de dados..."
	@mkdir -p $(DATA_DIR)/mariadb
	@mkdir -p $(DATA_DIR)/wordpress
	docker compose -f $(COMPOSE_FILE) build

up:
	docker compose -f $(COMPOSE_FILE) up -d

down:
	docker compose -f $(COMPOSE_FILE) down

clean:
	docker compose -f $(COMPOSE_FILE) down
	docker system prune -af

fclean: clean
	docker volume prune -f
	sudo rm -rf $(DATA_DIR)/mariadb/*
	sudo rm -rf $(DATA_DIR)/wordpress/*
	sudo rm -rf $(DATA_DIR)

re: fclean all

.PHONY: all build up down clean fclean re
