---
name: brand-visual-identity
description: "The upstream artefact every other skill in this playbook assumes exists: the brand's canonical visual identity — what the brand looks like, what its virtual character looks like across moods and scenes, what its colour palette and typography are, what scene templates recur, what voice tone the voiceover uses, what's off-brand and triggers a redo. Walks the operator through building it as a cross-agent-readable document so every agent generating brand content (this mentor's mentee, any other agent on the operator's stack) reads from the same source of truth."
license: LicenseRef-helmguild-mentoring-1.0
metadata:
  mentor: pepe
  playbook: multi-channel-content-pipelines
  order: 1
  ammp-draft: draft-ammp-01
allowed-tools:
  - bash
---

# Brand visual identity

Every skill in this playbook downstream of this one — character generation, channel publishing, content strategy — assumes that "the brand identity is already settled". This skill is the one that settles it. Without a written brand-visual-identity document, an agent will silently drift across shots: outfits change, lighting changes, the character's posture changes, the voice cadence wobbles. Each individual piece may look fine; the body of work as a brand corpus fragments.

This skill is the **first** skill in the playbook (`order: 1`) because it's a prerequisite for all the others. The strategy skill (`order: 7`) is the **last** because it consumes everything.

## Commands

### Command 1 — Setup (one-time per brand, operator runs this)

**Audience: the human operator.** The agent walks each numbered step.

1. **Pick the brand-identity store.** The document must be readable by every agent that may generate content for this brand. Sane choices:
   * **Shared Obsidian vault** — synced across the operator's devices + agents that mount the vault. Best for solo operators with multiple AI runtimes.
   * **Private GitHub repo** — `<brand>-style-guide` with a Markdown file per section. Best for engineering-flavoured operators.
   * **Notion / Confluence DB** — accessible via API. Best for teams.
   The agent reads from this location on first connect; the location is persisted as `BRAND_STYLE_GUIDE_PATH` in `~/.openclaw/credentials/brand/env`.
2. **Author the character one-pager.** A single paragraph + headshot grid. The paragraph names the character (real or fictional), their visible-age range, body type, signature visual marks. The headshot grid is 3-6 reference images covering the character in different lighting / moods. Persist as `<store>/character.md` + `<store>/refs/character/`.
3. **Author the per-discipline contracts.** Each "discipline" is a recurring scene category for this brand. For a fitness/sport brand: swim, run, bike, strength, talking-head. For a cooking brand: prep, plating, eating, kitchen-tour, ingredient-portrait. For a finance brand: solo-explainer, whiteboard-walkthrough, candid-with-pet. Each discipline gets a one-paragraph contract:
   * Setting + framing.
   * Outfit/gear (with the **softened** brand-name versions; see `real-person-cameo-protocol` Command 3).
   * Lighting + camera (focal length, shot type).
   * Voice cadence + tone for any spoken line.
   * Audio ambience hints.
   Persist as `<store>/disciplines/<name>.md`.
4. **Define the colour palette + typography.** Three primary colours + two secondary, with hex codes. One headline typeface + one body typeface. Used by the blog (CSS), by image-generation prompts (when ordering thumbnails or hero images), by physical merchandise if/when the brand ships any. Persist as `<store>/palette.md` + `<store>/typography.md`.
5. **Author the scene template library.** Beyond per-discipline contracts, name the scenes the brand revisits — the recurring visual motifs that make a body of work feel coherent. Pepe's: "Pepe sitting cross-legged on a mountain at dawn", "Pepe walking through a kitchen", "Pepe and Helmut at the kitchen table over coffee", "Helmut training solo at sunrise". Each template:
   * Sketch in words (3-5 sentences).
   * Where it works as a scene (which arc, what hook).
   * What gear / refs / cameos are pre-resolved.
   * Stock Veo prompt fragment.
   Persist as `<store>/scenes/<slug>.md`.
