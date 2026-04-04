#!/usr/bin/env bash

set -euo pipefail

docker compose ps
docker compose logs --tail=50 openclaw
