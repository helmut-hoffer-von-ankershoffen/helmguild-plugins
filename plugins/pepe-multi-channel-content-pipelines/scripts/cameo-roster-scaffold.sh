#!/usr/bin/env bash
# cameo-roster-scaffold.sh — create the empty templates the
# `real-person-cameo-protocol` skill's Setup walks an operator through.
#
# For each `--person <id>:<display-name>`, creates:
#   <root>/<id>/
#     ├── ref-index.json
#     ├── outfit-contract.md
#     ├── context-rules.md
#     ├── platform-routing.json
#     ├── consent-record.md
#     └── refs/        (drop JPEGs here)
#
# Plus a top-level roster.md indexing everyone.
#
# Read-only beyond writing the templates. Refuses to overwrite an
# existing person directory unless --force.
#
# Usage:
#   cameo-roster-scaffold.sh --root <path> --person helmut:"Helmut Hoffer von Ankershoffen" \
#                                          --person sandra:"Sandra Hoffer von Ankershoffen"
#
# Exit codes:
#   0 — scaffolded.
#   1 — would overwrite.
#   2 — usage error.

set -euo pipefail

root=""
persons=()
force=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) root="$2"; shift 2;;
    --person) persons+=("$2"); shift 2;;
    --force) force=1; shift;;
    --help|-h)
      sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
      exit 0;;
    *) echo "cameo-roster-scaffold: unknown arg $1" >&2; exit 2;;
  esac
done

if [[ -z "$root" ]]; then
  echo "cameo-roster-scaffold: --root required" >&2
  exit 2
fi
if [[ ${#persons[@]} -eq 0 ]]; then
  echo "cameo-roster-scaffold: at least one --person <id>:<display-name> required" >&2
  exit 2
fi

mkdir -p "$root"
roster_md="$root/roster.md"
{
  echo "# Cameo roster"
  echo ""
  echo "Authored per the real-person-cameo-protocol skill in the pepe-multi-channel-content-pipelines plugin."
  echo ""
  echo "$(date -u +"%Y-%m-%d") scaffold."
  echo ""
  echo "| id | display name | appearance_status | consent_record |"
  echo "| --- | --- | --- | --- |"
} > "$roster_md"

for entry in "${persons[@]}"; do
  id="${entry%%:*}"
  display="${entry#*:}"
  if [[ -z "$id" || "$id" == "$entry" || -z "$display" ]]; then
    echo "cameo-roster-scaffold: malformed --person $entry (expected id:Display)" >&2
    exit 2
  fi
  if ! printf '%s' "$id" | grep -qE '^[a-z][a-z0-9-]*$'; then
    echo "cameo-roster-scaffold: invalid id \"$id\" (must be lowercase kebab)" >&2
    exit 2
  fi

  person_dir="$root/$id"
  if [[ -e "$person_dir" && "$force" -eq 0 ]]; then
    echo "cameo-roster-scaffold: $person_dir already exists; --force to overwrite" >&2
    exit 1
  fi
  mkdir -p "$person_dir/refs"

  cat > "$person_dir/ref-index.json" <<EOF
{
  "person_id": "$id",
  "default": "talking-head_1024.jpg",
  "by_discipline": {
    "talking-head": "talking-head_1024.jpg",
    "candid": "candid_1024.jpg"
  },
  "_note": "Add discipline-specific entries as you build refs/. Same person needs different shots for different disciplines (swim cap vs aero helmet etc.)."
}
EOF

  cat > "$person_dir/outfit-contract.md" <<EOF
# $display — outfit + gear contracts per discipline

(One paragraph per discipline the person appears in. Brand-name-softened
per the cameo-protocol RAI-filter rule — e.g. "a black running cap" not
"Nike running cap".)

## talking-head
-

## candid
-
EOF

  cat > "$person_dir/context-rules.md" <<EOF
# $display — context rules

(What cameos require per-batch greenlight beyond default consent.)

## Per-batch greenlight required

- (e.g. couple-content, drinking alcohol, polarised topics)

## Hard embargoes

- (scenes the person will not appear in under any circumstance)
EOF

  cat > "$person_dir/platform-routing.json" <<EOF
{
  "platforms_allowed": ["instagram", "blog"],
  "platforms_denied": [],
  "collaborator_invite_default": false,
  "caption_tag_default": "",
  "_note": "Some people consent to public publish on IG but not X. Channel skills read this and refuse to publish to a denied platform."
}
EOF

  cat > "$person_dir/consent-record.md" <<EOF
# $display — consent record

| Date | Form | Notes |
|------|------|-------|
| $(date -u +"%Y-%m-%d") | scaffold | (replace with actual consent: signed PDF / written chat excerpt / etc.) |

## Initial consent text

(Paste verbatim the consent text the person gave. With date + platform.)
EOF

  echo "| $id | $display | (set in roster) | $id/consent-record.md |" >> "$roster_md"

  echo "scaffolded: $person_dir"
done

echo ""
echo "Next steps:"
echo "  1. For each person, replace the consent-record.md scaffold with their real consent."
echo "  2. Drop face-reference JPEGs into <person>/refs/ (1024×1024, per-discipline)."
echo "  3. Fill in <person>/ref-index.json with by-discipline mappings."
echo "  4. Write <person>/outfit-contract.md per discipline."
echo "  5. Decide <person>/context-rules.md + platform-routing.json."
echo "  6. Update $roster_md columns (appearance_status, etc.)."
echo "  7. Mount the roster root into every brand-content agent (Obsidian vault / GitHub repo / Notion)."
exit 0
