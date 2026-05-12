#!/bin/sh
# ps-apply-category-rules.sh — Apply category rules to transactions
# DRY-RUN BY DEFAULT. Pass --execute to apply.

set -e

PS_BASE_URL="https://api.pocketsmith.com/v2"
AUDIT_LOG="${PS_AUDIT_LOG:-$HOME/.pocketsmith-audit.log}"

usage() {
  cat <<EOF
Usage: ps-apply-category-rules.sh [OPTIONS]

Creates a category rule via POST /categories/{id}/category-rules.
This automatically categorises matching transactions.

DRY-RUN BY DEFAULT. Pass --execute to create the rule.

Options:
  --category-id ID          Category to assign matching transactions to (required)
  --payee-matches PATTERN   Payee string pattern to match (required)
  --apply-to-all            Apply rule to all existing transactions
  --apply-to-uncategorised  Apply rule to uncategorised transactions only
  --api-key KEY             API key (overrides PS_API_KEY env var)
  --execute                 Actually create the rule (default: dry-run)
  --help                    Show this help message

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
PAYEE_MATCHES=""
APPLY_TO_ALL=""
APPLY_TO_UNCATEGORISED=""
EXECUTE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --category-id)            CATEGORY_ID="$2"; shift 2 ;;
    --payee-matches)          PAYEE_MATCHES="$2"; shift 2 ;;
    --apply-to-all)           APPLY_TO_ALL="true"; shift ;;
    --apply-to-uncategorised) APPLY_TO_UNCATEGORISED="true"; shift ;;
    --api-key)                PS_API_KEY="$2"; shift 2 ;;
    --execute)                EXECUTE="true"; shift ;;
    --help)                   usage; exit 0 ;;
    *) echo "ERROR: Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [ "${PS_READ_ONLY}" = "1" ]; then
  echo "ERROR: PS_READ_ONLY=1 is set. Write operations are disabled." >&2; exit 1
fi
if [ -z "$PS_API_KEY" ]; then echo "ERROR: PS_API_KEY is not set." >&2; exit 2; fi
if [ -z "$CATEGORY_ID" ]; then echo "ERROR: --category-id is required." >&2; exit 2; fi
if [ -z "$PAYEE_MATCHES" ]; then echo "ERROR: --payee-matches is required." >&2; exit 2; fi

PAYLOAD="{\"payee_matches\":\"$PAYEE_MATCHES\""
[ -n "$APPLY_TO_ALL" ]           && PAYLOAD="${PAYLOAD},\"apply_to_all\":true"
[ -n "$APPLY_TO_UNCATEGORISED" ] && PAYLOAD="${PAYLOAD},\"apply_to_uncategorised\":true"
PAYLOAD="${PAYLOAD}}"

URL="$PS_BASE_URL/categories/$CATEGORY_ID/category-rules"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

if [ -z "$EXECUTE" ]; then
  echo "[DRY-RUN] Would execute:"
  echo "  Method:  POST"; echo "  URL:     $URL"; echo "  Payload: $PAYLOAD"
  echo ""; echo "Pass --execute to create this rule."
  printf '%s\tDRY_RUN\tapply_category_rules\t%s\n' "$TIMESTAMP" "$PAYLOAD" >> "$AUDIT_LOG" 2>/dev/null || true
  exit 0
fi

printf '%s\tEXECUTING\tapply_category_rules\t%s\n' "$TIMESTAMP" "$PAYLOAD" >> "$AUDIT_LOG" 2>/dev/null || true

HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
  -H "X-Developer-Key: $PS_API_KEY" -H "Content-Type: application/json" \
  -d "$PAYLOAD" "$URL")

HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')
HTTP_CODE=$(echo "$HTTP_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" != "200" ] && [ "$HTTP_CODE" != "201" ]; then
  echo "ERROR: API returned HTTP $HTTP_CODE" >&2; echo "$HTTP_BODY" >&2; exit 1
fi

printf '%s\tEXECUTED\tapply_category_rules\t{"category_id":%s,"payee_matches":"%s"}\n' "$TIMESTAMP" "$CATEGORY_ID" "$PAYEE_MATCHES" >> "$AUDIT_LOG" 2>/dev/null || true
if command -v jq >/dev/null 2>&1; then echo "$HTTP_BODY" | jq '.'; else echo "$HTTP_BODY"; fi
