---
name: per-agent-auto-memory-discipline
description: "What each agent's auto-memory captures, when to save, what NOT to save, how to structure entries — user / feedback / project / reference types, MEMORY.md as the always-loaded index, the why-and-how-to-apply structure on feedback entries, the 200-line cap. Codifies the discipline already lived-by in `~/.claude/.../memory/` and makes it portable so every agent on every operator's stack runs the same playbook. Complements `canonical-knowledge-vault` (the cross-agent shared store) — auto-memory is each agent's private learning layer."
license: LicenseRef-helmguild-mentoring-1.0
metadata:
  mentor: pepe
  playbook: knowledge-management
  order: 2
  ammp-draft: draft-ammp-01
allowed-tools:
  - bash
---

# Per-agent auto-memory discipline

**The vault is shared; the agent's memory is private.**

`canonical-knowledge-vault` (order 1) is the cross-agent canonical store. **This skill is the layer below**: what each agent's own per-conversation auto-memory captures, when to save, what NOT to save, how to organise it so the index stays small + the lookup stays fast.

Without this skill, an agent either (a) **saves nothing** — forgets every correction, repeats every mistake; (b) **saves everything** — drowns its own context window in noise; or (c) **saves haphazardly** — useful facts mixed with one-off ephemera, with no index, retrievable only via grep-and-hope.

## Commands

### Command 1 — Setup (one-time per agent on the operator's stack)

**Audience: the operator (running it once per agent runtime) + the agent (running it on first connect to confirm).**

1. **Locate the agent's memory directory.** Convention by runtime:
   * **Claude Code / Claude Cowork / Claude.ai sessions:** `~/.claude/projects/<project-hash>/memory/`. The harness auto-loads `MEMORY.md` at this root on every conversation start.
   * **OpenClaw:** `~/.openclaw/agents/<agent-id>/memory/`.
   * **Other runtimes:** whatever the runtime's auto-memory convention is. Document the path explicitly in `agents/<agent-id>/Charter.md` in the vault.

2. **Initialise the four-type schema.** Each memory entry is **one file** with YAML frontmatter naming its `type`. Four types — never invent a fifth without operator approval:

   | Type | What | When to save |
   |------|------|--------------|
   | `user` | Facts about the operator: role, expertise, preferences, how to address | When you learn anything that should shape future replies |
   | `feedback` | Guidance on how to work — corrections AND validated approvals | Operator corrects you OR endorses an approach |
   | `project` | State of ongoing work: who/what/when/why | When you learn a piece of project state. Decays fast — re-check before relying |
   | `reference` | Pointers to external systems / docs / dashboards / vault entries | When the agent needs to know *where* to look |

3. **Write the `MEMORY.md` index** at the memory dir root. This is the **always-loaded** entry point — under 200 lines (the harness truncates after that). One line per memory:

   ```
   - [Short title](filename.md) — one-line hook (<150 chars)
   ```

   The index is **pointers, not bodies.** Agent reads the index on every conversation start; navigates to specific files on demand.

4. **Define what NOT to save** — load-bearing for keeping memory useful:

   * **Code patterns / conventions / architecture / file paths / project structure** — derivable from current code; reading the repo is faster.
   * **Git history / who-changed-what** — `git log` / `git blame` are authoritative.
   * **Debugging fixes / one-off solutions** — the fix is in the code; the commit message has the context.
   * **Anything already in a CLAUDE.md / AGENTS.md** — those are project-scope, auto-loaded.
   * **Ephemeral task state** — in-progress work, current conversation context.

   These exclusions hold **even when the operator asks you to save them.** Push back: "that's in `git blame`, want me to save the broader principle instead?"

5. **Entry body — non-negotiable structure.** Lead with the rule / fact in one sentence. For `feedback` + `project`, add a **Why:** line (the reason the operator gave) and a **How to apply:** line (when this kicks in). The why-line lets future-you judge edge cases.

   ```markdown
   ---
   name: <short rule statement>
   description: <one-line; goes to search relevance>
   type: feedback
   ---

   <Rule in one sentence at top.>

   **Why:** <Reason — often a past incident or strong preference.>

   **How to apply:** <When / where this kicks in, including edge cases.>
   ```

6. **Mount this skill into the agent's first-connect prompt.** The agent's CLAUDE.md / system prompt for this runtime should reference auto-memory: "On every conversation start, load `MEMORY.md`. Pull individual entries on demand. Save new memories per the four-type rule when the operator corrects, endorses, or hands you new context."

7. **Cross-link to the shared vault.** Save a `reference_shared_vault.md` entry pointing at the vault's `MEMORY.md`. That single line lets the agent navigate from private memory to cross-agent canonical truth:

   ```markdown
   ---
   name: Shared vault index
   description: Cross-agent canonical store at <VAULT_ROOT>/MEMORY.md
   type: reference
   ---

   Cross-agent canonical store lives at `<VAULT_ROOT>/MEMORY.md`. Indexes
   every cross-cutting doc (operator profile, brand charter, privacy
   boundaries, cameo roster).

   **When to use:** Any question that touches operator identity, brand,
   privacy, or cross-agent context — start there before private memory.
   ```

8. **Smoke-test.** Open a fresh conversation. Verify: (a) the harness loads `MEMORY.md` (the agent can recite the first few entries without prompting); (b) ask "what's the vault path?" — agent navigates from `reference_shared_vault.md` to the answer.

