#!/usr/bin/env bash
# test-scripts-state-dir-init.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER="$SCRIPT_DIR/../scripts/state-dir-init.sh"
[[ -x "$HELPER" ]] || { echo "missing helper: $HELPER" >&2; exit 1; }

pass=0; fail=0
ok()  { printf '✓ %s\n' "$*"; pass=$((pass+1)); }
err() { printf '✗ %s\n' "$*" >&2; fail=$((fail+1)); }

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

# 1. No path → exit 2.
code=0; "$HELPER" >/dev/null 2>&1 || code=$?
[[ "$code" == 2 ]] && ok "no path → exit 2" || err "no path should exit 2 (got $code)"

# 2. Happy path.
"$HELPER" --path "$tmp/s1" >/dev/null
for f in publish-log.jsonl audit.jsonl plan-week-_template.md README.md .gitignore veo-queue; do
  [[ -e "$tmp/s1/$f" ]] && ok "created $f" || err "missing $f"
done

# 3. publish-log + audit start empty.
if [[ ! -s "$tmp/s1/publish-log.jsonl" ]] && [[ ! -s "$tmp/s1/audit.jsonl" ]]; then
  ok "log files start empty"
else
  err "log files should start empty"
fi

# 4. --canonical-here creates pieces/.
"$HELPER" --path "$tmp/s2" --canonical-here >/dev/null
[[ -d "$tmp/s2/pieces" ]] && ok "--canonical-here creates pieces/" || err "pieces/ missing"

# 5. No --canonical-here → no pieces/.
[[ ! -d "$tmp/s1/pieces" ]] && ok "without --canonical-here, no pieces/" || err "pieces/ should not exist"

# 6. .gitignore in place.
if grep -qE '^\*$' "$tmp/s1/.gitignore"; then ok ".gitignore present"; else err ".gitignore missing or wrong"; fi

# 7. README.md mentions setup-doctor.
if grep -q 'setup-doctor.sh' "$tmp/s1/README.md"; then ok "README points at setup-doctor"; else err "README missing setup-doctor pointer"; fi

# 8. Refuses to overwrite.
code=0; "$HELPER" --path "$tmp/s1" >/dev/null 2>&1 || code=$?
[[ "$code" == 1 ]] && ok "refuses to overwrite (exit 1)" || err "should refuse (got $code)"

# 9. --force overrides.
"$HELPER" --path "$tmp/s1" --force >/dev/null
ok "--force overwrites successfully"

# 10. PEPE_PIPELINE_STATE_DIR env var.
PEPE_PIPELINE_STATE_DIR="$tmp/s3" "$HELPER" >/dev/null
[[ -f "$tmp/s3/publish-log.jsonl" ]] && ok "PEPE_PIPELINE_STATE_DIR env honoured" || err "env var not honoured"

# 11. Unknown arg → exit 2.
code=0; "$HELPER" --frobnicate >/dev/null 2>&1 || code=$?
[[ "$code" == 2 ]] && ok "unknown arg → exit 2" || err "unknown arg should exit 2"

# 12. --help exits 0.
code=0; "$HELPER" --help >/dev/null 2>&1 || code=$?
[[ "$code" == 0 ]] && ok "--help exits 0" || err "--help should exit 0"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
