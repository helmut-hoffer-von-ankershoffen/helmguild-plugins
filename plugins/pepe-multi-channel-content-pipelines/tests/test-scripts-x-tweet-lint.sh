#!/usr/bin/env bash
# test-scripts-x-tweet-lint.sh — exercises every rule in the bundled
# x-tweet-lint helper.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER="$SCRIPT_DIR/../scripts/x-tweet-lint.sh"
[[ -x "$HELPER" ]] || { echo "helper missing or not executable: $HELPER" >&2; exit 1; }

pass=0; fail=0
ok()  { printf '✓ %s\n' "$*"; pass=$((pass+1)); }
err() { printf '✗ %s\n' "$*" >&2; fail=$((fail+1)); }

# 1. Empty text → fails.
if "$HELPER" "" >/dev/null 2>&1; then
  err "empty text should fail"
else
  ok "empty text fails"
fi

# 2. Clean short tweet → passes.
if "$HELPER" "Calm operator notes. #grounded 🍝" >/dev/null 2>&1; then
  ok "clean short tweet passes"
else
  err "clean short tweet should pass"
fi

# 3. Over the soft cap (270) but under hard cap (280) → fails.
soft_over=$(printf 'A%.0s' {1..275})
if "$HELPER" "$soft_over" >/dev/null 2>&1; then
  err "275 chars should fail soft cap"
else
  ok "275 chars fails soft cap"
fi

# 4. Over the hard cap (280) → fails.
hard_over=$(printf 'A%.0s' {1..300})
if "$HELPER" "$hard_over" >/dev/null 2>&1; then
  err "300 chars should fail hard cap"
else
  ok "300 chars fails hard cap"
fi

# 5. --max-length 270 explicit → 270 chars at soft cap passes.
soft_at=$(printf 'A%.0s' {1..270})
if "$HELPER" --max-length 270 "$soft_at" >/dev/null 2>&1; then
  ok "270 chars with --max-length 270 passes"
else
  err "270 chars with --max-length 270 should pass"
fi

# 6. > 3 hashtags → fails.
if "$HELPER" "#one #two #three #four 🍝" >/dev/null 2>&1; then
  err "4 hashtags should fail"
else
  ok "4 hashtags fails"
fi

# 7. Exactly 3 hashtags → passes.
if "$HELPER" "#one #two #three 🍝" >/dev/null 2>&1; then
  ok "3 hashtags passes"
else
  err "3 hashtags should pass"
fi

# 8. Mandatory emoji signature missing → fails.
if VOICE_EMOJI=🍝 "$HELPER" "Plain text no emoji" >/dev/null 2>&1; then
  err "missing emoji signature should fail"
else
  ok "missing emoji signature fails"
fi

# 9. Mandatory emoji signature present → passes.
if VOICE_EMOJI=🍝 "$HELPER" "Plain text 🍝" >/dev/null 2>&1; then
  ok "present emoji signature passes"
else
  err "present emoji signature should pass"
fi

# 10. Banned phrase trips.
if VOICE_BANNED="link in bio|DM us" "$HELPER" "Hot take: link in bio" >/dev/null 2>&1; then
  err "banned phrase should trip"
else
  ok "banned phrase trips"
fi

# 11. Placeholder TODO trips.
if "$HELPER" "TODO write this tweet" >/dev/null 2>&1; then
  err "placeholder TODO should trip"
else
  ok "placeholder TODO trips"
fi

# 12. Bad option exits 2.
code=0
"$HELPER" --frobnicate >/dev/null 2>&1 || code=$?
if [[ "$code" == 2 ]]; then
  ok "unknown option exits 2"
else
  err "unknown option should exit 2 (got $code)"
fi

# Summary.
printf '\n%d passed, %d failed\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
