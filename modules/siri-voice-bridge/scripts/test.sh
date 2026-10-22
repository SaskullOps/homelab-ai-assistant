#!/usr/bin/env bash
# Smoke tests against the local bridge. Uses .env. Pass --skip-ask to avoid calling the LLM.
set -uo pipefail
cd "$(dirname "$0")/.."

getenv() {
  grep -E "^$1=" .env | tail -1 | cut -d= -f2- | tr -d '\r' \
    | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e "s/^[\"']//" -e "s/[\"']\$//"
}
PORT=$(getenv N8N_PORT); PORT=${PORT:-5678}
[[ "$PORT" =~ ^[0-9]+$ ]] || { echo "N8N_PORT must be a number"; exit 1; }
ROUTER_PATH=$(getenv SIRI_ROUTER_PATH)
[[ "$ROUTER_PATH" =~ ^[A-Za-z0-9_-]{16,}$ ]] || { echo "SIRI_ROUTER_PATH is missing or malformed (see .env.example)"; exit 1; }
URL="${BRIDGE_URL:-http://127.0.0.1:${PORT}/webhook/${ROUTER_PATH}}"
TOKEN=$(getenv SIRI_TOKEN)
[[ "$TOKEN" =~ ^[A-Za-z0-9._~+/=-]{16,}$ ]] || { echo "SIRI_TOKEN is missing or malformed (see .env.example)"; exit 1; }
STATUS_SET=$(getenv STATUS_URL)
WAKE_SET=$(getenv WAKE_URL)

fail=0
# The token goes to curl through a config on stdin, so it never appears in argv
# (visible to every local user in the process list).
post() { # body [token]
  {
    [ -n "${2:-}" ] && printf 'header = "X-Siri-Token: %s"\n' "$2"
    printf 'header = "Content-Type: application/json"\n'
  } | curl -s -m 70 -w '\n%{http_code}' -X POST --config - -d "$1" "$URL"
}
check() { # name expected_code body_substring request_body [token]
  local name=$1 want=$2 sub=$3 out code body
  out=$(post "$4" "${5:-}")
  code=${out##*$'\n'}; body=${out%$'\n'*}
  if [ "$code" = "$want" ] && [[ "$body" == *"$sub"* ]]; then
    echo "PASS  $name ($code)"
  else
    echo "FAIL  $name: expected $want containing '$sub', got $code: ${body:0:120}"; fail=1
  fi
}

check "no token is rejected"      403 "Authorization data is wrong" '{"action":"ask","text":"hi"}'
check "wrong token is rejected"   403 "Authorization data is wrong" '{"action":"ask","text":"hi"}' wrong
check "empty text"                400 "did not catch" '{"action":"ask","text":"  "}' "$TOKEN"
check "empty body defaults to ask" 400 "did not catch" '{}' "$TOKEN"
check "unknown action"            200 "I do not know the action foo" '{"action":"foo"}' "$TOKEN"
[ -z "$STATUS_SET" ] && check "status not configured" 200 "not configured" '{"action":"status"}' "$TOKEN"
[ -z "$WAKE_SET" ]   && check "wake not configured"   200 "not configured" '{"action":"wake"}' "$TOKEN"

if [ "${1:-}" != "--skip-ask" ]; then
  out=$(post '{"action":"ask","text":"In one short sentence, what is the capital of France?"}' "$TOKEN")
  code=${out##*$'\n'}; body=${out%$'\n'*}
  if [ "$code" = "200" ] && [ -n "$body" ] && [[ "$body" != *"not responding"* ]] && [[ "$body" != *"did not answer"* ]]; then
    echo "PASS  ask returns text (200): $body"
  else
    echo "FAIL  ask: $code: ${body:0:160}"; fail=1
  fi
fi
exit $fail
