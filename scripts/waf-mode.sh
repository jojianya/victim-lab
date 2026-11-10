#!/usr/bin/env bash
# Usage: ./scripts/waf-mode.sh On|DetectionOnly|Off
set -euo pipefail
cd "$(dirname "$0")/.."
MODE="${1:?usage: $0 On|DetectionOnly|Off}"
sed -i "s/^MODSEC_RULE_ENGINE=.*/MODSEC_RULE_ENGINE=$MODE/" .env
docker compose up -d nginx-waf
echo "WAF mode: $MODE"
