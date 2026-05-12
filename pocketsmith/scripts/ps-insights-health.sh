#!/bin/sh
# ps-insights-health.sh — Financial health snapshot
# Usage: ps-insights-health.sh [OPTIONS]

set -e

PS_BASE_URL="https://api.pocketsmith.com/v2"

usage() {
  cat <<EOF
Usage: ps-insights-health.sh [OPTIONS]

Generates a composite financial health snapshot covering:
- Net worth (assets vs liabilities)
- Current month budget adherence
- Savings rate estimate
- Uncategorised transaction count
- Action items

Options:
  --user-id ID        PocketSmith user ID (overrides PS_USER_ID)
  --api-key KEY       API key (overrides PS_API_KEY)
  --start-date DATE   Period start (default: first of current month)
  --end-date DATE     Period end (default: today)
  --format FORMAT     Output format: markdown|json (default: markdown)
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
    --help)        usage; exit 0 ;;
    *) echo "ERROR: Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [ -z "$PS_API_KEY" ]; then echo "ERROR: PS_API_KEY is not set." >&2; exit 2; fi
if [ -z "$PS_USER_ID" ]; then echo "ERROR: PS_USER_ID is not set." >&2; exit 2; fi

# Fetch accounts (for net worth)
ACCOUNTS_RESP=$(curl -s -w "\n%{http_code}" \
  -H "X-Developer-Key: $PS_API_KEY" \
  "$PS_BASE_URL/users/$PS_USER_ID/accounts")
ACCOUNTS_BODY=$(echo "$ACCOUNTS_RESP" | sed '$d')
ACCOUNTS_CODE=$(echo "$ACCOUNTS_RESP" | tail -n1)
[ "$ACCOUNTS_CODE" != "200" ] && { echo "ERROR: Accounts API returned HTTP $ACCOUNTS_CODE" >&2; exit 1; }

# Fetch transactions (for income/expenses)
TXN_RESP=$(curl -s -w "\n%{http_code}" \
  -H "X-Developer-Key: $PS_API_KEY" \
  "$PS_BASE_URL/users/$PS_USER_ID/transactions?start_date=${START_DATE}&end_date=${END_DATE}&per_page=100")
TXN_BODY=$(echo "$TXN_RESP" | sed '$d')
TXN_CODE=$(echo "$TXN_RESP" | tail -n1)
[ "$TXN_CODE" != "200" ] && { echo "ERROR: Transactions API returned HTTP $TXN_CODE" >&2; exit 1; }

# Fetch budget summary
BUDGET_RESP=$(curl -s -w "\n%{http_code}" \
  -H "X-Developer-Key: $PS_API_KEY" \
  "$PS_BASE_URL/users/$PS_USER_ID/budget-summary?start_date=${START_DATE}&end_date=${END_DATE}")
BUDGET_BODY=$(echo "$BUDGET_RESP" | sed '$d')
BUDGET_CODE=$(echo "$BUDGET_RESP" | tail -n1)

if ! command -v jq >/dev/null 2>&1; then
  echo "NOTE: jq required for health insights. Install jq and retry." >&2; exit 1
fi

TOTAL_ASSETS=$(echo "$ACCOUNTS_BODY" | jq \
  '[.[] | select(.is_net_worth == true) | select(.type | test("bank|stocks|property|vehicle|pension|other_asset")) | .current_balance_in_base_currency] | add // 0 | . * 100 | round | . / 100')
TOTAL_LIABILITIES=$(echo "$ACCOUNTS_BODY" | jq \
  '[.[] | select(.is_net_worth == true) | select(.type | test("credits|loans|mortgage|other_liability")) | .current_balance_in_base_currency | . * -1] | add // 0 | . * 100 | round | . / 100')
NET_WORTH=$(echo "$TOTAL_ASSETS $TOTAL_LIABILITIES" | awk '{printf "%.2f", $1 - $2}')