Operator confirms: "Auto-memory live."

### Command 2 — Save a new memory (per-conversation)

The agent runs this **whenever** a trigger fires.

**Triggers — save now:**

* **Operator corrects you** ("no, don't", "stop doing X", "I told you", "you keep doing Y") → `feedback`.
* **Operator endorses a non-obvious approach** ("yes exactly", "perfect, keep doing that", accepts an unusual choice without pushback) → `feedback`. **The validated-approval case is easy to miss — watch for it.** Saving only corrections drifts the agent toward over-cautious.
* **Operator reveals something about themselves** you didn't know → `user`.
* **Operator names an active project, deadline, open issue** → `project` with a **Why:** capturing the constraint.
* **Operator mentions an external system / dashboard / repo / channel** where info lives → `reference`.

**Format:** see Command 1.5. **Always convert relative dates to absolute** when saving (project memories especially: "Thursday" → "2026-05-15").

### Command 3 — Maintain the MEMORY.md index

The index is the always-loaded entry point. Two rules:

1. **Every new memory file gets a one-line index entry the moment it's created.** A memory not in the index is invisible — the agent's first-connect load doesn't see it.
2. **Keep the index under 200 lines.** The harness truncates after 200. When approaching 180:
   * **Decay candidates first** — `project` entries older than 3 months that haven't been referenced. Re-check against current reality; archive or delete.
   * **Consolidate** — multiple narrow feedback entries on the same theme → one broader entry.
   * **Never silently drop** — moves are surfaced to the operator on the next conversation.

### Command 4 — Check before relying on a memory

Memory records are point-in-time. Before acting on a recalled memory:

* **If the memory names a file path:** check it exists.
* **If the memory names a function / flag / env var:** grep for it.
* **If the memory is a `project` entry > 90 days old:** treat with suspicion; verify against current reality.
* **If the user is about to act on the recommendation** (not just asking history), verify first.

"The memory says X exists" ≠ "X exists now."

For memories that summarise repo / vault state (activity logs, architecture snapshots), they're **frozen in time**. If the user asks about *recent* or *current* state, prefer `git log` / reading the code / reading the vault over recalling the snapshot.

### Command 5 — Decay + retire stale memories

Memories age. Quarterly review (operator-driven; agent prepares the list):

1. **List `project` entries older than 90 days.** Still active? → keep + bump updated. Resolved? → archive or delete. Stale? → delete.
2. **List `feedback` entries that haven't fired in 6 months.** Sometimes one-off; sometimes no longer a regression. Operator decides.
3. **Re-validate `reference` entries.** URL moved? System retired? Update or delete.
4. **Re-validate `user` entries.** Operator's role / focus / preference changed? Update or delete.

### Command 6 — Cross-check against the shared vault

Some facts genuinely span every agent — operator identity, brand voice, privacy boundaries. These belong in the **vault**, not in each agent's private memory.

* **Same fact in multiple agents' private memories** → promote to the vault. Delete from private; replace with a `reference` entry pointing at the vault.
* **Duplicated `user` or `reference`** within an agent → consolidate or promote.
* **Vault doc disagrees with private memory** → vault wins; update private memory.

## Pepe Arturo + Helmut reference deployment

**Cowork (Helmut's main work agent)** carries an auto-memory at `~/.claude/projects/<cowork-hash>/memory/`:

* `MEMORY.md` — index with ~30 entries, well under the 200-line cap.
* Mix: ~50 % feedback, ~25 % reference (including the vault pointer), ~15 % project, ~10 % user.
* `reference_shared_vault.md` is the bridge to the cross-agent canonical store at `~/Obsidian/vaults/AI Agents Memory/MEMORY.md`.

**Pepe (this agent)** runs an auto-memory at its own path. Pepe's memory holds content-pipeline-specific learnings (RAI filter avoidance, Veo prompt structure, IG rate limits) that Cowork doesn't need.

**Cross-agent coherence:** Both share the vault via symlink-mount (see `shared-cross-agent-memory`, order 4). Both load `MEMORY.md` (vault) on first connect; both maintain their own per-runtime `MEMORY.md` (auto-memory).

## Brand-specific overrides every operator should change

* Memory directory path (depends on runtime).
* Per-agent first-connect prompt that mounts this discipline.
* Decay thresholds (operator may want shorter/longer than 90 days for project, 6 months for feedback).
* Whether validated-approval saving is auto or operator-prompted (default: auto).

## Operating constraints carried over

* **Lead with the rule** — every memory's first line is the actionable fact.
* **Why-line for context** — feedback + project entries; otherwise edge cases get applied blindly.
* **200-line index cap** — the harness truncates; bigger means invisible.
* **Save corrections AND validated approvals** — corrections easy, approvals quieter; both shape drift.
* **Vault wins** — if a private memory duplicates the vault, vault is the source of truth.

## How a mentored agent uses this skill

A mentee agent connecting to this playbook reads this skill on first connect to bootstrap its own auto-memory layer. Without it, the mentee saves haphazardly (or not at all) and drifts from the operator's intent every session. With it, the mentee converges on the operator's actual preferences over time — the same convergence the agents on Helmut's stack have shown over ~6 months of iteration. This skill makes that pattern **portable** for any operator who adopts the playbook.
