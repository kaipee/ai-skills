#!/bin/sh
# ps-get-account.sh — Get a single PocketSmith account by ID
# Usage: ps-get-account.sh --account-id ID [--api-key KEY] [--help]

set -e

PS_BASE_URL="https://api.pocketsmith.com/v2"

usage() {
  cat <<EOF
Usage: ps-get-account.sh [OPTIONS]

Fetches full details for a single account via GET /accounts/{id}.
Includes balance, type, linked transaction accounts and scenarios.

Options:
  --account-id ID  Account ID (required)
  --api-key KEY    API key (overrides PS_API_KEY env var)
  --help           Show this help message

Environment:
  PS_API_KEY       PocketSmith developer API key (required)

Exit codes:
  0   Success
  1   API/HTTP error
  2   Missing arguments
EOF
}

ACCOUNT_ID=""

while [ $# -gt 0 ]; do
  case "$1" in
    --account-id) ACCOUNT_ID="$2"; shift 2 ;;
    --api-key)    PS_API_KEY="$2"; shift 2 ;;
    --help)       usage; exit 0 ;;
    *) echo "ERROR: Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [ -z "$PS_API_KEY" ]; then
  echo "ERROR: PS_API_KEY is not set. Export it or pass --api-key." >&2
  exit 2
fi
if [ -z "$ACCOUNT_ID" ]; then
  echo "ERROR: --account-id is required." >&2
  usage >&2; exit 2
fi

HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -H "X-Developer-Key: $PS_API_KEY" \
  -H "Content-Type: application/json" \
  "$PS_BASE_URL/accounts/$ACCOUNT_ID")

HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')
HTTP_CODE=$(echo "$HTTP_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" != "200" ]; then
  echo "ERROR: API returned HTTP $HTTP_CODE" >&2
  echo "$HTTP_BODY" >&2
  exit 1
fi

if command -v jq >/dev/null 2>&1; then
  echo "$HTTP_BODY" | jq '.'
else
  echo "$HTTP_BODY"
fi
