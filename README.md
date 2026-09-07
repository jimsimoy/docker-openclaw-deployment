## Docker OpenClaw Deployment — Self-Hosted Personal AI Operator

[![Docker Compose](https://img.shields.io/badge/docker-compose-blue.svg?style=flat-square)](https://docs.docker.com/compose/) [![OpenClaw](https://img.shields.io/badge/OpenClaw-compatible-green.svg?style=flat-square)](https://clawdocs.org) [![Ollama Cloud](https://img.shields.io/badge/models-Ollama%20Cloud-orange.svg?style=flat-square)](https://github.com/jimsimoy/docker-ollama) [![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](LICENSE)

"A Docker Compose scaffold for running OpenClaw as a persistent, always-on personal assistant —
identity, memory, and skills survive container rebuilds and server migrations."

by [Jan Ivan Simoy](https://github.com/jimsimoy)

---

## What is this?

This repo is a minimal, production-leaning Docker Compose setup for [OpenClaw](https://clawdocs.org),
an open-source AI agent runtime. It runs the OpenClaw gateway in a container, keeps the gateway off
the public internet by default, and bind-mounts a host directory (`openclaw-home/`) so your
assistant's identity, memory, and skills persist independently of the container lifecycle.

It does not bundle a specific LLM provider, reverse proxy, or messaging channel — you wire those up
through environment variables and OpenClaw's own onboarding, then point a reverse proxy of your
choice at the container.

---

## Requirements

| Requirement | Notes |
|---|---|
| Docker Engine + Compose plugin | Any recent version |
| Ubuntu 22.04/24.04 (or similar) | Works on any Docker host; see `docs/vps-runbook.md` for a VPS walkthrough |
| An LLM provider | Ollama Cloud (recommended, see below), OpenRouter, Anthropic, OpenAI, or xAI |
| A reverse proxy (optional) | Nginx Proxy Manager, Caddy, etc. — not bundled here |

---

## Quick Start

```bash
git clone https://github.com/jimsimoy/docker-openclaw-deployment.git
cd docker-openclaw-deployment
cp .env.example .env    # fill in your model provider key(s)
docker compose up -d
docker compose logs -f openclaw
```

The gateway is not published on any host port by default — see [Reverse Proxy](#reverse-proxy) to
expose it.

---

## Choosing a Model Provider

OpenClaw's model is configured through its own onboarding/CLI (`openclaw onboard`, `openclaw models
set <provider>/<model>`), not through this repo's Docker config — the provider API key just needs to
be present in `.env` so the container can hand it to OpenClaw.

**Recommended: [Ollama Cloud](https://ollama.com/cloud)** via [jimsimoy/docker-ollama](https://github.com/jimsimoy/docker-ollama) —
run your own Ollama instance from that repo (or use Ollama Cloud directly), set `OLLAMA_API_KEY` in
`.env`, then inside the container run:

```bash
docker compose exec openclaw node openclaw.mjs models set ollama/gpt-oss:120b-cloud
```

| Provider | Env var | Notes |
|---|---|---|
| Ollama Cloud | `OLLAMA_API_KEY` | Recommended — pairs with [docker-ollama](https://github.com/jimsimoy/docker-ollama) |
| OpenRouter | `OPENROUTER_API_KEY` | Free tier available; fine for smoke-testing, not for dependable automation |
| Anthropic | `ANTHROPIC_API_KEY` | |
| OpenAI | `OPENAI_API_KEY` | |
| Google Gemini | `GEMINI_API_KEY` / `GOOGLE_API_KEY` | |
| xAI | `XAI_API_KEY` | |

Set only the keys for the provider(s) you actually plan to use.

---

## Configuration

Copy `.env.example` to `.env` and fill in:

| Variable | Purpose |
|---|---|
| `COMPOSE_PROJECT_NAME`, `OPENCLAW_CONTAINER_NAME`, `OPENCLAW_NETWORK_NAME` | Naming — change if running multiple instances on one host |
| `TZ` | Timezone for scheduling/heartbeat |
| `OPENCLAW_PORT`, `OPENCLAW_WEB_PORT` | Internal gateway/control-UI ports |
| `OPENCLAW_HOME` | Host path bind-mounted to `/openclaw-home` in the container |
| `*_API_KEY` | Your chosen model provider(s), see above |
| `OPENCLAW_AUTH_TOKEN` | Gateway auth token |
| `TELEGRAM_BOT_TOKEN`, `TELEGRAM_ALLOWED_CHAT_IDS` | Optional Telegram channel |
| `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GOOGLE_PROJECT_ID` | Optional Gmail/Drive/Calendar integration |
| `OPENCLAW_DOMAIN` | Your public hostname, if fronting with a reverse proxy |

---

## Persistence Model

`openclaw-home/` is bind-mounted into the container and holds everything that should survive a
rebuild or a move to a new server:

- `openclaw-home/.openclaw/` — OpenClaw's real runtime state (identity, memory, credentials, exec
  approvals, installed skills). Created and managed entirely by OpenClaw itself once you run
  `openclaw onboard` inside the container. **Never commit this directory** — it's gitignored, and it
  contains your live secrets and personal data.
- `openclaw-home/workspace-sample/` — a generic template for the identity/behavior files OpenClaw
  reads on first onboarding (`AGENTS.md`, `IDENTITY.md`, `SOUL.md`, `TOOLS.md`, `USER.md`). Copy it to
  `openclaw-home/workspace/`, fill in the placeholders, then onboard — see
  `openclaw-home/workspace-sample/README.md`.
- `openclaw-home/memory/`, `openclaw-home/skills/` — example category files, safe to commit as-is or
  extend.
- `openclaw-home/logs/` — local log output.

To migrate to another server: copy the whole `openclaw-home/` directory (including the gitignored
`.openclaw/`) along with your `.env`, then `docker compose up -d` on the new host.

---

## Reverse Proxy

The OpenClaw gateway is not published on any host port by default and should stay off the public
internet directly. Run your reverse proxy (Nginx Proxy Manager, Caddy, etc.) as a separate stack and
join it to this project's Docker network:

```yaml
networks:
  default:
    external: true
    name: ${OPENCLAW_NETWORK_NAME:-openclaw-proxy}   # matches this repo's .env
```

Then route your proxy to `${OPENCLAW_CONTAINER_NAME:-openclaw}:18789`.

---

## Project Structure

```text
docker-openclaw-deployment/
  .env.example
  docker-compose.yml
  git-commit.sh / git-pull-current.sh / git-push-current.sh
  scripts/
    docker-healthcheck.sh
    restart-openclaw.sh
  docs/
    vps-runbook.md
    google-auth-notes.md
    telegram-setup.md
  openclaw-home/
    workspace-sample/     # generic identity template — copy to workspace/ and edit
    memory/                # example memory category files
    skills/                # drop reviewed OpenClaw skills here
    logs/
    .openclaw/             # gitignored — real runtime state, created by OpenClaw
    workspace/              # gitignored — your filled-in copy of workspace-sample/
```

---

## Security

- The gateway is never published on a host port in this Compose file — only reachable via the
  Docker network, by a reverse proxy you control.
- `.env`, `openclaw-home/.openclaw/`, `openclaw-home/workspace/`, and `openclaw-home/artifacts/` are
  gitignored — real credentials and personal agent state never get committed by default.
- `openclaw-home/workspace-sample/` is the only identity template tracked in git — it is fully
  generic, with no real names, handles, or domains.
- Review `openclaw-home/skills/` before installing any third-party skill — skills can request shell
  and filesystem access.
- A [gitleaks](https://github.com/gitleaks/gitleaks) pre-commit hook is included in `.githooks/` and
  blocks commits containing likely secrets. Enable it after cloning:
  ```bash
  git config core.hooksPath .githooks
  ```
  (requires `gitleaks` installed locally — `apt install gitleaks` or see its releases page)
- Also recommended on your GitHub fork: enable **Settings → Code security → Secret scanning** and
  **Push protection**, and rotate any provider key you ever paste into a chat, script, or terminal.

---

## License

[MIT](LICENSE) — free to use, modify, and distribute.

---

[Report a Bug](https://github.com/jimsimoy/docker-openclaw-deployment/issues) · [Request a Feature](https://github.com/jimsimoy/docker-openclaw-deployment/issues)
