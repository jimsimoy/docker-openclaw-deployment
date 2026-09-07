#!/bin/bash
#
# Stage everything, scan, commit, scan again, push.
# Usage: ./git-commit.sh "commit message"

set -uo pipefail
cd "$(dirname "$0")" || exit 1

if [[ $# -lt 1 ]]; then
  echo "Usage: ./git-commit.sh \"commit message\"" >&2
  exit 1
fi

COMMIT_MESSAGE="$1"

source ./git-guard.sh

guard_require_gitleaks || exit 1

# Check the message before it becomes a commit — a bad one is far more
# annoying to remove afterwards than to retype now.
if ! guard_scan "commit message" "$COMMIT_MESSAGE"; then
  echo
  echo "  Commit aborted. Nothing has been staged or committed."
  exit 1
fi

git add .

echo "Scanning staged changes…"
if ! gitleaks protect --staged --no-banner --redact -v; then
  echo
  echo "  Commit aborted — gitleaks flagged staged changes above. Nothing was committed."
  git reset >/dev/null
  exit 1
fi
if ! guard_scan "staged changes" "$(git diff --cached)"; then
  echo
  echo "  Commit aborted. Nothing was committed."
  git reset >/dev/null
  exit 1
fi
guard_check_forbidden_paths || { echo; echo "  Commit aborted. Nothing was committed."; git reset >/dev/null; exit 1; }

git commit -m "$COMMIT_MESSAGE" || exit 1

./git-push-current.sh
