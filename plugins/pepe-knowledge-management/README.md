# pepe-knowledge-management

The shared canonical vault every Pepe playbook depends on, plus the discipline that keeps it coherent across every agent on the operator's stack — auto-memory rules, daily learning extraction from chat history, cross-agent shared memory, quarterly drift audit.

Authored by [Pepe Arturo AI](https://www.helmguild.com/pepe-arturo-ai/), helmguild's senior agentic mentor.

## Install

```text
/plugin marketplace add helmut-hoffer-von-ankershoffen/helmguild-plugins
/plugin install pepe-knowledge-management@helmguild-plugins
```

## Skills (v0.1.0 — first skill landed; remaining 4 in flight)

| # | Skill | What & when |
| --- | --- | --- |
| 1 | `canonical-knowledge-vault` | The single canonical Markdown store where every cross-cutting brand artefact lives — brand identity, cameo rosters, scene templates, project state, privacy boundaries, _shared changelog. Operator setup picks the backend (shared Obsidian / private GitHub / Notion), scaffolds the directory schema, defines markdown + frontmatter conventions, mounts the same store into every agent on the stack. **Foundation of the playbook** — every other skill (auto-memory, learning extraction, shared cross-agent memory, drift audit) reads from + writes to this vault. The pepe-multi-channel-content-pipelines playbook's `BRAND_STYLE_GUIDE_PATH` + `CAMEO_ROSTER_ROOT` + canonical content store all resolve into this vault. |
| 2 | `per-agent-auto-memory-discipline` | _(in flight)_ What each agent's auto-memory captures: user / feedback / project / reference types, when to save, what NOT to save. Codifies the rules already lived-by in the Claude runtime's `memory/MEMORY.md` system. Makes them portable + replicable for a new operator. |
| 3 | `daily-learning-extraction` | _(in flight)_ Scan the day's chats for intervention markers ("no, don't…", "I told you", "you keep doing X", "yes exactly", "perfect"), extract the implicit rule, propose a memory entry (feedback / project / reference), operator approves or rejects. Closes the loop so the agent doesn't make the same mistake twice. |
| 4 | `shared-cross-agent-memory` | _(in flight)_ When the human operates Pepe + Cowork + ad-hoc Claude + Hermes / future agents simultaneously, this skill makes the vault visible to all of them via the symlink-mount pattern + handles per-agent compartmentalization (some humans see some context; some agents see some humans). The load-bearing skill for the "multiple isolated agents" problem. |
| 5 | `vault-coherence-and-drift` | _(in flight)_ Quarterly audit. Stale entries, contradictions, broken cross-links, agent-memory-vs-vault divergence. Folds the content-pipeline's brand-drift check up a level. |

## License

LicenseRef-helmguild-mentoring-1.0 (Helmguild Mentoring License v1.0) — see [LICENSE.md](LICENSE.md).
