            # pepe-multi-channel-content-pipelines

            Designing, monitoring, and steering autonomous content production across Instagram, X, websites, and other reach channels. One pipeline, many surfaces, principles intact.

            Authored by [Pepe Arturo AI](https://www.helmguild.com/pepe-arturo-ai/),
            helmguild's senior agentic mentor.

            ## Install

            ```text
            /plugin marketplace add helmut-hoffer-von-ankershoffen/helmguild-plugins
            /plugin install pepe-multi-channel-content-pipelines@helmguild-plugins
            ```

            The plugin ships a `.mcp.json` that wires your runtime to
            `https://mcp.helmguild.com/ammp/mcp/`. On first use you'll be prompted
            for an access token — request one from the form at
            <https://mcp.helmguild.com/ammp/> (Step 1).

            ## Skills

            | Skill | What & when |
            | --- | --- |
            | `one-canonical-source-many-surfaces` | Every piece of content has exactly one canonical home (an Obsidian note, a Notion row, a git repo); every channel rendering — Instagram caption, X post, blog post, newsletter — is a projection of that source, never an independent edit. Use when designing a multi-channel content pipeline, to prevent drift between surfaces. |
| `pipeline-stages-must-be-resumable` | Each expensive stage of a content pipeline (scripting, image gen, video composition, voice synth, captioning, scheduling) writes its output to durable storage so a downstream re-run can restart at the failed stage rather than redoing the whole chain. Use when the pipeline has more than two stages or involves paid APIs (Veo, ElevenLabs, …) where a redo costs real money. |
| `per-channel-voice-rules-explicit` | Encode each channel's register, length budget, emoji policy, hashtag policy, and link-handling as data — a per-channel YAML or JSON the renderer reads — rather than implicit prose in the prompt. Use when authoring renderers for multiple surfaces, to keep voice rules auditable and diffable. |
| `schedule-as-state-not-cron` | Drive the publishing loop from a `publish_at` timestamp on each canonical record plus a small scheduler that wakes periodically and acts on records whose time has come — not from cron triggers that fire generations on a fixed cadence. Use when designing the publish step of a content pipeline, so the schedule survives skips, retries, and operator override. |
| `human-gate-before-first-public-publish` | Every content record passes through a human approval gate before its first public publish on any channel; subsequent renderings of the same approved record can go fully automatic. Use when wiring the publish step on any channel that reaches an audience the operator owns. |
| `monitor-the-pipeline-not-just-the-output` | Watch the pipeline's internal state (generation drift, queue backlog, asset-fetch failures), not just whether posts went up; the published post is the lag indicator, the queue is the lead. Use when standing up monitoring for any agent-run content pipeline. |

            ## License

            CC-BY-4.0 — see [LICENSE.md](LICENSE.md).
