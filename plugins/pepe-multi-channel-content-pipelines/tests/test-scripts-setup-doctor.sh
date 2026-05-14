#!/usr/bin/env bash
# test-scripts-setup-doctor.sh — exercises the bundled setup-doctor
# helper. All cases use `--offline` to avoid hitting Google / Meta / X
# during CI; one explicit case asserts that the offline status flips
# from ready to skipped-offline.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER="$SCRIPT_DIR/../scripts/setup-doctor.sh"
[[ -x "$HELPER" ]] || { echo "helper missing or not executable: $HELPER" >&2; exit 1; }

pass=0; fail=0
ok()  { printf '✓ %s\n' "$*"; pass=$((pass+1)); }
err() { printf '✗ %s\n' "$*" >&2; fail=$((fail+1)); }

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

creds="$tmpdir/creds"
state="$tmpdir/state"
mkdir -p "$creds" "$state"

# 1. Empty tree: every channel reports `missing`; exit 1.
code=0
out=$("$HELPER" --offline --creds-root "$creds" --state-dir "$state" 2>&1) || code=$?
if [[ "$code" == 1 ]]; then ok "empty tree exits 1"; else err "empty tree should exit 1 (got $code)"; fi
# strategy probe sees the bare state dir (mkdir above) and reports
# `partial` because publish-log.jsonl isn't there yet; the four
# credential-backed channels report `missing`.
for ch in veo instagram x blog; do
  if echo "$out" | grep -qE "^✗ ${ch} +missing"; then
    ok "empty tree: ${ch} missing"
  else
    err "empty tree: ${ch} not reported missing"
  fi
done
if echo "$out" | grep -qE '^◐ strategy +partial'; then
  ok "empty tree: strategy partial (state dir but no publish-log)"
else
  err "empty tree: strategy not reported partial"
fi

# 2. Selective probe with --channel.
code=0
out=$("$HELPER" --offline --channel veo --creds-root "$creds" --state-dir "$state" 2>&1) || code=$?
veo_lines=$(echo "$out" | wc -l | tr -d ' ')
if [[ "$veo_lines" == "1" ]]; then
  ok "--channel veo emits exactly one line"
else
  err "--channel veo should emit 1 line, got $veo_lines"
fi

# 3. Populated creds + offline → skipped-offline for credentialed channels.
mkdir -p "$creds/gemini" "$creds/instagram" "$creds/x" "$creds/blog" "$tmpdir/blog"
echo "fake-key" > "$creds/gemini/api-key"
printf 'IG_USER_ID=12345\nIG_PAGE_TOKEN=tok\n' > "$creds/instagram/env"
printf 'X_CLIENT_ID=cid\nX_CLIENT_SECRET=csec\nX_REFRESH_TOKEN=rtok\n' > "$creds/x/env"
printf "BLOG_ROOT=$tmpdir/blog\nBLOG_PUBLIC_URL=https://example.invalid\n" > "$creds/blog/env"
touch "$state/publish-log.jsonl"
code=0
out=$("$HELPER" --offline --creds-root "$creds" --state-dir "$state" 2>&1) || code=$?
if [[ "$code" == 0 ]]; then ok "populated tree exits 0"; else err "populated tree should exit 0 (got $code)"; fi
for ch in veo instagram x blog; do
  if echo "$out" | grep -qE "^∅ ${ch} +skipped-offline"; then
    ok "populated tree: ${ch} skipped-offline"
  else
    err "populated tree: ${ch} not skipped-offline"
  fi
done
if echo "$out" | grep -qE '^✓ strategy +ready'; then
  ok "populated tree: strategy ready"
else
  err "populated tree: strategy not ready"
fi

# 4. Strategy partial when state dir exists but publish-log missing.
rm "$state/publish-log.jsonl"
code=0
out=$("$HELPER" --offline --channel strategy --creds-root "$creds" --state-dir "$state" 2>&1) || code=$?
if [[ "$code" == 1 ]] && echo "$out" | grep -qE '^◐ strategy +partial'; then
  ok "missing publish-log → strategy partial + exit 1"
else
  err "missing publish-log should mark strategy partial (got code=$code, out=$out)"
fi
touch "$state/publish-log.jsonl"

# 5. Blog error when BLOG_ROOT doesn't exist.
printf "BLOG_ROOT=/nonexistent-${RANDOM}\nBLOG_PUBLIC_URL=https://example.invalid\n" > "$creds/blog/env"
code=0
out=$("$HELPER" --offline --channel blog --creds-root "$creds" --state-dir "$state" 2>&1) || code=$?
if [[ "$code" == 1 ]] && echo "$out" | grep -qE '^✗ blog +error'; then
  ok "missing BLOG_ROOT → blog error + exit 1"
else
  err "missing BLOG_ROOT should mark blog error (got code=$code, out=$out)"
fi
printf "BLOG_ROOT=$tmpdir/blog\nBLOG_PUBLIC_URL=https://example.invalid\n" > "$creds/blog/env"

# 6. JSON output is parseable and shape-correct.
code=0
out=$("$HELPER" --offline --json --creds-root "$creds" --state-dir "$state" 2>&1) || code=$?
# Minimal JSON sanity: starts with [, ends with ], 5 channel objects.
if [[ "${out:0:1}" == "[" && "${out: -1}" == "]" ]] \
   && [[ $(echo "$out" | grep -c '"channel"') == "5" ]]; then
  ok "JSON output shape (5 channel objects)"
else
  err "JSON output unexpected: $out"
fi

# 7. Unknown channel reports error + exit 1.
code=0
out=$("$HELPER" --offline --channel xyzzy --creds-root "$creds" --state-dir "$state" 2>&1) || code=$?
if [[ "$code" == 1 ]] && echo "$out" | grep -qE '^✗ xyzzy +error'; then
  ok "unknown channel → error"
else
  err "unknown channel should error (got code=$code, out=$out)"
fi

# 8. Unknown option exits 2.
code=0
"$HELPER" --frobnicate >/dev/null 2>&1 || code=$?
if [[ "$code" == 2 ]]; then ok "unknown option exits 2"; else err "unknown option should exit 2 (got $code)"; fi

# 9. CREDENTIALS_ROOT env var honoured.
mkdir -p "$tmpdir/env-creds-test/gemini"
echo "x" > "$tmpdir/env-creds-test/gemini/api-key"
code=0
out=$(CREDENTIALS_ROOT="$tmpdir/env-creds-test" "$HELPER" --offline --channel veo --state-dir "$state" 2>&1) || code=$?
if [[ "$code" == 0 ]] && echo "$out" | grep -qE '^∅ veo +skipped-offline'; then
  ok "CREDENTIALS_ROOT env var resolves creds"
else
  err "CREDENTIALS_ROOT env var should set creds dir (got code=$code, out=$out)"
fi

# 10. Help flag exits 0.
code=0
"$HELPER" --help >/dev/null 2>&1 || code=$?
if [[ "$code" == 0 ]]; then ok "--help exits 0"; else err "--help should exit 0 (got $code)"; fi

# Summary.
printf '\n%d passed, %d failed\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
