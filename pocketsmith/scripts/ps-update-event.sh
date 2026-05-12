#!/bin/sh
# ps-update-event.sh — Update a PocketSmith budget forecast event
# DRY-RUN BY DEFAULT. Pass --execute to apply.

set -e

PS_BASE_URL="https://api.pocketsmith.com/v2"
AUDIT_LOG="${PS_AUDIT_LOG:-$HOME/.pocketsmith-audit.log}"

usage() {
  cat <<EOF
Usage: ps-update-event.sh [OPTIONS]

Updates a budget forecast event via PUT /events/{id}.
Only provided fields are updated.

DRY-RUN BY DEFAULT. Pass --execute to apply.

Options:
  --event-id ID           Event ID (required)
  --start-date DATE       New start date, YYYY-MM-DD
  --end-date DATE         New end date, YYYY-MM-DD
  --amount FLOAT          New amount
  --repeat-type TYPE      once|daily|weekly|fortnightly|monthly|yearly
  --repeat-interval N     Repeat every N units
  --category-id ID        New category ID
  --note TEXT             New note
  --api-key KEY           API key (overrides PS_API_KEY env var)
  --execute               Actually apply the update (default: dry-run)
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

EVENT_ID=""
START_DATE=""
END_DATE=""
AMOUNT=""
REPEAT_TYPE=""
REPEAT_INTERVAL=""
CATEGORY_ID=""
NOTE=""
EXECUTE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --event-id)         EVENT_ID="$2"; shift 2 ;;
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
if [ -z "$EVENT_ID" ]; then echo "ERROR: --event-id is required." >&2; exit 2; fi
if [ -z "$START_DATE$END_DATE$AMOUNT$REPEAT_TYPE$REPEAT_INTERVAL$CATEGORY_ID$NOTE" ]; then
  echo "ERROR: At least one field to update must be provided." >&2; exit 2
fi

validate_date() {
  echo "$1" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' || {
    echo "ERROR: Date must be YYYY-MM-DD. Got: \"$1\"" >&2; exit 2
  }
}
[ -n "$START_DATE" ] && validate_date "$START_DATE"
[ -n "$END_DATE" ]   && validate_date "$END_DATE"
if [ -n "$AMOUNT" ]; then
  echo "$AMOUNT" | grep -qE '^-?[0-9]+(\.[0-9]+)?$' || {
    echo "ERROR: Amount must be numeric. Got: \"$AMOUNT\"" >&2; exit 2
  }
fi

FIRST=1; PAYLOAD="{"
add_field() {
  if [ "$FIRST" = "1" ]; then FIRST=0; else PAYLOAD="${PAYLOAD},"; fi
  PAYLOAD="${PAYLOAD}$1"
}
[ -n "$START_DATE" ]      && add_field "\"start_date\":\"$START_DATE\""
[ -n "$END_DATE" ]        && add_field "\"end_date\":\"$END_DATE\""
[ -n "$AMOUNT" ]          && add_field "\"amount\":$AMOUNT"
[ -n "$REPEAT_TYPE" ]     && add_field "\"repeat_type\":\"$REPEAT_TYPE\""
[ -n "$REPEAT_INTERVAL" ] && add_field "\"repeat_interval\":$REPEAT_INTERVAL"
[ -n "$CATEGORY_ID" ]     && add_field "\"category_id\":$CATEGORY_ID"
[ -n "$NOTE" ]            && add_field "\"note\":\"$NOTE\""
PAYLOAD="${PAYLOAD}}"

URL="$PS_BASE_URL/events/$EVENT_ID"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

if [ -z "$EXECUTE" ]; then
  echo "[DRY-RUN] Would execute:"
  echo "  Method:  PUT"; echo "  URL:     $URL"; echo "  Payload: $PAYLOAD"
  echo ""; echo "Pass --execute to apply this change."
  printf '%s\tDRY_RUN\tupdate_event\t{"event_id":%s,"payload":%s}\n' "$TIMESTAMP" "$EVENT_ID" "$PAYLOAD" >> "$AUDIT_LOG" 2>/dev/null || true
  exit 0
fi

printf '%s\tEXECUTING\tupdate_event\t{"event_id":%s}\n' "$TIMESTAMP" "$EVENT_ID" >> "$AUDIT_LOG" 2>/dev/null || true

HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT \
  -H "X-Developer-Key: $PS_API_KEY" -H "Content-Type: application/json" \
  -d "$PAYLOAD" "$URL")

HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')
HTTP_CODE=$(echo "$HTTP_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" != "200" ]; then
  echo "ERROR: API returned HTTP $HTTP_CODE" >&2; echo "$HTTP_BODY" >&2; exit 1
fi

printf '%s\tEXECUTED\tupdate_event\t{"event_id":%s}\n' "$TIMESTAMP" "$EVENT_ID" >> "$AUDIT_LOG" 2>/dev/null || true
if command -v jq >/dev/null 2>&1; then echo "$HTTP_BODY" | jq '.'; else echo "$HTTP_BODY"; fi
