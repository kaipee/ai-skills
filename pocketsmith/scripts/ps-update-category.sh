#!/bin/sh
# ps-update-category.sh — Update a PocketSmith category
# DRY-RUN BY DEFAULT. Pass --execute to apply.

set -e

PS_BASE_URL="https://api.pocketsmith.com/v2"
AUDIT_LOG="${PS_AUDIT_LOG:-$HOME/.pocketsmith-audit.log}"

usage() {
  cat <<EOF
Usage: ps-update-category.sh [OPTIONS]

Updates a category via PUT /categories/{id}.
Only provided fields are updated.

DRY-RUN BY DEFAULT. Pass --execute to apply.

Options:
  --category-id ID    Category ID (required)
  --title NAME        New title
  --colour HEX        New hex colour (e.g. #FF5722)
  --parent-id ID      New parent category ID
  --is-transfer       Set as transfer category
  --refund-behaviour  One of: debits_are_deductions|credits_are_income|both
  --api-key KEY       API key (overrides PS_API_KEY env var)
  --execute           Actually apply the update (default: dry-run)
  --help              Show this help message

Environment:
  PS_API_KEY      PocketSmith developer API key (required)
  PS_READ_ONLY    Set to 1 to block all write operations
  PS_AUDIT_LOG    Path for audit log (default: ~/.pocketsmith-audit.log)

Exit codes:
  0   Success (or dry-run)
  1   API/HTTP error
  2   Missing/invalid arguments
EOF
}

CATEGORY_ID=""
TITLE=""
COLOUR=""
PARENT_ID=""
IS_TRANSFER=""
REFUND_BEHAVIOUR=""
EXECUTE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --category-id)      CATEGORY_ID="$2"; shift 2 ;;
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
if [ -z "$PS_API_KEY" ]; then echo "ERROR: PS_API_KEY is not set." >&2; exit 2; fi
if [ -z "$CATEGORY_ID" ]; then echo "ERROR: --category-id is required." >&2; exit 2; fi
if [ -z "$TITLE$COLOUR$PARENT_ID$IS_TRANSFER$REFUND_BEHAVIOUR" ]; then
  echo "ERROR: At least one field to update must be provided." >&2; exit 2
fi

FIRST=1; PAYLOAD="{"
add_field() {
  if [ "$FIRST" = "1" ]; then FIRST=0; else PAYLOAD="${PAYLOAD},"; fi
  PAYLOAD="${PAYLOAD}$1"
}
[ -n "$TITLE" ]            && add_field "\"title\":\"$TITLE\""
[ -n "$COLOUR" ]           && add_field "\"colour\":\"$COLOUR\""
[ -n "$PARENT_ID" ]        && add_field "\"parent_id\":$PARENT_ID"
[ -n "$IS_TRANSFER" ]      && add_field "\"is_transfer\":true"
[ -n "$REFUND_BEHAVIOUR" ] && add_field "\"refund_behaviour\":\"$REFUND_BEHAVIOUR\""
PAYLOAD="${PAYLOAD}}"

URL="$PS_BASE_URL/categories/$CATEGORY_ID"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

if [ -z "$EXECUTE" ]; then
  echo "[DRY-RUN] Would execute:"
  echo "  Method:  PUT"; echo "  URL:     $URL"; echo "  Payload: $PAYLOAD"
  echo ""; echo "Pass --execute to apply this change."
  printf '%s\tDRY_RUN\tupdate_category\t{"category_id":%s,"payload":%s}\n' "$TIMESTAMP" "$CATEGORY_ID" "$PAYLOAD" >> "$AUDIT_LOG" 2>/dev/null || true
  exit 0
fi

printf '%s\tEXECUTING\tupdate_category\t{"category_id":%s}\n' "$TIMESTAMP" "$CATEGORY_ID" >> "$AUDIT_LOG" 2>/dev/null || true

HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT \
  -H "X-Developer-Key: $PS_API_KEY" -H "Content-Type: application/json" \
  -d "$PAYLOAD" "$URL")

HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')
HTTP_CODE=$(echo "$HTTP_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" != "200" ]; then
  echo "ERROR: API returned HTTP $HTTP_CODE" >&2; echo "$HTTP_BODY" >&2; exit 1
fi

printf '%s\tEXECUTED\tupdate_category\t{"category_id":%s}\n' "$TIMESTAMP" "$CATEGORY_ID" >> "$AUDIT_LOG" 2>/dev/null || true
if command -v jq >/dev/null 2>&1; then echo "$HTTP_BODY" | jq '.'; else echo "$HTTP_BODY"; fi
