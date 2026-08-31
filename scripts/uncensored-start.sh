#!/bin/bash
# uncensored-start.sh — restart a stopped instance (resumes with models intact).
# usage: ./uncensored-start.sh <contract_id>
set -euo pipefail
VAST=/tmp/vastai-venv/bin/vastai
CONTRACT="${1:-}"
[ -n "$CONTRACT" ] || { echo "usage: uncensored-start.sh <contract_id>"; exit 1; }
$VAST start instance "$CONTRACT"
echo "Started $CONTRACT. Wait ~2 min for boot, then:"
echo "  $VAST show instance $CONTRACT   (check direct_port + public_ipaddr)"
echo "Then re-point the tunnel (launchd plist) to the new port/IP and restart the server if needed."