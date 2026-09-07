#!/bin/bash
#
# Push the current branch, but only after the mandatory pre-flight scan
# passes. See git-guard.sh for why this repo requires it rather than making
# it optional.

set -uo pipefail
cd "$(dirname "$0")" || exit 1
source ./git-guard.sh

guard_check || exit 1

BRANCH=$(git branch --show-current)
echo
echo "Pushing ${BRANCH} → origin…"
git push origin "$BRANCH"
