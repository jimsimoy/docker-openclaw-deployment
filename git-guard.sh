#!/bin/bash
#
# Pre-flight scan. Sourced by git-commit.sh and git-push-current.sh.
#
# This repo's working directory is the actual live deployment for a real,
# currently-running personal assistant — real secrets and PII sit on disk
# right next to this git tree (gitignored, never meant to be committed).
# A slip here is not hypothetical, so this scan is mandatory, not opt-in,
# and runs before every commit and every push. It does not skip itself if
# a dependency is missing — it blocks instead.
#
# Layers:
#   1. gitleaks (required) — broad, maintained detection of credential-shaped
#      secrets: cloud keys, tokens, private keys, high-entropy strings.
#      https://github.com/gitleaks/gitleaks
#   2. Generic patterns below — private hosts, IPs, emails, user:pass pairs,
#      and this deployment's own token shapes (e.g. Telegram bot tokens) —
#      things outside a generic secret-scanner's rule set.
#   3. .git-deny-patterns (gitignored, optional) — one regex per line, for
#      names that must never appear here but that would themselves be a leak
#      if hardcoded in a public script. Create it locally; it never ships.
#   4. A fixed list of paths that must never be tracked, regardless of what
#      .gitignore says today — a second gate in case .gitignore is ever
#      edited or a path is force-added by mistake.
#
# NOTE: this scan is never truncated, and gitleaks is required, not optional.
# A partial or skipped scan reported as an all-clear is exactly how
# credentials end up in a public repo's history.

set -uo pipefail

GUARD_GENERIC=(
  '(password|passwd|secret|api[_-]?key|access[_-]?token)[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"']{6,}'
  '(http_basic_auth|basic_auth|htpasswd)["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"']+["'"'"']'
  '["'"'"'][A-Za-z0-9]{6,}:[A-Za-z0-9]{6,}["'"'"']'   # a quoted user:pass pair
  'AIza[0-9A-Za-z_-]{20,}'                            # Google API key
  '[0-9]{8,10}:[A-Za-z0-9_-]{35}'                     # Telegram bot token shape
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'
  'https?://[^/[:space:]]+:[^@/[:space:]]+@'          # user:pass@host
  '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'    # email addresses
  '\b[a-z0-9-]+\.local\b'                             # private dev hostnames
  '\b(25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})(\.(25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})){3}\b'  # IPv4
)

# Lines that legitimately contain a trigger word. Keep this list short and specific.
GUARD_ALLOW='example\.(com|local|org)|yourdomain|your-key|placeholder|CHANGE_ME|<[A-Za-z_ ]+>|clawdocs\.org|docs\.docker\.com|docs\.astral\.sh|myaccount\.google\.com|console\.groq\.com|platform\.openai\.com|jimsimoy@gmail\.com|noreply@anthropic\.com|@param|@return'

# Paths that must never be tracked, whatever .gitignore says today.
GUARD_FORBIDDEN_PATHS=(
  '^openclaw-home/secrets/'
  '^openclaw-home/workspace/'
  '^openclaw-home/\.openclaw/'
  '^openclaw-home/config\.yml$'
  '^openclaw-home/MIGRATION-HANDOVER\.md$'
  '\.enc$'
  '\.key$'
  '(^|/)keys\.json$'
  '\.sqlite3?$'
)

guard_require_gitleaks() {
  if ! command -v gitleaks >/dev/null 2>&1; then
    cat <<'MSG' >&2

  ✖ gitleaks is not installed — this repo requires it for every commit and
    push; it is not optional here. Install it, then retry:
      macOS:   brew install gitleaks
      Linux:   apt install gitleaks   (or see https://github.com/gitleaks/gitleaks/releases)
MSG
    return 1
  fi
  return 0
}

guard_scan() {
  local subject="$1" content="$2" found=0 pat line

  local hits=""
  for pat in "${GUARD_GENERIC[@]}"; do
    line=$(printf '%s\n' "$content" | grep -inE -e "$pat" 2>/dev/null | grep -vE "$GUARD_ALLOW")
    [[ -n "$line" ]] && hits+="$line"$'\n'
  done
  if [[ -n "${hits// /}" ]]; then
    printf '\n  ✖ %s — possible sensitive content:\n' "$subject"
    printf '%s' "$hits" | sort -u -t: -k1,1n | sed 's/^/      /'
    found=1
  fi

  if [[ -f .git-deny-patterns ]]; then
    local denied=""
    while IFS= read -r pat; do
      [[ -z "$pat" || "$pat" == \#* ]] && continue
      line=$(printf '%s\n' "$content" | grep -inE -e "$pat" 2>/dev/null)
      [[ -n "$line" ]] && denied+="$line"$'\n'
    done < .git-deny-patterns
    if [[ -n "${denied// /}" ]]; then
      printf '\n  ✖ %s — matches a local deny pattern:\n' "$subject"
      printf '%s' "$denied" | sort -u -t: -k1,1n | sed 's/^/      /'
      found=1
    fi
  fi

  return $found
}

guard_check_forbidden_paths() {
  local rc=0 pat tracked
  for pat in "${GUARD_FORBIDDEN_PATHS[@]}"; do
    tracked=$(git ls-files | grep -E "$pat" || true)
    if [[ -n "$tracked" ]]; then
      printf '\n  ✖ a path that must never be tracked is staged/committed:\n'
      printf '%s\n' "$tracked" | sed 's/^/      /'
      rc=1
    fi
  done
  return $rc
}

# Full pre-push check: gitleaks over the outgoing commit range, the regex/
# deny-pattern layer over the outgoing diff and commit messages, and the
# forbidden-tracked-paths check.
guard_check() {
  local rc=0

  echo "Pre-flight scan (mandatory — see git-guard.sh)…"

  guard_require_gitleaks || return 1

  local branch range
  branch=$(git branch --show-current)
  if git rev-parse --verify --quiet "origin/$branch" >/dev/null; then
    range="origin/$branch..HEAD"
  else
    range="HEAD"
  fi

  echo "  running gitleaks over ${range}…"
  if ! gitleaks detect --source . --log-opts="${range}" --no-banner --redact -v; then
    echo "  ✖ gitleaks found a likely secret in the outgoing commit(s) — see above"
    rc=1
  fi

  local diff
  if [[ "$range" == "HEAD" ]]; then
    diff=$(git grep -I --no-color -n '' HEAD 2>/dev/null)
  else
    diff=$(git diff "$range" 2>/dev/null)
  fi
  guard_scan "outgoing changes" "$diff" || rc=1

  local msgs
  if [[ "$range" == "HEAD" ]]; then
    msgs=$(git log --format='%s%n%b' 2>/dev/null)
  else
    msgs=$(git log --format='%s%n%b' "$range" 2>/dev/null)
  fi
  guard_scan "commit messages" "$msgs" || rc=1

  guard_check_forbidden_paths || rc=1

  if [[ $rc -ne 0 ]]; then
    cat <<'MSG'

  ─────────────────────────────────────────────────────────────────────
  Push stopped. Review each line above.

  If a hit is a false positive, add a narrow exception to GUARD_ALLOW in
  git-guard.sh. Do not disable the scan, and do not skip it by uninstalling
  gitleaks — that's a fail-open hole, not a fix.

  If it is real: remove it, and treat the value as compromised — rotate it.
  Rewriting history later does not unpublish anything that was ever pushed.
  ─────────────────────────────────────────────────────────────────────
MSG
    return 1
  fi

  echo "  ✔ clean — gitleaks, pattern scan, and forbidden-path check all passed"
  return 0
}
