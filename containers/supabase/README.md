# Self-Hosted Supabase

This directory contains container configuration for running Supabase locally using **Docker** or **Podman**.

## Services Included

| Service | Description | Port |
|---------|-------------|------|
| PostgreSQL | Database | 5432 |
| Kong | API Gateway | 8000 (HTTP), 8443 (HTTPS) |
| GoTrue | Authentication | Internal |
| PostgREST | REST API | Internal |
| Realtime | WebSocket server | Internal |
| Storage | File storage | Internal |
| Studio | Admin dashboard | 3001 |

## Quick Start

### 1. Copy environment file

```bash
cp .env.example .env
```

### 2. Generate secure secrets

```bash
# Generate JWT secret
openssl rand -base64 32

# Generate secret key base
openssl rand -base64 64

# Generate Postgres password
openssl rand -base64 24
```

Update the `.env` file with your generated secrets.

### 3. Generate API keys

You need to generate `ANON_KEY` and `SERVICE_ROLE_KEY` using your JWT secret.

Using the Supabase CLI:
```bash
npx supabase@latest gen keys --jwt-secret YOUR_JWT_SECRET
```

Or visit: https://supabase.com/docs/guides/self-hosting/docker#generate-api-keys

### 4. Start the services

Using the helper script (auto-detects Docker or Podman):
```bash
./start.sh
```

Or manually:

**Docker:**
```bash
docker compose up -d
```

**Podman:**
```bash
# Using podman-compose (install: pip install podman-compose)
podman-compose up -d

# Or using podman with compose plugin
podman compose up -d
```

### 5. Access the services

- **API Gateway**: http://localhost:8000
- **Supabase Studio**: http://localhost:3001
- **PostgreSQL**: localhost:5432

## Connecting Your Frontend

Update your frontend `.env` file:

```env
NEXT_PUBLIC_SUPABASE_URL=http://localhost:8000
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=your-anon-key-here
```

---

## Docker vs Podman

This configuration supports both container runtimes:

| Feature | Docker | Podman |
|---------|--------|--------|
| Command | `docker compose` | `podman-compose` or `podman compose` |
| Daemon | Required | Daemonless |
| Root | Default (can be rootless) | Rootless by default |
| SELinux | N/A | Uses `:Z` volume labels |

### Installing Podman Compose

```bash
# Fedora/RHEL/CentOS
sudo dnf install podman-compose

# Ubuntu/Debian
pip install podman-compose

# Or use podman with docker-compose compatibility
sudo dnf install podman-docker  # Fedora
```

### Podman-Specific Notes

1. **Rootless mode**: Podman runs rootless by default, which is more secure
2. **SELinux**: Volume mounts use `:Z` labels for SELinux compatibility
3. **Named volumes**: Database and storage use named volumes for better compatibility
4. **Socket**: No daemon socket required

---

## Command Reference

### Using Docker

```bash
# Start all services
docker compose up -d

# View logs
docker compose logs -f

# View specific service logs
docker compose logs -f auth

# Stop all services
docker compose down

# Stop and remove volumes (WARNING: deletes all data)
docker compose down -v

# Restart a specific service
docker compose restart auth

# Check service status
docker compose ps
```

### Using Podman

```bash
# Start all services
podman-compose up -d

# View logs
podman-compose logs -f

# View specific service logs
podman-compose logs -f auth

# Stop all services
podman-compose down

# Stop and remove volumes (WARNING: deletes all data)
podman-compose down -v

# Restart a specific service
podman-compose restart auth

# Check service status
podman-compose ps

# List volumes
podman volume ls
```

---

## Data Persistence

Data is persisted in named volumes:
- `supabase_db-data` - PostgreSQL data
- `supabase_storage-data` - Uploaded files

To inspect volumes:
```bash
# Docker
docker volume ls
docker volume inspect supabase_db-data

# Podman
podman volume ls
podman volume inspect supabase_db-data
```

---

## Production Considerations

Before deploying to production:

1. **Change all secrets** in `.env`
2. **Enable HTTPS** via a reverse proxy (nginx, Traefik, Caddy)
3. **Configure SMTP** for email verification
4. **Set proper CORS origins** in Kong configuration
5. **Enable rate limiting** and security headers
6. **Set up backups** for PostgreSQL data
7. **Use proper domain names** instead of localhost

---

## Troubleshooting

### Database connection issues
```bash
# Docker
docker compose logs db
docker compose exec db pg_isready -U postgres

# Podman
podman-compose logs db
podman exec supabase-db pg_isready -U postgres
```

### Auth not working
```bash
# Check auth logs
docker compose logs auth  # or podman-compose logs auth

# Verify JWT secret matches between services
```

### Studio not loading
```bash
# Check studio and meta logs
docker compose logs studio meta  # or podman-compose
```

### Podman permission issues
```bash
# If you see permission denied errors, try:
podman unshare chown -R 1000:1000 ./volumes

# Or run with SELinux disabled (not recommended for production)
podman-compose --podman-run-args="--security-opt label=disable" up -d
```

### Reset everything
```bash
# Docker
docker compose down -v
docker compose up -d

# Podman
podman-compose down -v
podman volume prune
podman-compose up -d
```

---

## Updating Supabase

To update to newer versions, update the image tags in `docker-compose.yml` and run:

```bash
# Docker
docker compose pull
docker compose up -d

# Podman
podman-compose pull
podman-compose up -d
```

Check the [Supabase releases](https://github.com/supabase/supabase/releases) for version compatibility.
