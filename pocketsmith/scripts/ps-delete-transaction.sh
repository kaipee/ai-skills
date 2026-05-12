#!/bin/sh
# ps-delete-transaction.sh — Delete a PocketSmith transaction
# REQUIRES --confirm flag. Irreversible.

set -e

PS_BASE_URL="https://api.pocketsmith.com/v2"
AUDIT_LOG="${PS_AUDIT_LOG:-$HOME/.pocketsmith-audit.log}"

usage() {
  cat <<EOF
Usage: ps-delete-transaction.sh [OPTIONS]

Permanently deletes a transaction via DELETE /transactions/{id}.

REQUIRES --confirm flag. This operation is IRREVERSIBLE.

Options:
  --transaction-id ID   Transaction ID to delete (required)
  --api-key KEY         API key (overrides PS_API_KEY env var)
  --confirm             Required confirmation flag
  --help                Show this help message

Environment:
  PS_API_KEY      PocketSmith developer API key (required)
  PS_READ_ONLY    Set to 1 to block all write operations
  PS_AUDIT_LOG    Path for audit log (default: ~/.pocketsmith-audit.log)

Exit codes:
  0   Transaction deleted
  1   API/HTTP error or operation refused
  2   Missing arguments
EOF
}

TXN_ID=""
CONFIRM=""

while [ $# -gt 0 ]; do
  case "$1" in
    --transaction-id) TXN_ID="$2"; shift 2 ;;
    --api-key)        PS_API_KEY="$2"; shift 2 ;;
    --confirm)        CONFIRM="true"; shift ;;
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
if [ -z "$CONFIRM" ]; then
  echo "ERROR: Destructive operation requires --confirm flag." >&2
  echo "       Review the transaction ID before confirming:" >&2
  echo "         Transaction ID: $TXN_ID" >&2
  echo "       Re-run with --confirm to proceed." >&2
  exit 1
fi

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")
printf '%s\tDELETING\tdelete_transaction\t{"transaction_id":%s,"confirmed":true}\n' "$TIMESTAMP" "$TXN_ID" >> "$AUDIT_LOG" 2>/dev/null || true

HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X DELETE \
  -H "X-Developer-Key: $PS_API_KEY" \
  -H "Content-Type: application/json" \
  "$PS_BASE_URL/transactions/$TXN_ID")

HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')
HTTP_CODE=$(echo "$HTTP_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" != "200" ] && [ "$HTTP_CODE" != "204" ]; then
  echo "ERROR: API returned HTTP $HTTP_CODE" >&2; echo "$HTTP_BODY" >&2
  printf '%s\tFAILED\tdelete_transaction\t{"transaction_id":%s,"http_code":%s}\n' "$TIMESTAMP" "$TXN_ID" "$HTTP_CODE" >> "$AUDIT_LOG" 2>/dev/null || true
  exit 1
fi

printf '%s\tDELETED\tdelete_transaction\t{"transaction_id":%s}\n' "$TIMESTAMP" "$TXN_ID" >> "$AUDIT_LOG" 2>/dev/null || true
echo "{\"status\":\"deleted\",\"transaction_id\":$TXN_ID}"
