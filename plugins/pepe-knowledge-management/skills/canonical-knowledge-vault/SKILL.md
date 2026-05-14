---
name: canonical-knowledge-vault
description: "The single canonical Markdown store where every cross-cutting brand artefact lives — brand identity, cameo rosters, scene templates, project state, privacy boundaries, _shared changelog for cross-agent handoffs. Walks the operator through picking a store (shared Obsidian vault / private GitHub / Notion DB), authoring the directory schema, defining markdown + frontmatter conventions, and mounting the same store into every agent on their stack so all of them read the same source of truth. The foundation skill for the pepe-knowledge-management playbook — every other skill in the playbook (auto-memory, learning extraction, shared cross-agent memory, drift audit) reads from + writes to this vault."
license: LicenseRef-helmguild-mentoring-1.0
metadata:
  mentor: pepe
  playbook: knowledge-management
  order: 1
  ammp-draft: draft-ammp-01
allowed-tools:
  - bash
---

# Canonical knowledge vault

A brand running on AI agents accumulates **knowledge that the agents need but isn't code**: who's in the cameo roster, what the brand's voice rules are, what scenes the brand uses, what privacy boundaries apply to which person, what the operator's open project state looks like. If this knowledge lives in **one agent's memory**, the other agents drift. If it lives in **the operator's head**, the agents can't act on it. If it lives in **scattered notes**, nothing is canonical.

This skill is the artefact that fixes all three: **one vault, Markdown, structured, mounted into every agent the operator runs.**

## Commands

### Command 1 — Setup (one-time per operator, the operator runs this)

**Audience: the human operator.** The agent walks each step.

