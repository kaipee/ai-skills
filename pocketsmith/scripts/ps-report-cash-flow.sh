#!/bin/sh
# ps-report-cash-flow.sh — Cash flow report: income vs expenses by period
# Usage: ps-report-cash-flow.sh --start-date DATE --end-date DATE [OPTIONS]

set -e

PS_BASE_URL="https://api.pocketsmith.com/v2"

usage() {
  cat <<EOF
Usage: ps-report-cash-flow.sh [OPTIONS]

Generates a cash flow report showing income vs expenses.
Fetches all transactions in the period and computes net cash flow.

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

HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -H "X-Developer-Key: $PS_API_KEY" \
  -H "Content-Type: application/json" \
  "$PS_BASE_URL/users/$PS_USER_ID/transactions?start_date=${START_DATE}&end_date=${END_DATE}&per_page=${PER_PAGE}")

HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')
HTTP_CODE=$(echo "$HTTP_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" != "200" ]; then
  echo "ERROR: API returned HTTP $HTTP_CODE" >&2; echo "$HTTP_BODY" >&2; exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "NOTE: jq not found — outputting raw JSON." >&2
  echo "$HTTP_BODY"; exit 0
fi

TOTAL_INCOME=$(echo "$HTTP_BODY" | jq '[.[] | select(.amount > 0 and .is_transfer == false) | .amount] | add // 0 | . * 100 | round | . / 100')
TOTAL_EXPENSES=$(echo "$HTTP_BODY" | jq '[.[] | select(.amount < 0 and .is_transfer == false) | .amount] | add // 0 | . * -1 | . * 100 | round | . / 100')
NET_FLOW=$(echo "$TOTAL_INCOME $TOTAL_EXPENSES" | awk '{printf "%.2f", $1 - $2}')
TXN_COUNT=$(echo "$HTTP_BODY" | jq '[.[] | select(.is_transfer == false)] | length')
INCOME_COUNT=$(echo "$HTTP_BODY" | jq '[.[] | select(.amount > 0 and .is_transfer == false)] | length')
EXPENSE_COUNT=$(echo "$HTTP_BODY" | jq '[.[] | select(.amount < 0 and .is_transfer == false)] | length')

# Weekly breakdown
WEEKLY=$(echo "$HTTP_BODY" | jq -r '
  [.[] | select(.is_transfer == false)] |
  group_by(.date[0:7]) |
  map({
    month: .[0].date[0:7],
    income: ([.[] | select(.amount > 0) | .amount] | add // 0 | . * 100 | round | . / 100),
    expenses: ([.[] | select(.amount < 0) | .amount] | add // 0 | . * -1 | . * 100 | round | . / 100)
  }) |
  map(. + {net: (.income - .expenses | . * 100 | round | . / 100)})
')

if [ "$FORMAT" = "json" ]; then
  jq -n \
    --arg period "${START_DATE} to ${END_DATE}" \
    --argjson total_income "$TOTAL_INCOME" \
    --argjson total_expenses "$TOTAL_EXPENSES" \
    --arg net_flow "$NET_FLOW" \
    --argjson txn_count "$TXN_COUNT" \
    --argjson monthly "$WEEKLY" \
    '{period: $period, total_income: $total_income, total_expenses: $total_expenses, net_cash_flow: ($net_flow | tonumber), transaction_count: $txn_count, by_month: $monthly}'
  exit 0
fi

SURPLUS_DEFICIT="Surplus"
echo "$NET_FLOW" | grep -q '^-' && SURPLUS_DEFICIT="Deficit"

cat <<MDEOF
# Cash Flow Report: ${START_DATE} to ${END_DATE}

**Period:** ${START_DATE} to ${END_DATE}
**Total Income:** \$${TOTAL_INCOME} (${INCOME_COUNT} transactions)
**Total Expenses:** \$${TOTAL_EXPENSES} (${EXPENSE_COUNT} transactions)
**Net Cash Flow:** \$${NET_FLOW} (${SURPLUS_DEFICIT})

## Monthly Breakdown

| Month | Income | Expenses | Net Flow |
|-------|-------:|---------:|---------:|
MDEOF

echo "$WEEKLY" | jq -r '.[] | "| \(.month) | $\(.income) | $\(.expenses) | $\(.net) |"'

echo ""
echo "---"
echo "*Transfers between accounts are excluded. Data from PocketSmith API.*"
