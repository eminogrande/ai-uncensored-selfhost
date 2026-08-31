#!/bin/bash
# uncensored-stop.sh — destroy the uncensored instance (stops billing).
# usage: ./uncensored-stop.sh <contract_id>
set -euo pipefail
VAST=/tmp/vastai-venv/bin/vastai
CONTRACT="${1:-}"
[ -z "$CONTRACT" ] && { echo "usage: uncensored-stop.sh <contract_id>"; exit 1; }
"$VAST" destroy instance "$CONTRACT" -y
launchctl unload ~/Library/LaunchAgents/com.emin.vast-tunnel.plist 2>/dev/null || true
echo "destroyed $CONTRACT. Models are gone (re-download on next start). Tunnel unloaded."
