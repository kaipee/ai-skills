#!/bin/sh
# ps-create-transaction.sh — Create a transaction in a PocketSmith transaction account
# DRY-RUN BY DEFAULT. Pass --execute to apply.

set -e

PS_BASE_URL="https://api.pocketsmith.com/v2"
AUDIT_LOG="${PS_AUDIT_LOG:-$HOME/.pocketsmith-audit.log}"

usage() {
  cat <<EOF
Usage: ps-create-transaction.sh [OPTIONS]

Creates a new transaction in a transaction account via
POST /transaction-accounts/{id}/transactions.

DRY-RUN BY DEFAULT — prints the intended request without calling the API.
Pass --execute to actually create the transaction.

Options:
  --transaction-account-id ID   Transaction account ID (required)
  --date DATE                   Transaction date, YYYY-MM-DD (required)
  --amount FLOAT                Amount; negative=expense, positive=income (required)
  --payee NAME                  Payee name (required)
  --note TEXT                   Optional note
  --category-id ID              Optional category ID
  --labels "tag1,tag2"          Optional comma-separated labels
  --needs-review                Mark transaction as needing review
  --api-key KEY                 API key (overrides PS_API_KEY env var)
  --execute                     Actually create the transaction (default: dry-run)
  --help                        Show this help message

Environment:
  PS_API_KEY      PocketSmith developer API key (required)
  PS_READ_ONLY    Set to 1 to block all write operations
  PS_AUDIT_LOG    Path for audit log (default: ~/.pocketsmith-audit.log)

Exit codes:
  0   Success (or dry-run completed)
  1   API/HTTP error
  2   Missing/invalid arguments
EOF
}

TXN_ACCOUNT_ID=""
DATE=""
AMOUNT=""
PAYEE=""
NOTE=""
CATEGORY_ID=""
LABELS=""
NEEDS_REVIEW=""
EXECUTE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --transaction-account-id) TXN_ACCOUNT_ID="$2"; shift 2 ;;
    --date)         DATE="$2"; shift 2 ;;
    --amount)       AMOUNT="$2"; shift 2 ;;
    --payee)        PAYEE="$2"; shift 2 ;;
    --note)         NOTE="$2"; shift 2 ;;
    --category-id)  CATEGORY_ID="$2"; shift 2 ;;
    --labels)       LABELS="$2"; shift 2 ;;
    --needs-review) NEEDS_REVIEW="true"; shift ;;
    --api-key)      PS_API_KEY="$2"; shift 2 ;;
    --execute)      EXECUTE="true"; shift ;;
    --help)         usage; exit 0 ;;
    *) echo "ERROR: Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

# Read-only mode guard
if [ "${PS_READ_ONLY}" = "1" ]; then
  echo "ERROR: PS_READ_ONLY=1 is set. Write operations are disabled." >&2
  exit 1
fi

# Required field checks
if [ -z "$PS_API_KEY" ]; then
  echo "ERROR: PS_API_KEY is not set." >&2; exit 2
fi
if [ -z "$TXN_ACCOUNT_ID" ]; then
  echo "ERROR: --transaction-account-id is required." >&2; exit 2
fi
if [ -z "$DATE" ]; then
  echo "ERROR: --date is required." >&2; exit 2
fi
if [ -z "$AMOUNT" ]; then
  echo "ERROR: --amount is required." >&2; exit 2
fi
if [ -z "$PAYEE" ]; then
  echo "ERROR: --payee is required." >&2; exit 2
fi

# Validate date
echo "$DATE" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' || {
  echo "ERROR: Date must be YYYY-MM-DD format. Got: \"$DATE\"" >&2; exit 2
}

# Validate amount is numeric
echo "$AMOUNT" | grep -qE '^-?[0-9]+(\.[0-9]+)?$' || {
  echo "ERROR: Amount must be numeric. Got: \"$AMOUNT\"" >&2; exit 2
}

# Build JSON payload
PAYLOAD="{\"payee\":\"$PAYEE\",\"amount\":$AMOUNT,\"date\":\"$DATE\""
[ -n "$NOTE" ]        && PAYLOAD="${PAYLOAD},\"note\":\"$NOTE\""
[ -n "$CATEGORY_ID" ] && PAYLOAD="${PAYLOAD},\"category_id\":$CATEGORY_ID"
[ -n "$LABELS" ]      && PAYLOAD="${PAYLOAD},\"labels\":\"$LABELS\""
[ -n "$NEEDS_REVIEW" ] && PAYLOAD="${PAYLOAD},\"needs_review\":true"
PAYLOAD="${PAYLOAD}}"

URL="$PS_BASE_URL/transaction-accounts/$TXN_ACCOUNT_ID/transactions"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

if [ -z "$EXECUTE" ]; then
  echo "[DRY-RUN] Would execute:"
  echo "  Method:  POST"
  echo "  URL:     $URL"
  echo "  Payload: $PAYLOAD"
  echo ""
  echo "Pass --execute to apply this change."
  # Audit log dry-run
  printf '%s\tDRY_RUN\tcreate_transaction\t%s\n' "$TIMESTAMP" "$PAYLOAD" >> "$AUDIT_LOG" 2>/dev/null || true
  exit 0
fi

# Audit log before execute
printf '%s\tEXECUTING\tcreate_transaction\t%s\n' "$TIMESTAMP" "$PAYLOAD" >> "$AUDIT_LOG" 2>/dev/null || true

HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST \
  -H "X-Developer-Key: $PS_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  "$URL")

HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')
HTTP_CODE=$(echo "$HTTP_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" != "200" ] && [ "$HTTP_CODE" != "201" ]; then
  echo "ERROR: API returned HTTP $HTTP_CODE" >&2
  echo "$HTTP_BODY" >&2
  printf '%s\tFAILED\tcreate_transaction\t{"http_code":%s}\n' "$TIMESTAMP" "$HTTP_CODE" >> "$AUDIT_LOG" 2>/dev/null || true
  exit 1
fi

# Audit log result
if command -v jq >/dev/null 2>&1; then
  RESULT_ID=$(echo "$HTTP_BODY" | jq -r '.id // "unknown"')
else
  RESULT_ID="unknown"
fi
printf '%s\tEXECUTED\tcreate_transaction\t{"result_id":%s,"payload":%s}\n' "$TIMESTAMP" "$RESULT_ID" "$PAYLOAD" >> "$AUDIT_LOG" 2>/dev/null || true

if command -v jq >/dev/null 2>&1; then
  echo "$HTTP_BODY" | jq '.'
else
  echo "$HTTP_BODY"
fi
