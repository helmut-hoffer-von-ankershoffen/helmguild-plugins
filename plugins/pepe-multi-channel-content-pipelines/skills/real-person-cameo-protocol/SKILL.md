---
name: real-person-cameo-protocol
description: "The cross-cutting discipline for putting real humans (the operator themselves, a co-star, a family member, a colleague, a fan) into AI-generated brand content. Covers per-person consent records, per-discipline face-reference libraries (the same person needs different ref shots for swim / run / bike / talking-head / suit), outfit + gear coherence rules per discipline, brand-name softening (Veo's RAI filter trips on literal embroidered brand names), the IG collaborator-invite consent model, sport-emoji caption pairing, and the per-batch greenlight gate for sensitive cameos. Sits between `virtual-character-veo-3-1` (where references are consumed) and the three publishing skills (where consent + tagging matter)."
license: LicenseRef-helmguild-mentoring-1.0
metadata:
  mentor: pepe
  playbook: multi-channel-content-pipelines
  order: 2
  ammp-draft: draft-ammp-01
allowed-tools:
  - bash
---

# Real-person cameo protocol

A real human appearing in AI-generated brand content carries privacy, consent, and quality risks that no other asset does. This skill is the discipline that puts them in safely + consistently. It runs **before** any Veo generation involving the person, and gates the IG / X / blog publish step from the consent side.

If the brand has no real-person cameos (a pure-fictional-character brand), this skill is optional. The moment a real face appears, it's the most load-bearing skill in the playbook.

## Commands

### Command 1 — Setup (one-time per brand, operator runs this)

**Audience: the human operator.** The agent walks the operator through each numbered step.

1. **Scaffold the roster templates.** Run the bundled scaffolder to write the per-person directory skeleton for every named cameo:

   ```sh
   scripts/cameo-roster-scaffold.sh --root <CAMEO_ROSTER_ROOT> \
       --person <id>:"<Display Name>" \
       --person <id>:"<Display Name>" ...
   ```

   This creates `<root>/<id>/{ref-index.json,outfit-contract.md,context-rules.md,platform-routing.json,consent-record.md,refs/}` for each person and a top-level `roster.md` index. The next steps fill those templates in.

2. **Build the cameo roster.** Every real person who may appear in brand content is a row in the roster. Even the operator-of-themselves counts. Initial fields per person:
   * `id` — kebab-case slug (`helmut`, `sandra`, `co-founder-mia`).
   * `display_name` — what shows in captions + collaborator invites.
   * `relationship_to_operator` — self / partner / colleague / family / friend / public-figure-with-permission.
   * `appearance_status` — `approved-default` / `gated` / `embargoed`.
   * `consent_record_path` — where the signed/text-of-record consent lives (Obsidian note, GitHub repo, paper photo, etc.).
   * `platforms_allowed[]` — subset of `[instagram, x, blog]`. Some people consent to one surface only.
   * `cameo_kind_rules[]` — what scenes they may appear in (e.g. "sport: yes" / "drinking alcohol: no" / "controversial topic: ask first").
