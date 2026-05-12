#!/bin/sh
# ps-insights-month-review.sh — Month-end review of key financial metrics
# Usage: ps-insights-month-review.sh [OPTIONS]

set -e

PS_BASE_URL="https://api.pocketsmith.com/v2"

usage() {
  cat <<EOF
Usage: ps-insights-month-review.sh [OPTIONS]

Generates a comprehensive month-end review covering:
- Income vs expenses summary
- Top spending categories
- Budget vs actual status
- Top payees (merchants)
- Savings rate
- Notable items (large transactions, uncategorised)

Options:
  --user-id ID        PocketSmith user ID (overrides PS_USER_ID)
  --api-key KEY       API key (overrides PS_API_KEY)
  --start-date DATE   Period start, YYYY-MM-DD (default: first of current month)
  --end-date DATE     Period end, YYYY-MM-DD (default: today)
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

FORMAT="markdown"
PER_PAGE="100"
TODAY=$(date +"%Y-%m-%d")
MONTH_START=$(date +"%Y-%m-01")
START_DATE="$MONTH_START"
END_DATE="$TODAY"

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

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required for month review insights. Install jq and retry." >&2; exit 1
fi

# Fetch transactions
TXN_RESP=$(curl -s -w "\n%{http_code}" \
  -H "X-Developer-Key: $PS_API_KEY" \
  "$PS_BASE_URL/users/$PS_USER_ID/transactions?start_date=${START_DATE}&end_date=${END_DATE}&per_page=${PER_PAGE}")
TXN_BODY=$(echo "$TXN_RESP" | sed '$d')
TXN_CODE=$(echo "$TXN_RESP" | tail -n1)
[ "$TXN_CODE" != "200" ] && { echo "ERROR: API returned HTTP $TXN_CODE" >&2; exit 1; }

# Fetch budget summary
BUDGET_RESP=$(curl -s -w "\n%{http_code}" \
  -H "X-Developer-Key: $PS_API_KEY" \
  "$PS_BASE_URL/users/$PS_USER_ID/budget-summary?start_date=${START_DATE}&end_date=${END_DATE}")
BUDGET_BODY=$(echo "$BUDGET_RESP" | sed '$d')
BUDGET_CODE=$(echo "$BUDGET_RESP" | tail -n1)

TOTAL_INCOME=$(echo "$TXN_BODY" | jq '[.[] | select(.amount > 0 and .is_transfer == false) | .amount] | add // 0 | . * 100 | round | . / 100')
TOTAL_EXPENSES=$(echo "$TXN_BODY" | jq '[.[] | select(.amount < 0 and .is_transfer == false) | .amount] | add // 0 | . * -1 | . * 100 | round | . / 100')
SAVINGS=$(echo "$TOTAL_INCOME $TOTAL_EXPENSES" | awk '{printf "%.2f", $1 - $2}')
SAVINGS_RATE=$(echo "$TOTAL_INCOME" | jq ". > 0") 
[ "$SAVINGS_RATE" = "true" ] && SAVINGS_RATE=$(echo "$SAVINGS $TOTAL_INCOME" | awk '{printf "%.1f", ($1 / $2) * 100}') || SAVINGS_RATE="0"

TOP_CATEGORIES=$(echo "$TXN_BODY" | jq \
  '[.[] | select(.amount < 0 and .is_transfer == false)] |
   group_by(.category.title // "Uncategorised") |
   map({category: .[0].category.title // "Uncategorised", total: (map(.amount) | add | . * -1 | . * 100 | round | . / 100), count: length}) |
   sort_by(.total) | reverse | .[0:5]')

TOP_PAYEES=$(echo "$TXN_BODY" | jq \
  '[.[] | select(.amount < 0 and .is_transfer == false)] |
   group_by(.payee) |
   map({payee: .[0].payee, total: (map(.amount) | add | . * -1 | . * 100 | round | . / 100), visits: length}) |
   sort_by(.total) | reverse | .[0:5]')

LARGEST_TXN=$(echo "$TXN_BODY" | jq \
  '[.[] | select(.amount < 0 and .is_transfer == false)] | sort_by(.amount) | .[0] | {date, payee, amount: (.amount * -1), category: .category.title}')

UNCATEGORISED=$(echo "$TXN_BODY" | jq '[.[] | select(.category == null and .is_transfer == false)] | length')

if [ "$FORMAT" = "json" ]; then
  jq -n \
    --arg period "${START_DATE} to ${END_DATE}" \
    --argjson income "$TOTAL_INCOME" \
    --argjson expenses "$TOTAL_EXPENSES" \
    --arg savings "$SAVINGS" \
    --arg savings_rate "$SAVINGS_RATE" \
    --argjson top_categories "$TOP_CATEGORIES" \
    --argjson top_payees "$TOP_PAYEES" \
    --argjson largest_txn "$LARGEST_TXN" \
    --argjson uncategorised "$UNCATEGORISED" \
    '{period: $period, income: $income, expenses: $expenses, savings: ($savings|tonumber), savings_rate_pct: ($savings_rate|tonumber), top_categories: $top_categories, top_payees: $top_payees, largest_transaction: $largest_txn, uncategorised_count: $uncategorised}'
  exit 0
fi

cat <<MDEOF
# Month-End Review: ${START_DATE} to ${END_DATE}

## Summary
| Metric | Amount |
|--------|--------|
| Income | \$${TOTAL_INCOME} |
| Expenses | \$${TOTAL_EXPENSES} |
| Net Savings | \$${SAVINGS} |
| Savings Rate | ${SAVINGS_RATE}% |

## Top Spending Categories
| # | Category | Total | Transactions |
|---|----------|------:|:------------:|
MDEOF

echo "$TOP_CATEGORIES" | jq -r 'to_entries[] | "| \(.key + 1) | \(.value.category) | $\(.value.total) | \(.value.count) |"'

cat <<MDEOF

## Top Payees
| # | Payee | Total | Visits |
|---|-------|------:|:------:|
MDEOF

echo "$TOP_PAYEES" | jq -r 'to_entries[] | "| \(.key + 1) | \(.value.payee) | $\(.value.total) | \(.value.visits) |"'

echo ""
echo "## Notable Items"
echo ""
echo "**Largest transaction:**"
echo "$LARGEST_TXN" | jq -r '"  \(.date) — \(.payee) — $\(.amount) (\(.category // "Uncategorised"))"'
echo ""
[ "$UNCATEGORISED" -gt 0 ] && echo "⚠️ **${UNCATEGORISED} uncategorised transactions** — run \`ps-list-transactions.sh --type uncategorised\` to review"
[ "$UNCATEGORISED" -eq 0 ] && echo "✅ All transactions are categorised"

echo ""
echo "---"
echo "*Data: PocketSmith API. Transfers excluded.*"
