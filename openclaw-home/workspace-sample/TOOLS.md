# TOOLS.md

## Key Paths

- OpenClaw mounted path: `/openclaw-home`
- <Agent Name> Telegram bot: configured via `TELEGRAM_BOT_TOKEN`
- OpenClaw health script: `/openclaw-home/scripts/openclaw-healthcheck.sh`
- Shared alert env for host-run scripts: `/openclaw-home/scripts/script-alerts.env`

## Boundaries

- no host-path assumptions outside mounted locations
- no credentials/auth/public-exposure changes without approval
- no new cron jobs or monitoring duplicates unless explicitly requested
- no email sending or unapproved server access

## Operating Guidance

- prefer host-side cron for critical checks
- reuse existing tooling before inventing new systems
- use `/openclaw-home/scripts/script-alerts.env` for new host-run script alerts
- if a tool/action causes restarts or pairing failures, stop and reassess
- treat credentials, auth changes, destructive ops, and public-exposure changes as approval-required by policy
