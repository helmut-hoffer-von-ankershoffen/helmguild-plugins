#!/usr/bin/env bash
# test-scripts-vault-scaffold.sh — exercises the bundled vault-scaffold
# helper.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER="$SCRIPT_DIR/../scripts/vault-scaffold.sh"
[[ -x "$HELPER" ]] || { echo "missing helper: $HELPER" >&2; exit 1; }

pass=0; fail=0
ok()  { printf '✓ %s\n' "$*"; pass=$((pass+1)); }
err() { printf '✗ %s\n' "$*" >&2; fail=$((fail+1)); }

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

# 1. Missing args → exit 2.
code=0; "$HELPER" >/dev/null 2>&1 || code=$?
[[ "$code" == 2 ]] && ok "no args → exit 2" || err "no args should exit 2 (got $code)"

# 2. Happy path with explicit agents.
"$HELPER" \
  --vault-root "$tmp/v1" \
  --operator helmut \
  --brand pepe-arturo \
  --agents "pepe,cowork" >/dev/null

for f in README.md MEMORY.md \
         _shared/Conventions.md _shared/Privacy.md _shared/Changelog.md \
         helmut/Profile.md helmut/Work.md helmut/Philosophy.md helmut/Privacy-Boundaries.md \
         pepe-arturo/Charter.md pepe-arturo/Visual-Styling.md pepe-arturo/Cameo-Roster.md \
         pepe-arturo/Voice.md pepe-arturo/Content-Calendar.md \
         agents/pepe/Charter.md agents/pepe/Memory-Notes.md \
         agents/cowork/Charter.md agents/cowork/Memory-Notes.md; do
  [[ -f "$tmp/v1/$f" ]] && ok "created $f" || err "missing $f"
done

# 3. MEMORY.md references operator + brand + every agent.
m="$tmp/v1/MEMORY.md"
grep -q "helmut/Profile.md" "$m" && ok "MEMORY.md references operator profile" || err "operator profile not in MEMORY.md"
grep -q "pepe-arturo/Charter.md" "$m" && ok "MEMORY.md references brand charter" || err "brand charter not in MEMORY.md"
grep -q "agents/pepe/Charter.md" "$m" && ok "MEMORY.md references pepe agent" || err "pepe agent not in MEMORY.md"
grep -q "agents/cowork/Charter.md" "$m" && ok "MEMORY.md references cowork agent" || err "cowork agent not in MEMORY.md"

# 4. Default --agents = pepe only.
"$HELPER" \
  --vault-root "$tmp/v2" \
  --operator someone \
  --brand somebrand >/dev/null
[[ -d "$tmp/v2/agents/pepe" ]] && ok "default agent is pepe" || err "default agent should be pepe"
[[ ! -d "$tmp/v2/agents/cowork" ]] && ok "no extra agents by default" || err "should be only pepe by default"

# 5. Refuses to overwrite.
code=0; "$HELPER" --vault-root "$tmp/v1" --operator x --brand y >/dev/null 2>&1 || code=$?
[[ "$code" == 1 ]] && ok "refuses to overwrite (exit 1)" || err "should refuse overwrite (got $code)"

# 6. --force overrides.
"$HELPER" --vault-root "$tmp/v1" --operator helmut --brand pepe-arturo --force >/dev/null
ok "--force overwrites"

# 7. Invalid slug rejected.
code=0; "$HELPER" --vault-root "$tmp/v3" --operator "Bad_Slug" --brand x >/dev/null 2>&1 || code=$?
[[ "$code" == 2 ]] && ok "invalid operator slug rejected" || err "invalid slug should reject (got $code)"

# 8. VAULT_ROOT env var.
VAULT_ROOT="$tmp/v4" "$HELPER" --operator a --brand b >/dev/null
[[ -f "$tmp/v4/MEMORY.md" ]] && ok "VAULT_ROOT env honoured" || err "VAULT_ROOT env not honoured"

# 9. Frontmatter present on a stub doc.
if grep -qE '^title: ' "$tmp/v1/helmut/Profile.md" && grep -qE '^updated: ' "$tmp/v1/helmut/Profile.md"; then
  ok "stubs carry frontmatter"
else
  err "stubs missing frontmatter"
fi

# 10. Conventions.md mentions kebab-case + cross-link syntax.
if grep -q "kebab-case" "$tmp/v1/_shared/Conventions.md" && grep -q '\[\[' "$tmp/v1/_shared/Conventions.md"; then
  ok "Conventions.md captures conventions"
else
  err "Conventions.md missing key conventions"
fi

# 11. Multiple agents with spaces in --agents are tolerated.
"$HELPER" --vault-root "$tmp/v5" --operator x --brand y --agents " a , b , c " >/dev/null
for a in a b c; do
  [[ -d "$tmp/v5/agents/$a" ]] && ok "agent '$a' (with whitespace) created" || err "agent '$a' (with whitespace) missing"
done

# 12. Unknown arg → exit 2.
code=0; "$HELPER" --frobnicate >/dev/null 2>&1 || code=$?
[[ "$code" == 2 ]] && ok "unknown arg → exit 2" || err "unknown arg should exit 2"

# 13. --help exits 0.
code=0; "$HELPER" --help >/dev/null 2>&1 || code=$?
[[ "$code" == 0 ]] && ok "--help exits 0" || err "--help should exit 0"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
