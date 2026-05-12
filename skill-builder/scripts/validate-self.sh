#!/usr/bin/env sh
# validate-self.sh
#
# Self-reconciliation validator for the skill-builder skill. Verifies:
#   1. references/FETCHED.txt exists AND its epoch is within the last 600s
#      (i.e., fetch-standard.sh was run in this very invocation).
#   2. SKILL.md frontmatter satisfies the Agent Skills standard's hard rules:
#        - name matches ^[a-z0-9]+(-[a-z0-9]+)*$, length 1..64,
#          equals the directory name (skill-builder).
#        - description present, length 1..1024.
#        - compatibility (if present) length <= 500.
#        - metadata (if present) is a flat string->string map.
#        - license (if present) is a string.
#
# Exit codes:
#   0  all checks pass
#   1  any check failed (caller MUST NOT proceed with the skill)
#
# Usage:
#     sh skill-builder/scripts/validate-self.sh

set -eu

FRESH_WINDOW_SECS=600

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REF_DIR="$SKILL_DIR/references"
FETCHED="$REF_DIR/FETCHED.txt"
SKILL_MD="$SKILL_DIR/SKILL.md"
DIR_NAME="$(basename "$SKILL_DIR")"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

pass() {
    echo "PASS: $*"
}

# ---------------------------------------------------------------------------
# 1. Freshness check
# ---------------------------------------------------------------------------
if [ ! -f "$FETCHED" ]; then
    fail "references/FETCHED.txt missing — run scripts/fetch-standard.sh first."
fi

FETCHED_EPOCH="$(awk -F': *' '/^Epoch:/ {print $2; exit}' "$FETCHED" || true)"
if [ -z "${FETCHED_EPOCH:-}" ]; then
    fail "FETCHED.txt has no Epoch line — run scripts/fetch-standard.sh first."
fi

NOW_EPOCH="$(date -u +%s)"
AGE=$(( NOW_EPOCH - FETCHED_EPOCH ))
if [ "$AGE" -lt 0 ] || [ "$AGE" -gt "$FRESH_WINDOW_SECS" ]; then
    fail "references stale (age=${AGE}s, max=${FRESH_WINDOW_SECS}s) — run scripts/fetch-standard.sh first."
fi
pass "references fresh (age=${AGE}s)"

# ---------------------------------------------------------------------------
# 2. SKILL.md presence
# ---------------------------------------------------------------------------
if [ ! -f "$SKILL_MD" ]; then
    fail "SKILL.md not found at $SKILL_MD"
fi
pass "SKILL.md present"

# ---------------------------------------------------------------------------
# 3. Frontmatter validation (prefer python3+yaml; fall back to grep).
# ---------------------------------------------------------------------------
HAVE_PY=0
if command -v python3 >/dev/null 2>&1; then
    if python3 -c 'import yaml' >/dev/null 2>&1; then
        HAVE_PY=1
    fi
fi

if [ "$HAVE_PY" -eq 1 ]; then
    python3 - "$SKILL_MD" "$DIR_NAME" <<'PY'
import re, sys, yaml

path, dir_name = sys.argv[1], sys.argv[2]
text = open(path, 'r', encoding='utf-8').read()
m = re.match(r'^---\s*\n(.*?)\n---\s*\n', text, re.DOTALL)
if not m:
    print("FAIL: SKILL.md has no YAML frontmatter block", file=sys.stderr)
    sys.exit(1)

try:
    fm = yaml.safe_load(m.group(1)) or {}
except yaml.YAMLError as e:
    print(f"FAIL: frontmatter YAML parse error: {e}", file=sys.stderr)
    sys.exit(1)

errors = []

name = fm.get('name')
if not isinstance(name, str) or not name:
    errors.append("name missing or not a string")
else:
    if not re.match(r'^[a-z0-9]+(-[a-z0-9]+)*$', name):
        errors.append(f"name '{name}' violates ^[a-z0-9]+(-[a-z0-9]+)*$")
    if not (1 <= len(name) <= 64):
        errors.append(f"name length {len(name)} not in 1..64")
    if name != dir_name:
        errors.append(f"name '{name}' != directory '{dir_name}'")

desc = fm.get('description')
if not isinstance(desc, str) or not desc:
    errors.append("description missing or not a string")
elif not (1 <= len(desc) <= 1024):
    errors.append(f"description length {len(desc)} not in 1..1024")

compat = fm.get('compatibility')
if compat is not None:
    if not isinstance(compat, str):
        errors.append("compatibility present but not a string")
    elif len(compat) > 500:
        errors.append(f"compatibility length {len(compat)} > 500")

lic = fm.get('license')
if lic is not None and not isinstance(lic, str):
    errors.append("license present but not a string")

md = fm.get('metadata')
if md is not None:
    if not isinstance(md, dict):
        errors.append("metadata present but not a mapping")
    else:
        for k, v in md.items():
            if not isinstance(k, str):
                errors.append(f"metadata key {k!r} not a string")
            if not isinstance(v, str):
                errors.append(f"metadata['{k}'] not a string (got {type(v).__name__})")

if errors:
    for e in errors:
        print("FAIL: " + e, file=sys.stderr)
    sys.exit(1)

print(f"PASS: name='{name}' (matches dir, regex, length OK)")
print(f"PASS: description length={len(desc)} (<=1024)")
if compat is not None:
    print(f"PASS: compatibility length={len(compat)} (<=500)")
if lic is not None:
    print(f"PASS: license is a string")
if md is not None:
    print(f"PASS: metadata is a flat string->string map ({len(md)} keys)")
PY
    rc=$?
    if [ "$rc" -ne 0 ]; then
        fail "frontmatter validation failed (see errors above)"
    fi
else
    echo "WARN: python3+PyYAML unavailable; using minimal grep fallback."
    grep -q '^name: skill-builder$' "$SKILL_MD" || fail "name != skill-builder (grep fallback)"
    grep -q '^description: ' "$SKILL_MD"        || fail "description missing (grep fallback)"
    pass "minimal grep checks (name, description present)"
fi

# ---------------------------------------------------------------------------
# 4. Conciseness Directive presence (lightweight grep check)
# ---------------------------------------------------------------------------
if grep -q '^## Conciseness Directive' "$SKILL_MD"; then
    pass "Conciseness Directive section present"
else
    fail "Conciseness Directive section missing from SKILL.md"
fi

echo
echo "ALL CHECKS PASSED"
exit 0
