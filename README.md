# Ivan 2.0 Docker OpenClaw Stack

This folder contains the local deployment scaffold for `Ivan 2.0`.

The goal is to prepare the Docker/OpenClaw project here first, then copy or pull the same project onto the Contabo Ubuntu 24.04 VPS and run it there with minimal changes.

Docker/runtime naming in this folder uses `ai-assistant-ivan` for the Compose project, container names, and shared Docker network.

Important distinction:

- Docker/project name: `ai-assistant-ivan`
- Agent name/persona: `Ivan 2.0`

Current LLM setup target:

- development: OpenRouter free tier
- later production option: paid OpenRouter or direct OpenAI/Anthropic API

Provider and model selection are now stored in the host-persisted OpenClaw config, not Docker environment overrides.

Container image default:

- `ghcr.io/openclaw/openclaw:latest`

## Why Docker

Yes, OpenClaw should run in Docker on the VPS.

Why:

- OpenClaw officially supports Docker deployment
- containerized deployment is easier to reproduce
- the gateway can stay bound to `127.0.0.1`
- persistent data can live in mounted volumes
- upgrades and rollback are simpler than a hand-managed host install

Important security rule:

Do not expose the OpenClaw gateway port `18789` publicly. Keep it internal and add only tightly controlled access.

This stack also includes `Nginx Proxy Manager` so future services can share the same Docker bridge network and be fronted through one proxy layer when needed.

## Persistence Model

This project is set up so the important OpenClaw state lives on the host, not inside the container.

Host-mounted OpenClaw home includes:

- config
- persona files
- memory
- skills
- workspace
- artifacts

That means if you move this folder to another server and run Docker there, `Ivan 2.0` can keep:

- its identity
- its memory
- its prior config
- installed skills
- prior workspace files
- artifacts and continuity stored under the OpenClaw home directory

Important note:

Copy the full project folder, including `openclaw-home/`, not just the Compose file.

## Project Layout

```text
ai-assistant/ai-assistant-docker-openclaw/
  .env.example
  .gitignore
  docker-compose.yml
  git-commit.sh
  git-pull-current.sh
  git-push-current.sh
  README.md
  scripts/
  docs/
  nginx-proxy-manager/
    data/
    letsencrypt/
  openclaw-home/
    config.yml
    workspace/
    memory/
    skills/
    artifacts/
  logs/
```

## Current Services

- `ai-assistant-ivan-openclaw`
- `ai-assistant-ivan-nginx-proxy-manager`

Shared Docker network:

- `ai-assistant-ivan-shared`

Current local ports:

- OpenClaw chat/UI: `http://127.0.0.1:18889/chat`
- Nginx Proxy Manager admin UI: `http://127.0.0.1:8181`
- Nginx Proxy Manager HTTPS listener: `https://127.0.0.1:4443`

Notes:

- NPM host port `80` is intentionally not published in this environment
- OpenClaw and future containers can reach each other on the shared bridge network by container name

## Local Setup

1. Copy `.env.example` to `.env`.
2. Fill in `OPENROUTER_API_KEY` for the initial development setup.
3. Start the stack:

```bash
docker compose up -d
```

4. Check logs:

```bash
docker compose logs -f openclaw
```

5. Stop the stack:

```bash
docker compose down
```

Useful helper scripts in this folder:

```bash
./git-pull-current.sh
./git-push-current.sh
./git-commit.sh "your commit message"
```

Before first run, review the host-persisted OpenClaw files under `openclaw-home/`:

- `config.yml`
- `workspace/SOUL.md`
- `workspace/IDENTITY.md`
- `workspace/AGENTS.md`
- `workspace/USER.md`
- `workspace/TOOLS.md`

Current development defaults in `openclaw-home/config.yml`:

- provider: `openrouter`
- model: `openrouter/free`

If the free router is too inconsistent for a given task later, switch to a specific free model such as a `:free` variant in `openclaw-home/config.yml`.

Current `.env` / Compose naming defaults:

- `COMPOSE_PROJECT_NAME=ai-assistant-ivan`
- OpenClaw container name: `ai-assistant-ivan-openclaw`
- NPM container name: `ai-assistant-ivan-nginx-proxy-manager`
- shared network: `ai-assistant-ivan-shared`

## VPS Setup Model

Planned deployment target:

- provider: Contabo
- OS: Ubuntu 24.04
- runtime: Docker Engine + Docker Compose
- app: OpenClaw in container

Recommended deployment flow:

1. Provision VPS
2. Install Docker
3. Clone this project
4. Create `.env` on the server
5. Run `docker compose up -d`
6. Lock down network exposure
7. Decide whether Nginx Proxy Manager should own public `80/443` on that server
8. Add Telegram and Google integrations

## OpenClaw Paths Used

This project uses environment-variable overrides so OpenClaw reads from a bind-mounted home directory on the host:

- `OPENCLAW_HOME=/openclaw-home`
- `OPENCLAW_CONFIG=/openclaw-home/config.yml`
- `OPENCLAW_MEMORY_PATH=/openclaw-home/memory`
- `OPENCLAW_SKILLS_PATH=/openclaw-home/skills`

We intentionally do not override provider/model in Docker right now. Those stay in the persisted OpenClaw config to keep setup simpler.

## Reverse Proxy Notes

`Nginx Proxy Manager` is included for future routing and TLS management, but this local environment currently uses alternate host ports:

- `8181 -> 81`
- `4443 -> 443`

On a dedicated VM or VPS, you can change those host-side bindings later if you want NPM to own the normal public ports.

## Included Files

- `docs/contabo-runbook.md`
- `docs/google-auth-notes.md`
- `docs/telegram-setup.md`
- `git-commit.sh`
- `git-pull-current.sh`
- `git-push-current.sh`
- `scripts/bootstrap-vps.sh`
- `scripts/docker-healthcheck.sh`
- `scripts/package-migration.sh`

## Migration Workflow

To move `Ivan 2.0` to another server without resetting it:

1. Copy this whole project folder, or create an archive with `scripts/package-migration.sh`
2. Move it to the new server
3. Create or restore `.env`
4. Run `docker compose up -d`

Because the project stores OpenClaw state in `openclaw-home/`, the agent can keep its persona, memory, workspace files, and other persisted state.

If you are committing this folder into git, the local `.gitignore` is already set up to exclude:

- `.env`
- `logs/`
- `openclaw-home/.openclaw/`
- `openclaw-home/artifacts/`
- `nginx-proxy-manager/data/`
- `nginx-proxy-manager/letsencrypt/`

## Official References

- OpenClaw deployment options: https://clawdocs.org/guides/deployment-options/
- OpenClaw environment variables: https://clawdocs.org/reference/environment-variables/
- OpenClaw OpenRouter note: https://clawdocs.org/guides/cloud-gpu-models/
- OpenClaw installation: https://clawdocs.org/getting-started/installation/
- OpenClaw memory system: https://clawdocs.org/architecture/memory-system/
- OpenClaw SOUL.md guide: https://clawdocs.org/guides/soul-md/
- OpenClaw gateway security note: https://clawdocs.org/architecture/gateway/
