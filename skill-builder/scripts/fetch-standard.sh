#!/usr/bin/env sh
# fetch-standard.sh
#
# Refreshes the bundled Agent Skills standard documentation under
# `skill-builder/references/`. ALWAYS re-downloads — there is no
# "skip if cached" path. The skill-builder skill MUST run this at the
# start of every invocation so it reconciles itself against the latest
# upstream specification, never against a possibly-stale cache.
#
# Sources:
#   1. https://agentskills.io       — canonical Agent Skills spec & guides
#                                     (each page also published as <page>.md,
#                                     plus a combined llms-full.txt index).
#   2. https://github.com/anthropics/skills — Anthropic's reference impl.
#
# Usage:
#     sh skill-builder/scripts/fetch-standard.sh
#
# Requirements: POSIX sh, curl. No other dependencies.
#
# Exit codes:
#   0  success (all critical files fetched)
#   1  curl missing or a critical download failed (DO NOT proceed with
#      stale data; re-run after fixing connectivity).
#
# Files written into skill-builder/references/:
#   agent-skills-standard.md            — combined canonical spec & guides
#   agentskills-io/<page>.md            — individual upstream pages
#   anthropics-skills/spec.md           — upstream spec stub
#   anthropics-skills/template-SKILL.md — official minimal SKILL.md template
#   anthropics-skills/skill-creator-SKILL.md — Anthropic's skill-creator meta
#   FETCHED.txt                         — UTC + epoch timestamp + script ver

set -eu

SCRIPT_VERSION="3.0"

# ---------------------------------------------------------------------------
# Resolve paths relative to this script so the command works from any cwd.
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REF_DIR="$SKILL_DIR/references"
SITE_DIR="$REF_DIR/agentskills-io"
REPO_DIR="$REF_DIR/anthropics-skills"

# ---------------------------------------------------------------------------
# Preconditions
# ---------------------------------------------------------------------------
if ! command -v curl >/dev/null 2>&1; then
    echo "ERROR: curl is required but not found in PATH." >&2
    exit 1
fi

mkdir -p "$REF_DIR" "$SITE_DIR" "$REPO_DIR"

# Common curl options:
#   -fsSL : fail on HTTP errors, silent, show errors, follow redirects
#   Cache-busting headers ensure no intermediate cache returns stale bytes.
CURL='curl -fsSL --retry 3 --retry-delay 2 --connect-timeout 15 -H Cache-Control:no-cache -H Pragma:no-cache'

# fetch <url> <dest>  — download <url> to <dest>; warn (non-fatal) on failure.
fetch() {
    _url="$1"
    _dest="$2"
    if $CURL "$_url" -o "$_dest"; then
        echo "  ok   $_dest"
    else
        echo "  WARN failed: $_url" >&2
        return 1
    fi
}

# fetch_critical <url> <dest> — like fetch but aborts the script on failure.
fetch_critical() {
    if ! fetch "$1" "$2"; then
        echo "ERROR: critical download failed: $1" >&2
        echo "       Refusing to leave stale data behind. Fix connectivity and re-run." >&2
        exit 1
    fi
}

echo "Fetching Agent Skills standard (always-fresh, no cache) into: $REF_DIR"

# ---------------------------------------------------------------------------
# 1. agentskills.io — canonical spec & companion guides (clean Markdown)
# ---------------------------------------------------------------------------
SITE="https://agentskills.io"

PAGES="specification \
home \
clients \
client-implementation/adding-skills-support \
skill-creation/quickstart \
skill-creation/best-practices \
skill-creation/optimizing-descriptions \
skill-creation/evaluating-skills \
skill-creation/using-scripts"

echo "  source: $SITE"
for page in $PAGES; do
    out="$SITE_DIR/$(echo "$page" | tr '/' '_').md"
    fetch "$SITE/${page}.md" "$out" || true
done

# Combined LLM-friendly bundle. CRITICAL — this is the primary offline ref.
fetch_critical "$SITE/llms-full.txt" "$REF_DIR/agent-skills-standard.md"
# Also critical: per-page specification, used by reconciliation.
fetch_critical "$SITE/specification.md" "$SITE_DIR/specification.md"
fetch "$SITE/llms.txt" "$REF_DIR/agent-skills-index.md" || true

# ---------------------------------------------------------------------------
# 2. anthropics/skills — reference implementation artifacts
# ---------------------------------------------------------------------------
RAW="https://raw.githubusercontent.com/anthropics/skills/main"
echo "  source: $RAW"

fetch "$RAW/README.md"                          "$REPO_DIR/README.md"             || true
fetch "$RAW/spec/agent-skills-spec.md"          "$REPO_DIR/spec.md"               || true
fetch_critical "$RAW/template/SKILL.md"         "$REPO_DIR/template-SKILL.md"
fetch "$RAW/skills/skill-creator/SKILL.md"      "$REPO_DIR/skill-creator-SKILL.md" || true
fetch "$RAW/skills/skill-creator/references/schemas.md" \
                                                 "$REPO_DIR/skill-creator-schemas.md" || true

# ---------------------------------------------------------------------------
# 3. Provenance marker (UTC ISO + epoch seconds + script version)
# ---------------------------------------------------------------------------
NOW_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
NOW_EPOCH="$(date -u +%s)"
{
    printf 'Fetched: %s\n' "$NOW_UTC"
    printf 'Epoch: %s\n'   "$NOW_EPOCH"
    printf 'ScriptVersion: %s\n' "$SCRIPT_VERSION"
    printf 'Sources:\n'
    printf '  - %s/llms-full.txt\n'    "$SITE"
    printf '  - %s/specification.md\n' "$SITE"
    printf '  - %s/...\n'              "$RAW"
} > "$REF_DIR/FETCHED.txt"

echo "Done. Fetched at $NOW_UTC (epoch $NOW_EPOCH). See $REF_DIR/FETCHED.txt."
