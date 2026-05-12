#!/bin/sh
# ps-create-event.sh — Create a budget forecast event in a PocketSmith scenario
# DRY-RUN BY DEFAULT. Pass --execute to apply.

set -e

PS_BASE_URL="https://api.pocketsmith.com/v2"
AUDIT_LOG="${PS_AUDIT_LOG:-$HOME/.pocketsmith-audit.log}"

usage() {
  cat <<EOF
Usage: ps-create-event.sh [OPTIONS]

Creates a budget forecast event via POST /scenarios/{id}/events.
Events drive the PocketSmith forecasting engine.

DRY-RUN BY DEFAULT. Pass --execute to create the event.

Options:
  --scenario-id ID        Scenario ID (required — from account.primary_scenario.id)
  --start-date DATE       Event start date, YYYY-MM-DD (required)
  --end-date DATE         Event end date, YYYY-MM-DD (for finite series)
  --amount FLOAT          Amount; negative=expense, positive=income (required)
  --repeat-type TYPE      once|daily|weekly|fortnightly|monthly|yearly (default: once)
  --repeat-interval N     Repeat every N units (default: 1)
  --category-id ID        Category for the event
  --note TEXT             Note/description
  --api-key KEY           API key (overrides PS_API_KEY env var)
  --execute               Actually create the event (default: dry-run)
  --help                  Show this help message

Environment:
  PS_API_KEY      PocketSmith developer API key (required)
  PS_READ_ONLY    Set to 1 to block all write operations
  PS_AUDIT_LOG    Path for audit log (default: ~/.pocketsmith-audit.log)

Exit codes:
  0   Success (or dry-run)
  1   API/HTTP error
  2   Missing/invalid arguments
EOF
}

SCENARIO_ID=""
START_DATE=""
END_DATE=""
AMOUNT=""
REPEAT_TYPE="once"
REPEAT_INTERVAL=""
CATEGORY_ID=""
NOTE=""
EXECUTE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --scenario-id)      SCENARIO_ID="$2"; shift 2 ;;
    --start-date)       START_DATE="$2"; shift 2 ;;
    --end-date)         END_DATE="$2"; shift 2 ;;
    --amount)           AMOUNT="$2"; shift 2 ;;
    --repeat-type)      REPEAT_TYPE="$2"; shift 2 ;;
    --repeat-interval)  REPEAT_INTERVAL="$2"; shift 2 ;;
    --category-id)      CATEGORY_ID="$2"; shift 2 ;;
    --note)             NOTE="$2"; shift 2 ;;
    --api-key)          PS_API_KEY="$2"; shift 2 ;;
    --execute)          EXECUTE="true"; shift ;;
    --help)             usage; exit 0 ;;
    *) echo "ERROR: Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [ "${PS_READ_ONLY}" = "1" ]; then
  echo "ERROR: PS_READ_ONLY=1 is set. Write operations are disabled." >&2; exit 1
fi
if [ -z "$PS_API_KEY" ]; then echo "ERROR: PS_API_KEY is not set." >&2; exit 2; fi
if [ -z "$SCENARIO_ID" ]; then echo "ERROR: --scenario-id is required." >&2; exit 2; fi
if [ -z "$START_DATE" ]; then echo "ERROR: --start-date is required." >&2; exit 2; fi
if [ -z "$AMOUNT" ]; then echo "ERROR: --amount is required." >&2; exit 2; fi

validate_date() {
  echo "$1" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' || {
    echo "ERROR: Date must be YYYY-MM-DD. Got: \"$1\"" >&2; exit 2
  }
}
validate_date "$START_DATE"
[ -n "$END_DATE" ] && validate_date "$END_DATE"

echo "$AMOUNT" | grep -qE '^-?[0-9]+(\.[0-9]+)?$' || {
  echo "ERROR: Amount must be numeric. Got: \"$AMOUNT\"" >&2; exit 2
}

PAYLOAD="{\"amount\":$AMOUNT,\"start_date\":\"$START_DATE\",\"repeat_type\":\"$REPEAT_TYPE\""
[ -n "$END_DATE" ]        && PAYLOAD="${PAYLOAD},\"end_date\":\"$END_DATE\""
[ -n "$REPEAT_INTERVAL" ] && PAYLOAD="${PAYLOAD},\"repeat_interval\":$REPEAT_INTERVAL"
[ -n "$CATEGORY_ID" ]     && PAYLOAD="${PAYLOAD},\"category_id\":$CATEGORY_ID"
[ -n "$NOTE" ]            && PAYLOAD="${PAYLOAD},\"note\":\"$NOTE\""
PAYLOAD="${PAYLOAD}}"

URL="$PS_BASE_URL/scenarios/$SCENARIO_ID/events"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

if [ -z "$EXECUTE" ]; then
  echo "[DRY-RUN] Would execute:"
  echo "  Method:  POST"; echo "  URL:     $URL"; echo "  Payload: $PAYLOAD"
  echo ""; echo "Pass --execute to create this event."
  printf '%s\tDRY_RUN\tcreate_event\t%s\n' "$TIMESTAMP" "$PAYLOAD" >> "$AUDIT_LOG" 2>/dev/null || true
  exit 0
fi

printf '%s\tEXECUTING\tcreate_event\t%s\n' "$TIMESTAMP" "$PAYLOAD" >> "$AUDIT_LOG" 2>/dev/null || true

HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
  -H "X-Developer-Key: $PS_API_KEY" -H "Content-Type: application/json" \
  -d "$PAYLOAD" "$URL")

HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')
HTTP_CODE=$(echo "$HTTP_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" != "200" ] && [ "$HTTP_CODE" != "201" ]; then
  echo "ERROR: API returned HTTP $HTTP_CODE" >&2; echo "$HTTP_BODY" >&2; exit 1
fi

RESULT_ID=$(command -v jq >/dev/null 2>&1 && echo "$HTTP_BODY" | jq -r '.id // "unknown"' || echo "unknown")
printf '%s\tEXECUTED\tcreate_event\t{"result_id":%s}\n' "$TIMESTAMP" "$RESULT_ID" >> "$AUDIT_LOG" 2>/dev/null || true
if command -v jq >/dev/null 2>&1; then echo "$HTTP_BODY" | jq '.'; else echo "$HTTP_BODY"; fi
