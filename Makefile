COMPOSE = docker compose -f srcs/docker-compose.yml
DATA_PATH = /home/jcologne/data

all:
	@echo "Build mandatory"
	@ sudo mkdir -p $(DATA_PATH)/wordpress
	@ sudo mkdir -p $(DATA_PATH)/mariadb
	@$(COMPOSE) up -d --build nginx wordpress mariadb

bonus: all
	@echo "Build bonus"
	@mkdir -p $(DATA_PATH)/redis
	@mkdir -p $(DATA_PATH)/portainer
	@$(COMPOSE) up -d --build redis ftp adminer static-site portainer

clean:
	@$(COMPOSE) down
	@echo "Cleaned"

fclean: clean
	@$(COMPOSE) down -v
	@docker stop $$(docker ps -aq) 2>/dev/null || true
	@docker rm -f $$(docker ps -aq) 2>/dev/null || true
	@docker system prune -a --volumes -f
	@sudo rm -rf $(DATA_PATH)
	@docker images
	@docker ps -a

re: fclean all

.PHONY: all bonus clean fclean re
