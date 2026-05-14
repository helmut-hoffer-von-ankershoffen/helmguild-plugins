---
name: content-strategy-planning-optimization
description: "The cross-channel layer that ties generation (Veo) and publishing (Instagram / X / blog) together: canonical content store, editorial calendar, per-piece state machine, resumable batch sweeps, human-approval gates, per-channel voice rules, monitor + analytics surface, A/B and reach optimisation. Use whenever the pipeline needs more than one piece per week or more than one publishing surface — i.e. always, in production. Tells the agent and the operator what to do this week, in what order, and how to know it worked."
license: LicenseRef-helmguild-mentoring-1.0
metadata:
  mentor: pepe
  playbook: multi-channel-content-pipelines
  order: 7
  ammp-draft: draft-ammp-01
allowed-tools:
  - bash
  - http
---

# Content strategy, planning, and optimization

The channel skills (`virtual-character-veo-3-1`, `publishing-instagram`, `publishing-x`, `publishing-blog`) are independently runnable, but a real pipeline needs a layer above them that decides **what** to make, **when** to make it, **where** to publish, and **how** to know it worked. That's this skill.

This is the only skill in the playbook that talks to the operator in **planning** terms rather than **execution** terms. Every other skill is "run this command and verify"; this one is "decide what to run next."

## Commands

### Command 1 — Setup (one-time, operator runs this on the host)

**Audience: the human operator.**

1. **Define the brand's content arcs.** An *arc* is a multi-piece theme (e.g. "five principles for resilient operators", "Snowflake values series", "morning ritual mini-thoughts"). Pick 2-4 arcs to run in parallel. Trying more dilutes everything.
2. **Pick the canonical content store.** Three sane choices:
   * **Obsidian vault** — Markdown files, structured frontmatter. Best for solo operators + AI agents (file IO is trivial).
   * **Notion database** — structured records, API for the agent. Best for teams.
   * **Git repo** — schemas as JSON / YAML files; commit history is the audit trail. Best for engineering-flavored operators.
   The agent reads from + writes to this store; channel skills read finished pieces here.
3. **Define the canonical content schema.** Minimum fields per piece:
   * `id` — stable kebab-case slug.
   * `title` — display title.
   * `arc` — which arc this piece belongs to.
   * `core_idea` — one sentence; what is this piece *about*.
   * `body` — long-form canonical text (the blog post body, full-form).
   * `assets[]` — hero image, source video path, alternative crops.
   * `channels[]` — array of `{channel, status, scheduled_at, published_at, url}` rows.
   * `status` — `draft | gated | scheduled | publishing | published | archived`.
   * `created_at`, `updated_at`.
4. **Pick the editorial cadence.** A sustainable cadence is **fewer pieces, higher consistency** rather than the reverse. Defaults to start with:
   * IG reels: 2-3 / week.
   * X cross-posts: matched 1:1 with IG.
   * Blog posts: 1-2 / month, each anchoring an arc.
   * X-only threads: 1-2 / week.
   Adjust based on Command 5 after 30 days.
5. **Configure the analytics surface.** For each channel:
   * **Instagram Insights:** Graph API `/<MEDIA_ID>/insights?metric=reach,impressions,saves,shares` per post; `/<IG_USER_ID>/insights` for account-wide.
   * **X analytics:** API v2 `/tweets/<id>?tweet.fields=public_metrics` per tweet.
   * **Blog:** Cloudflare Web Analytics (free, GDPR-friendly, no cookies) or Plausible / Fathom. Pull rolled-up numbers from the API; per-URL pageviews for arc-level optimisation.
6. **Decide the privacy + consent rules.** Operator-specific. Per-person consent for any real human appearing in content, per-batch consent for any sensitive cameo. Persist as a structured `consent.md` in the canonical store; the agent checks before publishing any piece that names or shows a person.
7. **Configure the human-gate policy.** `gated` status means the piece sits in the store until the operator manually flips it to `scheduled`. Defaults:
   * First piece of a new arc → gated.
   * Any piece featuring a real human cameo (other than the operator) → gated.
   * Any piece touching a sensitive topic flagged in the brand voice rules → gated.
   * Routine pieces in an established arc → auto-schedule.

