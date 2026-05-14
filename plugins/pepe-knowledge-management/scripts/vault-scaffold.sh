#!/usr/bin/env bash
# vault-scaffold.sh — create the empty templates the
# `canonical-knowledge-vault` skill's Setup walks the operator through
# filling in. Lower-friction entry: instead of "build this directory
# tree + 12 files by hand", the scaffolder writes the skeleton +
# opens it for editing.
#
# Output: a directory tree at <VAULT_ROOT> matching the schema in the
# canonical-knowledge-vault skill (README, MEMORY.md, _shared/,
# <operator>/, <brand>/, agents/<each-agent>/).
#
# Refuses to overwrite an existing vault unless --force.
#
# Usage:
#   vault-scaffold.sh --vault-root <path> --operator <slug> \
#       --brand <slug> [--agents <agent-1>,<agent-2>,...]
#
#   VAULT_ROOT=~/Obsidian/Sandra-Brand vault-scaffold.sh \
#       --operator sandra --brand sandras-cooking-brand \
#       --agents pepe,cowork,hermes
#
# Exit codes:
#   0 — scaffolded.
#   1 — would overwrite an existing vault.
#   2 — usage error.

set -euo pipefail

vault_root="${VAULT_ROOT:-}"
operator=""
brand=""
agents="pepe"
force=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vault-root) vault_root="$2"; shift 2;;
    --operator) operator="$2"; shift 2;;
    --brand) brand="$2"; shift 2;;
    --agents) agents="$2"; shift 2;;
    --force) force=1; shift;;
    --help|-h)
      sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
      exit 0;;
    *) echo "vault-scaffold: unknown arg $1" >&2; exit 2;;
  esac
done

