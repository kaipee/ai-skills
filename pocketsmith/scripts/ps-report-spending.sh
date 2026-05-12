#!/bin/sh
# ps-report-spending.sh — Spending breakdown report by category
# Usage: ps-report-spending.sh --start-date DATE --end-date DATE [OPTIONS]

set -e

PS_BASE_URL="https://api.pocketsmith.com/v2"

usage() {
  cat <<EOF
Usage: ps-report-spending.sh [OPTIONS]

Generates a spending breakdown report grouped by category.
Fetches transactions and aggregates by category, showing amounts and percentages.

Options:
  --user-id ID        PocketSmith user ID (overrides PS_USER_ID)
  --api-key KEY       API key (overrides PS_API_KEY)
  --start-date DATE   Report period start, YYYY-MM-DD (required)
  --end-date DATE     Report period end, YYYY-MM-DD (required)
  --format FORMAT     Output format: markdown|json (default: markdown)
  --per-page N        Transactions per page, 1-100 (default: 100)
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
FORMAT="markdown"
PER_PAGE="100"

while [ $# -gt 0 ]; do
  case "$1" in
    --user-id)     PS_USER_ID="$2"; shift 2 ;;
    --api-key)     PS_API_KEY="$2"; shift 2 ;;
    --start-date)  START_DATE="$2"; shift 2 ;;
    --end-date)    END_DATE="$2"; shift 2 ;;
    --format)      FORMAT="$2"; shift 2 ;;
    --per-page)    PER_PAGE="$2"; shift 2 ;;
    --help)        usage; exit 0 ;;
    *) echo "ERROR: Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [ -z "$PS_API_KEY" ]; then echo "ERROR: PS_API_KEY is not set." >&2; exit 2; fi
if [ -z "$PS_USER_ID" ]; then echo "ERROR: PS_USER_ID is not set." >&2; exit 2; fi
if [ -z "$START_DATE" ] || [ -z "$END_DATE" ]; then
  echo "ERROR: --start-date and --end-date are required." >&2; exit 2
fi

validate_date() {
  echo "$1" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' || {
    echo "ERROR: Date must be YYYY-MM-DD. Got: \"$1\"" >&2; exit 2
  }
}
validate_date "$START_DATE"; validate_date "$END_DATE"

# Fetch all debit transactions in period
HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -H "X-Developer-Key: $PS_API_KEY" \
  -H "Content-Type: application/json" \
  "$PS_BASE_URL/users/$PS_USER_ID/transactions?start_date=${START_DATE}&end_date=${END_DATE}&type=debit&per_page=${PER_PAGE}")

HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')
HTTP_CODE=$(echo "$HTTP_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" != "200" ]; then
  echo "ERROR: API returned HTTP $HTTP_CODE" >&2; echo "$HTTP_BODY" >&2; exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "NOTE: jq not found — outputting raw JSON. Install jq for formatted reports." >&2
  echo "$HTTP_BODY"
  exit 0
fi

# Build spending summary with jq
SUMMARY=$(echo "$HTTP_BODY" | jq -r '
  [.[] | select(.amount < 0)] |
  group_by(.category.title // "Uncategorised") |
  map({
    category: (.[0].category.title // "Uncategorised"),
    total: (map(.amount) | add | . * -1 | . * 100 | round | . / 100),
    count: length
  }) |
  sort_by(.total) | reverse |
  . as $rows |
  ($rows | map(.total) | add) as $grand_total |
  $rows | map(. + {pct: (.total / $grand_total * 100 | . * 10 | round | . / 10)})
')

TXN_COUNT=$(echo "$HTTP_BODY" | jq '[.[] | select(.amount < 0)] | length')
GRAND_TOTAL=$(echo "$SUMMARY" | jq '[.[].total] | add // 0')

if [ "$FORMAT" = "json" ]; then
  echo "$SUMMARY" | jq "{period: \"${START_DATE} to ${END_DATE}\", total_spending: $GRAND_TOTAL, transaction_count: $TXN_COUNT, categories: .}"
  exit 0
fi

# Markdown output
cat <<MDEOF
# Spending Report: ${START_DATE} to ${END_DATE}

**Period:** ${START_DATE} to ${END_DATE}
**Total Spending:** \$$(echo "$GRAND_TOTAL" | jq '.')
**Transactions:** ${TXN_COUNT}

## Spending by Category

| # | Category | Amount | % of Total | Transactions |
|---|----------|-------:|:----------:|:------------:|
MDEOF

echo "$SUMMARY" | jq -r 'to_entries[] | "| \(.key + 1) | \(.value.category) | $\(.value.total) | \(.value.pct)% | \(.value.count) |"'

cat <<MDEOF

---
*Data: PocketSmith API /users/${PS_USER_ID}/transactions | Debits only | Transfers excluded where categorised as transfers*
MDEOF
