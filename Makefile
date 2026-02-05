# OnlyPaws - Project Makefile
# Run 'make' or 'make help' to see available commands

.PHONY: help dev start stop status logs clean install test build \
        supabase-start supabase-stop supabase-status supabase-logs supabase-reset \
        docker-up docker-down docker-logs docker-reset docker-setup \
        db-studio db-reset db-migrate db-seed

# Default target
.DEFAULT_GOAL := help

# Colors for help output
CYAN := \033[36m
GREEN := \033[32m
YELLOW := \033[33m
RESET := \033[0m

##@ General

help: ## Show this help message
	@echo ""
	@echo "$(GREEN)OnlyPaws$(RESET) - Development Commands"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf ""} \
		/^[a-zA-Z_-]+:.*?##/ { printf "  $(CYAN)%-20s$(RESET) %s\n", $$1, $$2 } \
		/^##@/ { printf "\n$(YELLOW)%s$(RESET)\n", substr($$0, 5) }' $(MAKEFILE_LIST)
	@echo ""

##@ Development (Frontend + Supabase CLI)

dev: supabase-start ## Start full development environment (Supabase + Frontend)
	@echo "Starting frontend..."
	@cd onlypawsfrontend && npm run dev

start: supabase-start ## Start Supabase local development
	@echo "Supabase is running. Start frontend with: make frontend"

stop: supabase-stop ## Stop all development services

frontend: ## Start frontend development server only
	@cd onlypawsfrontend && npm run dev

install: ## Install frontend dependencies
	@cd onlypawsfrontend && npm install

build: ## Build frontend for production
	@cd onlypawsfrontend && npm run build

test: ## Run frontend tests
	@cd onlypawsfrontend && npm test

lint: ## Run linter on frontend code
	@cd onlypawsfrontend && npm run lint

##@ Supabase CLI (Local Development)

supabase-start: ## Start Supabase local development
	@echo "Starting Supabase..."
	@cd onlypawsfrontend && npx supabase start
	@echo ""
	@echo "$(GREEN)Supabase is running!$(RESET)"
	@echo "  API:    http://127.0.0.1:54321"
	@echo "  Studio: http://127.0.0.1:54323"

supabase-stop: ## Stop Supabase local development
	@cd onlypawsfrontend && npx supabase stop

supabase-status: ## Show Supabase status
	@cd onlypawsfrontend && npx supabase status

supabase-logs: ## Show Supabase logs
	@cd onlypawsfrontend && npx supabase logs

supabase-reset: ## Reset Supabase database (deletes all data)
	@cd onlypawsfrontend && npx supabase db reset

##@ Database

db-studio: ## Open Supabase Studio in browser
	@echo "Opening Supabase Studio..."
	@xdg-open http://127.0.0.1:54323 2>/dev/null || open http://127.0.0.1:54323 2>/dev/null || echo "Open http://127.0.0.1:54323 in your browser"

db-reset: supabase-reset ## Alias for supabase-reset

db-migrate: ## Run database migrations
	@cd onlypawsfrontend && npx supabase migration up

db-seed: ## Seed the database
	@cd onlypawsfrontend && npx supabase db seed

db-diff: ## Generate migration from database changes
	@cd onlypawsfrontend && npx supabase db diff -f $(name)

db-push: ## Push local migrations to remote database
	@cd onlypawsfrontend && npx supabase db push

##@ Docker Compose (Production Self-Hosting)

docker-setup: ## Setup Docker environment (generate secrets and .env)
	@cd containers/supabase && ./scripts/setup.sh

docker-up: ## Start Supabase with Docker Compose
	@echo "Starting Supabase (Docker Compose)..."
	@cd containers/supabase && docker compose up -d
	@echo ""
	@echo "$(GREEN)Supabase is running!$(RESET)"
	@echo "  API:    http://localhost:8000"
	@echo "  Studio: http://localhost:8000 (via Kong)"

docker-down: ## Stop Supabase Docker containers
	@cd containers/supabase && docker compose down

docker-logs: ## Show Docker Compose logs
	@cd containers/supabase && docker compose logs -f

docker-ps: ## Show Docker container status
	@cd containers/supabase && docker compose ps

docker-reset: ## Reset Docker environment (deletes all data)
	@echo "$(YELLOW)Warning: This will delete all data!$(RESET)"
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	@cd containers/supabase && docker compose down -v
	@cd containers/supabase && docker compose up -d

docker-pull: ## Pull latest Docker images
	@cd containers/supabase && docker compose pull

##@ Podman (Alternative to Docker)

podman-up: ## Start Supabase with Podman
	@echo "Starting Supabase (Podman)..."
	@export DOCKER_HOST=unix:///run/user/$$(id -u)/podman/podman.sock && \
		cd containers/supabase && docker-compose up -d
	@echo ""
	@echo "$(GREEN)Supabase is running!$(RESET)"

podman-down: ## Stop Supabase Podman containers
	@export DOCKER_HOST=unix:///run/user/$$(id -u)/podman/podman.sock && \
		cd containers/supabase && docker-compose down

podman-logs: ## Show Podman container logs
	@export DOCKER_HOST=unix:///run/user/$$(id -u)/podman/podman.sock && \
		cd containers/supabase && docker-compose logs -f

podman-ps: ## Show Podman container status
	@export DOCKER_HOST=unix:///run/user/$$(id -u)/podman/podman.sock && \
		cd containers/supabase && docker-compose ps

##@ Utilities

clean: ## Clean build artifacts and caches
	@echo "Cleaning..."
	@rm -rf onlypawsfrontend/.next
	@rm -rf onlypawsfrontend/node_modules/.cache
	@echo "Done."

clean-all: clean ## Clean everything including node_modules
	@rm -rf onlypawsfrontend/node_modules
	@echo "Run 'make install' to reinstall dependencies."

env-example: ## Show required environment variables
	@echo "$(YELLOW)Frontend (.env):$(RESET)"
	@cat onlypawsfrontend/.env.example
	@echo ""
	@echo "$(YELLOW)Docker Compose (.env):$(RESET)"
	@head -30 containers/supabase/.env.example

status: ## Show status of all services
	@echo "$(YELLOW)Supabase CLI Status:$(RESET)"
	@cd onlypawsfrontend && npx supabase status 2>/dev/null || echo "  Not running"
	@echo ""
	@echo "$(YELLOW)Docker Compose Status:$(RESET)"
	@cd containers/supabase && docker compose ps 2>/dev/null || echo "  Not running"
