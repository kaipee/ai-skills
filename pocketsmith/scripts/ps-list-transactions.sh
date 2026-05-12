#!/bin/sh
# ps-list-transactions.sh — List/search transactions for a PocketSmith user
# Usage: ps-list-transactions.sh [OPTIONS]

set -e

PS_BASE_URL="https://api.pocketsmith.com/v2"

usage() {
  cat <<EOF
Usage: ps-list-transactions.sh [OPTIONS]

Lists and filters transactions via GET /users/{id}/transactions.
All filter parameters are optional; omitting them returns recent transactions.

Options:
  --user-id ID          PocketSmith user ID (overrides PS_USER_ID env var)
  --api-key KEY         API key (overrides PS_API_KEY env var)
  --start-date DATE     Filter from date, YYYY-MM-DD (inclusive)
  --end-date DATE       Filter to date, YYYY-MM-DD (inclusive)
  --search KEYWORD      Keyword search across payee and notes
  --category-id ID      Filter by category ID
  --type TYPE           Filter by type: uncategorised|debit|credit
  --needs-review        Filter to transactions flagged for review
  --page N              Page number (default: 1)
  --per-page N          Results per page, 1-100 (default: 100)
  --help                Show this help message

Environment:
  PS_API_KEY            PocketSmith developer API key (required)
  PS_USER_ID            PocketSmith user ID (required)

Exit codes:
  0   Success
  1   API/HTTP error
  2   Missing/invalid arguments
EOF
}

START_DATE=""
END_DATE=""
SEARCH=""
CATEGORY_ID=""
TXN_TYPE=""
NEEDS_REVIEW=""
PAGE="1"
PER_PAGE="100"

while [ $# -gt 0 ]; do
  case "$1" in
    --user-id)      PS_USER_ID="$2"; shift 2 ;;
    --api-key)      PS_API_KEY="$2"; shift 2 ;;
    --start-date)   START_DATE="$2"; shift 2 ;;
    --end-date)     END_DATE="$2"; shift 2 ;;
    --search)       SEARCH="$2"; shift 2 ;;
    --category-id)  CATEGORY_ID="$2"; shift 2 ;;
    --type)         TXN_TYPE="$2"; shift 2 ;;
    --needs-review) NEEDS_REVIEW="true"; shift ;;
    --page)         PAGE="$2"; shift 2 ;;
    --per-page)     PER_PAGE="$2"; shift 2 ;;
    --help)         usage; exit 0 ;;
    *) echo "ERROR: Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [ -z "$PS_API_KEY" ]; then
  echo "ERROR: PS_API_KEY is not set." >&2; exit 2
fi
if [ -z "$PS_USER_ID" ]; then
  echo "ERROR: PS_USER_ID is not set. Run ps-get-user.sh to find it." >&2; exit 2
fi

# Validate date format
validate_date() {
  echo "$1" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' || {
    echo "ERROR: Date must be YYYY-MM-DD format. Got: \"$1\"" >&2; exit 2
  }
}
[ -n "$START_DATE" ] && validate_date "$START_DATE"
[ -n "$END_DATE" ]   && validate_date "$END_DATE"

# Validate per-page
case "$PER_PAGE" in
  ''|*[!0-9]*) echo "ERROR: --per-page must be a number 1-100." >&2; exit 2 ;;
esac
if [ "$PER_PAGE" -gt 100 ] || [ "$PER_PAGE" -lt 1 ]; then
  echo "ERROR: --per-page must be 1-100. Got: $PER_PAGE" >&2; exit 2
fi

# Build query string
QUERY="page=${PAGE}&per_page=${PER_PAGE}"
[ -n "$START_DATE" ]   && QUERY="${QUERY}&start_date=${START_DATE}"
[ -n "$END_DATE" ]     && QUERY="${QUERY}&end_date=${END_DATE}"
[ -n "$CATEGORY_ID" ]  && QUERY="${QUERY}&category_id=${CATEGORY_ID}"
[ -n "$TXN_TYPE" ]     && QUERY="${QUERY}&type=${TXN_TYPE}"
[ -n "$NEEDS_REVIEW" ] && QUERY="${QUERY}&needs_review=true"
if [ -n "$SEARCH" ]; then
  ENCODED_SEARCH=$(printf '%s' "$SEARCH" | sed 's/ /%20/g')
  QUERY="${QUERY}&search=${ENCODED_SEARCH}"
fi

HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -H "X-Developer-Key: $PS_API_KEY" \
  -H "Content-Type: application/json" \
  "$PS_BASE_URL/users/$PS_USER_ID/transactions?${QUERY}")

HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')
HTTP_CODE=$(echo "$HTTP_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" != "200" ]; then
  echo "ERROR: API returned HTTP $HTTP_CODE" >&2
  echo "$HTTP_BODY" >&2
  exit 1
fi

if command -v jq >/dev/null 2>&1; then
  echo "$HTTP_BODY" | jq '[.[] | {id, date, payee, amount, type, category: .category.title, labels, needs_review, note}]'
else
  echo "$HTTP_BODY"
fi