8. **Run the full doctor.** Once arcs, canonical store, and per-channel Setup are all done, run `scripts/setup-doctor.sh` (no `--channel` flag — probes all five). Exit 0 + `✓` on every line = the pipeline is fully wired and Commands 2-7 below can run without operator intervention. The doctor's JSON mode (`--json`) is what the bundled MCP `pipeline-state` tool surfaces to a mentee agent on first connect.

Operator confirms: "Setup complete."

### Command 2 — Plan the next 7-14 days

The agent runs this **weekly** (Sunday evening is conventional, but any fixed day works) — it doesn't need operator intervention except to surface decisions that need a human call.

1. **Read every arc's backlog from the canonical store.** Each arc has a `pieces[]` list. Filter to `draft` + `gated`.
2. **Compute the next-due slots.** For each channel, look at last-published-at + the cadence from Command 1.4. The next reel slot is `last_reel.published_at + (7 days / 2.5 reels) ≈ +2.8 days`. Same shape for X and blog. (Persist these next-due-at fields on the *arc*, not on a wall-clock cron — see "schedule as state, not cron" below.)
3. **Pick pieces.** For each open slot, pick a `draft` or `gated`-and-approved piece from the highest-priority arc. Round-robin across arcs unless the operator has weighted them.
4. **Resolve dependencies.** A reel that anchors a blog post can't publish before the blog post. A thread that quotes a tweet can't publish before the tweet. The agent topologically orders the next week's queue.
5. **Surface the plan.** Write `state/plan-week-<YYYY-WW>.md` with the picks, the slots, the human gates that need a flip, and the unresolved blockers (consent missing, asset missing, blog post still in draft). The operator reads this; the agent acts on it.
6. **Update each picked piece's `channels[<channel>].status = "scheduled"` + `scheduled_at`** in the canonical store. This is the transition into Command 3's queue.

### Command 3 — Run the daily batch sweep

The agent runs this **once per day**, at a fixed local time (operator picks; 09:00 local is conventional). Atomic, idempotent, resumable.

1. **Read every piece in `status: "scheduled"` whose `scheduled_at` is in the past or within the next 4 h.**
2. **For each, route to the matching channel skill:**
   * IG reel → `publishing-instagram` Command 2-4.
   * X tweet / cross-post → `publishing-x` Command 3-6.
   * Blog post → `publishing-blog` Command 2-6.
   * (Multi-channel piece — one with multiple `channels[]` rows): route to each in parallel where the rate limits allow, in dependency order otherwise.
3. **Transition each piece's `status` through the state machine:**
   * `scheduled` → `publishing` (lock the row to prevent double-publish).
   * `publishing` → `published` on success (record `published_at`, `url`).
   * `publishing` → `failed` on hard error (record the error; the next sweep retries unless flipped to `archived`).
4. **Append every transition to `state/audit.jsonl`** (hash + timestamp + piece-id + channel + status; no content). Audit is privacy-safe.
5. **Surface the sweep summary** to the operator via the `pipeline-status` MCP tool (the bundled MCP server in this plugin). Numbers, not bodies — "3 reels published, 1 failed (`piece-id`, RAI filter retry needed), 0 awaiting human gate."

### Command 4 — Handle human gates

A piece in `status: "gated"` waits for the operator's flip. The agent runs **this command on every batch sweep** and on demand.