6. **Author the voice + tone rules.** The brand's spoken voice across surfaces. For Pepe: "calm, grounded, succinct, sport-flavoured English, no Italian, no filler, slow cadence". Plus a list of phrases that are **on-brand** (acceptable verbatim) and **off-brand** (never use). Plus the brand emoji signature (Pepe: 🍝 on every post; see `publishing-instagram` Command 5). Persist as `<store>/voice.md`.
7. **Author the off-brand list.** This is what the visual-styling guide says **never to do**. Common entries:
   * Outfit/gear combinations that read as off-brand (wrong cap with wrong wetsuit; suit with sneakers; etc.).
   * Lighting setups that misrepresent the brand (harsh fluorescent for a calm-grounded brand).
   * Character poses that contradict the voice (frenetic motion for a calm character).
   * Backgrounds that pull focus from the character (busy stages for a contemplative character).
   * Any third-party trademark or logo not licensed.
   Each entry has a one-line description + (where useful) a "before/after" pair: a wrong example + the on-brand replacement. Persist as `<store>/off-brand.md`.
8. **Define the redo criteria.** What makes a generated shot a redo vs. a "ship it"? Make it binary, not a feeling. Pepe's:
   * Face drifts mid-shot? → redo.
   * Outfit doesn't match the discipline contract? → redo.
   * Audio is missing when the prompt asked for VO? → redo (Veo RAI rejection; soften and retry).
   * Background pulls focus? → redo.
   * One of the off-brand entries from step 7 is present? → redo.
   * Frame rate stutter? → redo.
   * None of the above + the piece is on-brand within the discipline contract? → ship.
   Persist as `<store>/redo-criteria.md`.
9. **Cross-agent visibility.** Whatever store you picked in step 1, make sure every agent on the operator's stack reads it on first connect. For shared Obsidian vault: mount the same vault in every runtime (Claude Cowork, the mentee agent running Claude Code, ad-hoc Claude.ai sessions via the shared-vault-symlink pattern). For private GitHub: each agent has read access via SSH key or a tokenised HTTPS clone. For Notion DB: each agent has an API token. The `BRAND_STYLE_GUIDE_PATH` env var resolves the location for the agent.
10. **Smoke-test.** Have the agent read the brand identity doc and produce a one-page summary of what it learned. Compare against the operator's mental model. If anything drifts, the doc is missing a section — go back and add it. Iterate until summary = mental model.

Operator confirms: "Brand visual identity live."

### Command 2 — Apply the brand identity to a new piece

This is the per-piece command. Runs immediately before Veo prompt assembly in `virtual-character-veo-3-1` Command 3.

1. **Read the canonical piece's metadata:** discipline, scene template (if any), cameos.
2. **Read the matching contracts:**
   * `<store>/disciplines/<discipline>.md` for outfit/setting/lighting/voice.
   * `<store>/scenes/<scene-template>.md` if the piece references a stock scene.
   * `<store>/character.md` for the character one-pager.
   * `<store>/voice.md` for spoken-line cadence + emoji signature.
3. **Compose the Veo prompt fragment** as a sequence:
   * Character appearance (from `character.md`).
   * Scene + setting (from the discipline + scene template).
   * Outfit/gear, brand-name-softened.
   * Action + camera (from the discipline contract).
   * Dialogue cue, on-brand cadence.
   * Audio ambience.
4. **Hand off to `virtual-character-veo-3-1` Command 3** with the assembled prompt.

### Command 3 — Validate a generated piece against the brand identity

This runs **after** Veo's own Command 4 validation. Brand-identity validation is more subjective than the encoder-fingerprint or audio-track checks.

1. **For each redo-criterion in `<store>/redo-criteria.md`,** evaluate the shot. Bug to flag any criterion that's met.
2. **If any criterion fires, mark the piece as `failed` with the specific criterion** (so the next sweep tries a different prompt fragment + the operator can track which criteria fire most).
3. **If none fire**, the piece is brand-OK. Hand off to the publishing skills' caption-lint + collaborator-invite + emoji-signature steps.

### Command 4 — Evolve the brand identity

The brand voice + visual identity evolve. The doc is **versioned, not immutable.**

1. **Quarterly review** (operator-driven). Look at the last quarter's pieces; surface any pattern of "we kept doing X but X felt off-brand" or "we kept doing Y but Y wasn't in the contract". Update the relevant section.
2. **Major rewrites** (rebrands, new direction, new co-star) bump the doc's `version` field. Pieces generated under the previous version stay; new pieces follow the new version.
3. **Cross-agent re-sync.** When the doc updates, every agent needs to re-read it. The MCP `setup_readiness` tool's `brand-identity` row surfaces the doc's `version` so a stale agent can self-detect.

