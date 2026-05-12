#!/bin/sh
# ps-create-category.sh — Create a category in PocketSmith
# DRY-RUN BY DEFAULT. Pass --execute to apply.

set -e

PS_BASE_URL="https://api.pocketsmith.com/v2"
AUDIT_LOG="${PS_AUDIT_LOG:-$HOME/.pocketsmith-audit.log}"

usage() {
  cat <<EOF
Usage: ps-create-category.sh [OPTIONS]

Creates a new category via POST /users/{id}/categories.

DRY-RUN BY DEFAULT. Pass --execute to create the category.

Options:
  --user-id ID        PocketSmith user ID (overrides PS_USER_ID)
  --title NAME        Category title (required)
  --colour HEX        Hex colour code (e.g. #4CAF50)
  --parent-id ID      Parent category ID (omit for top-level)
  --is-transfer       Mark as a transfer category
  --refund-behaviour  One of: debits_are_deductions|credits_are_income|both
  --api-key KEY       API key (overrides PS_API_KEY env var)
  --execute           Actually create the category (default: dry-run)
  --help              Show this help message

Environment:
  PS_API_KEY      PocketSmith developer API key (required)
  PS_USER_ID      PocketSmith user ID (required)
  PS_READ_ONLY    Set to 1 to block all write operations
  PS_AUDIT_LOG    Path for audit log (default: ~/.pocketsmith-audit.log)

Exit codes:
  0   Success (or dry-run completed)
  1   API/HTTP error
  2   Missing/invalid arguments
EOF
}

TITLE=""
COLOUR=""
PARENT_ID=""
IS_TRANSFER=""
REFUND_BEHAVIOUR=""
EXECUTE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --user-id)          PS_USER_ID="$2"; shift 2 ;;
    --title)            TITLE="$2"; shift 2 ;;
    --colour)           COLOUR="$2"; shift 2 ;;
    --parent-id)        PARENT_ID="$2"; shift 2 ;;
    --is-transfer)      IS_TRANSFER="true"; shift ;;
    --refund-behaviour) REFUND_BEHAVIOUR="$2"; shift 2 ;;
    --api-key)          PS_API_KEY="$2"; shift 2 ;;
    --execute)          EXECUTE="true"; shift ;;
    --help)             usage; exit 0 ;;
    *) echo "ERROR: Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [ "${PS_READ_ONLY}" = "1" ]; then
  echo "ERROR: PS_READ_ONLY=1 is set. Write operations are disabled." >&2; exit 1
fi
if [ -z "$PS_API_KEY" ]; then
  echo "ERROR: PS_API_KEY is not set." >&2; exit 2
fi
if [ -z "$PS_USER_ID" ]; then
  echo "ERROR: PS_USER_ID is not set." >&2; exit 2
fi
if [ -z "$TITLE" ]; then
  echo "ERROR: --title is required." >&2; exit 2
fi

FIRST=1; PAYLOAD="{"
add_field() {
  if [ "$FIRST" = "1" ]; then FIRST=0; else PAYLOAD="${PAYLOAD},"; fi
  PAYLOAD="${PAYLOAD}$1"
}
add_field "\"title\":\"$TITLE\""
[ -n "$COLOUR" ]           && add_field "\"colour\":\"$COLOUR\""
[ -n "$PARENT_ID" ]        && add_field "\"parent_id\":$PARENT_ID"
[ -n "$IS_TRANSFER" ]      && add_field "\"is_transfer\":true"
[ -n "$REFUND_BEHAVIOUR" ] && add_field "\"refund_behaviour\":\"$REFUND_BEHAVIOUR\""
PAYLOAD="${PAYLOAD}}"

URL="$PS_BASE_URL/users/$PS_USER_ID/categories"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

if [ -z "$EXECUTE" ]; then
  echo "[DRY-RUN] Would execute:"
  echo "  Method:  POST"
  echo "  URL:     $URL"
  echo "  Payload: $PAYLOAD"
  echo ""; echo "Pass --execute to apply this change."
  printf '%s\tDRY_RUN\tcreate_category\t%s\n' "$TIMESTAMP" "$PAYLOAD" >> "$AUDIT_LOG" 2>/dev/null || true
  exit 0
fi

printf '%s\tEXECUTING\tcreate_category\t%s\n' "$TIMESTAMP" "$PAYLOAD" >> "$AUDIT_LOG" 2>/dev/null || true

HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST \
  -H "X-Developer-Key: $PS_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" "$URL")

HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')
HTTP_CODE=$(echo "$HTTP_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" != "200" ] && [ "$HTTP_CODE" != "201" ]; then
  echo "ERROR: API returned HTTP $HTTP_CODE" >&2; echo "$HTTP_BODY" >&2
  printf '%s\tFAILED\tcreate_category\t{"http_code":%s}\n' "$TIMESTAMP" "$HTTP_CODE" >> "$AUDIT_LOG" 2>/dev/null || true
  exit 1
fi

RESULT_ID=$(command -v jq >/dev/null 2>&1 && echo "$HTTP_BODY" | jq -r '.id // "unknown"' || echo "unknown")
printf '%s\tEXECUTED\tcreate_category\t{"result_id":%s}\n' "$TIMESTAMP" "$RESULT_ID" >> "$AUDIT_LOG" 2>/dev/null || true

if command -v jq >/dev/null 2>&1; then echo "$HTTP_BODY" | jq '.'; else echo "$HTTP_BODY"; fi
