#!/bin/sh
# ps-list-events.sh — List budget forecast events for a PocketSmith user
# Usage: ps-list-events.sh [OPTIONS]

set -e

PS_BASE_URL="https://api.pocketsmith.com/v2"

usage() {
  cat <<EOF
Usage: ps-list-events.sh [OPTIONS]

Lists budget forecast events via GET /users/{id}/events.
Events drive the PocketSmith forecasting engine.

Options:
  --user-id ID        PocketSmith user ID (overrides PS_USER_ID env var)
  --api-key KEY       API key (overrides PS_API_KEY env var)
  --start-date DATE   Filter events from date, YYYY-MM-DD
  --end-date DATE     Filter events to date, YYYY-MM-DD
  --help              Show this help message

Environment:
  PS_API_KEY          PocketSmith developer API key (required)
  PS_USER_ID          PocketSmith user ID (required)

Exit codes:
  0   Success
  1   API/HTTP error
  2   Missing arguments
EOF
}

START_DATE=""
END_DATE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --user-id)     PS_USER_ID="$2"; shift 2 ;;
    --api-key)     PS_API_KEY="$2"; shift 2 ;;
    --start-date)  START_DATE="$2"; shift 2 ;;
    --end-date)    END_DATE="$2"; shift 2 ;;
    --help)        usage; exit 0 ;;
    *) echo "ERROR: Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [ -z "$PS_API_KEY" ]; then
  echo "ERROR: PS_API_KEY is not set." >&2; exit 2
fi
if [ -z "$PS_USER_ID" ]; then
  echo "ERROR: PS_USER_ID is not set." >&2; exit 2
fi

validate_date() {
  echo "$1" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' || {
    echo "ERROR: Date must be YYYY-MM-DD. Got: \"$1\"" >&2; exit 2
  }
}
[ -n "$START_DATE" ] && validate_date "$START_DATE"
[ -n "$END_DATE" ]   && validate_date "$END_DATE"

QUERY=""
[ -n "$START_DATE" ] && QUERY="start_date=${START_DATE}"
[ -n "$END_DATE" ]   && QUERY="${QUERY:+$QUERY&}end_date=${END_DATE}"

URL="$PS_BASE_URL/users/$PS_USER_ID/events"
[ -n "$QUERY" ] && URL="${URL}?${QUERY}"

HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -H "X-Developer-Key: $PS_API_KEY" \
  -H "Content-Type: application/json" \
  "$URL")

HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')
HTTP_CODE=$(echo "$HTTP_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" != "200" ]; then
  echo "ERROR: API returned HTTP $HTTP_CODE" >&2; echo "$HTTP_BODY" >&2; exit 1
fi

if command -v jq >/dev/null 2>&1; then
  echo "$HTTP_BODY" | jq '[.[] | {id, date, amount, repeat_type, repeat_interval, note, category: .category.title, scenario_id: .scenario.id}]'
else
  echo "$HTTP_BODY"
fi
