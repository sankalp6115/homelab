# Homelab Docker System

A scalable, convention-driven Docker Compose setup for self-hosted services. Each service or group of services gets its own compose file; all share a single external Docker network and a centralised `.env` file.

---

## Directory Structure

```
docker/
├── .env                        # Real env file — GITIGNORED, never commit
├── .env.example                # Documented template — commit this
├── _template.yml               # Copy-paste template for adding new services
├── composes/
│   ├── standalone/             # One compose file per single service
│   │   ├── gotify.yml
│   │   ├── uptime-kuma.yml
│   │   └── pihole.yml
│   └── groups/                 # One compose file for services that run together
│       └── monitoring.yml      # Gotify + Uptime Kuma
├── scripts/
│   └── init-network.sh         # Creates the shared Docker network (run once)
└── README.md                   # This file
```

> [!IMPORTANT]
> Legacy compose files (`gotify-compose.yml`, `uptime-kuma-compose.yml`, `monitoring-compose.yml`, `pihole-compose.yml`) in the `docker/` root are kept for reference but are superseded by the files under `composes/`.

---

## Quick Start

### 1 — Create the shared network (run once)

```bash
cd docker/
bash scripts/init-network.sh
```

### 2 — Copy and edit the env file

```bash
cp .env.example .env
# Edit .env — set DATA_ROOT, TZ, passwords, ports
nano .env
```

### 3 — Bring up a service

All commands should be run from the `docker/` root directory so that Docker Compose picks up `.env` automatically.

**Standalone service:**

```bash
docker compose -f composes/standalone/gotify.yml up -d
docker compose -f composes/standalone/uptime-kuma.yml up -d
docker compose -f composes/standalone/pihole.yml up -d
```

**Group (Gotify + Uptime Kuma together):**

```bash
docker compose -f composes/groups/monitoring.yml up -d
```

> [!NOTE]
> Do **not** run both the standalone files and the group file for the same service at the same time — they will conflict on ports.

---

## How `.env` Works

Each compose subdirectory (`composes/standalone/`, `composes/groups/`) contains a `.env` **symlink** pointing back to `docker/.env`. Docker Compose automatically reads `.env` from the same directory as the compose file, so the symlink makes this transparent — no flags needed.

```
composes/standalone/.env  →  ../../.env   (symlink)
composes/groups/.env      →  ../../.env   (symlink)
```

You can run compose commands from anywhere:

```bash
# Works — compose file's directory has .env symlink
docker compose -f composes/standalone/gotify.yml up -d

# Also works — explicit flag always takes precedence
docker compose -f composes/standalone/gotify.yml --env-file .env up -d
```

> [!NOTE]
> The symlinks are relative (`../../.env`), so they work correctly regardless of where you clone the repo — no hardcoded paths.

---

## Services

| Service | Compose file | Default host port | Notes |
|---|---|---|---|
| Gotify | `composes/standalone/gotify.yml` | `8000` | Push notifications |
| Uptime Kuma | `composes/standalone/uptime-kuma.yml` | `3001` | Status monitoring |
| Pi-hole | `composes/standalone/pihole.yml` | `8080` (UI), `53` (DNS) | DNS ad blocker |
| Gotify + Uptime Kuma | `composes/groups/monitoring.yml` | `8000`, `3001` | Start both as one unit |

---

## Adding a New Service

1. Copy the template:

   ```bash
   cp _template.yml composes/standalone/myapp.yml
   ```

2. Edit `composes/standalone/myapp.yml`:
   - Set `name:` to the app name.
   - Replace `TODO_IMAGE`, `TODO_APP_PORT`, etc.
   - Adjust volumes and environment variables.

3. Add any new env vars to both `.env` and `.env.example`.

4. Bring it up:

   ```bash
   docker compose -f composes/standalone/myapp.yml up -d
   ```

---

## Conventions

| Rule | Detail |
|---|---|
| No `container_name` | Let Docker auto-generate names to avoid conflicts |
| External network | All composes join the `homelab` network via `external: true` |
| `restart: unless-stopped` | Every service must include this |
| `TZ: ${TZ}` | Every service sets the timezone from `.env` |
| Data under `DATA_ROOT` | Volumes follow `${DATA_ROOT}/service-name:/container/path` |
| Quoted port mappings | Always use `"host:container"` string format |
| Label stub | Every service includes a `labels:` block for future proxy integration |

---

## Useful Commands

```bash
# View logs for a service
docker compose -f composes/standalone/gotify.yml logs -f

# Stop and remove containers (data is preserved)
docker compose -f composes/standalone/gotify.yml down

# Stop, remove containers AND volumes (destructive!)
docker compose -f composes/standalone/gotify.yml down -v

# Pull latest images
docker compose -f composes/standalone/gotify.yml pull

# List all containers in the homelab network
docker network inspect homelab
```

