#!/usr/bin/env bash
# test-scripts-cameo-roster-scaffold.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER="$SCRIPT_DIR/../scripts/cameo-roster-scaffold.sh"
[[ -x "$HELPER" ]] || { echo "missing helper: $HELPER" >&2; exit 1; }

pass=0; fail=0
ok()  { printf '✓ %s\n' "$*"; pass=$((pass+1)); }
err() { printf '✗ %s\n' "$*" >&2; fail=$((fail+1)); }

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

# 1. No root → exit 2.
code=0; "$HELPER" --person id:Name >/dev/null 2>&1 || code=$?
[[ "$code" == 2 ]] && ok "no --root → exit 2" || err "no root should exit 2 (got $code)"

# 2. No persons → exit 2.
code=0; "$HELPER" --root "$tmp/r1" >/dev/null 2>&1 || code=$?
[[ "$code" == 2 ]] && ok "no --person → exit 2" || err "no person should exit 2 (got $code)"

# 3. Happy path — two persons.
"$HELPER" --root "$tmp/r2" \
  --person helmut:"Helmut Hoffer von Ankershoffen" \
  --person sandra:"Sandra Hoffer von Ankershoffen" >/dev/null

for who in helmut sandra; do
  for f in ref-index.json outfit-contract.md context-rules.md platform-routing.json consent-record.md refs; do
    if [[ -e "$tmp/r2/$who/$f" ]]; then ok "created $who/$f"; else err "missing $who/$f"; fi
  done
done

# 4. Roster index lists both.
if grep -qE '\| helmut \|' "$tmp/r2/roster.md" && grep -qE '\| sandra \|' "$tmp/r2/roster.md"; then
  ok "roster.md indexes both"
else
  err "roster.md missing one or both entries"
fi

# 5. Display name lands in outfit-contract header.
if grep -qE '^# Helmut Hoffer von Ankershoffen ' "$tmp/r2/helmut/outfit-contract.md"; then
  ok "display name in outfit-contract header"
else
  err "display name not in outfit-contract header"
fi

# 6. Display name in consent-record table.
if grep -qE '^# Helmut Hoffer von Ankershoffen ' "$tmp/r2/helmut/consent-record.md"; then
  ok "display name in consent-record header"
else
  err "display name not in consent-record"
fi

# 7. ref-index.json includes person_id.
if grep -qE '"person_id": "helmut"' "$tmp/r2/helmut/ref-index.json"; then
  ok "ref-index has person_id"
else
  err "ref-index missing person_id"
fi

# 8. Bad id format rejected.
code=0; "$HELPER" --root "$tmp/r3" --person "Bad_Id:Name" >/dev/null 2>&1 || code=$?
[[ "$code" == 2 ]] && ok "bad id rejected" || err "bad id should be rejected (got $code)"

# 9. Malformed --person rejected.
code=0; "$HELPER" --root "$tmp/r4" --person "noseparator" >/dev/null 2>&1 || code=$?
[[ "$code" == 2 ]] && ok "malformed --person rejected" || err "malformed --person should be rejected"

# 10. Refuses to overwrite, --force overrides.
code=0; "$HELPER" --root "$tmp/r2" --person helmut:"Other Name" >/dev/null 2>&1 || code=$?
[[ "$code" == 1 ]] && ok "refuses to overwrite person" || err "should refuse overwrite (got $code)"

"$HELPER" --root "$tmp/r2" --person helmut:"Forced" --force >/dev/null
if grep -qE '^# Forced' "$tmp/r2/helmut/outfit-contract.md"; then ok "--force overwrites person"; else err "--force did not overwrite"; fi

# 11. Unknown arg → exit 2.
code=0; "$HELPER" --frobnicate >/dev/null 2>&1 || code=$?
[[ "$code" == 2 ]] && ok "unknown arg → exit 2" || err "unknown arg should exit 2"

# 12. --help exits 0.
code=0; "$HELPER" --help >/dev/null 2>&1 || code=$?
[[ "$code" == 0 ]] && ok "--help exits 0" || err "--help should exit 0"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
