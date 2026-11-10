#!/usr/bin/env bash
# Wipe app state (DB volume) and logs, restart clean.
set -euo pipefail
cd "$(dirname "$0")/.."
docker compose down -v
find logs -type f -name '*.log' -exec truncate -s 0 {} \;
docker compose up -d
echo "Reset complete. Open http://dvwa.lab/setup.php and click 'Create / Reset Database'."
