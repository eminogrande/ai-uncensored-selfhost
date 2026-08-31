#!/bin/bash
# uncensored-stop.sh — stop the instance but KEEP the disk (models preserved).
# usage: ./uncensored-stop.sh <contract_id>
set -euo pipefail
VAST=/tmp/vastai-venv/bin/vastai
CONTRACT="${1:-}"
[ -n "$CONTRACT" ] || { echo "usage: uncensored-stop.sh <contract_id>"; exit 1; }
$VAST stop instance "$CONTRACT"
echo "Stopped $CONTRACT. Models + llama.cpp preserved on disk."
echo "Restart later with: bash scripts/uncensored-start.sh $CONTRACT"