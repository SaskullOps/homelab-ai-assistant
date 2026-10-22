#!/usr/bin/env bash
# Imports the siri-router workflow into the running n8n container, creates the
# two credentials from .env, publishes the workflow and restarts n8n so the
# webhook is registered. Safe to re-run.
set -euo pipefail
cd "$(dirname "$0")/.."

[ -f .env ] || { echo "missing .env (cp .env.example .env and fill it in)"; exit 1; }
command -v python3 >/dev/null || { echo "python3 is required"; exit 1; }

# Read KEY=value from .env, drop quotes, CR and surrounding whitespace.
# A stray newline in the token is the classic cause of "network connection was lost".
getenv() {
  grep -E "^$1=" .env | tail -1 | cut -d= -f2- | tr -d '\r' \
    | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e "s/^[\"']//" -e "s/[\"']\$//"
}
ROUTER_PATH=$(getenv SIRI_ROUTER_PATH)
TOKEN=$(getenv SIRI_TOKEN)
LLM_KEY=$(getenv LLM_API_KEY)
LLM_KEY=${LLM_KEY:-none}

[[ "$ROUTER_PATH" =~ ^[A-Za-z0-9_-]{16,}$ ]] || { echo "SIRI_ROUTER_PATH must be 16+ chars of [A-Za-z0-9_-] (openssl rand -hex 12)"; exit 1; }
[[ "$TOKEN" =~ ^[^[:space:]]{16,}$ ]] || { echo "SIRI_TOKEN must be 16+ chars, no spaces (openssl rand -hex 24)"; exit 1; }

DC="docker compose"
EXEC="$DC exec -T n8n"

echo "waiting for n8n..."
for _ in $(seq 1 60); do
  $EXEC wget -qO- http://127.0.0.1:5678/healthz >/dev/null 2>&1 && break
  sleep 2
done
$EXEC wget -qO- http://127.0.0.1:5678/healthz >/dev/null 2>&1 || { echo "n8n did not become healthy"; exit 1; }

# Credentials travel through stdin, never through argv or the process list.
creds=$($EXEC sh -c 'umask 077; mktemp /tmp/creds.XXXXXX' | tr -d '\r')
TOKEN="$TOKEN" LLM_KEY="$LLM_KEY" python3 -c '
import json, os
def c(i, n, h, v):
    return {"id": i, "name": n, "type": "httpHeaderAuth", "data": {"name": h, "value": v}}
print(json.dumps([
    c("SiriToken0001", "Siri token", "X-Siri-Token", os.environ["TOKEN"]),
    c("LlmApiKey0001", "LLM API key", "Authorization", "Bearer " + os.environ["LLM_KEY"]),
]))' | $EXEC sh -c "cat > $creds"
$EXEC n8n import:credentials --input="$creds" >/dev/null
$EXEC rm -f "$creds"
echo "credentials imported"

rendered=$(mktemp)
trap 'rm -f "$rendered"' EXIT
PH="__SIRI_ROUTER_PATH__" VAL="$ROUTER_PATH" python3 -c '
import os, sys
src = open("n8n/siri-router.json").read()
open(sys.argv[1], "w").write(src.replace(os.environ["PH"], os.environ["VAL"]))' "$rendered"
$EXEC sh -c 'cat > /tmp/siri-router.json' < "$rendered"
$EXEC n8n import:workflow --input=/tmp/siri-router.json >/dev/null
$EXEC rm -f /tmp/siri-router.json
echo "workflow imported"

timeout 150 $EXEC n8n publish:workflow --id=SiriRouter0001 >/dev/null
echo "workflow published"

$DC restart n8n >/dev/null 2>&1
PORT=$(getenv N8N_PORT); PORT=${PORT:-5678}
URL="http://127.0.0.1:${PORT}/webhook/${ROUTER_PATH}"
echo "waiting for the webhook to register..."
timeout 120 bash -c "until curl -s -X POST '$URL' | grep -q 'Authorization data is wrong'; do sleep 2; done" \
  || { echo "webhook did not register; check: $DC logs n8n"; exit 1; }

echo "ready: POST $URL  (header X-Siri-Token)"
