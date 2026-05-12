#!/bin/sh
# ps-report-net-worth.sh — Net worth report showing assets, liabilities, and balance
# Usage: ps-report-net-worth.sh [OPTIONS]

set -e

PS_BASE_URL="https://api.pocketsmith.com/v2"

usage() {
  cat <<EOF
Usage: ps-report-net-worth.sh [OPTIONS]

Generates a net worth report from account balances.
Fetches all accounts and separates assets from liabilities.

Options:
  --user-id ID        PocketSmith user ID (overrides PS_USER_ID)
  --api-key KEY       API key (overrides PS_API_KEY)
  --format FORMAT     Output format: markdown|json (default: markdown)
  --help              Show this help message

Note: --start-date and --end-date are accepted for compatibility but
net worth is always reported as of the current balance date.

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

while [ $# -gt 0 ]; do
  case "$1" in
    --user-id)     PS_USER_ID="$2"; shift 2 ;;
    --api-key)     PS_API_KEY="$2"; shift 2 ;;
    --format)      FORMAT="$2"; shift 2 ;;
    --start-date)  shift 2 ;;  # accepted, ignored
    --end-date)    shift 2 ;;  # accepted, ignored
    --help)        usage; exit 0 ;;
    *) echo "ERROR: Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [ -z "$PS_API_KEY" ]; then echo "ERROR: PS_API_KEY is not set." >&2; exit 2; fi
if [ -z "$PS_USER_ID" ]; then echo "ERROR: PS_USER_ID is not set." >&2; exit 2; fi

HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -H "X-Developer-Key: $PS_API_KEY" \
  -H "Content-Type: application/json" \
  "$PS_BASE_URL/users/$PS_USER_ID/accounts")

HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')
HTTP_CODE=$(echo "$HTTP_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" != "200" ]; then
  echo "ERROR: API returned HTTP $HTTP_CODE" >&2; echo "$HTTP_BODY" >&2; exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "NOTE: jq not found — outputting raw JSON." >&2
  echo "$HTTP_BODY"; exit 0
fi

ASSET_TYPES="bank stocks property vehicle pension other_asset"
LIABILITY_TYPES="credits loans mortgage insurance other_liability"

ASSETS=$(echo "$HTTP_BODY" | jq --argjson types '["bank","stocks","property","vehicle","pension","other_asset"]' \
  '[.[] | select(.is_net_worth == true) | select(.type as $t | $types | index($t) != null) | {title, type, current_balance: .current_balance_in_base_currency, institution: .institution.title, balance_date: .current_balance_date}] | sort_by(.current_balance) | reverse')

LIABILITIES=$(echo "$HTTP_BODY" | jq --argjson types '["credits","loans","mortgage","insurance","other_liability"]' \
  '[.[] | select(.is_net_worth == true) | select(.type as $t | $types | index($t) != null) | {title, type, current_balance: .current_balance_in_base_currency, institution: .institution.title, balance_date: .current_balance_date}]')

TOTAL_ASSETS=$(echo "$ASSETS" | jq '[.[].current_balance] | add // 0')
TOTAL_LIABILITIES=$(echo "$LIABILITIES" | jq '[.[].current_balance | . * -1] | add // 0')
NET_WORTH=$(echo "$TOTAL_ASSETS $TOTAL_LIABILITIES" | awk '{printf "%.2f", $1 - $2}')

REPORT_DATE=$(date +"%Y-%m-%d")

if [ "$FORMAT" = "json" ]; then
  jq -n \
    --argjson assets "$ASSETS" \
    --argjson liabilities "$LIABILITIES" \
    --argjson total_assets "$TOTAL_ASSETS" \
    --argjson total_liabilities "$TOTAL_LIABILITIES" \
    --arg net_worth "$NET_WORTH" \
    --arg report_date "$REPORT_DATE" \
    '{report_date: $report_date, total_assets: $total_assets, total_liabilities: $total_liabilities, net_worth: ($net_worth | tonumber), assets: $assets, liabilities: $liabilities}'
  exit 0
fi

cat <<MDEOF
# Net Worth Report

**As at:** ${REPORT_DATE}
**Total Assets:** \$${TOTAL_ASSETS}
**Total Liabilities:** \$${TOTAL_LIABILITIES}
**Net Worth:** \$${NET_WORTH}

## Assets

| Account | Type | Balance | Institution |
|---------|------|--------:|-------------|
MDEOF

echo "$ASSETS" | jq -r '.[] | "| \(.title) | \(.type) | $\(.current_balance) | \(.institution // "—") |"'
echo "| | **Total Assets** | **\$${TOTAL_ASSETS}** | |"
echo ""
echo "## Liabilities"
echo ""
echo "| Account | Type | Balance | Institution |"
echo "|---------|------|--------:|-------------|"

echo "$LIABILITIES" | jq -r '.[] | "| \(.title) | \(.type) | $\(.current_balance) | \(.institution // "—") |"'
echo "| | **Total Liabilities** | **\$${TOTAL_LIABILITIES}** | |"
echo ""
echo "---"
echo "*Only accounts marked 'included in net worth' are shown. Balances in base currency.*"
