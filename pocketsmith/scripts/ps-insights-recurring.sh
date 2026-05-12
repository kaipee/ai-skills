#!/bin/sh
# ps-insights-recurring.sh — Identify recurring expenses by payee pattern
# Usage: ps-insights-recurring.sh [OPTIONS]

set -e

PS_BASE_URL="https://api.pocketsmith.com/v2"

usage() {
  cat <<EOF
Usage: ps-insights-recurring.sh [OPTIONS]

Identifies recurring expenses by analysing transaction patterns.
Looks for payees that appear regularly (monthly or more frequently)
across the analysis period and estimates annual cost.

Options:
  --user-id ID          PocketSmith user ID (overrides PS_USER_ID)
  --api-key KEY         API key (overrides PS_API_KEY)
  --start-date DATE     Analysis start, YYYY-MM-DD (default: 3 months ago)
  --end-date DATE       Analysis end, YYYY-MM-DD (default: today)
  --min-occurrences N   Minimum occurrences to flag as recurring (default: 2)
  --format FORMAT       Output format: markdown|json (default: markdown)
  --per-page N          Transactions per page, 1-100 (default: 100)
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

FORMAT="markdown"
PER_PAGE="100"
MIN_OCCURRENCES="2"
TODAY=$(date +"%Y-%m-%d")
# Default: 3 months ago — use awk for POSIX compatibility
THREE_MONTHS_AGO=$(date +"%Y-%m-%d" -d "3 months ago" 2>/dev/null || \
  awk 'BEGIN {
    split(ENVIRON["TODAY"] == "" ? "'$TODAY'" : ENVIRON["TODAY"], d, "-")
    y = d[1]; m = d[2] - 3
    if (m <= 0) { m += 12; y-- }
    printf "%04d-%02d-%02d\n", y, m, d[3]
  }')
START_DATE="$THREE_MONTHS_AGO"
END_DATE="$TODAY"

while [ $# -gt 0 ]; do
  case "$1" in
    --user-id)          PS_USER_ID="$2"; shift 2 ;;
    --api-key)          PS_API_KEY="$2"; shift 2 ;;
    --start-date)       START_DATE="$2"; shift 2 ;;
    --end-date)         END_DATE="$2"; shift 2 ;;
    --min-occurrences)  MIN_OCCURRENCES="$2"; shift 2 ;;
    --format)           FORMAT="$2"; shift 2 ;;
    --per-page)         PER_PAGE="$2"; shift 2 ;;
    --help)             usage; exit 0 ;;
    *) echo "ERROR: Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [ -z "$PS_API_KEY" ]; then echo "ERROR: PS_API_KEY is not set." >&2; exit 2; fi
if [ -z "$PS_USER_ID" ]; then echo "ERROR: PS_USER_ID is not set." >&2; exit 2; fi

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required for recurring expense analysis. Install jq and retry." >&2; exit 1
fi

HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -H "X-Developer-Key: $PS_API_KEY" \
  "$PS_BASE_URL/users/$PS_USER_ID/transactions?start_date=${START_DATE}&end_date=${END_DATE}&type=debit&per_page=${PER_PAGE}")

HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')
HTTP_CODE=$(echo "$HTTP_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" != "200" ]; then
  echo "ERROR: API returned HTTP $HTTP_CODE" >&2; echo "$HTTP_BODY" >&2; exit 1
fi

# Group by payee, find those appearing >= min_occurrences times
RECURRING=$(echo "$HTTP_BODY" | jq \
  --argjson min "$MIN_OCCURRENCES" \
  '[.[] | select(.amount < 0 and .is_transfer == false)] |
   group_by(.payee) |
   map(select(length >= $min)) |
   map({
     payee: .[0].payee,
     category: (.[0].category.title // "Uncategorised"),
     occurrences: length,
     avg_amount: (map(.amount | . * -1) | add / length | . * 100 | round | . / 100),
     total_in_period: (map(.amount | . * -1) | add | . * 100 | round | . / 100),
     first_seen: (map(.date) | sort | .[0]),
     last_seen: (map(.date) | sort | reverse | .[0]),
     months_seen: (map(.date[0:7]) | unique | length)
   }) |
   map(. + {
     estimated_annual: (.avg_amount * 12 | . * 100 | round | . / 100)
   }) |
   sort_by(.total_in_period) | reverse')

TOTAL_ANNUAL=$(echo "$RECURRING" | jq '[.[].estimated_annual] | add // 0 | . * 100 | round | . / 100')
COUNT=$(echo "$RECURRING" | jq 'length')

if [ "$FORMAT" = "json" ]; then
  echo "$RECURRING" | jq \
    --arg period "${START_DATE} to ${END_DATE}" \
    --argjson total_annual "$TOTAL_ANNUAL" \
    --argjson count "$COUNT" \
    '{period: $period, recurring_count: $count, estimated_total_annual_cost: $total_annual, recurring_expenses: .}'
  exit 0
fi

cat <<MDEOF
# Recurring Expenses Analysis

**Period analysed:** ${START_DATE} to ${END_DATE}
**Minimum occurrences to qualify:** ${MIN_OCCURRENCES}
**Recurring payees found:** ${COUNT}
**Estimated annual cost:** \$${TOTAL_ANNUAL}

## Recurring Expenses

| Payee | Category | Occurrences | Avg Amount | Total (Period) | Est. Annual |
|-------|----------|:-----------:|:----------:|:--------------:|:-----------:|
MDEOF

echo "$RECURRING" | jq -r '.[] | "| \(.payee) | \(.category) | \(.occurrences) | $\(.avg_amount) | $\(.total_in_period) | $\(.estimated_annual) |"'

echo ""
echo "## Notes"
echo ""
echo "- Occurrences are within the analysis period (${START_DATE} to ${END_DATE})"
echo "- Estimated annual cost assumes the average monthly amount × 12"
echo "- Review subscriptions you may want to cancel: run \`ps-update-transaction.sh\` to label them"
echo ""
echo "---"
echo "*Data: PocketSmith API — debit transactions only. Transfers excluded.*"