3. **Record consent.** For every roster entry except the operator-of-themselves, get explicit consent and persist the record. Forms that work:
   * **Signed paper/PDF** — scanned, filed at `consent_record_path`.
   * **Written-text consent in a private chat** — copied verbatim into the consent record, with timestamp + chat-platform metadata.
   * **Stand-in: a partner / family member who is in the loop on the brand and has previously agreed in conversation** — record the conversation excerpt + date in a private note. Less formal than signed, but acceptable for low-risk cameos. For sensitive cameos (anything involving the cameo subject's likeness in a way they could plausibly object to), get explicit per-batch greenlight even if a general consent exists.
   * **Public figure** — only with documented permission (DM, email, contract). Implicit consent from "they're famous" is not consent.
4. **Build the per-person face-reference library.** Same person, different shots for different disciplines. A talking-head face ref doesn't generate a believable swim sequence. The library is a directory per person:

   ```
   <brand>/refs/<person-id>/
     ├── talking-head_1024.jpg        # neutral, eye-line forward, indoor light
     ├── headshot-suit_1024.jpg       # formal, business context
     ├── swim_1024.jpg                # swim cap, goggles up, neutral expression
     ├── run_1024.jpg                 # running cap, daylight
     ├── bike_1024.jpg                # aero helmet, sunglasses, daylight
     ├── strength_1024.jpg            # gym/outdoor strength context
     ├── candid_1024.jpg              # informal smile, mixed lighting
     └── ref-index.json               # which ref to use for which discipline
   ```

   `ref-index.json` is the contract — Veo prompt assembly reads it to pick the right ref:

   ```json
   {
     "person_id": "helmut",
     "default": "talking-head_1024.jpg",
     "by_discipline": {
       "swim": "swim_1024.jpg",
       "run": "run_1024.jpg",
       "bike": "bike_1024.jpg",
       "strength": "strength_1024.jpg",
       "talking-head": "talking-head_1024.jpg",
       "suit": "headshot-suit_1024.jpg",
       "candid": "candid_1024.jpg"
     }
   }
   ```

5. **Build the per-discipline outfit + gear contract.** For each discipline the cameo can appear in, write a one-paragraph "what's on-brand" spec:
   * **Swim:** Orca wetsuit, Orca swim cap, goggles (Orca or Roka). Not: Nike or generic-branded swim gear.
   * **Run:** black running cap (Orca or unbranded), light technical tee, daylight. Not: heavy winter layers, branded gym wear.
   * **Bike:** Canyon Speedmax or generic TT bike, black aero helmet, daylight. Not: road-bike upright posture, helmet-less.
   * **Strength:** kettlebell or barbell, hoodie or technical shirt, alpine/outdoor backdrop OK. Not: gym mirrors.
   * **Suit:** dark blazer, no tie unless context demands, neutral background.
   These specs become Veo prompt fragments. Persist as `<brand>/refs/<person-id>/outfit-contract.md`.
6. **Define the per-person privacy / context rules.** For each person, what cameos require explicit per-batch greenlight beyond the default consent? Common patterns:
   * **Partner / spouse appearing alongside the operator** → per-batch greenlight (couple-reel content has a different emotional weight than solo content).
   * **Children** → very high bar; default to absolute embargo unless legal guardian + child both consent + a clear safeguarding policy exists.
   * **Drinking alcohol** → per-batch.
   * **Political or polarised topics** → per-batch, even if the person is otherwise an approved default cameo.
   Persist these per-person as `<brand>/refs/<person-id>/context-rules.md`.
7. **Define the platform routing rules.** Some people consent to public publish on IG but not on X (different audience, different risk surface). Persist per-person:

   ```json
   {
     "platforms_allowed": ["instagram", "blog"],
     "platforms_denied": ["x"],
     "collaborator_invite_default": true,
     "caption_tag_default": "@helmut.hoffer.von.ankershoffen"
   }
   ```

   The publishing skills (`publishing-instagram`, `publishing-x`, `publishing-blog`) read this and refuse to publish to a denied platform.
8. **Set the per-person sport-emoji signature** (if the brand voice uses it). Pepe's mapping:

   | Discipline | Emoji bundle |
   |-------|-----|
   | Swim | 🏊‍♂️🍝 |
   | Run | 🏃‍♂️🍝 |
   | Bike | 🚴‍♂️🍝 |
   | Strength | 🏋️‍♂️🍝 |
   | Talking-head | 🍝 + small context emoji |
   | Suit | 👔🍝 |
   | Candid | 🤝🍝 |

   The caption-render step picks the bundle based on the cameo's discipline tag on the canonical piece.
9. **Smoke-test the whole protocol.** Pick the lowest-risk cameo (operator-of-themselves, talking-head, indoor, neutral). Run `virtual-character-veo-3-1` Command 3 with the person's ref + outfit contract. Inspect the output. If face matches, outfit is on-brand, and the validation in `virtual-character-veo-3-1` Command 4 passes → the protocol works. If not, fix the refs and re-shoot.

Operator confirms: "Cameo protocol live."

### Command 2 — Resolve a cameo for a new shot

This is the per-piece command. Runs immediately before `virtual-character-veo-3-1` Command 3 (render a shot).

1. **Read the canonical piece's cameo fields.** Schema additions to the content-strategy skill's canonical piece:

   ```json
   {
     "cameos": [
       {"person_id": "helmut", "discipline": "swim"}
     ]
   }
   ```

2. **Look up each cameo in the roster.** For each cameo:
   * `appearance_status == "embargoed"` → **abort**. Surface to the operator: "this person is embargoed, the piece can't be generated as drafted".
   * `appearance_status == "gated"` → **block until per-batch greenlight**. The strategy skill's human-gate machinery handles this; the piece sits in `gated` until the operator flips.
   * `appearance_status == "approved-default"` → proceed.
3. **Check context rules.** Even an approved-default cameo can trip a context rule (drinking alcohol, polarised topic, child co-appearance). The agent reads the piece's scene description and context-rule list; any match → block until per-batch greenlight.
4. **Pick the face reference** by discipline from `ref-index.json`. If the discipline isn't in the index, fall back to `default` and flag a warning (the operator should add a discipline-specific ref).
5. **Pull the outfit contract** for that discipline.
6. **Compose the Veo prompt fragment.** Append to the appearance contract from `virtual-character-veo-3-1` Command 2:
   * The discipline-specific face reference (passed as `referenceImages[1]`, with the character avatar at `[0]`).
   * The outfit contract paragraph.
   * The discipline-specific dialogue cue (if the cameo speaks).
7. **Run Veo Command 3** with the assembled prompt + refs.
8. **Validate per cameo rules in Veo Command 4** — visual consistency now includes "is the face the right ref?" + "is the outfit on-brand?". If either drifts → redo with a tighter prompt fragment.

### Command 3 — Soften brand-name embroidery in prompts

Veo's RAI filter trips on literal embroidered brand names ("Nike" on a cap, "Canyon" on a bike frame, "Orca" on a wetsuit). The visual remains correct after softening — only the literal text needs to go.

1. **Read the discipline's outfit contract.**
2. **Substitute literal brand names with generic descriptors:**
   * `Nike running cap` → `a black running cap`.
   * `Canyon Speedmax TT bike` → `a black aerodynamic TT bike`.
   * `Orca wetsuit` → `a black neoprene wetsuit`.
   * `Orca swim cap` → `a black silicone swim cap`.
   Keep the visual fidelity (`black + aerodynamic + TT bike` produces a Canyon-like silhouette in Veo's training); only the literal text gets soft.
3. **Record the substitution table** as a per-brand `softening-rules.json` so the agent applies it consistently across shots.
4. **If the substitution doesn't trip the filter on the FIRST shot**, the brand may have re-tuned the filter or the wording was already safe. Re-promote the literal name to a regression candidate.

### Command 4 — Handle the IG collaborator invite consent model

The IG `collaborators` field is a public co-publish — both accounts appear at the top of the post; once the invitee accepts, the reel shows on their feed too. This is **consent-required** even for an otherwise-approved cameo.

1. **Read the cameo's `collaborator_invite_default`.** Pepe's default for Helmut is `true`; for any other roster entry it's `false`.
2. **If `true`, set `IG_COLLABORATORS=<handle>`** as `publishing-instagram` Command 4 expects.
3. **If `false`, but the operator has marked this specific piece as collaborator-on**, set the override only for that publish.
4. **The cameo subject must accept the invite once per post.** This is unavoidable — the agent can't auto-accept on someone else's behalf. The strategy skill should not block on the accept; the post is live before the accept lands. The accept extends reach; it doesn't gate the publish.

### Command 5 — Surface skipped consent + cross-agent context

The cameo protocol is a brand-wide rule, but content is sometimes generated by **other agents** (ad-hoc Claude sessions, Cowork sessions, a teammate working in a different runtime). The protocol is enforceable only if those agents can read the same roster + rules.

1. **Persist the roster + rules in a cross-agent-readable location.** For Pepe, this is the shared Obsidian vault at `~/Obsidian/vaults/AI Agents Memory/<brand>/Cameo Roster.md`. For other operators, the equivalent is whatever cross-agent share is in place (a private GitHub repo, a Notion DB the team's agents have read access to).
2. **Every agent generating brand content must read this on first connect.** The `pipeline-status` MCP server's `setup_readiness` tool surfaces a `cameo-protocol-ready: true|false` row per the presence of this doc.
3. **Off-brand cameo events get logged.** When the operator catches an off-brand publish (wrong face ref, missing consent, denied platform), log it in `state/cameo-incident-log.jsonl` — hash + person-id + summary. The next planning sweep flags any recurring person-id for "tighten the context rules".

### Command 6 — Quarterly re-affirm consent

Consent is not perpetual; the cameo subject's life changes. Quarterly (operator decides cadence — minimum once a year):

1. **For every roster entry that's not the operator-of-themselves**, briefly check in with the person: "I'm still using your likeness in [brand]; you're still good with this, right?" Form depends on the relationship — for a partner, a one-line "still ok with cameos?"; for a colleague or fan, a more formal ask.
2. **Record the re-affirmation** with date. The roster entry's `consent_record_path` accumulates dated lines.
3. **Anyone who says no, or doesn't respond after a follow-up**, flip to `appearance_status: embargoed`. Existing published content is not retroactively deleted (that's a separate conversation with the person), but new generations stop.

## Pepe Arturo reference deployment

* **Roster:** Helmut (self-of-operator's-partner-AI; brand persona), Helmut Hoffer von Ankershoffen (operator-and-co-star, `approved-default`), Sandra Hoffer von Ankershoffen (`gated`; per-batch greenlight required for every couple-reel).
* **Helmut's ref library:** `talking-head_1024.jpg` (Snowflake profile photo), `swim_1024.jpg`, `run_1024.jpg`, `bike_1024.jpg`, `strength_1024.jpg`, `candid_1024.jpg`. Generated from `/Volumes/My Shared Files/Assets/Helmut/IMG_*.HEIC` source pool.
* **Outfit contracts:** Swim = Orca wetsuit + Orca swim cap (softened in prompt to "black neoprene + black silicone"). Bike = Canyon Speedmax + black aero helmet (softened to "black aerodynamic TT bike + black aero helmet"). Run = black running cap (softened from Nike).
* **IG collaborator default:** Helmut on, Sandra off. Couple-reel batches require per-batch greenlight from Helmut before Sandra is invited.
* **Cross-agent doc:** `~/Obsidian/vaults/AI Agents Memory/Helmut/Visual Styling.md` + `~/Obsidian/vaults/AI Agents Memory/Pepe Arturo/Cameo Roster.md`. Any agent generating Pepe content reads both first.
* **Privacy rules:** see `feedback_dont_contact_sandra_about_pepe_content` in the operator's auto-memory — no AI agent contacts Sandra about Pepe content; all family communication on this topic goes through Helmut.

## Brand-specific overrides every operator should change

* Roster (who appears).
* Discipline taxonomy (Pepe's is sport-flavoured; a chef brand would have cooking-action disciplines instead).
* Outfit contracts per discipline.
* Consent record format.
* Sport-emoji signature mapping.
* Cross-agent doc location.

## Operating constraints carried over

* **Human gate before first public publish** — every new cameo person gets first-piece-gated even if `approved-default`. The strategy skill enforces this.
* **One canonical source** — the cameo roster + ref-index are the single source of truth; channel skills read from them.
* **Resumable stages** — a missing/wrong-ref shot is detected at validation time, the piece flips to `failed`, the next sweep retries with a fixed ref.
* **Monitor the pipeline** — the cameo-incident log is part of pipeline health (Command 5.3); a rising incident rate is a signal the roster or the contracts need an update.

## How a mentored agent uses this skill

When a mentee agent connects to this playbook and the operator has a real-person cameo brand, the mentee agent reads this skill **second** (after `content-strategy-planning-optimization` and before any channel skill). Without the roster + ref library, the mentee cannot legitimately generate any cameo-bearing shot. The `setup_readiness` MCP tool surfaces whether this skill's Setup has been completed (`cameo-protocol-ready` row).
