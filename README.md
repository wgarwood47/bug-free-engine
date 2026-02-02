# OnlyPaws

A full-stack pet management application built with Next.js and self-hosted Supabase.

## Tech Stack

- **Frontend**: Next.js 15, React 19, TypeScript, TailwindCSS, shadcn/ui
- **Backend**: Self-hosted Supabase (PostgreSQL, Kong API Gateway, GoTrue Auth, PostgREST)
- **Infrastructure**: Docker / Podman support

## Prerequisites

Before getting started, make sure you have:

- **Node.js** (v18 or higher)
- **npm** (comes with Node.js)
- **Docker** or **Podman** (for running Supabase)
- **Git**

## Quick Start

### 1. Clone the repository

```bash
git clone <your-repo-url>
cd bug-free-engine
```

### 2. Install dependencies

```bash
make install
```

### 3. Start Supabase

**Option A: Using Supabase CLI (Recommended for development)**

```bash
make supabase-start
```

This starts Supabase with:
- API: http://127.0.0.1:54321
- Studio: http://127.0.0.1:54323

**Option B: Using Docker Compose (For production-like setup)**

```bash
make docker-setup  # First time only - generates secrets
make docker-up
```

This starts Supabase with:
- API & Studio: http://localhost:8000

### 4. Start the frontend

```bash
make frontend
```

The app will be running at http://localhost:3000

## Available Commands

Run `make help` to see all commands. Here are the most useful ones:

| Command | Description |
|---------|-------------|
| `make dev` | Start everything (Supabase + Frontend) |
| `make frontend` | Start frontend only |
| `make install` | Install frontend dependencies |
| `make build` | Build frontend for production |
| `make supabase-start` | Start Supabase (CLI mode) |
| `make supabase-stop` | Stop Supabase (CLI mode) |
| `make supabase-status` | Check Supabase status |
| `make db-studio` | Open Supabase Studio in browser |
| `make db-reset` | Reset database (deletes all data) |
| `make docker-up` | Start Supabase (Docker mode) |
| `make docker-down` | Stop Supabase (Docker mode) |
| `make docker-logs` | View Docker logs |
| `make status` | Show status of all services |
| `make clean` | Clean build artifacts |

## Project Structure

```
bug-free-engine/
├── onlypawsfrontend/       # Next.js frontend application
│   ├── app/                # App Router pages and layouts
│   │   ├── auth/           # Authentication pages (login, signup, etc.)
│   │   └── protected/      # Pages requiring authentication
│   ├── components/         # React components
│   │   └── ui/             # shadcn/ui components
│   └── lib/                # Utilities and Supabase client
├── containers/supabase/    # Self-hosted Supabase configuration
│   ├── docker-compose.yml  # Container orchestration
│   ├── scripts/            # Setup and helper scripts
│   └── volumes/            # Container configuration files
├── docs/                   # Documentation
└── Makefile                # Development commands
```

## Development Workflow

### Working with the Frontend

The frontend uses Next.js App Router with TypeScript. Key locations:

- **Pages**: `onlypawsfrontend/app/`
- **Components**: `onlypawsfrontend/components/`
- **Supabase Client**: `onlypawsfrontend/lib/supabase/`

### Working with the Database

- Open Supabase Studio with `make db-studio`
- Run migrations with `make db-migrate`
- Reset the database with `make db-reset`

### Environment Variables

Frontend environment variables are in `onlypawsfrontend/.env` (or `.env.local`):

```env
NEXT_PUBLIC_SUPABASE_URL=http://127.0.0.1:54321
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=your-anon-key
```

## Additional Documentation

- [Infrastructure Guide](docs/INFRASTRUCTURE.md) - Detailed architecture and service documentation
- [Docker Setup](containers/supabase/README.md) - Self-hosted Supabase configuration
- [Frontend README](onlypawsfrontend/README.md) - Next.js starter kit documentation

## License

This project is private.
