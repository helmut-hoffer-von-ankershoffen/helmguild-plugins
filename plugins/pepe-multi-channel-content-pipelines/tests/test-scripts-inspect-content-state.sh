#!/usr/bin/env bash
# test-scripts-inspect-content-state.sh — exercises the bundled bash
# helper at ../scripts/inspect-content-state.sh against a synthetic
# state directory.
#
# Run:
#   bash tests/test-scripts-inspect-content-state.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER="$SCRIPT_DIR/../scripts/inspect-content-state.sh"

[[ -x "$HELPER" ]] || { echo "✗ helper missing or not executable: $HELPER" >&2; exit 1; }

pass=0
fail=0
note() { printf '· %s\n' "$*"; }
ok()   { printf '✓ %s\n' "$*"; pass=$((pass + 1)); }
err()  { printf '✗ %s\n' "$*" >&2; fail=$((fail + 1)); }

tmp=$(mktemp -d -t pepe-inspect-test-XXXXXX)
trap 'rm -rf "$tmp"' EXIT

# ── Case 1: $PEPE_PIPELINE_STATE_DIR unset → exit 2 with a clear message
note "case 1: env unset"
unset PEPE_PIPELINE_STATE_DIR || true
if out=$("$HELPER" 2>&1); then
  err "case 1: expected non-zero exit, got 0"
else
  rc=$?
  if [[ "$rc" -eq 2 ]] && echo "$out" | grep -q "PEPE_PIPELINE_STATE_DIR"; then
    ok "case 1: exit=2 + names the env var"
  else
    err "case 1: rc=$rc, out=$out"
  fi
fi

# ── Case 2: env points at missing dir → exit 3
note "case 2: env points at missing dir"
if PEPE_PIPELINE_STATE_DIR="/does-not-exist/anywhere-$$" "$HELPER" 2>&1 >/dev/null; then
  err "case 2: expected non-zero, got 0"
else
  rc=$?
  if [[ "$rc" -eq 3 ]]; then
    ok "case 2: exit=3 on missing dir"
  else
    err "case 2: rc=$rc"
  fi
fi

# ── Case 3: env points at a real dir with files → exit 0 + lists them
note "case 3: real dir with two files"
echo "alpha" > "$tmp/a.txt"
echo "beta"  > "$tmp/b.txt"
out=$(PEPE_PIPELINE_STATE_DIR="$tmp" "$HELPER")
if echo "$out" | grep -q "files=2" && echo "$out" | grep -q "a.txt" && echo "$out" | grep -q "b.txt"; then
  ok "case 3: header + both files present in output"
else
  err "case 3: out=$out"
fi

# ── Case 4: --limit 1 truncates the listing
note "case 4: --limit 1"
out=$(PEPE_PIPELINE_STATE_DIR="$tmp" "$HELPER" --limit 1)
listed=$(echo "$out" | grep -cE "^  [^ ]")
if [[ "$listed" -eq 1 ]]; then
  ok "case 4: --limit 1 truncates to one listed file"
else
  err "case 4: expected 1 listed file, got $listed; out=$out"
fi

# ── Summary
printf '\n%d passed, %d failed.\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]] || exit 1
