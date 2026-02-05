# Self-Hosted Supabase

This directory contains the **official Supabase Docker Compose** configuration for self-hosting in production or staging environments.

> **For local development**, use the Supabase CLI instead (see below).

## Two Options for Running Supabase

### Option 1: Supabase CLI (Recommended for Development)

The simplest way to run Supabase locally:

```bash
cd ../onlypawsfrontend
npx supabase start
```

This automatically handles all migrations and provides:
- Studio: http://127.0.0.1:54323
- API: http://127.0.0.1:54321
- Database: postgresql://postgres:postgres@127.0.0.1:54322/postgres

### Option 2: Docker Compose (For Production/Staging)

This directory contains the official Supabase Docker setup for self-hosting.

## Services Included

| Service | Description | Default Port |
|---------|-------------|--------------|
| Studio | Admin dashboard | 8000 (via Kong) |
| Kong | API Gateway | 8000, 8443 |
| GoTrue | Authentication | Internal |
| PostgREST | REST API | Internal |
| Realtime | WebSocket server | Internal |
| Storage | File storage | Internal |
| PostgreSQL | Database | 5432 |
| Analytics | Logflare | 4000 |
| Edge Functions | Deno runtime | Internal |
| Supavisor | Connection pooler | 6543 |

## Quick Start (Docker Compose)

### 1. Copy and configure environment

```bash
cp .env.example .env
# Edit .env with your secrets
```

### 2. Generate secure secrets

```bash
# Generate passwords and keys
openssl rand -hex 32  # For JWT_SECRET
openssl rand -hex 24  # For POSTGRES_PASSWORD
openssl rand -hex 32  # For SECRET_KEY_BASE
openssl rand -hex 16  # For VAULT_ENC_KEY
openssl rand -hex 16  # For PG_META_CRYPTO_KEY

# Generate API keys using your JWT_SECRET
./scripts/generate-keys.sh YOUR_JWT_SECRET
```

### 3. Start services

```bash
# Docker
docker compose up -d

# Podman (set DOCKER_HOST first)
export DOCKER_HOST=unix:///run/user/$(id -u)/podman/podman.sock
docker-compose up -d
```

### 4. Access services

- **API Gateway**: http://localhost:8000
- **Studio**: http://localhost:8000 (via Kong, login with DASHBOARD_USERNAME/PASSWORD)
- **Database**: localhost:5432

## Directory Structure

```
containers/supabase/
├── docker-compose.yml      # Official Supabase compose file
├── .env.example            # Environment template
├── scripts/
│   ├── setup.sh           # Automated setup script
│   └── generate-keys.sh   # JWT key generator
└── volumes/
    ├── api/kong.yml       # Kong API gateway config
    ├── db/                # Database init scripts
    │   ├── roles.sql
    │   ├── webhooks.sql
    │   ├── jwt.sql
    │   ├── realtime.sql
    │   ├── logs.sql
    │   ├── pooler.sql
    │   └── _supabase.sql
    ├── functions/main/    # Edge functions
    ├── logs/vector.yml    # Log collection config
    ├── pooler/pooler.exs  # Connection pooler config
    ├── snippets/          # SQL snippets for Studio
    └── storage/           # File storage
```

## Connecting Your Frontend

```env
# For Docker Compose self-hosting
NEXT_PUBLIC_SUPABASE_URL=http://localhost:8000
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=your-anon-key

# For Supabase CLI
NEXT_PUBLIC_SUPABASE_URL=http://127.0.0.1:54321
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

## Commands

### Docker

```bash
docker compose up -d          # Start
docker compose down           # Stop
docker compose down -v        # Stop and delete data
docker compose logs -f        # View logs
docker compose logs -f auth   # View specific service logs
docker compose ps             # Check status
```

### Podman

```bash
export DOCKER_HOST=unix:///run/user/$(id -u)/podman/podman.sock
docker-compose up -d
docker-compose down
```

### Supabase CLI

```bash
npx supabase start            # Start local development
npx supabase stop             # Stop
npx supabase stop --no-backup # Stop and delete data
npx supabase status           # Check status
npx supabase db reset         # Reset database
```

## Production Checklist

Before deploying to production:

- [ ] Change all secrets in `.env`
- [ ] Generate new JWT keys with your JWT_SECRET
- [ ] Set up HTTPS via reverse proxy (nginx, Traefik, Caddy)
- [ ] Configure SMTP for email verification
- [ ] Set proper CORS origins
- [ ] Enable rate limiting
- [ ] Set up database backups
- [ ] Use proper domain names
- [ ] Review security settings

## Updating

```bash
# Pull latest images
docker compose pull
docker compose up -d

# Check Supabase releases for compatibility
# https://github.com/supabase/supabase/releases
```

## Troubleshooting

### Check service health

```bash
docker compose ps
docker compose logs auth
docker compose logs db
```

### Database connection issues

```bash
docker compose exec db pg_isready -U postgres
```

### Reset everything

```bash
docker compose down -v
docker compose up -d
```

## Resources

- [Official Self-Hosting Docs](https://supabase.com/docs/guides/self-hosting)
- [Supabase GitHub](https://github.com/supabase/supabase)
- [Docker Compose Reference](https://github.com/supabase/supabase/tree/master/docker)
