# AGENTS.md — `helmguild-plugins`

Operator guide for AI agents (and humans) editing this marketplace. Match the project's tone: terse, factual, no decoration.

## What this is

The **private** marketplace of plugins that helmguild's mentors publish for their mentees. Each plugin is one playbook from a mentor's corpus, rendered as a Claude-Code plugin: skills + optional bundled MCP servers + optional bundled scripts + an `.mcp.json` wiring the live mentor on AMMP.

The plugins themselves never leave this repo + the `mcp.helmguild.com/ammp` server. Mentees install through AMMP `GetPluginArchive` — they receive a Bearer-gated zip URL, download it, and the user runs `/plugin install <extracted>` in their runtime. **Do not** publish anywhere else.

This marketplace is the **commercial** side. The validator enforces `metadata.commercial: true` + `metadata.distribution: "private"` on `marketplace.json`, plus `"commercial": true` on every `plugin.json` and every marketplace plugin entry. Community-licensed (non-commercial) plugins go in the sibling [`helmguild-plugins-public`](https://github.com/helmut-hoffer-von-ankershoffen/helmguild-plugins-public) repo, which mirrors the same shape but enforces `commercial: false` + OSI-approved licenses.

- Marketplace catalogue: `.claude-plugin/marketplace.json`
- License (everything): `LicenseRef-helmguild-mentoring-1.0` — see [`LICENSE.md`](LICENSE.md).
- Reference AMMP server: <https://github.com/helmut-hoffer-von-ankershoffen/ammp-mcp>
- Live deployment: <https://mcp.helmguild.com/ammp>

## Repository layout

```
helmguild-plugins/
├── LICENSE.md                       # Helmguild Mentoring License v1.0 (root, canonical)
├── README.md                        # Reader-facing — distribution policy + plugin catalogue
├── .claude-plugin/
│   └── marketplace.json             # Marketplace manifest (Claude-Code spec)
├── .github/
│   ├── workflows/validate.yml       # CI — runs validate.py on push/PR
│   └── scripts/validate.py          # Enforces shape + license on every push
└── plugins/
    └── <mentor>-<playbook>/
        ├── .claude-plugin/
        │   └── plugin.json          # name, description, version, license, …
        ├── .mcp.json                # AMMP HTTP server + optional bundled stdio MCP(s)
        ├── mcp-server/              # (optional) bundled stdio MCP scripts
        ├── scripts/                 # (optional) bundled bash / helper scripts
        ├── skills/
        │   └── <id>/SKILL.md        # AgentSkills frontmatter + Markdown body
        ├── LICENSE.md               # short stub pointing at root LICENSE.md
        └── README.md                # plugin overview
```

## The invariants the validator enforces

`.github/scripts/validate.py` runs on every push / PR and exits non-zero on any of:

1. `.claude-plugin/marketplace.json` is missing, doesn't parse, or references a plugin folder that doesn't exist.
2. A plugin under `plugins/<name>/` is missing `.claude-plugin/plugin.json`, or its `name` doesn't match the folder name, or its `version` is absent.
3. **`plugin.json.license` is not `LicenseRef-helmguild-mentoring-1.0`.**
4. **A `SKILL.md`'s frontmatter `license:` is not `LicenseRef-helmguild-mentoring-1.0`.**
5. A plugin folder is missing `LICENSE.md`.
6. A `SKILL.md` has invalid frontmatter (missing `name`, wrong `name`, missing/oversize `description`, duplicate `metadata.order` within the same plugin).
7. A plugin's `.mcp.json` exists but doesn't parse.
8. **A bundled script under `scripts/` or `mcp-server/` is missing a matching test at `tests/test-<dir>-<stem>.{sh,mjs}`, or the test isn't executable.** Scripts ship with proof they work; the test-bundled-scripts CI job actually runs them on every push.

Run locally before pushing: `python3 .github/scripts/validate.py`.

## Tests for bundled scripts (required)

**Every script bundled in a plugin ships with a test.** No exceptions. The test lives at:

```
plugins/<plugin>/tests/test-<source-dir>-<stem>.<ext>
```

| Bundled artefact                                      | Test file                                              | Runner       |
| ----------------------------------------------------- | ------------------------------------------------------ | ------------ |
| `plugins/<p>/scripts/foo.sh`                          | `plugins/<p>/tests/test-scripts-foo.sh`                | `bash`       |
| `plugins/<p>/mcp-server/foo.mjs`                      | `plugins/<p>/tests/test-mcp-server-foo.mjs`            | `node --test` |

Pattern for the `.mjs` tests: spawn the MCP over stdin/stdout, run the JSON-RPC handshake (`initialize` → `notifications/initialized` → `tools/list` → `tools/call`), assert response shapes. Pure Node stdlib + `node:test`; zero dependencies. See `plugins/pepe-multi-channel-content-pipelines/tests/test-mcp-server-pipeline-status.mjs` for the reference.

Pattern for the `.sh` tests: `set -euo pipefail`, run the helper with crafted env / args under `mktemp -d`, assert exit codes + grep stdout. See `plugins/pepe-multi-channel-content-pipelines/tests/test-scripts-inspect-content-state.sh`.

The CI workflow runs every `tests/*.{mjs,sh}` on every push and fails on any non-zero exit. The validator also asserts the test files exist + are executable, so a "scripts but no tests" PR fails fast even before the test runner spins up.

Run locally before pushing:

```sh
# from the plugin root
node --test tests/test-mcp-server-pipeline-status.mjs
bash tests/test-scripts-inspect-content-state.sh
```

## Editing a skill

```
plugins/<mentor>-<playbook>/skills/<skill-id>/SKILL.md
```

Frontmatter shape:

```yaml
---
name: <skill-id>                                  # must match folder name
description: "<≤1024-char one-line description>"  # surfaced by ListPlaybooks
license: LicenseRef-helmguild-mentoring-1.0       # required, enforced
allowed-tools:                                    # optional
  - Bash
  - mcp__<server>__<tool>
metadata:
  mentor: <mentor-slug>                           # e.g. pepe
  playbook: <playbook-id>
  order: <int>                                    # unique within the plugin
  ammp-draft: draft-ammp-01
---

# <H1 title — first line of body>

<Markdown body. ≤ a few KB ideally; the runtime loads every byte at plugin install.>
```

Add a new skill: create the `skills/<new-id>/SKILL.md` folder, increment the plugin's `version` in both `plugins/<name>/.claude-plugin/plugin.json` AND the corresponding entry in `.claude-plugin/marketplace.json` (they must agree), validate.

## Adding a bundled stdio MCP

For plugins that need to ship an MCP server beyond the AMMP wire (see `pepe-multi-channel-content-pipelines` for the reference pattern):

1. Drop the executable into `plugins/<name>/mcp-server/<server>.mjs` (or any language; Node is preferred for zero-dep portability). Pure stdlib; no `npm install` step on the mentee side.
2. Register it in `plugins/<name>/.mcp.json` next to the existing `helmguild-ammp` entry:

   ```json
   {
     "mcpServers": {
       "helmguild-ammp": { "type": "http", "...": "..." },
       "<server-name>": {
         "type": "stdio",
         "command": "node",
         "args": ["${CLAUDE_PLUGIN_ROOT}/mcp-server/<server>.mjs"],
         "env": {}
       }
     }
   }
   ```
3. `chmod +x` the file. The zip route preserves the bit (regression-tested in `ammp-mcp`).
4. Reference the bundled MCP's tools in the relevant SKILL.md `allowed-tools` (`mcp__<server-name>__<tool-name>`).

## Adding a bundled script

Same pattern — drop into `plugins/<name>/scripts/<helper>.sh`, mark executable, reference from a SKILL.md via `allowed-tools: ["Bash"]`. Read-only / no-credentials helpers only; anything that needs secrets must read them from env at runtime.

## Bumping a version

A `version` bump is a contract change. When changing skills bodies, adding a new skill, or adding a bundled artefact:

- Increment `plugin.json.version` (SemVer).
- Mirror the bump in the matching entry of `.claude-plugin/marketplace.json`.
- Validator fails if the two disagree.
- **Breaking license change → major bump.** (We did 0.2.0 → 1.0.0 when CC-BY → Helmguild Mentoring.)

## Distribution rules (re-statement of the License)

Per [`LICENSE.md`](LICENSE.md), §1:

- **OK:** AMMP `GetPluginArchive` on `mcp.helmguild.com/ammp` (Bearer-gated) delivers the plugin to a mentee inside an active engagement.
- **OK:** A helmguild mentor hands a plugin zip directly to a mentee they have an engagement with.
- **Not OK:** Anywhere else. Don't add it to a public marketplace, mirror, registry, archive, gist, paste, or blog post. Don't paste skill bodies into model-training corpora.

## Live verification

After pushing a plugin update + rolling the marketplace clone on the deployed AMMP server:

```sh
# Pull the marketplace clone the server reads
git -C ~/.ammp/marketplaces/helmguild-plugins pull --ff-only

# (No server restart needed — load_playbooks reads marketplaces_root per request.)

# Smoke-test from the mentee side
ammp-mcp/scripts/e2e-claude-code-install.sh   # in the ammp-mcp repo
# or
PLUGIN=<plugin-name> HELMGUILD_AMMP_BEARER=ammp-… \
  ammp-mcp/scripts/e2e-claude-code-install.sh
```

The script downloads the live zip via the auth-gated route, runs `claude plugin validate`, wraps the plugin in a throw-away local marketplace, installs it under `--scope local`, asserts the install landed in `.claude/settings.local.json`, and tears down. Trap-cleanup is on so a failed mid-run doesn't leave debris.

## See also

- [`ammp-mcp` AGENTS.md](https://github.com/helmut-hoffer-von-ankershoffen/ammp-mcp/blob/main/AGENTS.md) — operator guide for the server side.
- [AMMP draft-ammp-01](https://www.helmguild.com/rfc/ammp/) — the protocol this marketplace is the corpus side of.
- [agentskills.io](https://agentskills.io/home) — SKILL.md format spec.
- [Claude Code plugin docs](https://code.claude.com/docs/en/plugins) — plugin runtime spec.
- [Claude Code marketplace docs](https://code.claude.com/docs/en/plugin-marketplaces) — marketplace catalogue spec.