### Command 5 — Detect brand drift

A piece passes Command 3 individually but the body of work as a corpus drifts (audience can tell something feels different after 20 pieces even if no single piece is off-brand). Quarterly:

1. **Sample 20 recent pieces** (or a quarter's worth, whichever is smaller). Lay them out side-by-side (a screenful of stills + captions).
2. **Read the brand identity doc aloud** (the operator does this part; agents can prepare the layout but the eyes-on review is human).
3. **Flag any of these patterns:**
   * Outfit/gear drifted gradually (caps changed colour over 10 pieces).
   * Character expression drifted (started calm, has been getting more animated).
   * Caption length / tone drifted (started terse, captions have been getting long).
   * Background variety dropped (every shot is now in the same one location).
4. **Decide:** is the drift intentional (the brand is evolving and the doc should be updated to match) or is it sloppy execution (the doc is right; the recent pieces are off-brand)?
5. **Update the doc OR plan a re-shoot batch** accordingly.

## Pepe Arturo reference deployment

* **Store:** Shared Obsidian vault `~/Obsidian/vaults/AI Agents Memory/` mounted into every agent (Pepe, Cowork, ad-hoc Claude).
* **Files:**
  * `Helmut/Visual Styling.md` — canonical style guide (Pepe character, scene templates, voiceover style, RAI-filter avoidance, redo criteria).
  * `Pepe Arturo/Content Business.md` — brand charter + open backlog.
  * `Pepe Arturo/Cameo Roster.md` — cross-link into the `real-person-cameo-protocol` artefacts.
* **Character one-pager:** "Pepe Arturo is a small calm frog monk in a brown rope-belt habit. Sitting cross-legged is the default posture. Soft male English voice, slow cadence."
* **Discipline contracts:** swim / run / bike / strength / talking-head / suit / candid — each one paragraph in `Helmut/Visual Styling.md` § 4.
* **Scene templates:** Pepe-on-mountain, Pepe-in-kitchen, Pepe-and-Helmut-at-table, Helmut-training-solo. Each in `Helmut/Visual Styling.md` § 5.
* **Voice rules:** calm / grounded / sport-flavoured / English only / no Italian / no filler / slow cadence. Plus the emoji signature 🍝 on every post.
* **Off-brand list:** literal brand names embroidered (Nike / Canyon / Orca), frenetic motion, harsh fluorescent lighting, mismatched gear/discipline combos.
* **Cross-agent enforcement:** the shared vault is mounted into Pepe (this agent) + Cowork (Helmut's main work agent) + any ad-hoc session via the shared-vault-symlink pattern. The MCP `setup_readiness` tool flags `brand-identity-ready: true` only when the vault is mounted + the canonical doc is present.

## Brand-specific overrides every operator should change

* Store choice (Obsidian / GitHub / Notion).
* Character one-pager.
* Discipline taxonomy.
* Colour palette + typography (often borrowed from a website's design system).
* Scene template library.
* Voice tone descriptors.
* Off-brand list (specific to the brand's product / audience).

## Operating constraints carried over

* **One canonical source** — the brand identity doc IS the canonical source for "what does this brand look + sound like".
* **Cross-agent visibility** — same source must be readable by every agent generating content.
* **Versioned, not immutable** — the doc evolves; the MCP layer surfaces version mismatches.
* **Human-driven drift review** — the quarterly drift review (Command 5) is human-eyes-on; agents prepare the layout.

## How a mentored agent uses this skill

A mentee agent connecting to this playbook reads `content-strategy-planning-optimization` first (strategy + planning), then **this skill** second (what the brand looks like), then `real-person-cameo-protocol` third (if real-human cameos are in scope), then the four channel skills (Veo + IG + X + blog). Without `brand-visual-identity` Setup done, the mentee cannot legitimately generate any new shot — every Veo prompt assembly reads from this skill's outputs. The `setup_readiness` MCP tool's `brand-identity` row gates the agent's first procedural action.
