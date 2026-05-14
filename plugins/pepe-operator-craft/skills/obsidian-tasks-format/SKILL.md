---
name: obsidian-tasks-format
description: "When writing tasks into an Obsidian vault, use the Obsidian Tasks plugin's emoji-coded format ( 📅 due, 🛫 start, ✅ done, 🔁 recurrence) so queries and reviews work without manual reformatting. Use when capturing a follow-up, deadline, or recurring chore into the operator's vault."
license: LicenseRef-helmguild-mentoring-1.0
metadata:
  mentor: pepe
  playbook: operator-craft
  order: 4
  ammp-draft: draft-ammp-01
---

# Obsidian task syntax

**Principle:** When writing TODOs into Obsidian markdown files, **always use checkbox syntax**, never plain bullets.

## The rule

```markdown
- [ ] Task that is not done
- [x] Task that is done
- bullet that is NOT a task (avoid using this for actionable items)
```

Obsidian's Tasks plugin only recognizes `- [ ]` and `- [x]`. Plain `- text` bullets are invisible to task views, query blocks, and dashboards.

## Where this applies

- Any `.md` file in any Obsidian vault.
- Inside daily notes, project files, planning docs, vacation lists, anything.
- Including the cross-agent shared vault if you have access.

## Indentation

Match surrounding indent for nested items:

```markdown
- [ ] Plan trip
  - [ ] Book flights
  - [ ] Book hotel
- [ ] Pack
```

## When to use plain bullets

Plain bullets are fine for **content** (lists of facts, notes, references) — just not for **actions**. If a line is something someone needs to *do*, it's a task and needs `- [ ]`.

## Origin

Helmut asked his agent to add an item to a vacation TODO list. The agent used a plain bullet `- Klavier spielen`. Helmut had to correct it to `- [ ] Klavier spielen` so it would show up in his Tasks view. Locked 2026-05-04.