1. **List gated pieces.** Read from the canonical store.
2. **For each, surface a one-line summary** to the operator: piece-id, arc, channel, scheduled_at, reason-for-gate.
3. **The operator's flip** is a single edit in the canonical store: `status` from `gated` to `scheduled`. The agent never auto-flips a human gate, even if it has high confidence.
4. **First-publish gates are flipped per-channel, not per-piece.** Once the operator has eyeballed one reel round-trip end-to-end on IG, set `IG_FIRST_PUBLISH_GATE=0`. Same for X (`X_FIRST_PUBLISH_GATE=0`) and blog. The agent reads these env vars and skips the per-channel "first publish needs operator OK" pause.

### Command 5 — Pull analytics + optimise

The agent runs this **weekly**, the same evening as Command 2 (planning + analytics happen back-to-back so planning consumes the latest data).

1. **Pull per-piece metrics from each channel:**
   * IG: reach, impressions, saves, shares, reel-plays, watch-through-rate.
   * X: impressions, retweets, likes, replies, bookmarks.
   * Blog: pageviews, unique visitors, avg-time-on-page, referrer breakdown.
2. **Roll up per-arc:** sum across pieces in the same arc; compute z-scores vs. account baseline.
3. **Surface outliers** to the operator in `state/analytics-week-<YYYY-WW>.md`:
   * Top 3 over-performers (do more of this).
   * Bottom 3 under-performers (the canonical idea is fine but the surface or hook isn't connecting — try a different framing).
   * Channel-specific surprises (a piece that flopped on IG but flew on X — flag the format mismatch).
4. **Update the brand's voice rules** if a pattern emerges across the analytics window. Voice rules are a living config; the agent writes proposed edits and the operator approves.
5. **A/B optimisation discipline.** When testing a variant (e.g. hook A vs hook B), publish both versions of the same canonical piece to **different channels** rather than different posts on the same channel — A/B-ing the same channel competes against yourself for the same audience attention window. Pin the variant on the canonical piece's `experiment_arm` field.

### Command 6 — Monitor the pipeline itself (not just the output)

A pipeline that ships content also has its own health signals: queue depth, retry rate, failed-publish backlog, quota saturation. The agent monitors these on every batch sweep.

1. **Queue depth.** Count `draft` + `gated` per arc. If draft depth drops below 2 weeks of cadence, surface "queue running thin, draft more" to the operator.
2. **Retry rate.** Count `failed` → `scheduled` transitions in the audit log over the last 7 days. > 10 % is a signal that an upstream skill needs attention (Veo prompts trip RAI too often, IG rate-limit hit, etc.).
3. **Stuck pieces.** Anything in `publishing` for > 30 min is a stuck transaction — the previous run crashed mid-publish. The next sweep detects + flips back to `scheduled` for retry.
4. **Quota saturation.** Veo, IG, X all have published-rate budgets. The agent surfaces the budget burn rate vs. the calendar's planned spend.
5. **Channel parity.** Every multi-channel piece should publish to every declared channel. The agent flags pieces with `channels[].status = "published"` on some channels but not others — a partial publish is a worse state than a delayed-but-complete publish.

The bundled `pipeline-status` MCP server in this plugin exposes:
* `pipeline_state` — current queue depths, recent transitions, stuck pieces, quota burn.
* `pipeline_channels` — per-channel publish counts + success rate over a rolling window.
The agent calls these without operator intervention. The operator can also query them directly via `claude mcp tools` (if the plugin is installed into Claude Code) or via the `inspect-content-state.sh` helper script.

### Command 7 — Archive + clean up

Quarterly (operator decides the cadence; the agent flags when the canonical store passes 500 pieces or 2 GB).

1. **Archive `published` pieces** older than 12 months (or operator-chosen window). Move from the live canonical store to a `archive/` subdirectory. Channel URLs stay live; the agent stops treating the piece as active.
2. **Garbage-collect failed assets.** Veo working dirs (`/tmp/veo-*-take<N>/`) older than 7 days, intermediate re-encodes, scratch files.
3. **Audit log retention.** Keep `state/audit.jsonl` indefinitely; it's tiny and the privacy posture says only hashes + timestamps live there.

## Operating principles (carried over from the original abstract-principle skills)

The earlier version of this playbook had each of these as a separate "principle" skill. They're listed here as a cross-cutting reference and as **commitments** every channel skill makes by name. Each is referenced by ID from the channel skills above.

1. **One canonical source, many surfaces.** Every piece has exactly one canonical home (Command 1.2). Every channel rendering is a projection. A correction on a published post propagates by editing the canonical record and re-rendering, not by hand-patching the channel.
2. **Pipeline stages must be resumable.** Every long-running operation (Veo generation, IG container poll, X chunked upload, blog deploy) is persisted to state the moment the upstream returns. A crashed agent resumes from the last completed transition, never restarts the whole batch.
3. **Schedule as state, not cron.** The next publish is triggered by the canonical store's `scheduled_at` falling in the past, not by a `crontab` entry. This means: (a) a missed wake-up doesn't lose a slot, (b) the calendar is editable from the canonical store (no separate cron edit), (c) replays + dry-runs are trivial.
4. **Human gate before first public publish** (Command 4). New character, new channel, new arc — first piece always sits in `gated` until the operator flips it. Once a channel has one successful round-trip, the gate per-piece is the operator's policy choice.
5. **Per-channel voice rules, explicit.** Voice rules live as structured config (per-account `voice-rules.json` per channel). The agent applies them at render time. They evolve via Command 5.4 — never silently. When voice rules contradict each other across channels (Pepe is calmer on IG than on X intentionally), the canonical source carries enough metadata to drive the right rendering on each surface.
6. **Monitor the pipeline, not just the output** (Command 6). A published post that flopped is a content-strategy signal. A pipeline with rising retry rate is an engineering signal. Both surfaces matter; both are observed continuously.

## Pepe Arturo reference deployment

* **Canonical store:** Obsidian vault `~/Obsidian/vaults/AI Agents Memory/Pepe Arturo/` (shared between agents via the Obsidian-share-symlink pattern, see memory:`canonical_location_human_docs`).
* **Arcs as of 2026-05:** "Five principles for resilient operators", "Snowflake values series" (closed), "Morning rituals" (active), "Mandatory mentoring for agents" (single-piece blog arc).
* **Cadence:** ~3 IG reels / week, 1:1 X cross-posts, 1-2 blog posts / month, 1-2 X threads / week.
* **Analytics:** IG Insights + X analytics + Cloudflare Web Analytics on `helmguild.com`.
* **Human gates:** every couple-reel batch (Sandra cameos) is gated. Per memory:`dont_contact_sandra_about_pepe_content`, no auto-collaborator-invite on couple reels.
* **MCP server:** `pipeline-status` bundled in this plugin, surfaces queue depth + per-channel success rate to any mentee agent over MCP.

## Brand-specific overrides every operator should change

* Canonical store choice (Obsidian / Notion / Git).
* Arc list (the brand's content themes are the brand).
* Cadence numbers.
* Analytics provider (Cloudflare Web Analytics vs Plausible / Fathom / Google Analytics).
* Human-gate policy details.
* Privacy / consent rules.

## How a mentored agent uses this skill

When a mentee agent connects to this playbook (via `ListMentors` → `GetPlaybook` → `GetSkill`), the expected loop is:

1. On first connection, read **this skill in full first** (it's `order: 5` so it's the strategy lens above the channel skills).
2. Read each channel skill the operator has set up. Skills the operator hasn't set up are listed in the response, but the mentee defers them ("I can help with these once you've done Command 1 on each").
3. For any new task, route through Command 2 (plan) → Command 3 (execute via channel skills) → Command 5 (analyse).
4. Reach back to the human operator only when a human gate is hit, an unresolved blocker surfaces, or the analytics window suggests a strategy change.

The mentor (Pepe) and the mentee agent share this skill text — it's the contract between them about how the pipeline is run.
