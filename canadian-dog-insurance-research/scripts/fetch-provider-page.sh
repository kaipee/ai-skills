#!/bin/sh
# fetch-provider-page.sh
#
# Fetch a Canadian dog insurance provider page (HTML and optionally linked
# same-domain PDFs) into a timestamped cache directory and emit a traceability
# index entry. Designed for use by the canadian-dog-insurance-research skill.
#
# Usage:
#   fetch-provider-page.sh <url> [output-dir] [--with-pdfs]
#
# Defaults:
#   output-dir = ${TMPDIR:-/tmp}/canadian-dog-insurance-research/<UTC-date>
#
# Behaviour:
#   - Uses curl with a realistic User-Agent, --fail, --location, --max-time.
#   - Saves the response body to <output-dir>/<host>__<slug>.html
#   - Computes SHA256, captures HTTP status, retrieval UTC timestamp.
#   - Appends a CSV row to <output-dir>/index.csv
#       columns: utc,url,http_status,sha256,bytes,saved_path,kind
#   - With --with-pdfs, additionally downloads any *.pdf links whose host
#     matches the original URL's host. SPA-rendered links (set via JS) will
#     not be discovered; that is by design — fall back to WebFetch.
#
# Exit codes:
#   0  success
#   1  bad usage
#   2  curl hard failure on primary URL
#   3  missing dependency (curl, shasum/sha256sum)
#
# Limitations:
#   - Does not execute JavaScript. Quote-tool SPA pages will return shells.
#     The skill must fall back to a rendering-capable WebFetch in that case.
#   - PDF discovery is a naive grep; works for typical static link tags.
#   - Does not respect robots.txt; intended for low-volume manual research only.
#
set -eu

usage() {
  cat <<EOF >&2
Usage: $0 <url> [output-dir] [--with-pdfs]

  <url>          Required. https URL to fetch.
  [output-dir]   Optional. Default: \${TMPDIR:-/tmp}/canadian-dog-insurance-research/<UTC-date>
  --with-pdfs    Optional. Also download same-host *.pdf links found in the body.
EOF
  exit 1
}

# --- arg parsing ---
URL=""
OUT_DIR=""
WITH_PDFS="0"

for a in "$@"; do
  case "$a" in
    --with-pdfs) WITH_PDFS="1" ;;
    -h|--help) usage ;;
    *)
      if [ -z "$URL" ]; then URL="$a"
      elif [ -z "$OUT_DIR" ]; then OUT_DIR="$a"
      else
        echo "ERR: unexpected argument: $a" >&2
        usage
      fi
      ;;
  esac
done

[ -z "$URL" ] && usage

# --- dependency checks ---
command -v curl >/dev/null 2>&1 || { echo "ERR: curl not found" >&2; exit 3; }

if command -v shasum >/dev/null 2>&1; then
  SHA_CMD="shasum -a 256"
elif command -v sha256sum >/dev/null 2>&1; then
  SHA_CMD="sha256sum"
else
  echo "ERR: neither shasum nor sha256sum available" >&2
  exit 3
fi

# --- output dir ---
UTC_DATE="$(date -u +%Y-%m-%d)"
UTC_TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
DEFAULT_BASE="${TMPDIR:-/tmp}"
# strip trailing slash
DEFAULT_BASE="${DEFAULT_BASE%/}"
[ -z "$OUT_DIR" ] && OUT_DIR="$DEFAULT_BASE/canadian-dog-insurance-research/$UTC_DATE"
mkdir -p "$OUT_DIR"

INDEX="$OUT_DIR/index.csv"
if [ ! -f "$INDEX" ]; then
  printf 'utc,url,http_status,sha256,bytes,saved_path,kind\n' > "$INDEX"
fi

# --- helpers ---
slugify() {
  # turn a URL path/query into a filesystem-safe slug
  printf '%s' "$1" | tr '/?&=#%:.' '________' | tr -s '_' | cut -c1-120
}

host_of() {
  printf '%s' "$1" | awk -F/ '{print $3}'
}

UA='Mozilla/5.0 (compatible; canadian-dog-insurance-research/0.1; +https://github.com/anomalyco/opencode)'

fetch_one() {
  url="$1"
  kind="$2" # html|pdf
  host="$(host_of "$url")"
  slug="$(slugify "${url#*://*/}")"
  [ -z "$slug" ] && slug="root"
  ext="html"
  [ "$kind" = "pdf" ] && ext="pdf"
  out_file="$OUT_DIR/${host}__${slug}.${ext}"

  http_status="$(curl -sS -L --max-time 30 \
    -A "$UA" \
    -o "$out_file" \
    -w '%{http_code}' \
    "$url" || echo 000)"

  if [ "$http_status" = "000" ] || [ ! -s "$out_file" ]; then
    echo "WARN: fetch failed for $url (status=$http_status)" >&2
    rm -f "$out_file"
    if [ "$kind" = "html" ]; then
      return 2
    else
      return 0
    fi
  fi

  sha="$($SHA_CMD "$out_file" | awk '{print $1}')"
  bytes="$(wc -c < "$out_file" | tr -d ' ')"
  utc="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  # CSV-quote any field that contains a comma or quote
  csv_escape() {
    case "$1" in
      *,*|*\"*) printf '"%s"' "$(printf '%s' "$1" | sed 's/"/""/g')" ;;
      *) printf '%s' "$1" ;;
    esac
  }
  printf '%s,%s,%s,%s,%s,%s,%s\n' \
    "$utc" \
    "$(csv_escape "$url")" \
    "$http_status" \
    "$sha" \
    "$bytes" \
    "$(csv_escape "$out_file")" \
    "$kind" >> "$INDEX"

  echo "$out_file"
}

# --- primary fetch ---
PRIMARY_FILE="$(fetch_one "$URL" "html")" || {
  rc=$?
  echo "ERR: primary fetch failed (rc=$rc)" >&2
  exit 2
}

echo "Saved primary HTML: $PRIMARY_FILE" >&2
echo "Index:              $INDEX" >&2
echo "Retrieved at (UTC): $UTC_TS" >&2

# --- optional PDF discovery ---
if [ "$WITH_PDFS" = "1" ]; then
  PRIMARY_HOST="$(host_of "$URL")"
  # naive PDF link extraction: look for href="...pdf" or src="...pdf"
  # produce absolute URLs (best-effort)
  TMP_LINKS="$OUT_DIR/.pdf-links.$$"
  : > "$TMP_LINKS"

  # extract candidate PDF urls
  grep -oiE '(href|src)=["'\''"][^"'\'' ]+\.pdf' "$PRIMARY_FILE" \
    | sed -E 's/^(href|src)=["'\''"]//I' \
    | while read -r link; do
        case "$link" in
          http*) printf '%s\n' "$link" ;;
          //*)   printf 'https:%s\n' "$link" ;;
          /*)    printf 'https://%s%s\n' "$PRIMARY_HOST" "$link" ;;
          *)     printf 'https://%s/%s\n' "$PRIMARY_HOST" "$link" ;;
        esac
      done | sort -u >> "$TMP_LINKS" || true

  # filter to same host
  while read -r pdf_url; do
    [ -z "$pdf_url" ] && continue
    pdf_host="$(host_of "$pdf_url")"
    if [ "$pdf_host" = "$PRIMARY_HOST" ]; then
      echo "Fetching PDF: $pdf_url" >&2
      fetch_one "$pdf_url" "pdf" >/dev/null || true
    else
      echo "Skipping cross-host PDF: $pdf_url" >&2
    fi
  done < "$TMP_LINKS"

  rm -f "$TMP_LINKS"
fi

exit 0
