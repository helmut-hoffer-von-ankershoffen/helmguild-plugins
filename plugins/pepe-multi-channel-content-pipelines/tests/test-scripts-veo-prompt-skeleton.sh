#!/usr/bin/env bash
# test-scripts-veo-prompt-skeleton.sh — exercises the bundled Veo
# prompt skeleton renderer.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER="$SCRIPT_DIR/../scripts/veo-prompt-skeleton.sh"
[[ -x "$HELPER" ]] || { echo "helper missing or not executable: $HELPER" >&2; exit 1; }

pass=0; fail=0
ok()  { printf '✓ %s\n' "$*"; pass=$((pass+1)); }
err() { printf '✗ %s\n' "$*" >&2; fail=$((fail+1)); }

# 1. No brief → exit 64
if "$HELPER" >/dev/null 2>&1; then
  err "no brief should fail"
else
  rc=$?
  if [[ "$rc" -eq 64 ]]; then ok "no brief → exit 64"; else err "no brief expected 64, got $rc"; fi
fi

# 2. Default values present in output
out=$("$HELPER" "Pepe walks along a Berlin canal")
for needle in "SHOT: medium" "SUBJECT: Pepe walks along a Berlin canal" "LIGHTING: overcast" "LENS: 35mm" "CAMERA: static" "PACE: slow" "DURATION: 8s"; do
  if grep -q "$needle" <<<"$out"; then ok "default present: $needle"; else err "default missing: $needle"; fi
done

# 3. Override flags take effect
out=$("$HELPER" --shot wide --duration 10 --lighting "golden hour" --lens 85mm "test")
for needle in "SHOT: wide" "DURATION: 10s" "LIGHTING: golden hour" "LENS: 85mm"; do
  if grep -q "$needle" <<<"$out"; then ok "override applied: $needle"; else err "override missing: $needle"; fi
done

# 4. SOUND default uses diegetic-only phrasing (Pepe's voice rule)
out=$("$HELPER" "x")
if grep -q "diegetic" <<<"$out"; then ok "default sound is diegetic"; else err "default sound should be diegetic"; fi

# 5. Unknown option → exit 64
if "$HELPER" --bogus 1 "x" >/dev/null 2>&1; then
  err "unknown option should fail"
else
  rc=$?
  if [[ "$rc" -eq 64 ]]; then ok "unknown option → exit 64"; else err "unknown option expected 64, got $rc"; fi
fi

# 6. Output contains exactly the 9 expected keys, no more.
out=$("$HELPER" "x")
keys=$(grep -oE '^[A-Z]+:' <<<"$out" | sort -u | wc -l | tr -d ' ')
if [[ "$keys" -eq 9 ]]; then ok "output has 9 prompt keys"; else err "expected 9 keys, got $keys"; fi

printf '\n%d passed, %d failed.\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]] || exit 1
