# Workspace Sample

`openclaw-home/workspace/` is where OpenClaw keeps your assistant's live identity, behavior
rules, and durable notes. It's real per-deployment state, so it's gitignored and never
committed — this `workspace-sample/` directory is the generic starting point instead.

## Setup

```bash
cp -r openclaw-home/workspace-sample openclaw-home/workspace
```

Then edit the copied files and replace the placeholders:

- `<Agent Name>` — your assistant's persona name (e.g. `Nova`, `Jarvis`, `Ops`)
- `<Your Name>` — the name the assistant should use for you, its principal
- `<Your Timezone>` — your IANA timezone (e.g. `America/Vancouver`)

## Files

- `AGENTS.md` — startup sequence, core operating rules, what requires approval first
- `IDENTITY.md` — the assistant's name, role, duties, timezone
- `SOUL.md` — the assistant's core truths, boundaries, and tone
- `TOOLS.md` — key paths and tool boundaries
- `USER.md` — who you are and how you like to work

Once copied and filled in, keep iterating on these files directly in `workspace/` —
that's where the running assistant actually reads from.
