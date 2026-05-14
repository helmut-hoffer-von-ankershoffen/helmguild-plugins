#!/usr/bin/env bash
# inspect-content-state.sh — bundled with the Pepe multi-channel-content-pipelines plugin.
#
# Reads a content-pipeline state directory and prints a compact summary
# of recently scheduled / published items. The actual state path is
# user-configurable via $PEPE_PIPELINE_STATE_DIR (no credentials
# anywhere — the script only reads filesystem state).
#
# This script demonstrates the AgentSkills "bundled tooling" pattern:
# a plugin can ship executable helpers that its skills then reference
# via `allowed-tools: ["Bash"]` in their SKILL.md frontmatter.
#
# Usage:
#   inspect-content-state.sh [--limit N]
#
# Exit codes:
#   0  success (or empty state)
#   2  $PEPE_PIPELINE_STATE_DIR not set
#   3  state dir does not exist

set -euo pipefail

LIMIT=10
while [[ $# -gt 0 ]]; do
  case "$1" in
    --limit) LIMIT="${2:?--limit requires a number}"; shift 2 ;;
    -h|--help)
      sed -n '1,/^set/p' "$0" | grep -E '^# ?' | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 64 ;;
  esac
done

STATE_DIR="${PEPE_PIPELINE_STATE_DIR:-}"
if [[ -z "$STATE_DIR" ]]; then
  echo "PEPE_PIPELINE_STATE_DIR is not set." >&2
  echo "Set it to your content-pipeline state directory; e.g.:" >&2
  echo "  export PEPE_PIPELINE_STATE_DIR=\"\$HOME/.openclaw/state/instagram-media\"" >&2
  exit 2
fi

if [[ ! -d "$STATE_DIR" ]]; then
  echo "PEPE_PIPELINE_STATE_DIR=$STATE_DIR does not exist (or is not a directory)." >&2
  exit 3
fi

count=$(find "$STATE_DIR" -maxdepth 2 -type f 2>/dev/null | wc -l | tr -d ' ')
printf 'state_dir=%s files=%s\n' "$STATE_DIR" "$count"
# Most-recently-modified items first, capped at $LIMIT.
find "$STATE_DIR" -maxdepth 2 -type f -print0 2>/dev/null \
  | xargs -0 ls -1t 2>/dev/null \
  | head -n "$LIMIT" \
  | while IFS= read -r f; do
      rel="${f#"$STATE_DIR"/}"
      size=$(wc -c < "$f" 2>/dev/null | tr -d ' ')
      printf '  %s  (%s bytes)\n' "$rel" "$size"
    done
