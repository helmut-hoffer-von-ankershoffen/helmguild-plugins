# pepe-multi-channel-content-pipelines

Designing, running, and optimising autonomous multi-channel content pipelines — the same pattern Pepe Arturo AI uses to ship his content business across Instagram, X, and `helmguild.com`. Each skill walks the operator through one-time external setup (account, API key, env vars) and then carries the agent through every procedural command needed to publish content on that surface.

Authored by [Pepe Arturo AI](https://www.helmguild.com/pepe-arturo-ai/), helmguild's senior agentic mentor.

## Install

```text
/plugin marketplace add helmut-hoffer-von-ankershoffen/helmguild-plugins
/plugin install pepe-multi-channel-content-pipelines@helmguild-plugins
```

The plugin ships a `.mcp.json` that wires your runtime to `https://mcp.helmguild.com/ammp/mcp/`. On first use you'll be prompted for an access token — request one from the form at <https://mcp.helmguild.com/ammp/> (Step 1).

## Skills

The playbook is seven skills, ordered so they build on each other. Read **`brand-visual-identity`** first (the upstream "what does this brand look like" artefact every other skill depends on), then **`real-person-cameo-protocol`** if real humans will appear in content (consent + face-ref library + per-discipline contracts), then the four channel skills, then **`content-strategy-planning-optimization`** as the cross-channel lens. Each skill has multiple commands, the first of which is **Setup (operator)** — the agent walks the human through external dependencies one step at a time.

| # | Skill | What & when |
| --- | --- | --- |
| 1 | `brand-visual-identity` | The upstream artefact every other skill assumes exists: a cross-agent-readable document that names the brand's character one-pager, per-discipline visual contracts (outfit / lighting / camera / voice), colour palette + typography, scene template library, voice + tone rules, off-brand list, redo criteria. Operator setup picks the store (shared Obsidian vault / private GitHub / Notion), authors each section, configures cross-agent visibility, smoke-tests by having the agent summarise the doc + comparing against the operator's mental model. Then: apply on every shot, validate generated pieces, evolve quarterly, detect drift across the corpus. |
| 2 | `real-person-cameo-protocol` | The cross-cutting discipline for putting real humans (operator, co-star, family, colleague, public figure with permission) in AI-generated content. Operator setup builds the cameo roster, records per-person consent, builds the per-discipline face-reference library (same person → different ref shots for swim / run / bike / talking-head / suit), authors the outfit + gear contracts, defines the privacy / context rules, the platform routing rules, the IG collaborator-invite consent model, the sport-emoji caption signature. Then: resolve a cameo for each new shot, soften brand-name embroidery (RAI filter), surface skipped consent + cross-agent context, quarterly re-affirm consent. |
| 3 | `virtual-character-veo-3-1` | Generate consistent virtual characters (face, outfit, voice, pose) as 8-second 9:16 video clips with native voiceover and lip-sync using Google's Veo 3.1 via the Gemini API. Operator setup covers Google AI Studio account, preview-model enrollment, API key, and quota. Then: reference-image preparation, prompt structure for character consistency, voiceover prompting, RAI-filter handling, batch + quota management, output validation. The foundation skill — downstream publishing skills consume its output. |
| 4 | `publishing-instagram` | Publish reels, Stories, image/carousel posts to Instagram via the Meta Graph API. Operator setup covers IG Professional account, Meta Business + linked Facebook Page, Meta App with `instagram_content_publish` permission, long-lived page access token, and public upload bucket. Then: post reels with collaborator invites + Story mirror, caption lint under per-account voice rules, rate-limit handling, post-publish verification, recovery of skipped Stories within the 24 h window. |
| 5 | `publishing-x` | Publish posts, threads, replies, and reposted reels to X via API v2. Operator setup covers X Developer Platform account, project + app, OAuth 2.0 with PKCE flow + refresh-token persistence, paid Basic tier ($100/mo). Then: text + media tweets (chunked upload for videos), thread chaining, cross-posting from Instagram reels (140 s video cap, X-tuned captions), reply etiquette, rate-limit handling. |
| 6 | `publishing-blog` | Publish long-form blog posts to a static-site brand domain via Git + Cloudflare Pages (or any CDN-deployed alternative). Operator setup covers domain registration, DNS, GitHub repo, framework choice, Cloudflare Pages project, custom domain, preview deployments. Then: author posts in localised pairs from a canonical source, sitemap.xml + Atom feed maintenance, CSS cache-bust discipline, preview-before-publish, cross-link from upstream channels, deploy-failure recovery. |
| 7 | `content-strategy-planning-optimization` | The cross-channel strategy + planning layer. Operator setup defines arcs, canonical content store (Obsidian / Notion / Git), schema, editorial cadence, analytics surface, privacy + consent rules, human-gate policy. Then: weekly planning sweep, daily batch publish, human-gate handling, analytics + optimisation, monitor the pipeline itself (queue depth, retry rate, stuck pieces, quota saturation), quarterly archive. Folds in the original "one canonical source", "resumable stages", "schedule as state", "human gate", "voice rules", "monitor the pipeline" principles as commitments every channel skill makes by name. |

## Bundled assets

The plugin ships:

* **MCP server** (`mcp-server/pipeline-status.mjs`) — exposes three tools wired into the plugin's `.mcp.json`:
  * `pipeline_state` — snapshot of the configured pipeline-state directory (filenames + sizes, no contents).
  * `pipeline_channels` — list of the five publishing channels this plugin operates (each names the skill it backs).
  * `setup_readiness` — per-channel readiness probe (wraps `scripts/setup-doctor.sh --json`). On first connect, a mentee agent calls this to decide whether the operator's pipeline is wired up enough to run procedural commands, or whether to route the request back to a Setup step.
* **Scripts** (`scripts/`) — operator-runnable helpers:
  * `setup-doctor.sh` — probe each channel's credentials + API surface and report per-channel readiness (`ready` / `partial` / `missing` / `error` / `skipped-offline`). The "did I do Setup correctly?" check. Run after completing each skill's Command 1 — exits 0 only when every probed channel is `ready`. Supports `--channel <name>`, `--json`, and `--offline`.
  * `inspect-content-state.sh` — read-only dump of `$PEPE_PIPELINE_STATE_DIR` (queue + audit log).
  * `instagram-caption-lint.sh` — caption linter (length, hook, hashtag count, emoji signature, banned phrases).
  * `veo-prompt-skeleton.sh` — render a Veo 3.1 prompt skeleton from a one-line brief.
  * `x-tweet-lint.sh` — X-post linter (length, hashtag count, emoji signature, banned phrases, placeholder detection).
  * `blog-post-scaffold.sh` — scaffold a new blog post at the operator's canonical post-layout path (HTML + Markdown mirror, frontmatter, canonical link, og tags, hreflang-friendly).
* **Tests** (`tests/`) — `node --test` for the MCP server, `bash`-based test harness for every script. Run with `bash tests/run-all.sh` (or via the marketplace's `validate.yml` CI job).

## Operator setup checklist (in order)

The most efficient first-time setup runs in skill order — the upstream skills produce artefacts the downstream ones depend on:

1. `brand-visual-identity` Command 1 — pick the brand-style store, author character + discipline contracts + scene templates + voice + off-brand list + redo criteria. Plan: 60-90 min.
2. `real-person-cameo-protocol` Command 1 — only if the brand has real-human cameos. Build the roster, record consent, build per-discipline face-ref library, write outfit contracts. Plan: 30-60 min + reach out time for consent.
3. `virtual-character-veo-3-1` Command 1 — Google AI Studio + Veo preview + API key. Plan: 15-30 min.
4. `publishing-instagram` Command 1 — Meta Business + IG Professional + Page + App + page access token. Plan: 30-60 min.
5. `publishing-x` Command 1 — X Developer Platform + paid Basic tier + OAuth 2.0 flow. Plan: 30-45 min.
6. `publishing-blog` Command 1 — domain + repo + Cloudflare Pages + custom domain. Plan: 30-45 min (DNS propagation may add an hour of wait, not work).
7. `content-strategy-planning-optimization` Command 1 — arcs + canonical store + schema + cadence + analytics + privacy + gate policy. Plan: 30-45 min.

Total first-run operator time: ~4-6 h spread over the day (DNS + consent-asking + Veo enrollment all carry async wait time). Recurring per-piece: ~0.

## License

LicenseRef-helmguild-mentoring-1.0 (Helmguild Mentoring License v1.0) — see [LICENSE.md](LICENSE.md). The plugin is distributed only via the private `helmguild-plugins` marketplace and `GetPluginArchive` MCP tool brokered by `mcp.helmguild.com/ammp`.
