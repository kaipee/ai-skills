#!/bin/sh
# ps-delete-category.sh — Delete a PocketSmith category
# REQUIRES --confirm flag. Irreversible.

set -e

PS_BASE_URL="https://api.pocketsmith.com/v2"
AUDIT_LOG="${PS_AUDIT_LOG:-$HOME/.pocketsmith-audit.log}"

usage() {
  cat <<EOF
Usage: ps-delete-category.sh [OPTIONS]

Permanently deletes a category via DELETE /categories/{id}.

REQUIRES --confirm flag. This operation is IRREVERSIBLE.
Transactions in this category will become uncategorised.

Options:
  --category-id ID   Category ID to delete (required)
  --api-key KEY      API key (overrides PS_API_KEY env var)
  --confirm          Required confirmation flag
  --help             Show this help message

Environment:
  PS_API_KEY      PocketSmith developer API key (required)
  PS_READ_ONLY    Set to 1 to block all write operations
  PS_AUDIT_LOG    Path for audit log (default: ~/.pocketsmith-audit.log)

Exit codes:
  0   Deleted
  1   API/HTTP error or refused
  2   Missing arguments
EOF
}

CATEGORY_ID=""
CONFIRM=""

while [ $# -gt 0 ]; do
  case "$1" in
    --category-id) CATEGORY_ID="$2"; shift 2 ;;
    --api-key)     PS_API_KEY="$2"; shift 2 ;;
    --confirm)     CONFIRM="true"; shift ;;
    --help)        usage; exit 0 ;;
    *) echo "ERROR: Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [ "${PS_READ_ONLY}" = "1" ]; then
  echo "ERROR: PS_READ_ONLY=1 is set. Write operations are disabled." >&2; exit 1
fi
if [ -z "$PS_API_KEY" ]; then echo "ERROR: PS_API_KEY is not set." >&2; exit 2; fi
if [ -z "$CATEGORY_ID" ]; then echo "ERROR: --category-id is required." >&2; exit 2; fi
if [ -z "$CONFIRM" ]; then
  echo "ERROR: Destructive operation requires --confirm flag." >&2
  echo "       Category ID: $CATEGORY_ID" >&2
  echo "       Transactions will become uncategorised." >&2
  echo "       Re-run with --confirm to proceed." >&2
  exit 1
fi

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")
printf '%s\tDELETING\tdelete_category\t{"category_id":%s}\n' "$TIMESTAMP" "$CATEGORY_ID" >> "$AUDIT_LOG" 2>/dev/null || true

HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE \
  -H "X-Developer-Key: $PS_API_KEY" -H "Content-Type: application/json" \
  "$PS_BASE_URL/categories/$CATEGORY_ID")

HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')
HTTP_CODE=$(echo "$HTTP_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" != "200" ] && [ "$HTTP_CODE" != "204" ]; then
  echo "ERROR: API returned HTTP $HTTP_CODE" >&2; echo "$HTTP_BODY" >&2; exit 1
fi

printf '%s\tDELETED\tdelete_category\t{"category_id":%s}\n' "$TIMESTAMP" "$CATEGORY_ID" >> "$AUDIT_LOG" 2>/dev/null || true
echo "{\"status\":\"deleted\",\"category_id\":$CATEGORY_ID}"
