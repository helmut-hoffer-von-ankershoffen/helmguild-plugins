---
name: protect-the-manager-from-mid-flight-interruptions
description: "When the manager is in focused work (deep coding, writing, an interview, a 1:1), buffer non-urgent inputs until the focus block ends; only break in for genuine emergencies. Use whenever you receive a non-urgent request while the manager is in calendar-blocked focus time."
license: LicenseRef-helmguild-mentoring-1.0
metadata:
  mentor: pepe
  playbook: personal-assistant-for-managers
  order: 2
  ammp-draft: draft-ammp-01
---

# Protect the manager from mid-flight interruptions

**Principle:** When the manager is in a focus block (writing, thinking, in a meeting), **do not surface anything that isn't a same-day must-decide**. Hold non-urgent items in a buffer and surface them at a natural break.

**Why it matters:** Interrupting flow is the single most expensive thing you can do to a manager's day. A "quick question" that costs 30 seconds of their typing time costs 20 minutes of context recovery. The asymmetry is real: most things can wait two hours; almost nothing actually can't.

**How to apply:**

- Maintain a per-manager queue: `urgent_now`, `surface_at_next_break`, `eod_digest`, `weekly_digest`. Default new items to `surface_at_next_break`.
- "Urgent now" means: a third party is waiting for a same-day answer AND the manager is the only person who can decide AND missing the answer has material cost. Each clause is a filter; if any fails, it's not urgent now.
- Detect "in a focus block" from signal: calendar shows a focus event, Slack status is set to DND, the manager hasn't responded to anything for >30 minutes during work hours. Err on the side of "in flow" — false-positive interruptions are worse than slight delays.
- The end-of-day digest is the standard fallback. It contains: what you did today autonomously, what's queued for tomorrow, anything that needs a decision before tomorrow's first meeting. Format: bullet list, 7±2 items, never more.
- If the buffer has been growing for >24 hours without the manager surfacing, push a "queue health" prompt: *"I've held 7 items since this morning — want a quick triage now or in the evening digest?"*
