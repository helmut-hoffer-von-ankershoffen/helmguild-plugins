#!/usr/bin/env bash
# test-scripts-brand-identity-scaffold.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER="$SCRIPT_DIR/../scripts/brand-identity-scaffold.sh"
[[ -x "$HELPER" ]] || { echo "missing helper: $HELPER" >&2; exit 1; }

pass=0; fail=0
ok()  { printf '✓ %s\n' "$*"; pass=$((pass+1)); }
err() { printf '✗ %s\n' "$*" >&2; fail=$((fail+1)); }

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

# 1. No path + no env var → exit 2.
code=0; "$HELPER" >/dev/null 2>&1 || code=$?
[[ "$code" == 2 ]] && ok "no path → exit 2" || err "no path should exit 2 (got $code)"

# 2. Happy path with --brand + --disciplines.
out=$("$HELPER" --path "$tmp/b1" --brand "Test Brand" --disciplines "demo other" 2>&1)
for f in character.md voice.md palette.md typography.md off-brand.md redo-criteria.md scenes/_template.md refs/character/README.md disciplines/demo.md disciplines/other.md README.md; do
  if [[ -f "$tmp/b1/$f" ]]; then ok "created $f"; else err "missing $f"; fi
done

# 3. Brand name interpolated into character.md.
if grep -q "Test Brand" "$tmp/b1/character.md"; then ok "brand name interpolated"; else err "brand name not interpolated"; fi

# 4. Discipline contracts created from --disciplines list.
if grep -qE "^# Test Brand discipline: demo" "$tmp/b1/disciplines/demo.md"; then ok "discipline file has correct header"; else err "discipline header wrong"; fi

# 5. Default disciplines used when --disciplines omitted.
"$HELPER" --path "$tmp/b2" --brand "Default Brand" >/dev/null
for d in talking-head suit candid; do
  [[ -f "$tmp/b2/disciplines/$d.md" ]] && ok "default discipline $d" || err "default discipline $d missing"
done

# 6. Refuses to overwrite.
code=0; "$HELPER" --path "$tmp/b1" --brand "X" >/dev/null 2>&1 || code=$?
[[ "$code" == 1 ]] && ok "refuses to overwrite (exit 1)" || err "should refuse overwrite (got $code)"

# 7. --force overrides.
"$HELPER" --path "$tmp/b1" --brand "Forced" --force >/dev/null
if grep -q "Forced" "$tmp/b1/character.md"; then ok "--force overwrites"; else err "--force did not overwrite"; fi

# 8. BRAND_STYLE_GUIDE_PATH env var.
BRAND_STYLE_GUIDE_PATH="$tmp/b3" "$HELPER" --brand "From Env" >/dev/null
[[ -f "$tmp/b3/character.md" ]] && ok "BRAND_STYLE_GUIDE_PATH env honoured" || err "env var not honoured"

# 9. Brand defaults to basename of path when --brand omitted.
"$HELPER" --path "$tmp/auto-brand" >/dev/null
if grep -q "auto-brand" "$tmp/auto-brand/character.md"; then ok "brand defaults to basename"; else err "brand basename default missing"; fi

# 10. --help exits 0.
code=0; "$HELPER" --help >/dev/null 2>&1 || code=$?
[[ "$code" == 0 ]] && ok "--help exits 0" || err "--help should exit 0"

# 11. Unknown arg → exit 2.
code=0; "$HELPER" --frobnicate >/dev/null 2>&1 || code=$?
[[ "$code" == 2 ]] && ok "unknown arg → exit 2" || err "unknown arg should exit 2"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
