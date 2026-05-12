#!/bin/sh
# ps-list-attachments.sh — List attachments for a transaction or user
# Usage: ps-list-attachments.sh [OPTIONS]

set -e

PS_BASE_URL="https://api.pocketsmith.com/v2"

usage() {
  cat <<EOF
Usage: ps-list-attachments.sh [OPTIONS]

Lists attachments. Pass --transaction-id to list attachments for a specific
transaction, or use --user-id to list all attachments for a user.

Options:
  --transaction-id ID   List attachments for this transaction
  --user-id ID          List all attachments for user (overrides PS_USER_ID)
  --api-key KEY         API key (overrides PS_API_KEY env var)
  --help                Show this help message

Environment:
  PS_API_KEY            PocketSmith developer API key (required)
  PS_USER_ID            PocketSmith user ID (used if --transaction-id not given)

Exit codes:
  0   Success
  1   API/HTTP error
  2   Missing arguments
EOF
}

TXN_ID=""

while [ $# -gt 0 ]; do
  case "$1" in
    --transaction-id) TXN_ID="$2"; shift 2 ;;
    --user-id)        PS_USER_ID="$2"; shift 2 ;;
    --api-key)        PS_API_KEY="$2"; shift 2 ;;
    --help)           usage; exit 0 ;;
    *) echo "ERROR: Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [ -z "$PS_API_KEY" ]; then
  echo "ERROR: PS_API_KEY is not set." >&2; exit 2
fi

if [ -n "$TXN_ID" ]; then
  URL="$PS_BASE_URL/transactions/$TXN_ID/attachments"
elif [ -n "$PS_USER_ID" ]; then
  URL="$PS_BASE_URL/users/$PS_USER_ID/attachments"
else
  echo "ERROR: Either --transaction-id or PS_USER_ID must be provided." >&2; exit 2
fi

HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -H "X-Developer-Key: $PS_API_KEY" \
  -H "Content-Type: application/json" \
  "$URL")

HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')
HTTP_CODE=$(echo "$HTTP_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" != "200" ]; then
  echo "ERROR: API returned HTTP $HTTP_CODE" >&2; echo "$HTTP_BODY" >&2; exit 1
fi

if command -v jq >/dev/null 2>&1; then
  echo "$HTTP_BODY" | jq '[.[] | {id, title, file_name, file_type, file_size, file_url, created_at}]'
else
  echo "$HTTP_BODY"
fi
