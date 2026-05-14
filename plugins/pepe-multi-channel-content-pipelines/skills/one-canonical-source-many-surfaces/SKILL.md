---
name: one-canonical-source-many-surfaces
description: "Every piece of content has exactly one canonical home (an Obsidian note, a Notion row, a git repo); every channel rendering — Instagram caption, X post, blog post, newsletter — is a projection of that source, never an independent edit. Use when designing a multi-channel content pipeline, to prevent drift between surfaces."
license: LicenseRef-helmguild-mentoring-1.0
metadata:
  mentor: pepe
  playbook: multi-channel-content-pipelines
  order: 1
  ammp-draft: draft-ammp-01
---

# One canonical source, many surfaces

**Principle:** Every piece of content has exactly **one canonical home** — usually a structured note in the operator's vault (Obsidian, Notion, a git repo, a database row). Every channel-specific rendering (Instagram caption, X post, website article, newsletter blurb) is a **projection** of that canonical source, not an independent edit.

**Why it matters:** When the same idea gets re-typed into Instagram and X and a blog post independently, the three versions drift. A correction to one doesn't propagate. The brand voice fragments. After three months you can't tell which version is current. With a single canonical source plus channel renderers, a fix lives in one place and re-renders everywhere on the next publish.

**How to apply:**

- Pick a canonical store before you write the first piece. A directory of structured markdown files works. So does a Notion database. Whatever it is, the schema is the contract.
- Every piece has stable fields: `id`, `title`, `core_idea`, `body`, `assets[]`, `created_at`, `status`. Channel renderers read these and produce the per-channel surface.
- A channel rendering is **derived**, not authored. If the Instagram caption needs an emoji that isn't in the canonical body, the renderer adds it as a function of the channel's voice rules — not by hand-editing the canonical text.
- When a channel needs something the canonical source doesn't capture (e.g. Instagram needs a square 1080×1080 still, the website wants a 16:9 hero), record that as an *asset reference* on the canonical record. The renderer pulls the right asset for each surface.
- Treat "edit one channel after publish" as a signal to update the canonical source and re-render, not as a one-off patch. The patch-and-forget path is how drift starts.
