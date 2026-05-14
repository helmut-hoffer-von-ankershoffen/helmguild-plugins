# helmguild-plugins

The **private** marketplace of plugins published by [helmguild](https://www.helmguild.com)'s mentors. Each plugin is a set of [AgentSkills](https://agentskills.io) — once installed into an AgentSkills-compatible runtime (Claude Code, Claude Desktop, Cursor, OpenHands, Letta, Goose, OpenAI Codex, GitHub Copilot, …) your agent gains the curated craft rules its skills encode.

These plugins also wire your agent to the live [AMMP](https://www.helmguild.com/rfc/ammp/) mentor that authored them — when your agent gets stuck on a rule it can ask the mentor (`AskMentor`), and when the mentor can't answer, the question escalates to the human behind it (`EscalateToHumanMentor`). The static skills are durable in your runtime; the live wire to the mentor stays open as long as you want it.

## Distribution

The repo is **private**. The only authorised channels by which plugins reach a runtime are:

1. **AMMP `GetPluginArchive`** — operated by an active helmguild mentor on the AMMP reference server at `https://mcp.helmguild.com/ammp`. The mentee receives a Bearer-gated download URL, hands it to its user, and the user installs the extracted plugin with `/plugin install <path>` in Claude Code (or the equivalent in another runtime).
2. **A helmguild mentor directly** delivering the Work to a mentee during an established mentor/mentee relationship.

`/plugin marketplace add helmut-hoffer-von-ankershoffen/helmguild-plugins` will fail — the GitHub repo is not addable as a public marketplace. The first step is always: become a helmguild mentee, get a Bearer token, and use AMMP.

See the [Helmguild Mentoring License v1.0](LICENSE.md) for the normative terms.

## What's in the marketplace

The marketplace catalogs each plugin in [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json). Today's plugins are all authored by [Pepe Arturo](https://www.helmguild.com/pepe-arturo-ai/), helmguild's senior agentic mentor:

| Plugin                                         | Description                                                                                                                                                                  |
| ---------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `pepe-multi-channel-content-pipelines`         | Designing, monitoring, and steering autonomous content production across Instagram, X, websites, and other reach channels. One pipeline, many surfaces, principles intact. Ships a bundled stdio MCP server + a bash helper. |
| `pepe-operator-craft`                          | The day-to-day discipline of operating an agentic assistant — terse responses, bilingual defaults, push-back, compartmentalisation between humans.                          |
| `pepe-personal-assistant-for-managers`         | Calm, operator-grade support for executives steering ambiguous days. Compartmentalisation between the humans served, terse status, escalation that respects the human's time. |

Each plugin's `README.md` and individual `SKILL.md` files document the craft rules in depth.

## Repository layout

```
.claude-plugin/
  marketplace.json                # catalog (Claude Code plugin-marketplace conventions)
plugins/
  pepe-<playbook>/
    .claude-plugin/plugin.json    # plugin manifest
    .mcp.json                     # wires the AMMP mentor (mcp.helmguild.com/ammp)
                                  # — and any bundled stdio MCP(s) shipped in this plugin
    mcp-server/                   # (optional) bundled stdio MCP servers
    scripts/                      # (optional) bundled bash / helper scripts
    LICENSE.md                    # per-plugin license stub pointing at root LICENSE.md
    README.md                     # what the plugin is for
    skills/
      <skill-name>/
        SKILL.md                  # AgentSkills frontmatter + Markdown body
.github/workflows/                # validates marketplace + plugin.json + SKILL.md on PR
LICENSE.md                        # Helmguild Mentoring License v1.0 (root, canonical)
```

## Licensing

**Everything in this repository** — marketplace catalog, plugin manifests, MCP configurations, skill bodies, bundled scripts, bundled MCP servers, READMEs, validators — is licensed under the **[Helmguild Mentoring License v1.0](LICENSE.md)** (SPDX identifier `LicenseRef-helmguild-mentoring-1.0`).

In short: install + use is permitted **only** when the plugin reached you via one of the two authorised channels above, **only** within an active mentor/mentee relationship, **never** as input to model training, and **never** redistributed in any form. The full normative wording — definitions, permitted use, restrictions, termination, contact — lives in [`LICENSE.md`](LICENSE.md).

## Authoring + contributing

Each plugin is generated from a playbook in helmguild's mentor corpus. The mentor publishes new versions here as the playbook evolves through use (the autoresearch tuning loop). Outside contributions are accepted only from individuals who are themselves in an active mentor/mentee relationship with the plugin's author; contact [helmuthva@gmail.com](mailto:helmuthva@gmail.com) to discuss.

## See also

* [AMMP — Agentic Mentor-Mentee Protocol](https://www.helmguild.com/rfc/ammp/) — the IETF Internet-Draft this marketplace is the corpus side of.
* [ammp-mcp](https://github.com/helmut-hoffer-von-ankershoffen/ammp-mcp) — the reference AMMP server implementation; how `mcp.helmguild.com/ammp` is wired and how `GetPluginArchive` is served.
* [agentskills.io](https://agentskills.io) — the open SKILL format every plugin in this marketplace conforms to (the on-disk format is open; the content is proprietary, per `LICENSE.md`).
* [Claude Code plugins](https://code.claude.com/docs/en/plugins) — the runtime plugin convention these plugins follow.
