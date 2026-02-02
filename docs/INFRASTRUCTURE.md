# OnlyPaws Infrastructure Documentation

This document describes the infrastructure components and architecture of the OnlyPaws project.

## Overview

OnlyPaws is a full-stack pet management application with a self-hosted Supabase backend running in Docker or Podman containers, paired with a Next.js frontend.

```
bug-free-engine/
├── containers/supabase/    # Self-hosted Supabase stack
├── onlypawsfrontend/       # Next.js TypeScript frontend
├── docs/                   # Documentation
└── .claude/agents/         # Claude Code agent definitions
```

## Architecture Diagram

```
┌─────────────────────┐
│  Browser (User)     │
└──────────┬──────────┘
           │
           ▼
┌──────────────────────────┐
│  Next.js Frontend        │
│  (localhost:3000)        │
└──────────┬───────────────┘
           │ HTTP
           ▼
┌──────────────────────────┐
│  Kong API Gateway        │
│  (localhost:8000)        │
├──────────────────────────┤
│ Routes to microservices: │
│ /auth/v1/*   → GoTrue    │
│ /rest/v1/*   → PostgREST │
│ /realtime/*  → Realtime  │
│ /storage/v1/*→ Storage   │
│ /pg/*        → Meta      │
└──────────┬───────────────┘
           │
           ▼
┌──────────────────────────┐
│     PostgreSQL DB        │
│  (localhost:5432)        │
└──────────────────────────┘

Supabase Studio (localhost:3001)
└─ Admin dashboard for database management
```

## Supabase Services

The self-hosted Supabase stack runs 10 containerized services:

| Service | Version | Port | Purpose |
|---------|---------|------|---------|
| PostgreSQL | 15.8.1 | 5432 | Core relational database |
| Kong | 2.8.1 | 8000, 8443 | API Gateway & reverse proxy |
| GoTrue | 2.158.1 | - | Authentication service |
| PostgREST | 12.2.0 | - | Auto-generated REST API |
| Realtime | 2.30.34 | - | WebSocket subscriptions |
| Storage API | 1.0.6 | - | File storage service |
| imgproxy | 3.8.0 | - | Image transformation |
| Postgres-Meta | 0.83.2 | - | Database metadata API |
| Supabase Studio | 20240729 | 3001 | Admin dashboard |

All services communicate on the internal `supabase-network` bridge network.

## Database Configuration

### Roles

The PostgreSQL instance initializes with these roles:

- `anon` - Anonymous/public users
- `authenticated` - Logged-in users
- `service_role` - Backend server with admin access
- `authenticator` - PostgREST connection role
- `supabase_auth_admin` - Auth service admin
- `supabase_storage_admin` - Storage service admin
- `supabase_functions_admin` - Functions admin
- `supabase_realtime_admin` - Realtime admin

### Schemas

- `public` - Application tables
- `auth` - Authentication data
- `storage` - File metadata
- `realtime` - Realtime subscriptions
- `extensions` - PostgreSQL extensions

### Extensions

- `uuid-ossp` - UUID generation
- `pgcrypto` - Cryptographic functions
- `pgjwt` - JWT signing/verification

## Data Persistence

Named volumes ensure data survives container restarts:

- `db-data` - PostgreSQL database files
- `storage-data` - Uploaded files

## Quick Start

### Initial Setup

```bash
# Run the setup script to generate secrets and environment files
./containers/supabase/scripts/setup.sh
```

This script:
1. Generates secure secrets (passwords, JWT secret)
2. Creates JWT tokens for API keys (10-year expiry)
3. Creates `.env` files for both backend and frontend

### Container Management

```bash
cd containers/supabase

# Start all services
./start.sh up

# Stop all services
./start.sh stop

# View logs
./start.sh logs

# Restart services
./start.sh restart

# Reset everything (destroys data)
./start.sh reset
```

The start script auto-detects Docker or Podman.

## Environment Configuration

### Backend (`containers/supabase/.env`)

| Variable | Purpose |
|----------|---------|
| `POSTGRES_PASSWORD` | Database password |
| `JWT_SECRET` | Secret for signing JWTs |
| `ANON_KEY` | Public API key for anonymous access |
| `SERVICE_ROLE_KEY` | Admin API key for backend services |
| `API_EXTERNAL_URL` | External API URL (Kong gateway) |
| `SITE_URL` | Frontend application URL |
| `SMTP_*` | Email configuration for auth |
| `STUDIO_*` | Supabase Studio settings |

### Frontend (`onlypawsfrontend/.env`)

| Variable | Purpose |
|----------|---------|
| `NEXT_PUBLIC_SUPABASE_URL` | Kong gateway URL |
| `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` | Anon key for client-side |

## Frontend Stack

- **Next.js** with App Router
- **React 19** with TypeScript
- **Supabase Client Libraries** (`@supabase/supabase-js`, `@supabase/ssr`)
- **UI**: shadcn/ui, TailwindCSS, Lucide icons
- **Theming**: next-themes

### Route Structure

```
onlypawsfrontend/app/
├── page.tsx                  # Home page
├── layout.tsx                # Root layout
├── auth/                     # Authentication routes
│   ├── login/
│   ├── sign-up/
│   ├── sign-up-success/
│   ├── forgot-password/
│   ├── update-password/
│   ├── error/
│   └── confirm/route.ts      # Auth callback
└── protected/                # Requires authentication
    ├── layout.tsx
    └── page.tsx
```

## Authentication Flow

1. User submits credentials via Next.js form
2. Request goes to `http://localhost:8000/auth/v1/...` (Kong)
3. Kong routes to GoTrue service
4. GoTrue validates and stores user in `auth.users` table
5. GoTrue generates JWT token
6. Frontend stores JWT for subsequent requests
7. Kong validates JWT on each API request
8. Request routed to appropriate service

## Kong API Gateway

Kong handles all external API traffic with:

- **Authentication**: JWT validation via `key-auth` plugin
- **ACL**: `admin` and `anon` access groups
- **CORS**: Enabled for cross-origin requests
- **Routing**: Prefix-based routing to microservices

Configuration: `containers/supabase/volumes/kong/kong.yml`

## Claude Code Agents

Three specialized agents are available for development:

| Agent | Purpose |
|-------|---------|
| `supabase-db-architect` | Database schema, migrations, backups |
| `nextjs-crud-builder` | Components, API routes, CRUD features |
| `cicd-architect` | CI/CD pipelines, GitHub Actions |

## Production Considerations

Before deploying to production:

- [ ] Regenerate all secrets with strong values
- [ ] Enable HTTPS via reverse proxy (nginx, Traefik, Caddy)
- [ ] Configure SMTP for email verification
- [ ] Set proper CORS origins (not `*`)
- [ ] Enable rate limiting on Kong
- [ ] Set up automated database backups
- [ ] Replace `localhost` with actual domain names
- [ ] Review and restrict network exposure
