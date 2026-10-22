#!/usr/bin/env bash
# Smoke tests against the local bridge. Uses .env. Pass --skip-ask to avoid calling the LLM.
set -uo pipefail
cd "$(dirname "$0")/.."

getenv() {
  grep -E "^$1=" .env | tail -1 | cut -d= -f2- | tr -d '\r' \
    | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e "s/^[\"']//" -e "s/[\"']\$//"
}
PORT=$(getenv N8N_PORT); PORT=${PORT:-5678}
URL="${BRIDGE_URL:-http://127.0.0.1:${PORT}/webhook/$(getenv SIRI_ROUTER_PATH)}"
TOKEN=$(getenv SIRI_TOKEN)
STATUS_SET=$(getenv STATUS_URL)
WAKE_SET=$(getenv WAKE_URL)

fail=0
check() { # name expected_code body_substring [extra curl args...]
  local name=$1 want=$2 sub=$3; shift 3
  local out code body
  out=$(curl -s -m 70 -w '\n%{http_code}' -X POST "$URL" "$@")
  code=${out##*$'\n'}; body=${out%$'\n'*}
  if [ "$code" = "$want" ] && [[ "$body" == *"$sub"* ]]; then
    echo "PASS  $name ($code)"
  else
    echo "FAIL  $name: expected $want containing '$sub', got $code: ${body:0:120}"; fail=1
  fi
}
json='-H Content-Type:application/json'

check "no token is rejected"      403 "Authorization data is wrong" $json -d '{"action":"ask","text":"hi"}'
check "wrong token is rejected"   403 "Authorization data is wrong" $json -H "X-Siri-Token: wrong" -d '{"action":"ask","text":"hi"}'
check "empty text"                400 "did not catch" $json -H "X-Siri-Token: $TOKEN" -d '{"action":"ask","text":"  "}'
check "empty body defaults to ask" 400 "did not catch" $json -H "X-Siri-Token: $TOKEN" -d '{}'
check "unknown action"            200 "I do not know the action foo" $json -H "X-Siri-Token: $TOKEN" -d '{"action":"foo"}'
[ -z "$STATUS_SET" ] && check "status not configured" 200 "not configured" $json -H "X-Siri-Token: $TOKEN" -d '{"action":"status"}'
[ -z "$WAKE_SET" ]   && check "wake not configured"   200 "not configured" $json -H "X-Siri-Token: $TOKEN" -d '{"action":"wake"}'

if [ "${1:-}" != "--skip-ask" ]; then
  out=$(curl -s -m 70 -w '\n%{http_code}' -X POST "$URL" $json -H "X-Siri-Token: $TOKEN" \
        -d '{"action":"ask","text":"In one short sentence, what is the capital of France?"}')
  code=${out##*$'\n'}; body=${out%$'\n'*}
  if [ "$code" = "200" ] && [ -n "$body" ] && [[ "$body" != *"not responding"* ]] && [[ "$body" != *"did not answer"* ]]; then
    echo "PASS  ask returns text (200): $body"
  else
    echo "FAIL  ask: $code: ${body:0:160}"; fail=1
  fi
fi
exit $fail