# Required args.
missing=()
[[ -z "$vault_root" ]] && missing+=("--vault-root (or VAULT_ROOT)")
[[ -z "$operator" ]] && missing+=("--operator")
[[ -z "$brand" ]] && missing+=("--brand")
if [[ ${#missing[@]} -gt 0 ]]; then
  echo "vault-scaffold: missing required: ${missing[*]}" >&2
  exit 2
fi

# Validate slugs.
for s in "$operator" "$brand"; do
  if ! printf '%s' "$s" | grep -qE '^[a-z][a-z0-9-]*$'; then
    echo "vault-scaffold: invalid slug \"$s\" (must be lowercase kebab)" >&2
    exit 2
  fi
done

operator_dir="$vault_root/$operator"
brand_dir="$vault_root/$brand"

if [[ -e "$vault_root/MEMORY.md" && "$force" -eq 0 ]]; then
  echo "vault-scaffold: $vault_root/MEMORY.md already exists; --force to overwrite" >&2
  exit 1
fi

mkdir -p "$vault_root/_shared" "$operator_dir" "$brand_dir" "$vault_root/agents"

# Per-agent dirs.
IFS=',' read -ra agent_list <<< "$agents"
for a in "${agent_list[@]}"; do
  a=$(printf '%s' "$a" | tr -d ' ')
  [[ -z "$a" ]] && continue
  mkdir -p "$vault_root/agents/$a"
done

today=$(date -u +"%Y-%m-%d")

# ── README + top-level MEMORY index ──────────────────────────────────
cat > "$vault_root/README.md" <<EOF
# Vault — $operator

Shared canonical Markdown knowledge store. Authored per the
\`canonical-knowledge-vault\` skill in the \`pepe-knowledge-management\`
playbook.

## What lives here

- **MEMORY.md** — the "if you read one doc, read this" index.
- **_shared/** — cross-agent context (changelog, conventions, privacy).
- **$operator/** — operator's profile, work, philosophy, privacy boundaries.
- **$brand/** — brand charter, visual styling, cameo roster, voice, content calendar pointer.
- **agents/** — per-agent charter + memory notes (one dir per agent: $(printf '%s ' "${agent_list[@]}")).

## Who reads this

Every agent in the operator's stack: $(printf '%s ' "${agent_list[@]}").
Each mounts this directory and reads it as canonical truth.

## Authored

$today via vault-scaffold.sh.
EOF

cat > "$vault_root/MEMORY.md" <<EOF
# Vault MEMORY index

The "if you read one doc, read this" entry point. Each line: one cross-cutting fact
the agent should consult first. Under 200 lines — pointers, not content.

## Operator + brand

- [Operator profile](./$operator/Profile.md) — who $operator is, how to address them
- [Operator work](./$operator/Work.md) — current open projects + focus
- [Operator philosophy](./$operator/Philosophy.md) — values, orientation
- [Operator privacy boundaries](./$operator/Privacy-Boundaries.md) — per-person + per-topic
- [Brand charter](./$brand/Charter.md) — what $brand is + isn't
- [Brand visual styling](./$brand/Visual-Styling.md) — referenced by content pipeline
- [Brand cameo roster](./$brand/Cameo-Roster.md) — who appears + consent posture
- [Brand voice + tone](./$brand/Voice.md) — banned phrases, emoji signature

## Cross-cutting

- [Vault conventions](./_shared/Conventions.md) — frontmatter, naming, cross-links
- [Cross-agent privacy](./_shared/Privacy.md) — who-sees-what
- [Cross-agent changelog](./_shared/Changelog.md) — every cross-agent-relevant change

EOF

# Per-agent dirs entries.
for a in "${agent_list[@]}"; do
  a=$(printf '%s' "$a" | tr -d ' ')
  [[ -z "$a" ]] && continue
  echo "- [Agent: $a — charter](./agents/$a/Charter.md) — $a's role + boundaries" >> "$vault_root/MEMORY.md"
done

# ── _shared/ ────────────────────────────────────────────────────────
cat > "$vault_root/_shared/Conventions.md" <<EOF
---
title: Vault conventions
slug: conventions
updated: $today
authors: [vault-scaffold]
readers: [all]
---

# Vault conventions

## Frontmatter

Every doc carries YAML frontmatter:

\`\`\`yaml
---
title: <human-readable>
slug: <kebab-case>
updated: YYYY-MM-DD
authors: [<agent-or-human-id>, ...]
readers: [all | <list of agent / human ids>]
supersedes: <slug-of-prior-doc-if-any>
---
\`\`\`

## Naming

- Kebab-case slugs for file names.
- Spaces in filenames only when the file is human-edited frequently (e.g. \`Visual Styling.md\` in Obsidian).
- Per-doc \`slug\` field is the canonical short id.

## Cross-links

- \`[[Other Doc Title]]\` — Obsidian-style, works inside the vault.
- \`vault://<rel-path>\` — full reference from agent memory entries to vault docs.

## Length

- Keep each doc < 5 000 tokens (~3 500 words).
- Larger → split into a parent + children + cross-link.

## Updates

- Full-rewrites, not diff-patches. When a fact changes, edit the doc + bump \`updated:\`.
EOF

cat > "$vault_root/_shared/Privacy.md" <<EOF
---
title: Cross-agent privacy boundaries
slug: privacy
updated: $today
authors: [vault-scaffold]
readers: [all]
---

# Cross-agent privacy boundaries

Operator-specific. Fill in:

- Which **humans** appear in this vault (the operator, family, co-stars, colleagues).
- For each, which **agents may discuss them** (e.g. agent-A may discuss person-B, agent-C may not).
- For each, what **topics** are off-limits (e.g. medical, financial, family-internal).
- **Compartmentalization** rules: when person-X chats with agent-Y, do NOT import from person-Z's chat unless explicitly cross-referenced.

This file is the contract every agent reads on first connect.
EOF

cat > "$vault_root/_shared/Changelog.md" <<EOF
# Cross-agent changelog

Chronological log of changes that other agents on the operator's stack need to know about.

## Format

Each entry:

\`\`\`
## YYYY-MM-DD HH:MM <agent-id> — <one-line summary>
- bullet 1
- bullet 2
\`\`\`

## $today scaffold

- vault-scaffold created the initial directory tree for $operator + $brand.
EOF

# ── operator/ ───────────────────────────────────────────────────────
for f in Profile Work Philosophy Privacy-Boundaries; do
  cat > "$operator_dir/$f.md" <<EOF
---
title: $operator — $f
slug: $(printf '%s' "$f" | tr 'A-Z' 'a-z')
updated: $today
authors: []
readers: [all]
---

# $operator — $f

<!-- Fill in per the canonical-knowledge-vault skill's schema. -->
EOF
done

# ── brand/ ──────────────────────────────────────────────────────────
for f in Charter Visual-Styling Cameo-Roster Voice Content-Calendar; do
  cat > "$brand_dir/$f.md" <<EOF
---
title: $brand — $f
slug: $(printf '%s' "$f" | tr 'A-Z' 'a-z')
updated: $today
authors: []
readers: [all]
---

# $brand — $f

<!-- Fill in per the canonical-knowledge-vault + brand-visual-identity + real-person-cameo-protocol skills. -->
EOF
done

# ── agents/<each>/ ──────────────────────────────────────────────────
for a in "${agent_list[@]}"; do
  a=$(printf '%s' "$a" | tr -d ' ')
  [[ -z "$a" ]] && continue
  for f in Charter Memory-Notes; do
    cat > "$vault_root/agents/$a/$f.md" <<EOF
---
title: $a — $f
slug: $(printf '%s' "$f" | tr 'A-Z' 'a-z')
updated: $today
authors: []
readers: [$a]
---

# $a — $f

<!-- Fill in per the canonical-knowledge-vault skill's schema. -->
EOF
  done
done

echo "vault-scaffold: wrote skeleton to $vault_root"
echo ""
echo "Next steps:"
echo "  1. Edit $vault_root/$operator/Profile.md (one-pager about you)."
echo "  2. Edit $vault_root/$brand/Charter.md (what is this brand?)."
echo "  3. Run brand-identity-scaffold.sh from the content-pipelines plugin, pointing --path at $brand_dir."
echo "  4. Run cameo-roster-scaffold.sh, pointing --root at $brand_dir/Cameo-Roster/."
echo "  5. Mount $vault_root into every agent on your stack (see canonical-knowledge-vault skill, Command 1.6)."
echo "  6. Persist KNOWLEDGE_VAULT_PATH=$vault_root in ~/.openclaw/credentials/knowledge-vault/env."
exit 0
