# Contabo Runbook

Planned target:

- Contabo VPS
- Ubuntu 24.04
- Docker Engine
- Docker Compose
- OpenClaw container

High-level server steps:

1. Provision the VPS and add your SSH key
2. Update Ubuntu packages
3. Install Docker Engine and Compose plugin
4. Enable firewall rules
5. Clone this project to `/opt/ai-assistant-ivan`
6. Copy `.env.example` to `.env`
7. Fill in keys and tokens
8. Start with `docker compose up -d`
9. Verify OpenClaw is not directly published on the host
10. Connect the intended reverse proxy container to `ai-assistant-ivan-proxy`
11. Add proxy or webhook ingress later if needed

Do not expose the OpenClaw control plane publicly.

Current development provider choice:

- `OpenRouter` with `openrouter/free` for initial local setup and smoke testing

Before production use, move to a more reliable paid model path.

Persistence note:

The full OpenClaw home lives under `openclaw-home/` in this project. To migrate Ivan 2.0 to another server, copy the whole project folder including:

- `openclaw-home/config.yml`
- `openclaw-home/workspace/`
- `openclaw-home/memory/`
- `openclaw-home/skills/`
- `openclaw-home/artifacts/`
- `logs/`
