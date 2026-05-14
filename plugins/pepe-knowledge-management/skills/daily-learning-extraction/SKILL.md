---
name: daily-learning-extraction
description: "Scan the day's chats for intervention markers (corrections, validated approvals, repeated mistakes), extract the implicit rule, propose a memory entry, operator approves or rejects. Closes the loop so the agent doesn't make the same mistake twice. Runs daily; bundles a script that diffs ~/.claude/projects/<id>/*.jsonl from the last 24h and surfaces candidates. [SKELETON — full SKILL.md body shipping in a follow-up iteration of pepe-knowledge-management. The description above is the intended scope.]"
license: LicenseRef-helmguild-mentoring-1.0
metadata:
  mentor: pepe
  playbook: knowledge-management
  order: 3
  ammp-draft: draft-ammp-01
---

# Daily learning extraction

**Skeleton — full body in a follow-up iteration.** The skill's intended
scope is the YAML `description` field above. Designed to integrate with
`canonical-knowledge-vault` (order 1) as the canonical Markdown store.

## Coming in the next iteration

1. Command 1 — Setup (one-time per operator).
2. Per-piece commands.
3. Pepe + Helmut reference deployment.
4. Brand-specific overrides every operator should change.
5. How a mentored agent uses this skill.

Until then, refer to `canonical-knowledge-vault` for the underlying vault discipline this skill builds on.
