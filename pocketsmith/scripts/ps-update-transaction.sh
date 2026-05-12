#!/bin/sh
# ps-update-transaction.sh — Update a PocketSmith transaction
# DRY-RUN BY DEFAULT. Pass --execute to apply.

set -e

PS_BASE_URL="https://api.pocketsmith.com/v2"
AUDIT_LOG="${PS_AUDIT_LOG:-$HOME/.pocketsmith-audit.log}"

usage() {
  cat <<EOF
Usage: ps-update-transaction.sh [OPTIONS]

Updates a transaction via PUT /transactions/{id}.
Only the fields you provide are updated (partial update).

DRY-RUN BY DEFAULT — prints the intended request without calling the API.
Pass --execute to actually update the transaction.

Options:
  --transaction-id ID   Transaction ID (required)
  --payee NAME          New payee name
  --date DATE           New date, YYYY-MM-DD
  --amount FLOAT        New amount
  --note TEXT           New note
  --category-id ID      New category ID (use 0 to uncategorise)
  --labels "t1,t2"      New comma-separated labels (replaces existing)
  --needs-review        Set the needs-review flag to true
  --no-needs-review     Clear the needs-review flag
  --api-key KEY         API key (overrides PS_API_KEY env var)
  --execute             Actually update the transaction (default: dry-run)
  --help                Show this help message

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

TXN_ID=""
PAYEE=""
DATE=""
AMOUNT=""
NOTE=""
CATEGORY_ID=""
LABELS=""
NEEDS_REVIEW=""
EXECUTE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --transaction-id) TXN_ID="$2"; shift 2 ;;
    --payee)          PAYEE="$2"; shift 2 ;;
    --date)           DATE="$2"; shift 2 ;;
    --amount)         AMOUNT="$2"; shift 2 ;;
    --note)           NOTE="$2"; shift 2 ;;
    --category-id)    CATEGORY_ID="$2"; shift 2 ;;
    --labels)         LABELS="$2"; shift 2 ;;
    --needs-review)   NEEDS_REVIEW="true"; shift ;;
    --no-needs-review) NEEDS_REVIEW="false"; shift ;;
    --api-key)        PS_API_KEY="$2"; shift 2 ;;
    --execute)        EXECUTE="true"; shift ;;
    --help)           usage; exit 0 ;;
    *) echo "ERROR: Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [ "${PS_READ_ONLY}" = "1" ]; then
  echo "ERROR: PS_READ_ONLY=1 is set. Write operations are disabled." >&2; exit 1
fi
if [ -z "$PS_API_KEY" ]; then
  echo "ERROR: PS_API_KEY is not set." >&2; exit 2
fi
if [ -z "$TXN_ID" ]; then
  echo "ERROR: --transaction-id is required." >&2; exit 2
fi

# Validate optional date
if [ -n "$DATE" ]; then
  echo "$DATE" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' || {
    echo "ERROR: Date must be YYYY-MM-DD. Got: \"$DATE\"" >&2; exit 2
  }
fi

# Validate optional amount
if [ -n "$AMOUNT" ]; then
  echo "$AMOUNT" | grep -qE '^-?[0-9]+(\.[0-9]+)?$' || {
    echo "ERROR: Amount must be numeric. Got: \"$AMOUNT\"" >&2; exit 2
  }
fi

# Ensure at least one field is being updated
if [ -z "$PAYEE$DATE$AMOUNT$NOTE$CATEGORY_ID$LABELS$NEEDS_REVIEW" ]; then
  echo "ERROR: At least one field to update must be provided." >&2; exit 2
fi

# Build JSON payload (only provided fields)
FIRST=1
PAYLOAD="{"
add_field() {
  if [ "$FIRST" = "1" ]; then FIRST=0; else PAYLOAD="${PAYLOAD},"; fi
  PAYLOAD="${PAYLOAD}$1"
}
[ -n "$PAYEE" ]       && add_field "\"payee\":\"$PAYEE\""
[ -n "$DATE" ]        && add_field "\"date\":\"$DATE\""
[ -n "$AMOUNT" ]      && add_field "\"amount\":$AMOUNT"
[ -n "$NOTE" ]        && add_field "\"note\":\"$NOTE\""
[ -n "$CATEGORY_ID" ] && add_field "\"category_id\":$CATEGORY_ID"
[ -n "$LABELS" ]      && add_field "\"labels\":\"$LABELS\""
[ -n "$NEEDS_REVIEW" ] && add_field "\"needs_review\":$NEEDS_REVIEW"
PAYLOAD="${PAYLOAD}}"

URL="$PS_BASE_URL/transactions/$TXN_ID"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

if [ -z "$EXECUTE" ]; then
  echo "[DRY-RUN] Would execute:"
  echo "  Method:  PUT"
  echo "  URL:     $URL"
  echo "  Payload: $PAYLOAD"
  echo ""
  echo "Pass --execute to apply this change."
  printf '%s\tDRY_RUN\tupdate_transaction\t{"transaction_id":%s,"payload":%s}\n' "$TIMESTAMP" "$TXN_ID" "$PAYLOAD" >> "$AUDIT_LOG" 2>/dev/null || true
  exit 0
fi

printf '%s\tEXECUTING\tupdate_transaction\t{"transaction_id":%s,"payload":%s}\n' "$TIMESTAMP" "$TXN_ID" "$PAYLOAD" >> "$AUDIT_LOG" 2>/dev/null || true

HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X PUT \
  -H "X-Developer-Key: $PS_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  "$URL")

HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')
HTTP_CODE=$(echo "$HTTP_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" != "200" ]; then
  echo "ERROR: API returned HTTP $HTTP_CODE" >&2; echo "$HTTP_BODY" >&2
  printf '%s\tFAILED\tupdate_transaction\t{"transaction_id":%s,"http_code":%s}\n' "$TIMESTAMP" "$TXN_ID" "$HTTP_CODE" >> "$AUDIT_LOG" 2>/dev/null || true
  exit 1
fi

printf '%s\tEXECUTED\tupdate_transaction\t{"transaction_id":%s}\n' "$TIMESTAMP" "$TXN_ID" >> "$AUDIT_LOG" 2>/dev/null || true

if command -v jq >/dev/null 2>&1; then
  echo "$HTTP_BODY" | jq '.'
else
  echo "$HTTP_BODY"
fi
