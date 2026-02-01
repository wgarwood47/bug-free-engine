#!/usr/bin/env bash
#
# Start Supabase containers using Docker or Podman
# Automatically detects which runtime is available
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check for .env file
if [ ! -f ".env" ]; then
    log_warn ".env file not found"
    if [ -f ".env.example" ]; then
        log_info "Copying .env.example to .env"
        cp .env.example .env
        log_warn "Please edit .env with your secrets before continuing"
        log_info "Generate secrets with:"
        echo "  openssl rand -base64 32  # JWT_SECRET"
        echo "  openssl rand -base64 64  # SECRET_KEY_BASE"
        echo "  openssl rand -base64 24  # POSTGRES_PASSWORD"
        exit 1
    else
        log_error ".env.example not found"
        exit 1
    fi
fi

# Detect container runtime
detect_runtime() {
    if command -v docker &> /dev/null; then
        if docker compose version &> /dev/null; then
            echo "docker-compose-plugin"
            return
        elif command -v docker-compose &> /dev/null; then
            echo "docker-compose"
            return
        fi
    fi

    if command -v podman &> /dev/null; then
        if podman compose version &> /dev/null 2>&1; then
            echo "podman-compose-plugin"
            return
        elif command -v podman-compose &> /dev/null; then
            echo "podman-compose"
            return
        fi
    fi

    echo "none"
}

RUNTIME=$(detect_runtime)

case "$RUNTIME" in
    "docker-compose-plugin")
        log_info "Using Docker with compose plugin"
        COMPOSE_CMD="docker compose"
        ;;
    "docker-compose")
        log_info "Using docker-compose"
        COMPOSE_CMD="docker-compose"
        ;;
    "podman-compose-plugin")
        log_info "Using Podman with compose plugin"
        COMPOSE_CMD="podman compose"
        ;;
    "podman-compose")
        log_info "Using podman-compose"
        COMPOSE_CMD="podman-compose"
        ;;
    *)
        log_error "No container runtime found!"
        echo "Please install one of:"
        echo "  - Docker: https://docs.docker.com/get-docker/"
        echo "  - Podman: https://podman.io/getting-started/installation"
        exit 1
        ;;
esac

# Parse command line arguments
ACTION="${1:-up}"

case "$ACTION" in
    "up"|"start")
        log_info "Starting Supabase services..."
        $COMPOSE_CMD up -d
        echo ""
        log_info "Services started!"
        echo "  API Gateway: http://localhost:8000"
        echo "  Studio:      http://localhost:3001"
        echo "  PostgreSQL:  localhost:5432"
        ;;
    "down"|"stop")
        log_info "Stopping Supabase services..."
        $COMPOSE_CMD down
        ;;
    "logs")
        SERVICE="${2:-}"
        if [ -n "$SERVICE" ]; then
            $COMPOSE_CMD logs -f "$SERVICE"
        else
            $COMPOSE_CMD logs -f
        fi
        ;;
    "ps"|"status")
        $COMPOSE_CMD ps
        ;;
    "restart")
        SERVICE="${2:-}"
        if [ -n "$SERVICE" ]; then
            log_info "Restarting $SERVICE..."
            $COMPOSE_CMD restart "$SERVICE"
        else
            log_info "Restarting all services..."
            $COMPOSE_CMD restart
        fi
        ;;
    "pull")
        log_info "Pulling latest images..."
        $COMPOSE_CMD pull
        ;;
    "reset")
        log_warn "This will delete all data!"
        read -p "Are you sure? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "Stopping and removing volumes..."
            $COMPOSE_CMD down -v
            log_info "Starting fresh..."
            $COMPOSE_CMD up -d
        fi
        ;;
    *)
        echo "Usage: $0 {up|down|logs|ps|restart|pull|reset} [service]"
        echo ""
        echo "Commands:"
        echo "  up, start     Start all services"
        echo "  down, stop    Stop all services"
        echo "  logs [svc]    View logs (optionally for specific service)"
        echo "  ps, status    Show service status"
        echo "  restart [svc] Restart services"
        echo "  pull          Pull latest images"
        echo "  reset         Stop, remove volumes, and restart (WARNING: deletes data)"
        exit 1
        ;;
esac
