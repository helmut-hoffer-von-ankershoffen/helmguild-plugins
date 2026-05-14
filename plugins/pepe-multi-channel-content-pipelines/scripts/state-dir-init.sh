#!/usr/bin/env bash
# state-dir-init.sh — initialise the canonical pipeline state directory
# the `content-strategy-planning-optimization` skill expects. Empty
# files are not enough; the agent will silently skip a missing
# publish-log on every batch sweep. This scaffolder writes the layout
# explicitly so the next sweep has a target to append to.
#
# Output:
#   <state>/
#     ├── publish-log.jsonl       (touched empty; channel skills append here)
#     ├── audit.jsonl             (touched empty; state-machine transitions)
#     ├── plan-week-_template.md  (template; weekly planning sweep clones this)
#     ├── pieces/                 (canonical content store directory — only created if --canonical-here)
#     ├── veo-queue/              (Veo long-running operation state files)
#     ├── README.md               (what each file is for)
#     └── .gitignore              (state is local; never commit)
#
# Read-only beyond writing the templates. Refuses to overwrite an
# existing state directory unless --force.
#
# Usage:
#   state-dir-init.sh --path <state-dir> [--canonical-here]
#   PEPE_PIPELINE_STATE_DIR=~/.openclaw/state/mybrand state-dir-init.sh
#
# Exit codes:
#   0 — initialised.
#   1 — would overwrite an existing publish-log.
#   2 — usage error.

set -euo pipefail

path="${PEPE_PIPELINE_STATE_DIR:-}"
canonical_here=0
force=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --path) path="$2"; shift 2;;
    --canonical-here) canonical_here=1; shift;;
    --force) force=1; shift;;
    --help|-h)
      sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
      exit 0;;
    *) echo "state-dir-init: unknown arg $1" >&2; exit 2;;
  esac
done

if [[ -z "$path" ]]; then
  echo "state-dir-init: --path or PEPE_PIPELINE_STATE_DIR required" >&2
  exit 2
fi

if [[ -e "$path/publish-log.jsonl" && "$force" -eq 0 ]]; then
  echo "state-dir-init: $path/publish-log.jsonl already exists; --force to re-initialise" >&2
  exit 1
fi

mkdir -p "$path/veo-queue"
[[ "$canonical_here" -eq 1 ]] && mkdir -p "$path/pieces"

touch "$path/publish-log.jsonl"
touch "$path/audit.jsonl"

cat > "$path/plan-week-_template.md" <<'EOF'
# Plan — week <YYYY-WW>

Authored by the agent's weekly planning sweep (content-strategy-planning-optimization Command 2).

## Reels (Instagram + X mirror)

| Slot | Piece | Cameo | Discipline | Status |
|------|-------|-------|------------|--------|

## X threads (X-only)

| Slot | Piece | Status |
|------|-------|--------|

## Blog posts

| Slot | Piece | Locale set | Status |
|------|-------|------------|--------|

## Human gates needing operator flip

-

## Unresolved blockers

-
EOF

cat > "$path/README.md" <<EOF
# Pipeline state directory

Authored by state-dir-init.sh on $(date -u +"%Y-%m-%d").

## Files

- **publish-log.jsonl** — append-only line-per-publish-event log. Every channel skill writes here on a successful publish. Read by the strategy + analytics skills.
- **audit.jsonl** — append-only line-per-state-machine-transition. Hash + timestamp + piece-id + channel + status. Privacy-safe (no content bodies).
- **plan-week-<YYYY-WW>.md** — weekly planning artefact. Clone plan-week-_template.md per week.
- **veo-queue/** — Veo long-running operation names. State files persisted the moment Veo returns the op-name, polled on next sweep. Resumable.
$([[ "$canonical_here" -eq 1 ]] && echo "- **pieces/** — canonical content store (chosen via --canonical-here). One file per piece.")

## Conventions

- All log files are append-only. Never rewrite history; corrections live in the canonical store + flow forward.
- Hash-only audit log: no body content here, only hashes + ids + timestamps.
- Resumable: a crashed agent reads publish-log to find the last completed event and resumes from there.

## Setup verification

\`scripts/setup-doctor.sh --channel strategy\` reads this directory.
EOF

cat > "$path/.gitignore" <<EOF
# Pipeline state is local. Don't commit.
*
!.gitignore
!README.md
!plan-week-_template.md
EOF

echo "state-dir-init: wrote layout to $path"
echo ""
echo "Files:"
ls -la "$path" | tail -n +2

echo ""
echo "Persist this path in your shell + agent env:"
echo "  echo 'export PEPE_PIPELINE_STATE_DIR=$path' >> ~/.zshrc"
echo ""
echo "Then run scripts/setup-doctor.sh --channel strategy — it should report \`✓ strategy ready\`."
exit 0
