#!/usr/bin/env bash
# x-tweet-lint.sh — lint a draft X (formerly Twitter) post against the
# per-account voice rules of the publishing-x skill. Read-only; no API
# calls. Exits non-zero on any rule violation.
#
# Lints applied (in order):
#
#   1. Length — text must be ≤ 280 chars (X hard limit) and ≤ 270 by
#      default (margin for an auto-appended emoji signature).
#   2. Hashtag count — 0-3. X tolerates fewer than IG; 4+ trips the
#      "thirsty" perception and the spam heuristic.
#   3. Mandatory emoji signature — if VOICE_EMOJI is set, the post must
#      contain it.
#   4. Banned phrases — VOICE_BANNED="phrase1|phrase2" disqualifies any
#      post containing one of them. Case-insensitive substring match.
#   5. Empty / placeholder text — `TODO`, `XXX`, `<draft>`, etc.
#
# Usage:
#   x-tweet-lint.sh "<tweet text>"
#   VOICE_EMOJI=🍝 VOICE_BANNED="link in bio|DM us" x-tweet-lint.sh "..."
#   x-tweet-lint.sh --max-length 270 "..."
#
# Exit codes:
#   0 — clean.
#   1 — one or more lints failed (stdout lists which).
#   2 — usage error.

set -euo pipefail

max_length=270
hard_max=280

while [[ $# -gt 0 ]]; do
  case "$1" in
    --max-length) max_length="$2"; shift 2;;
    --help|-h)
      sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
      exit 0;;
    --) shift; break;;
    -*) echo "x-tweet-lint: unknown option $1" >&2; exit 2;;
    *) break;;
  esac
done

if [[ $# -ne 1 ]]; then
  echo "x-tweet-lint: expected exactly one positional argument (the tweet text)" >&2
  echo "usage: x-tweet-lint.sh [--max-length N] \"<tweet text>\"" >&2
  exit 2
fi

text="$1"
errors=()

# 1. Length.
# wc -m counts characters (locale-aware); X counts code-points roughly the
# same way for ASCII + most emoji. Close enough for lint purposes.
length=$(printf '%s' "$text" | wc -m | tr -d ' ')
if (( length > hard_max )); then
  errors+=("length: $length chars exceeds X hard cap of $hard_max")
elif (( length > max_length )); then
  errors+=("length: $length chars exceeds soft cap of $max_length (leave margin for emoji signature)")
fi

# 2. Hashtag count.
# Word boundary-aware count of `#word` tokens. grep returns 1 when there
# are no matches under pipefail, which would fail the whole script; the
# `|| true` swallows the no-match case so the count cleanly returns 0.
hashtag_count=$( { printf '%s' "$text" | grep -oE '(^|[[:space:]])#[A-Za-z0-9_]+' || true; } | wc -l | tr -d ' ')
if (( hashtag_count > 3 )); then
  errors+=("hashtags: $hashtag_count found, X voice rules cap at 3")
fi

# 3. Mandatory emoji signature.
if [[ -n "${VOICE_EMOJI:-}" ]]; then
  if ! printf '%s' "$text" | grep -qF -- "$VOICE_EMOJI"; then
    errors+=("emoji signature: required \"$VOICE_EMOJI\" missing")
  fi
fi

# 4. Banned phrases.
if [[ -n "${VOICE_BANNED:-}" ]]; then
  while IFS= read -r phrase; do
    [[ -z "$phrase" ]] && continue
    if printf '%s' "$text" | grep -qiF -- "$phrase"; then
      errors+=("banned phrase: \"$phrase\" found")
    fi
  done < <(printf '%s\n' "$VOICE_BANNED" | tr '|' '\n')
fi

# 5. Empty / placeholder.
if [[ -z "$text" ]]; then
  errors+=("empty: tweet text is empty")
fi
for placeholder in 'TODO' 'XXX' '<draft>' 'lorem ipsum'; do
  if printf '%s' "$text" | grep -qiF -- "$placeholder"; then
    errors+=("placeholder: \"$placeholder\" still in text")
  fi
done

if [[ ${#errors[@]} -gt 0 ]]; then
  printf 'x-tweet-lint: %d issue(s)\n' "${#errors[@]}" >&2
  for e in "${errors[@]}"; do printf '  - %s\n' "$e" >&2; done
  exit 1
fi

echo "x-tweet-lint: ok (length=$length, hashtags=$hashtag_count)"
exit 0