TOTAL_INCOME=$(echo "$TXN_BODY" | jq '[.[] | select(.amount > 0 and .is_transfer == false) | .amount] | add // 0 | . * 100 | round | . / 100')
TOTAL_EXPENSES=$(echo "$TXN_BODY" | jq '[.[] | select(.amount < 0 and .is_transfer == false) | .amount] | add // 0 | . * -1 | . * 100 | round | . / 100')
SAVINGS=$(echo "$TOTAL_INCOME $TOTAL_EXPENSES" | awk '{printf "%.2f", $1 - $2}')
SAVINGS_RATE="0"
INCOME_CHECK=$(echo "$TOTAL_INCOME" | jq '. > 0')
[ "$INCOME_CHECK" = "true" ] && SAVINGS_RATE=$(echo "$SAVINGS $TOTAL_INCOME" | awk '{printf "%.1f", ($1 / $2) * 100}')

UNCATEGORISED=$(echo "$TXN_BODY" | jq '[.[] | select(.category == null and .is_transfer == false)] | length')
NEEDS_REVIEW=$(echo "$TXN_BODY" | jq '[.[] | select(.needs_review == true)] | length')

# Budget adherence (only if budget API succeeded)
OVER_BUDGET_COUNT="0"
if [ "$BUDGET_CODE" = "200" ]; then
  OVER_BUDGET_COUNT=$(echo "$BUDGET_BODY" | jq '[.[] | select(.type == "expense") | select(.actual_amount < .budget_amount)] | length')
fi

if [ "$FORMAT" = "json" ]; then
  jq -n \
    --arg period "${START_DATE} to ${END_DATE}" \
    --arg report_date "$(date +"%Y-%m-%d")" \
    --argjson total_assets "$TOTAL_ASSETS" \
    --argjson total_liabilities "$TOTAL_LIABILITIES" \
    --arg net_worth "$NET_WORTH" \
    --argjson total_income "$TOTAL_INCOME" \
    --argjson total_expenses "$TOTAL_EXPENSES" \
    --arg savings "$SAVINGS" \
    --arg savings_rate "$SAVINGS_RATE" \
    --argjson uncategorised "$UNCATEGORISED" \
    --argjson needs_review "$NEEDS_REVIEW" \
    --argjson over_budget_count "$OVER_BUDGET_COUNT" \
    '{period: $period, report_date: $report_date, net_worth: ($net_worth|tonumber), total_assets: $total_assets, total_liabilities: $total_liabilities, income: $total_income, expenses: $total_expenses, savings: ($savings|tonumber), savings_rate_pct: ($savings_rate|tonumber), uncategorised_transactions: $uncategorised, needs_review_count: $needs_review, over_budget_categories: $over_budget_count}'
  exit 0
fi

cat <<MDEOF
# Financial Health Snapshot

**As at:** ${END_DATE} | **Period:** ${START_DATE} to ${END_DATE}

## Net Worth
| Metric | Amount |
|--------|--------|
| Total Assets | \$${TOTAL_ASSETS} |
| Total Liabilities | \$${TOTAL_LIABILITIES} |
| **Net Worth** | **\$${NET_WORTH}** |

## Period Cash Flow
| Metric | Amount |
|--------|--------|
| Income | \$${TOTAL_INCOME} |
| Expenses | \$${TOTAL_EXPENSES} |
| Net Savings | \$${SAVINGS} |
| Savings Rate | ${SAVINGS_RATE}% |

## Action Items
MDEOF

[ "$UNCATEGORISED" -gt 0 ] && echo "- ⚠️ **${UNCATEGORISED} uncategorised transactions** — run \`ps-list-transactions.sh --type uncategorised\` to review"
[ "$NEEDS_REVIEW" -gt 0 ] && echo "- 🔍 **${NEEDS_REVIEW} transactions need review** — run \`ps-list-transactions.sh --needs-review\`"
[ "$OVER_BUDGET_COUNT" -gt 0 ] && echo "- 🔴 **${OVER_BUDGET_COUNT} categories over budget** — run \`ps-report-budget-vs-actual.sh\` for details"
[ "$UNCATEGORISED" -eq 0 ] && [ "$NEEDS_REVIEW" -eq 0 ] && [ "$OVER_BUDGET_COUNT" -eq 0 ] && echo "- ✅ No immediate action items"

echo ""
echo "---"
echo "*Run \`ps-insights-month-review.sh\` for a full month-end analysis.*"