1. **Scaffold the vault layout.** Run the bundled scaffolder:

   ```sh
   scripts/vault-scaffold.sh \
     --vault-root <PATH_TO_VAULT> \
     --operator "<operator-slug>" \
     --brand "<brand-slug>" \
     --agents "<agent-1>,<agent-2>,..."   # e.g. pepe,cowork,hermes
   ```

   Writes the directory skeleton + a `README.md` describing each top-level dir + the `MEMORY.md` index (linking operator / brand / each agent's charter) + `_shared/Conventions.md` + `_shared/Privacy.md` + `_shared/Changelog.md` seed + stubs for every operator + brand + per-agent doc. Both slugs must be lowercase kebab. 36 unit tests cover the scaffolder.

2. **Pick the vault backend.** Three sane choices, each with its own properties:
   * **Shared Obsidian vault** (recommended for solo operators). Local-first, syncs across devices via iCloud / Obsidian Sync / Syncthing. AI agents read via filesystem mounts. Best for: single-human operator running multiple agents.
   * **Private GitHub repo** (`<operator>-knowledge-vault`). Versioned, commit history is the audit trail. AI agents read via SSH-key clone. Best for: engineering-flavoured operators, teams of two.
   * **Notion / Confluence DB.** Accessed via API token by each agent. Best for: teams ≥ 3, brands where non-engineers also edit the vault.
   The agent reads from the location resolved via `KNOWLEDGE_VAULT_PATH` (or the equivalent API token + workspace id).

3. **The canonical top-level directory schema:**

   ```
   <vault-root>/
   ├── README.md                  (what this vault is, who reads it)
   ├── MEMORY.md                  (operator + agent shared facts; the
   │                               "if you read one file, read this" entry)
   ├── _shared/
   │   ├── Changelog.md           (chronological cross-agent change log)
   │   ├── Conventions.md         (markdown conventions, frontmatter, naming)
   │   └── Privacy.md             (cross-cutting privacy boundaries)
   ├── <operator-slug>/           (e.g. Helmut/)
   │   ├── Profile.md             (one-pager about the human operator)
   │   ├── Work.md                (open projects, current focus)
   │   ├── Philosophy.md          (orientation, values, preferences)
   │   └── Privacy Boundaries.md  (per-person consent, no-go zones)
   ├── <brand-slug>/              (e.g. Pepe Arturo/)
   │   ├── Charter.md             (what is this brand, why does it exist)
   │   ├── Visual Styling.md      (brand identity — read by content pipeline)
   │   ├── Cameo Roster.md        (cross-link to per-person cameo dirs)
   │   ├── Content Calendar.md    (link to canonical content store)
   │   └── Voice.md               (voice + tone, banned phrases, emoji)
   └── agents/
       ├── <agent-1>/             (e.g. pepe-arturo/)
       │   ├── Charter.md         (this agent's role + boundaries)
       │   └── Memory Notes.md    (agent-specific running notes)
       └── <agent-2>/             (e.g. cowork/)
           └── ...
   ```

4. **Define the canonical Markdown conventions** in `_shared/Conventions.md`:
   * **Frontmatter (YAML) on every doc:**
     ```yaml
     ---
     title: <human-readable>
     slug: <kebab-case>
     updated: YYYY-MM-DD
     authors: [<agent-or-human-id>, ...]
     readers: [all | <list of agent / human ids>]
     supersedes: <slug-of-prior-doc-if-any>
     ---
     ```
   * **Naming:** kebab-case slugs. Spaces in filenames only where the file is human-facing (titles); kebab elsewhere.
   * **Cross-links:** `[[Vault Doc Title]]` (Obsidian-style) within the vault; full path `vault://<rel-path>` from agent memory references.
   * **Length:** keep each doc < 5 000 tokens (~3 500 words). Larger → split into a parent + children with cross-links.
   * **Updates are full-rewrites, not patches:** when a fact changes, edit the doc and bump `updated`. Don't patch with diffs — keeps round-trips clean.

5. **Initialise `MEMORY.md` at the vault root.** This is the **"if you read one doc, read this"** entry. Index, not content — under 200 lines. Each line is `- [Title](path) — one-line hook`. Pattern:

   ```
   - [Operator profile](Helmut/Profile.md) — who Helmut is + how to address him
   - [Brand charter — Pepe Arturo](Pepe Arturo/Charter.md) — what Pepe is + isn't
   - [Privacy boundaries](_shared/Privacy.md) — what crosses agent / human compartments
   - [Pepe brand identity](Pepe Arturo/Visual Styling.md) — content-pipeline reference
   - [Cameo roster](Pepe Arturo/Cameo Roster.md) — who appears + consent posture
   ```

6. **Mount the vault into every agent.** Per backend:
   * **Obsidian:** symlink the vault path into each agent's working directory:
     ```sh
     ln -s <VAULT_ROOT> ~/.openclaw/workspace/AgentName/vault
     ```
     Then the agent reads `~/.openclaw/workspace/AgentName/vault/...` and gets the same files Obsidian is editing.
   * **GitHub repo:** each agent clones the repo into its working dir on startup. `git pull` on every agent invocation if freshness matters.
   * **Notion:** each agent's startup config carries the Notion API token + workspace id. The agent's "open the vault" tool wraps the Notion API.

7. **Wire the `MEMORY.md` index into each agent's auto-memory layer.** A Claude runtime's auto-memory system at `~/.claude/.../memory/MEMORY.md` should carry a **pointer to the vault's MEMORY.md** as a reference-type memory:

   ```markdown
   - [Shared vault index](reference_shared_vault.md) — `~/Obsidian/vaults/...`/`MEMORY.md` lists every cross-agent doc.
   ```

   On every conversation start, the auto-memory loads the index; whenever the conversation touches a domain (brand identity / privacy / project state), the agent navigates from the index to the vault doc. The agent does **not** load the whole vault on every turn — only on-demand from the index.

8. **Smoke-test cross-agent visibility.** From two different agents (e.g. Claude Code + Claude.ai web), ask each: "What's the brand emoji signature for `<brand>`?" Both must answer from the vault's `Voice.md`. If they disagree, one isn't reading the vault — fix the mount + retry.

9. **Define the vault-change cadence.** Most files are touched as needed. Two files have stricter cadence:
   * `_shared/Changelog.md` — appended **on every cross-agent-relevant change** (any agent that learns something other agents need to know). Format: `## YYYY-MM-DD HH:MM <agent-id> — <one-line summary>` + a bullet list.
   * `<operator>/Work.md` — refreshed at the operator's daily check-in (or weekly minimum). Lists open projects + current focus.

10. **Run the doctor.** `scripts/setup-doctor.sh --channel knowledge-vault` (once that probe is wired) confirms the vault path resolves + the canonical files exist.

Operator confirms: "Vault live."

### Command 2 — Author a new vault doc

The per-doc workflow when an agent or operator needs to add something to the vault.

1. **Decide where it lives.** Use the schema in Command 1.3: operator stuff under `<operator>/`, brand stuff under `<brand>/`, cross-cutting under `_shared/`, agent-specific under `agents/<agent>/`. When in doubt, ask the operator.

2. **Write the frontmatter first.** Title, slug, updated, authors, readers. The `readers` field controls compartmentalization (see `shared-cross-agent-memory` skill) — `[all]` is open; specific lists restrict.

3. **Body in Markdown.** Cross-link to related docs with `[[Other Doc Title]]`. Keep under 5 000 tokens.

4. **Update `MEMORY.md`** at the vault root with a one-line index entry (only for cross-cutting docs that other agents would benefit from finding via the index — not every doc).

5. **Append to `_shared/Changelog.md`** — one line summarising what changed + which other agents should be aware.

### Command 3 — Read from the vault

The agent reads on-demand, navigating from the index.

1. **Start with `MEMORY.md`** at the vault root. It's the "if you read one doc" entry — under 200 lines, cross-links to everything.
2. **For a question that names a domain** (brand, privacy, project), navigate from the index to the matching doc. Read only what's needed.
3. **For unknown territory** (a question that doesn't obviously map to a vault entry), grep the vault — `rg <topic> <VAULT_ROOT>` — for matching docs, then fall back to asking the operator.
4. **Surface stale-looking docs.** If a doc's `updated:` frontmatter is > 90 days old AND the answer feels uncertain, flag to the operator: "this looks stale, want me to confirm?"

### Command 4 — Cross-link to + from the content pipeline

The `pepe-multi-channel-content-pipelines` playbook's `brand-visual-identity` and `real-person-cameo-protocol` skills both reference Markdown files. **The vault is where those live.** Concretely:

* `brand-visual-identity`'s `BRAND_STYLE_GUIDE_PATH` resolves to `<VAULT_ROOT>/<brand>/Visual Styling.md` + a `<VAULT_ROOT>/<brand>/refs/` sibling dir.
* `real-person-cameo-protocol`'s `CAMEO_ROSTER_ROOT` resolves to `<VAULT_ROOT>/<brand>/Cameo Roster/` (one dir per person).
* `content-strategy-planning-optimization`'s canonical content store can be `<VAULT_ROOT>/<brand>/pieces/` (one Markdown per piece) or a separate Obsidian DB — operator's choice.

The vault is the **single source of truth**. The content pipeline is one **consumer** of it; future playbooks (PA-for-managers, operator-craft) are other consumers.

### Command 5 — Handle agent-vault conflicts

Two agents update the same doc concurrently → conflict. Resolution:

1. **Vault backend handles concurrency.** Obsidian Sync conflicts produce `<filename> (conflict-<sha>).md`; GitHub gives merge conflicts. Notion is last-write-wins.
2. **The agent that detects the conflict** appends a `## Conflict <timestamp>` block to the canonical doc + names both versions. The operator resolves manually.
3. **Never silently overwrite** another agent's edit. If the agent isn't sure → conflict + escalate.

## Pepe + Helmut reference deployment

* **Vault:** `~/Obsidian/vaults/AI Agents Memory/` — shared across Pepe + Cowork + ad-hoc Claude.ai sessions.
* **Layout** (live):
  * `Helmut/Visual Styling.md` — brand identity (read by content pipeline).
  * `Helmut/Work & Projects.md` — current focus.
  * `Helmut/Privacy Boundaries.md` — per-person consent posture.
  * `Helmut/Philosophy.md` — Stoic + Buddhist orientation, informs tone.
  * `Pepe Arturo/Content Business.md` — Pepe's charter + open backlog.
  * `Pepe Arturo/Cameo Roster.md` — cameo discipline cross-link.
  * `_shared/Changelog.md` — cross-agent change log, three entries logged 2026-05-06 alone.
* **Mount pattern:** Obsidian vault path symlinked into Pepe's working dir; Cowork sees the same path natively.
* **Operator's auto-memory** at `~/.claude/projects/.../memory/` carries a `reference_shared_vault.md` pointing at the vault root.

## Brand-specific overrides every operator should change

* Vault backend (Obsidian / GitHub / Notion).
* Vault root path.
* Operator + brand slugs (the directory names).
* Agent list (which agents on the operator's stack mount the vault).

## Operating constraints carried over

* **One canonical source, many surfaces** — the vault IS the source; agents project. Same principle as the content pipeline's canonical-content-store.
* **Resumable** — agent crashes don't lose vault state; the next agent on next connect reads the same vault.
* **Schedule as state** — vault changes have no cron; the agent re-reads on every relevant turn.
* **Privacy compartmentalization** — the `readers` frontmatter field is the contract; the agent enforces.

## How a mentored agent uses this skill

When a mentee agent connects to a playbook that consumes the vault (brand-identity, cameo-protocol, content-strategy), the mentee reads **this skill first** to confirm: (a) the vault is mounted + readable, (b) `MEMORY.md` exists at the root, (c) the canonical paths for `<brand>/Visual Styling.md` etc. resolve. Without those, the mentee escalates back to the operator: "vault setup not complete — please run `vault-scaffold.sh` and mount per Command 1.6 before I can proceed with the content pipeline."
