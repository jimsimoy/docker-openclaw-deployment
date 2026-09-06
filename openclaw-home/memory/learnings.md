# Learnings

- Keep OpenClaw state on the host via bind mounts.
- Keep the gateway bound to localhost on the host side.
- For this deployment, the gateway is reverse-proxied and browser origins must be explicitly allowlisted.
- First-time browser use requires device pairing approval.
- OpenClaw self-managed cron currently hits internal gateway pairing/auth issues, so critical monitoring should stay outside OpenClaw for now.
