# Docker 101 — common tasks.
# Usage: `make help` (or just `make`).

SHELL := /bin/sh
COMPOSE_DIR := examples/compose
FRONTEND_DIR := examples/frontend-multistage
HELLO_DIR := examples/hello-app

.PHONY: help hello-build hello-run frontend-build frontend-run compose-up compose-down \
        compose-logs compose-ps smoke sizes clean prune disk prune-cache

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

hello-build: ## Build the hello-app image
	docker build -t docker101-hello:local $(HELLO_DIR)

hello-run: hello-build ## Build + run hello-app on :8080
	docker run --rm -d --name docker101-hello -p 8080:8000 docker101-hello:local
	@echo "→ http://localhost:8080  (stop: docker stop docker101-hello)"

frontend-build: ## Build the multi-stage nginx image
	docker build -t docker101-frontend:local $(FRONTEND_DIR)

frontend-run: frontend-build ## Build + run frontend on :8080
	docker run --rm -d --name docker101-frontend -p 8080:80 docker101-frontend:local
	@echo "→ http://localhost:8080  (stop: docker stop docker101-frontend)"

compose-up: ## Start the full web+db+redis stack
	docker compose -f $(COMPOSE_DIR)/docker-compose.yml up -d --build

compose-down: ## Stop the stack AND remove its volumes
	docker compose -f $(COMPOSE_DIR)/docker-compose.yml down -v

compose-logs: ## Follow stack logs
	docker compose -f $(COMPOSE_DIR)/docker-compose.yml logs -f

compose-ps: ## Stack status (health included)
	docker compose -f $(COMPOSE_DIR)/docker-compose.yml ps

smoke: ## Build + curl the frontend, then clean up
	docker build -t docker101-frontend:smoke $(FRONTEND_DIR)
	docker run -d --name docker101-smoke -p 18080:80 docker101-frontend:smoke
	@sleep 1 && curl -fsS http://localhost:18080/ >/dev/null && echo "smoke: OK"
	@docker rm -f docker101-smoke >/dev/null

sizes: ## Compare image sizes (multi-stage payoff)
	@docker image inspect docker101-frontend:local docker101-hello:local \
		--format '{{.RepoTags}} {{.Size}}' 2>/dev/null || \
		echo "build the images first (make frontend-build hello-build)"

clean: ## Stop demo containers and remove demo images
	-@docker rm -f docker101-hello docker101-frontend docker101-smoke 2>/dev/null
	-@docker rmi docker101-hello:local docker101-frontend:local docker101-frontend:smoke 2>/dev/null
	@echo "cleaned"

prune: ## Reclaim disk (containers, dangling images, build cache)
	docker system df
	docker container prune -f
	docker image prune -f
	docker builder prune -f

disk: ## Report Docker disk usage (read-only, deletes nothing)
	sh scripts/docker-disk-report.sh

prune-cache: ## Soft prune: stopped containers + dangling images + build cache (keep 10GB)
	docker container prune -f
	docker image prune -f
	docker buildx prune -f --keep-storage 10GB
