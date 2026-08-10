	# Définir la variable avec une valeur par défaut
COMPOSE_FILE ?= local.yml

prepare:
	mkdir -p ./backend/staticfiles ./backend/media
	chmod -R 777 ./backend/staticfiles ./backend/media

build:
	docker compose -f $(COMPOSE_FILE) up --build -d --remove-orphans

up:
	docker compose -f $(COMPOSE_FILE) up -d

down:
	docker compose -f $(COMPOSE_FILE) down

down-v:
	docker compose -f $(COMPOSE_FILE) down -v

show-logs:
	docker compose -f $(COMPOSE_FILE) logs

show-logs-api:
	docker compose -f $(COMPOSE_FILE) logs api

makemigrations:
	docker compose -f $(COMPOSE_FILE) run --rm api python manage.py makemigrations

migrate:
	docker compose -f $(COMPOSE_FILE) run --rm api python manage.py migrate

collectstatic:
	docker compose -f $(COMPOSE_FILE) run --rm api python manage.py collectstatic --no-input --clear

superuser:
	docker compose -f $(COMPOSE_FILE) run --rm api python manage.py createsuperuser

dump_admin:
	docker compose -f $(COMPOSE_FILE) run --rm api python manage.py dumpdata admin_interface --indent 2 > ./backend/admin_interface_config.json

db-volume:
	docker volume inspect koda_postgres_data

mailpit-volume:
	docker volume inspect koda_mailpit_data

koda-db:
	docker compose -f $(COMPOSE_FILE) exec postgres psql --username=admin --dbname=koda

# Cibles pour différents environnements
dev:
	$(MAKE) COMPOSE_FILE=local.yml up

staging:
	$(MAKE) COMPOSE_FILE=staging.yml up

prod:
	$(MAKE) COMPOSE_FILE=prod.yml up

# Afficher l'aide
help:
	@echo "Usage:"
	@echo "  make <target> [COMPOSE_FILE=<file>]"
	@echo ""
	@echo "Examples:"
	@echo "  make up                          # Utilise local.yml par défaut"
	@echo "  make up COMPOSE_FILE=staging.yml # Utilise staging.yml"
	@echo "  make build COMPOSE_FILE=prod.yml # Utilise prod.yml"
	@echo ""
	@echo "Targets:"
	@echo "  build, up, down, down-v, show-logs, show-logs-api"
	@echo "  makemigrations, migrate, collectstatic, superuser"
	@echo "  dump_admin, db-volume, mailpit-volume, koda-db"
	@echo "  dev, staging, prod, help"