#!/usr/bin/env bash
# instagram-caption-lint.sh — lints a draft Instagram caption against
# Pepe's per-channel voice rules. Read-only; no API calls.
#
# Pepe's per-channel rules for Instagram (encoded as static lint
# checks below; the playbook skill `per-channel-voice-rules-explicit`
# is the normative source):
#
#   - First line: hook (<= 125 chars; truncation rule of the feed).
#   - Hashtags: 3–15 inclusive, last block of the caption, no
#     mid-caption hashtags.
#   - No emoji-only lines.
#   - No "click the link in bio" (low-friction CTAs only).
#   - Total length: <= 2200 chars (IG API limit).
#
# Usage:
#   instagram-caption-lint.sh <path-to-caption.txt>
#   echo "caption..." | instagram-caption-lint.sh -
#
# Exit codes:
#   0  all checks pass
#   1  at least one rule violated (errors on stderr)
#   2  bad invocation

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: instagram-caption-lint.sh <file|-> " >&2
  exit 2
fi

src="$1"
if [[ "$src" == "-" ]]; then
  text="$(cat)"
elif [[ -f "$src" ]]; then
  text="$(cat "$src")"
else
  echo "no such file: $src" >&2
  exit 2
fi

# Reusable counters.
errors=0
fail() { printf '✗ %s\n' "$*" >&2; errors=$((errors + 1)); }
ok()   { printf '✓ %s\n' "$*"; }

# 1. Total length
len=${#text}
if (( len == 0 )); then
  fail "empty caption"
elif (( len > 2200 )); then
  fail "caption is $len chars; Instagram caps at 2200"
else
  ok "length $len <= 2200"
fi

# 2. First-line hook length (everything before the first \n).
first_line="${text%%$'\n'*}"
hook_len=${#first_line}
if (( hook_len == 0 )); then
  fail "first line is empty; feed truncation needs a hook in the first 125 chars"
elif (( hook_len > 125 )); then
  fail "first line is $hook_len chars; > 125 (feed truncation cutoff)"
else
  ok "hook line $hook_len <= 125"
fi

# 3. No emoji-only lines (rough heuristic: line with no a-zA-Z0-9).
emoji_only=$(awk 'NF && !match($0, /[A-Za-z0-9]/) { print NR }' <<<"$text" || true)
if [[ -n "$emoji_only" ]]; then
  fail "emoji-only line(s) at: $(echo "$emoji_only" | tr '\n' ',' | sed 's/,$//')"
else
  ok "no emoji-only lines"
fi

# 4. CTA scan — block any "click the link in bio".
if grep -Fqi "link in bio" <<<"$text"; then
  fail "'link in bio' CTA found (against Pepe's voice rule)"
else
  ok "no link-in-bio CTA"
fi

# 5. Hashtag count + position. Strip trailing whitespace, then count
# #words anywhere; separately count #words in the trailing block.
total_tags=$(grep -oE '#[A-Za-z][A-Za-z0-9_]*' <<<"$text" | wc -l | tr -d ' ')
# Last paragraph = everything after the final blank line (or full body
# if there's none).
last_block=$(awk 'BEGIN{RS=""} {body=$0} END{print body}' <<<"$text")
tail_tags=$(grep -oE '#[A-Za-z][A-Za-z0-9_]*' <<<"$last_block" | wc -l | tr -d ' ')
if (( total_tags < 3 )); then
  fail "$total_tags hashtags; Pepe's range is 3-15"
elif (( total_tags > 15 )); then
  fail "$total_tags hashtags; Pepe's range is 3-15"
elif (( tail_tags != total_tags )); then
  fail "hashtags must all live in the final paragraph ($tail_tags of $total_tags do)"
else
  ok "$total_tags hashtags, all in the tail block"
fi

# Summary
if (( errors == 0 )); then
  printf '\n%d/%d rules passed.\n' 5 5
  exit 0
else
  printf '\n%d rule(s) violated.\n' "$errors" >&2
  exit 1
fi
