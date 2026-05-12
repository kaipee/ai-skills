#!/bin/sh
# ps-auth-check.sh — Validate PocketSmith API key and connectivity
# Usage: ps-auth-check.sh [--api-key KEY] [--help]

set -e

PS_BASE_URL="https://api.pocketsmith.com/v2"

usage() {
  cat <<EOF
Usage: ps-auth-check.sh [OPTIONS]

Validates that the PocketSmith API key is set and can authenticate successfully.
Calls GET /me and prints the authenticated user's ID, name, and email.

Options:
  --api-key KEY   API key (overrides PS_API_KEY env var)
  --help          Show this help message

Environment:
  PS_API_KEY      PocketSmith developer API key (required)

Exit codes:
  0   Authentication successful
  1   API/HTTP error
  2   Missing arguments
EOF
}

# Parse args
while [ $# -gt 0 ]; do
  case "$1" in
    --api-key) PS_API_KEY="$2"; shift 2 ;;
    --help)    usage; exit 0 ;;
    *) echo "ERROR: Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

# Validate API key
if [ -z "$PS_API_KEY" ]; then
  echo "ERROR: PS_API_KEY is not set. Export it or pass --api-key." >&2
  exit 2
fi

# Check curl is available
if ! command -v curl >/dev/null 2>&1; then
  echo "ERROR: curl is required but not found in PATH." >&2
  exit 1
fi

echo "Checking PocketSmith API connectivity..." >&2

HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -H "X-Developer-Key: $PS_API_KEY" \
  -H "Content-Type: application/json" \
  "$PS_BASE_URL/me")

HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')
HTTP_CODE=$(echo "$HTTP_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" != "200" ]; then
  echo "ERROR: API returned HTTP $HTTP_CODE" >&2
  echo "$HTTP_BODY" >&2
  case "$HTTP_CODE" in
    401) echo "HINT: API key is invalid or missing." >&2 ;;
    403) echo "HINT: API key lacks required scope." >&2 ;;
    429) echo "HINT: Rate limited. Wait and retry." >&2 ;;
    *)   echo "HINT: See references/api-endpoints.md for HTTP status meanings." >&2 ;;
  esac
  exit 1
fi

echo "Authentication successful (HTTP 200)." >&2

if command -v jq >/dev/null 2>&1; then
  echo "$HTTP_BODY" | jq '{id: .id, name: .name, email: .email, base_currency_code: .base_currency_code, time_zone: .time_zone}'
else
  echo "$HTTP_BODY"
fi
