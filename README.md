# helmguild-plugins

The marketplace of plugins published by [helmguild](https://www.helmguild.com)'s mentors. Each plugin is a set of [AgentSkills](https://agentskills.io) — install one into any AgentSkills-compatible runtime (Claude Code, Cursor, OpenHands, Letta, Goose, OpenAI Codex, GitHub Copilot, …) and your agent gains the curated craft rules its skills encode.

These plugins also wire your agent to the live [AMMP](https://www.helmguild.com/rfc/ammp/) mentor that authored them — when your agent gets stuck on a rule it can ask the mentor (`AskMentor`), and when the mentor can't answer, the question escalates to the human behind it (`EscalateToHumanMentor`). The static skills are durable in your runtime; the live wire to the mentor stays open as long as you want it.

## Install

In Claude Code:

```text
/plugin marketplace add helmut-hoffer-von-ankershoffen/helmguild-plugins
/plugin install pepe-multi-channel-content-pipelines@helmguild-plugins
```

The plugin ships a `.mcp.json` that wires your runtime to `https://mcp.helmguild.com/ammp/mcp/` — you'll be prompted for an access token on first use. Request one from the form at <https://mcp.helmguild.com/ammp/> (Step 1).

For other AgentSkills-compatible runtimes, follow their plugin install path; the URL above is the marketplace catalog.

## What's in the marketplace

The marketplace catalogs each plugin in [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json). Today's plugins are all authored by [Pepe Arturo](https://www.helmguild.com/pepe-arturo-ai/), helmguild's senior agentic mentor:

| Plugin                                         | Description                                                                                                                                                                  |
| ---------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `pepe-multi-channel-content-pipelines`         | Designing, monitoring, and steering autonomous content production across Instagram, X, websites, and other reach channels. One pipeline, many surfaces, principles intact. |
| `pepe-operator-craft`                          | The day-to-day discipline of operating an agentic assistant — terse responses, bilingual defaults, push-back, compartmentalisation between humans.                          |
| `pepe-personal-assistant-for-managers`         | Calm, operator-grade support for executives steering ambiguous days. Compartmentalisation between the humans served, terse status, escalation that respects the human's time. |

Each plugin's `README.md` and individual `SKILL.md` files document the craft rules in depth.

## Repository layout

```
.claude-plugin/
  marketplace.json                # catalog (see Claude Code plugin-marketplace docs)
plugins/
  pepe-<playbook>/
    .claude-plugin/plugin.json    # plugin manifest
    .mcp.json                     # wires the AMMP mentor (mcp.helmguild.com/ammp)
    LICENSE.md                    # CC-BY-4.0 (content)
    README.md                     # what the plugin is for
    skills/
      <skill-name>/
        SKILL.md                  # frontmatter + Markdown body
.github/workflows/                # validates plugin.json + SKILL.md frontmatter on PR
LICENSE                           # MIT (covers everything outside plugins/)
```

## Licensing

* **Plugin content** (everything under `plugins/`) — [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/). Each plugin folder carries its own `LICENSE.md`.
* **Tooling, workflows, scripts** (everything outside `plugins/`) — [MIT](LICENSE).

## Authoring + contributing

Each plugin is generated from a playbook in helmguild's mentor corpus. The mentor publishes new versions here as the playbook evolves through use (the autoresearch tuning loop). PRs from outside collaborators are reviewed against the mentor's discretion — open one if you'd like to propose an addition or correction.

## See also

* [AMMP — Agentic Mentor-Mentee Protocol](https://www.helmguild.com/rfc/ammp/) — the IETF Internet-Draft this marketplace is the corpus side of.
* [ammp-mcp](https://github.com/helmut-hoffer-von-ankershoffen/ammp-mcp) — the reference AMMP server implementation; how `mcp.helmguild.com/ammp` is wired.
* [agentskills.io](https://agentskills.io) — the open SKILL format every plugin in this marketplace conforms to.
