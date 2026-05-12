#!/bin/sh
# ps-report-budget-vs-actual.sh — Budget vs actual report with variance analysis
# Usage: ps-report-budget-vs-actual.sh --start-date DATE --end-date DATE [OPTIONS]

set -e

PS_BASE_URL="https://api.pocketsmith.com/v2"

usage() {
  cat <<EOF
Usage: ps-report-budget-vs-actual.sh [OPTIONS]

Generates a budget vs actual report using the PocketSmith budget-summary API.
Shows each category's budgeted amount, actual spend, and variance.

Options:
  --user-id ID        PocketSmith user ID (overrides PS_USER_ID)
  --api-key KEY       API key (overrides PS_API_KEY)
  --start-date DATE   Report period start, YYYY-MM-DD (required)
  --end-date DATE     Report period end, YYYY-MM-DD (required)
  --format FORMAT     Output format: markdown|json (default: markdown)
  --roll-up           Roll sub-categories into parent categories
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
ROLL_UP=""

while [ $# -gt 0 ]; do
  case "$1" in
    --user-id)     PS_USER_ID="$2"; shift 2 ;;
    --api-key)     PS_API_KEY="$2"; shift 2 ;;
    --start-date)  START_DATE="$2"; shift 2 ;;
    --end-date)    END_DATE="$2"; shift 2 ;;
    --format)      FORMAT="$2"; shift 2 ;;
    --roll-up)     ROLL_UP="true"; shift ;;
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

if ! command -v jq >/dev/null 2>&1; then
  echo "NOTE: jq not found — outputting raw JSON." >&2
  echo "$HTTP_BODY"; exit 0
fi

if [ "$FORMAT" = "json" ]; then
  echo "$HTTP_BODY" | jq \
    --arg period "${START_DATE} to ${END_DATE}" \
    '{period: $period, budget_summary: .}'
  exit 0
fi

# Process and display
EXPENSE_DATA=$(echo "$HTTP_BODY" | jq '[.[] | select(.type == "expense") | {
  category: .category.title,
  budgeted: (.budget_amount | . * -1 | . * 100 | round | . / 100),
  actual: (.actual_amount | . * -1 | . * 100 | round | . / 100),
  variance: ((.budget_amount - .actual_amount) | . * -1 | . * 100 | round | . / 100)
}] | sort_by(.actual) | reverse')

INCOME_DATA=$(echo "$HTTP_BODY" | jq '[.[] | select(.type == "income") | {
  category: .category.title,
  budgeted: (.budget_amount | . * 100 | round | . / 100),
  actual: (.actual_amount | . * 100 | round | . / 100),
  variance: ((.actual_amount - .budget_amount) | . * 100 | round | . / 100)
}]')

TOTAL_BUDGET_EXP=$(echo "$EXPENSE_DATA" | jq '[.[].budgeted] | add // 0')
TOTAL_ACTUAL_EXP=$(echo "$EXPENSE_DATA" | jq '[.[].actual] | add // 0')
TOTAL_VARIANCE=$(echo "$EXPENSE_DATA" | jq '[.[].variance] | add // 0')

cat <<MDEOF
# Budget vs Actual: ${START_DATE} to ${END_DATE}

**Period:** ${START_DATE} to ${END_DATE}
**Total Budgeted (Expenses):** \$${TOTAL_BUDGET_EXP}
**Total Actual (Expenses):** \$${TOTAL_ACTUAL_EXP}
**Variance:** \$${TOTAL_VARIANCE}

## Expenses

| Category | Budgeted | Actual | Variance | Status |
|----------|:--------:|:------:|:--------:|:------:|
MDEOF

echo "$EXPENSE_DATA" | jq -r '.[] |
  if .variance > 0 then "✅"
  elif (.actual / .budgeted) > 0.9 then "⚠️"
  else "🔴"
  end as $status |
  "| \(.category) | $\(.budgeted) | $\(.actual) | $\(.variance) | \($status) |"'

echo "| **Total** | **\$${TOTAL_BUDGET_EXP}** | **\$${TOTAL_ACTUAL_EXP}** | **\$${TOTAL_VARIANCE}** | |"
echo ""
echo "## Income"
echo ""
echo "| Category | Budgeted | Actual | Variance |"
echo "|----------|:--------:|:------:|:--------:|"

echo "$INCOME_DATA" | jq -r '.[] | "| \(.category) | $\(.budgeted) | $\(.actual) | $\(.variance) |"'

echo ""
echo "**Status key:** ✅ Under budget | ⚠️ >90% used | 🔴 Over budget"
echo ""
echo "---"
echo "*Data: PocketSmith API /users/${PS_USER_ID}/budget-summary*"
