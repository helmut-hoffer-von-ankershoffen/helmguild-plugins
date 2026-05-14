#!/usr/bin/env bash
# test-scripts-instagram-caption-lint.sh — exercises every rule in the
# bundled instagram-caption-lint helper.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER="$SCRIPT_DIR/../scripts/instagram-caption-lint.sh"
[[ -x "$HELPER" ]] || { echo "helper missing or not executable: $HELPER" >&2; exit 1; }

pass=0; fail=0
ok()  { printf '✓ %s\n' "$*"; pass=$((pass+1)); }
err() { printf '✗ %s\n' "$*" >&2; fail=$((fail+1)); }

run_with() { printf '%s' "$1" | "$HELPER" - "${@:2}"; }

# 1. Empty input → fails
if echo -n "" | "$HELPER" - >/dev/null 2>&1; then
  err "empty caption should fail"
else
  ok "empty caption fails"
fi

# 2. Hook too long → fails
long_hook=$(printf 'A%.0s' {1..200})
caption="$long_hook"$'\n\n#one #two #three'
if echo "$caption" | "$HELPER" - >/dev/null 2>&1; then
  err "long hook should fail"
else
  ok "hook > 125 chars fails"
fi

# 3. Too few hashtags → fails
caption=$'Short hook line.\n\n#alpha'
if echo "$caption" | "$HELPER" - >/dev/null 2>&1; then
  err "1 hashtag should fail"
else
  ok "< 3 hashtags fails"
fi

# 4. Too many hashtags → fails
tail=$(printf '#h%d ' {1..20})
caption="Hook line."$'\n\n'"$tail"
if echo "$caption" | "$HELPER" - >/dev/null 2>&1; then
  err "20 hashtags should fail"
else
  ok "> 15 hashtags fails"
fi

# 5. Hashtag in mid-caption (not in trailing block) → fails
caption="Hook with #midtag mid-line."$'\n\n'"#a #b #c"
if echo "$caption" | "$HELPER" - >/dev/null 2>&1; then
  err "mid-caption hashtag should fail"
else
  ok "mid-caption hashtag fails"
fi

# 6. "Link in bio" CTA → fails
caption=$'Hook line.\n\nClick the LINK IN BIO!\n\n#alpha #beta #gamma'
if echo "$caption" | "$HELPER" - >/dev/null 2>&1; then
  err "link-in-bio should fail"
else
  ok "link-in-bio CTA fails"
fi

# 7. Emoji-only line → fails
caption=$'Hook.\n\n🚀🚀🚀\n\n#a #b #c'
if echo "$caption" | "$HELPER" - >/dev/null 2>&1; then
  err "emoji-only line should fail"
else
  ok "emoji-only line fails"
fi

# 8. Valid caption → passes
caption=$'Pepe Arturo on calm operating, in 90 seconds.\n\nA grounded pipeline doesn'\''t need to be exciting. It just needs to ship.\n\n#agentic #mentoring #pepearturo #helmguild'
if echo "$caption" | "$HELPER" - >/dev/null 2>&1; then
  ok "well-formed caption passes"
else
  err "well-formed caption should pass"
fi

# 9. Over 2200 chars → fails
huge=$(printf 'a%.0s' {1..2500})
caption="$huge"$'\n\n#a #b #c'
if echo "$caption" | "$HELPER" - >/dev/null 2>&1; then
  err "> 2200 chars should fail"
else
  ok "> 2200 chars fails"
fi

# 10. Missing file argument → exit 2
if "$HELPER" /no/such/file >/dev/null 2>&1; then
  err "missing file should fail"
else
  rc=$?
  if [[ "$rc" -eq 2 ]]; then
    ok "missing file → exit 2"
  else
    err "missing file should exit 2, got $rc"
  fi
fi

printf '\n%d passed, %d failed.\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]] || exit 1
