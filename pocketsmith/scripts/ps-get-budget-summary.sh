#!/bin/sh
# ps-get-budget-summary.sh — Get budget summary (actuals vs budgeted) for a date range
# Usage: ps-get-budget-summary.sh --start-date DATE --end-date DATE [OPTIONS]

set -e

PS_BASE_URL="https://api.pocketsmith.com/v2"

usage() {
  cat <<EOF
Usage: ps-get-budget-summary.sh [OPTIONS]

Returns budget vs actual summary via GET /users/{id}/budget-summary.
Shows each category's budgeted amount, actual spend, and variance.

Options:
  --user-id ID        PocketSmith user ID (overrides PS_USER_ID env var)
  --api-key KEY       API key (overrides PS_API_KEY env var)
  --start-date DATE   Period start, YYYY-MM-DD (required)
  --end-date DATE     Period end, YYYY-MM-DD (required)
  --roll-up           Roll sub-categories into parent (default: false)
  --help              Show this help message

Environment:
  PS_API_KEY          PocketSmith developer API key (required)
  PS_USER_ID          PocketSmith user ID (required)

Exit codes:
  0   Success
  1   API/HTTP error
  2   Missing/invalid arguments
EOF
}

START_DATE=""
END_DATE=""
ROLL_UP=""

while [ $# -gt 0 ]; do
  case "$1" in
    --user-id)     PS_USER_ID="$2"; shift 2 ;;
    --api-key)     PS_API_KEY="$2"; shift 2 ;;
    --start-date)  START_DATE="$2"; shift 2 ;;
    --end-date)    END_DATE="$2"; shift 2 ;;
    --roll-up)     ROLL_UP="true"; shift ;;
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
if [ -z "$START_DATE" ] || [ -z "$END_DATE" ]; then
  echo "ERROR: --start-date and --end-date are required." >&2; usage >&2; exit 2
fi

validate_date() {
  echo "$1" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' || {
    echo "ERROR: Date must be YYYY-MM-DD. Got: \"$1\"" >&2; exit 2
  }
}
validate_date "$START_DATE"
validate_date "$END_DATE"

QUERY="start_date=${START_DATE}&end_date=${END_DATE}"
[ -n "$ROLL_UP" ] && QUERY="${QUERY}&roll_up=true"

HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -H "X-Developer-Key: $PS_API_KEY" \
  -H "Content-Type: application/json" \
  "$PS_BASE_URL/users/$PS_USER_ID/budget-summary?${QUERY}")

HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')
HTTP_CODE=$(echo "$HTTP_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" != "200" ]; then
  echo "ERROR: API returned HTTP $HTTP_CODE" >&2; echo "$HTTP_BODY" >&2; exit 1
fi

if command -v jq >/dev/null 2>&1; then
  echo "$HTTP_BODY" | jq '[.[] | {category: .category.title, category_id: .category.id, type, budget_amount, actual_amount, refund_amount, currency_code}]'
else
  echo "$HTTP_BODY"
fi
