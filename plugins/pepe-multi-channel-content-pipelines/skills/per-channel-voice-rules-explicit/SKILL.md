---
name: per-channel-voice-rules-explicit
description: "Encode each channel's register, length budget, emoji policy, hashtag policy, and link-handling as data — a per-channel YAML or JSON the renderer reads — rather than implicit prose in the prompt. Use when authoring renderers for multiple surfaces, to keep voice rules auditable and diffable."
license: CC-BY-4.0
metadata:
  mentor: pepe
  playbook: multi-channel-content-pipelines
  order: 3
  ammp-draft: draft-ammp-01
---

# Per-channel voice rules — explicit, not implicit

**Principle:** Each channel has its own register, length budget, emoji policy, hashtag policy, and link-handling rule. **Encode those as data** (a per-channel YAML or JSON) and have the renderer read them. Never let the per-channel voice live in the renderer's prose.

**Why it matters:** "Instagram likes a more playful tone, fewer technical terms, one emoji per paragraph" — if that lives only inside the prompt template, you can't audit it, you can't A/B it, and you certainly can't have a human sign-off on the rules without reading prompt code. When the rules are data, you can hand the YAML to the brand owner and they can edit it themselves.

**How to apply:**

- `channels/instagram.yaml`, `channels/x.yaml`, `channels/website.yaml`, etc. Each carries: max chars, allowed emoji count, hashtag rules, mention format, link inclusion policy, image aspect requirements, voice register (one of a small set like "professional / conversational / playful").
- The per-channel renderer takes (canonical record, channel rules) → outputs the channel-specific surface. The LLM call inside the renderer gets the channel rules in its system prompt and the canonical record in its user message.
- When the brand owner says "Instagram should be more concise now" — that's a one-line edit to `instagram.yaml`. No code change. Re-render and the next publish reflects it.
- Test the rules: every renderer should emit a sample rendering of three canonical records every time the rules file changes (locally, not published). The brand owner reviews the samples before the rules ship.
- Cross-channel consistency lives at the *canonical* level (same idea, same facts). Per-channel *expression* of that idea is the renderer's job. Don't try to make Instagram and a blog post look identical — they shouldn't.
