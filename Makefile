.DEFAULT_GOAL := migrate-help

.PHONY: \
	migrate-help \
	migrate-create \
	migrate-up \
	migrate-version \
	migrate-goto \
	migrate-down \
	migrate-force

SERVICE=demo-api

migrate-help:
	@echo ""
	@echo "Migration commands:"
	@echo ""
	@echo "Create migration:"
	@echo "  make migrate-create NAME=create_movies_table"
	@echo ""
	@echo "Apply all migrations:"
	@echo "  make migrate-up"
	@echo ""
	@echo "Show current version:"
	@echo "  make migrate-version"
	@echo ""
	@echo "Go to specific version:"
	@echo "  make migrate-goto VERSION=1"
	@echo ""
	@echo "Rollback all migrations:"
	@echo "  make migrate-down"
	@echo ""
	@echo "Rollback N migrations:"
	@echo "  make migrate-down N=3"
	@echo ""
	@echo "Force migration version:"
	@echo "  make migrate-force VERSION=2"
	@echo ""

migrate-create:
	@if [ -z "$(NAME)" ]; then \
		echo "Usage: make migrate-create NAME=create_movies_table"; \
		exit 1; \
	fi
	docker compose exec $(SERVICE) sh -c '\
		gosu "$$DEMO_API_MAIN_SYSTEM_USER_NAME" \
		migrate create \
		-seq \
		-ext sql \
		-dir /app/migrations \
		$(NAME)'

migrate-up:
	docker compose exec $(SERVICE) sh -c '\
		migrate \
		-path=/app/migrations \
		-database="$$DEMO_API_DB_DSN" \
		up'

migrate-version:
	docker compose exec $(SERVICE) sh -c '\
		migrate \
		-path=/app/migrations \
		-database="$$DEMO_API_DB_DSN" \
		version'

migrate-goto:
	@if [ -z "$(VERSION)" ]; then \
		echo "Usage: make migrate-goto VERSION=1"; \
		exit 1; \
	fi
	docker compose exec $(SERVICE) sh -c '\
		migrate \
		-path=/app/migrations \
		-database="$$DEMO_API_DB_DSN" \
		goto $(VERSION)'

migrate-down:
	@if [ -n "$(N)" ]; then \
		docker compose exec $(SERVICE) sh -c '\
			migrate \
			-path=/app/migrations \
			-database="$$DEMO_API_DB_DSN" \
			down $(N)'; \
	else \
		docker compose exec $(SERVICE) sh -c '\
			migrate \
			-path=/app/migrations \
			-database="$$DEMO_API_DB_DSN" \
			down'; \
	fi

migrate-force:
	@if [ -z "$(VERSION)" ]; then \
		echo "Usage: make migrate-force VERSION=1"; \
		exit 1; \
	fi
	docker compose exec $(SERVICE) sh -c '\
		migrate \
		-path=/app/migrations \
		-database="$$DEMO_API_DB_DSN" \
		force $(VERSION)'