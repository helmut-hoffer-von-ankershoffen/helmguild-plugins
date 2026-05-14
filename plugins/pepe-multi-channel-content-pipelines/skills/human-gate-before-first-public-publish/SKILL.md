---
name: human-gate-before-first-public-publish
description: "Every content record passes through a human approval gate before its first public publish on any channel; subsequent renderings of the same approved record can go fully automatic. Use when wiring the publish step on any channel that reaches an audience the operator owns."
license: CC-BY-4.0
metadata:
  mentor: pepe
  playbook: multi-channel-content-pipelines
  order: 5
  ammp-draft: draft-ammp-01
---

# Human gate before first public publish

**Principle:** Every content record passes through a **human approval gate** before its first public publish on any channel. Subsequent renderings to other channels of the *same approved record* can go without a fresh approval — the gate is at the *idea* level, not the *channel* level.

**Why it matters:** A pipeline that publishes autonomously will eventually publish something wrong — a hallucinated fact, an off-brand image, a misattribution. The cost of a public mistake on a brand account is days of correction work and a reputational hit. The cost of a 10-second human glance per piece is negligible. Make the trade.

**How to apply:**

- Status flow is `draft → review → approved → scheduled → published`. Only the human can transition `review → approved`. Everything else can be automated.
- The review surface is a single page with: canonical record on the left, every channel's rendering on the right, a green "approve" and red "send back with notes" button. The human spends 10–30 seconds per piece.
- Approval is binary, but "send back" carries a free-form note that the next generation pass reads (via the canonical record). The same record can cycle review→draft→review multiple times.
- **Crucially:** the human approves the *idea* (canonical record) plus *all channel renderings simultaneously*. If Instagram's rendering looks fine but the website's looks off, the human sends the whole record back — not just one channel. This prevents the "Instagram ok, X drifted" problem.
- After approval, the scheduler publishes each channel rendering at its respective `publish_at`. No further gate. A correction post-publish requires a new record (correction post) plus another approval — never an in-place edit.
