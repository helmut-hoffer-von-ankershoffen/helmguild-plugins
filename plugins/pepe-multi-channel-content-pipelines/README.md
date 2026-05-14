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

The playbook is five skills: four channel-specific (generation + each publishing surface), plus one cross-cutting strategy skill that ties them together. Read **`content-strategy-planning-optimization`** first — it's the lens above the channel skills. Each skill has multiple commands, the first of which is **Setup (operator)** — the agent walks the human through accounts, keys, and env vars one step at a time.

| Skill | What & when |
| --- | --- |
| `virtual-character-veo-3-1` | Generate consistent virtual characters (face, outfit, voice, pose) as 8-second 9:16 video clips with native voiceover and lip-sync using Google's Veo 3.1 via the Gemini API. Operator setup covers Google AI Studio account, preview-model enrollment, API key, and quota. Then: reference-image preparation, prompt structure for character consistency, voiceover prompting, RAI-filter handling, batch + quota management, output validation. The foundation skill — downstream publishing skills consume its output. |
| `publishing-instagram` | Publish reels, Stories, image/carousel posts to Instagram via the Meta Graph API. Operator setup covers IG Professional account, Meta Business + linked Facebook Page, Meta App with `instagram_content_publish` permission, long-lived page access token, and public upload bucket. Then: post reels with collaborator invites + Story mirror, caption lint under per-account voice rules, rate-limit handling, post-publish verification, recovery of skipped Stories within the 24 h window. |
| `publishing-x` | Publish posts, threads, replies, and reposted reels to X via API v2. Operator setup covers X Developer Platform account, project + app, OAuth 2.0 with PKCE flow + refresh-token persistence, paid Basic tier ($100/mo). Then: text + media tweets (chunked upload for videos), thread chaining, cross-posting from Instagram reels (140 s video cap, X-tuned captions), reply etiquette, rate-limit handling. |
| `publishing-blog` | Publish long-form blog posts to a static-site brand domain via Git + Cloudflare Pages (or any CDN-deployed alternative). Operator setup covers domain registration, DNS, GitHub repo, framework choice, Cloudflare Pages project, custom domain, preview deployments. Then: author posts in localised pairs from a canonical source, sitemap.xml + Atom feed maintenance, CSS cache-bust discipline, preview-before-publish, cross-link from upstream channels, deploy-failure recovery. |
| `content-strategy-planning-optimization` | The cross-channel strategy + planning layer. Operator setup defines arcs, canonical content store (Obsidian / Notion / Git), schema, editorial cadence, analytics surface, privacy + consent rules, human-gate policy. Then: weekly planning sweep, daily batch publish, human-gate handling, analytics + optimisation, monitor the pipeline itself (queue depth, retry rate, stuck pieces, quota saturation), quarterly archive. Folds in the original "one canonical source", "resumable stages", "schedule as state", "human gate", "voice rules", "monitor the pipeline" principles as commitments every channel skill makes by name. |

## Bundled assets

The plugin ships:

* **MCP server** (`mcp-server/pipeline-status.mjs`) — exposes two tools: `pipeline_state` (current queue depths, recent transitions, stuck pieces, quota burn) and `pipeline_channels` (per-channel publish counts + success rate over a rolling window). Wired into the plugin's `.mcp.json`.
* **Scripts** (`scripts/`) — operator-runnable helpers:
  * `inspect-content-state.sh` — read-only dump of `$PEPE_PIPELINE_STATE_DIR` (queue + audit log).
  * `instagram-caption-lint.sh` — caption linter (length, hook, hashtag count, emoji signature, banned phrases).
  * `veo-prompt-skeleton.sh` — render a Veo 3.1 prompt skeleton from a one-line brief.
* **Tests** (`tests/`) — `node --test` for the MCP server, `bash`-based test harness for every script. Run with `bash tests/run-all.sh` (or via the marketplace's `validate.yml` CI job).

## Operator setup checklist (in order)

The most efficient first-time setup goes channel-by-channel rather than skill-by-skill:

1. `virtual-character-veo-3-1` Command 1 — Google AI Studio + Veo preview + API key.
2. `publishing-instagram` Command 1 — Meta Business + IG Professional + Page + App + page access token.
3. `publishing-x` Command 1 — X Developer Platform + paid Basic tier + OAuth 2.0 flow.
4. `publishing-blog` Command 1 — domain + repo + Cloudflare Pages + custom domain.
5. `content-strategy-planning-optimization` Command 1 — arcs + canonical store + schema + cadence + analytics + consent + gate policy.

Plan for ~2-3 h of operator time on first run; ~0 thereafter.

## License

LicenseRef-helmguild-mentoring-1.0 (Helmguild Mentoring License v1.0) — see [LICENSE.md](LICENSE.md). The plugin is distributed only via the private `helmguild-plugins` marketplace and `GetPluginArchive` MCP tool brokered by `mcp.helmguild.com/ammp`.
