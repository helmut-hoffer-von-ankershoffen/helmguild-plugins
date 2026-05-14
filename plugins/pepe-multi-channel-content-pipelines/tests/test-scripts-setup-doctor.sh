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

# 1. Empty tree: every channel reports `missing` (or `skipped-offline` for
# cameo-protocol, which is optional and `partial` for strategy because the
# bare state dir from the test fixture exists); exit 1.
code=0
out=$("$HELPER" --offline --creds-root "$creds" --state-dir "$state" 2>&1) || code=$?
if [[ "$code" == 1 ]]; then ok "empty tree exits 1"; else err "empty tree should exit 1 (got $code)"; fi
for ch in brand-identity veo instagram x blog; do
  if echo "$out" | grep -qE "^✗ ${ch} +missing"; then
    ok "empty tree: ${ch} missing"
  else
    err "empty tree: ${ch} not reported missing"
  fi
done
# cameo-protocol is optional — reports skipped-offline when no roster
# root configured (a pure-fictional-character brand doesn't need it).
if echo "$out" | grep -qE '^∅ cameo-protocol +skipped-offline'; then
  ok "empty tree: cameo-protocol skipped-offline (optional)"
else
  err "empty tree: cameo-protocol should be skipped-offline (got: $out)"
fi
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

# 3a. brand-identity probe: scaffold a complete brand dir + assert ready.
brand_dir=$(mktemp -d)
mkdir -p "$brand_dir/disciplines" "$brand_dir/refs/character"
touch "$brand_dir/character.md" "$brand_dir/voice.md" "$brand_dir/off-brand.md" "$brand_dir/redo-criteria.md" "$brand_dir/disciplines/test.md"
code=0
out=$(BRAND_STYLE_GUIDE_PATH="$brand_dir" "$HELPER" --offline --channel brand-identity --creds-root "$creds" --state-dir "$state" 2>&1) || code=$?
if [[ "$code" == 0 ]] && echo "$out" | grep -qE '^✓ brand-identity +ready'; then
  ok "brand-identity ready when artefacts present"
else
  err "brand-identity should be ready with full artefacts (got code=$code, out=$out)"
fi
rm -rf "$brand_dir"

# 3b. cameo-protocol probe: scaffold a roster + assert ready.
cameos=$(mktemp -d)
echo "# Cameo roster" > "$cameos/roster.md"
mkdir -p "$cameos/helmut/refs"
echo "{}" > "$cameos/helmut/ref-index.json"
echo "consent" > "$cameos/helmut/consent-record.md"
code=0
out=$(CAMEO_ROSTER_ROOT="$cameos" "$HELPER" --offline --channel cameo-protocol --creds-root "$creds" --state-dir "$state" 2>&1) || code=$?
if [[ "$code" == 0 ]] && echo "$out" | grep -qE '^✓ cameo-protocol +ready'; then
  ok "cameo-protocol ready with full roster"
else
  err "cameo-protocol should be ready (got code=$code, out=$out)"
fi
rm -rf "$cameos"

# 3. Populated creds + offline → skipped-offline for credentialed channels.
mkdir -p "$creds/gemini" "$creds/instagram" "$creds/x" "$creds/blog" "$creds/brand" "$creds/cameos" "$tmpdir/blog"
echo "fake-key" > "$creds/gemini/api-key"
printf 'IG_USER_ID=12345\nIG_PAGE_TOKEN=tok\n' > "$creds/instagram/env"
printf 'X_CLIENT_ID=cid\nX_CLIENT_SECRET=csec\nX_REFRESH_TOKEN=rtok\n' > "$creds/x/env"
printf "BLOG_ROOT=$tmpdir/blog\nBLOG_PUBLIC_URL=https://example.invalid\n" > "$creds/blog/env"
# brand-identity: point env at a complete brand store.
mkdir -p "$tmpdir/brand-store/disciplines" "$tmpdir/brand-store/refs/character"
touch "$tmpdir/brand-store/character.md" "$tmpdir/brand-store/voice.md" "$tmpdir/brand-store/off-brand.md" "$tmpdir/brand-store/redo-criteria.md" "$tmpdir/brand-store/disciplines/test.md"
printf "BRAND_STYLE_GUIDE_PATH=$tmpdir/brand-store\n" > "$creds/brand/env"
# cameo-protocol: point env at a complete roster.
mkdir -p "$tmpdir/cameo-store/helmut/refs"
echo "# Roster" > "$tmpdir/cameo-store/roster.md"
echo "{}" > "$tmpdir/cameo-store/helmut/ref-index.json"
echo "consent" > "$tmpdir/cameo-store/helmut/consent-record.md"
printf "CAMEO_ROSTER_ROOT=$tmpdir/cameo-store\n" > "$creds/cameos/env"
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

# 6. JSON output is parseable and shape-correct (7 channels now).
code=0
out=$("$HELPER" --offline --json --creds-root "$creds" --state-dir "$state" 2>&1) || code=$?
if [[ "${out:0:1}" == "[" && "${out: -1}" == "]" ]] \
   && [[ $(echo "$out" | grep -c '"channel"') == "7" ]]; then
  ok "JSON output shape (7 channel objects)"
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
