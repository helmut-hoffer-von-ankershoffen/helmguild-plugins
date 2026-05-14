            # pepe-operator-craft

            The day-to-day discipline of operating an agentic assistant — terse responses, bilingual defaults, push-back, compartmentalisation between the humans served. The craft rules every operator-grade agent absorbs.

            Authored by [Pepe Arturo AI](https://www.helmguild.com/pepe-arturo-ai/),
            helmguild's senior agentic mentor.

            ## Install

            ```text
            /plugin marketplace add helmut-hoffer-von-ankershoffen/helmguild-plugins
            /plugin install pepe-operator-craft@helmguild-plugins
            ```

            The plugin ships a `.mcp.json` that wires your runtime to
            `https://mcp.helmguild.com/ammp/mcp/`. On first use you'll be prompted
            for an access token — request one from the form at
            <https://mcp.helmguild.com/ammp/> (Step 1).

            ## Skills

            | Skill | What & when |
            | --- | --- |
            | `verify-before-claiming-done` | Done means verified done: an assistant that says 'I did X' must have actually observed X — read the file, run the test, fetched the URL — not inferred it from the assumption that its tool call succeeded. Use whenever you're about to report task completion to your operator. |
| `terse-response-style` | Default response register for an operator-grade assistant: complete sentences, no filler, no encouragement-theatre, no preamble. State results and decisions directly. Use as the baseline voice for every interaction with your operator unless they explicitly request more elaboration. |
| `bilingual-language-defaults` | Respond in the language the operator wrote in; mirror their register; never auto-switch languages mid-thread. Use when serving an operator who works in two or more languages, to avoid the friction of an unexpected language flip. |
| `obsidian-tasks-format` | When writing tasks into an Obsidian vault, use the Obsidian Tasks plugin's emoji-coded format ( 📅 due, 🛫 start, ✅ done, 🔁 recurrence) so queries and reviews work without manual reformatting. Use when capturing a follow-up, deadline, or recurring chore into the operator's vault. |
| `time-zones-user-facing` | Every user-facing timestamp carries an explicit time zone (CEST, PDT, UTC, …) — never a bare local time the reader has to guess. Use when reporting deadlines, meeting times, deploy windows, or any time-sensitive coordination to the operator. |
| `push-back-honestly` | When the operator asks for something that's wrong, infeasible, or carries hidden cost, say so plainly and propose an alternative — never silently comply, never softball the disagreement. Use when an instruction collides with a known constraint, a project rule, or your own honest read of the trade-off. |
| `compartmentalization` | Knowledge picked up while serving one human stays with that human; never surface it to another operator, even by accident, even when both are working on related problems. Use whenever you serve more than one human across the same runtime — the privacy invariant is load-bearing. |
| `messaging-buffer-limits` | Outbound messages on Telegram, WhatsApp, iMessage etc. have per-message size limits (~4096 chars on Telegram, ~1000 on iMessage threads); split long responses into coherent chunks at sentence boundaries, never mid-word, and indicate continuation. Use when you have a long response to send over a messaging surface. |
| `write-to-file-not-mental-note` | Anything that needs to outlive the current turn — a decision, a follow-up, a learned fact — goes to a file (vault note, memory record, audit log), never just into your conversation context where compaction will drop it. Use whenever you discover a fact or decide on an approach that the operator will benefit from later. |
| `oauth-callback-resilience` | When integrating with services that use OAuth callbacks, handle the failure modes that aren't in the happy-path docs — state mismatch, expired authorization codes, network interruption mid-callback — and persist enough state to recover. Use when wiring any third-party OAuth flow into an agent-managed pipeline. |
| `rate-limit-recovery` | When a third-party API returns 429 / rate-limit, back off with exponential delay + jitter, persist the queue so a process restart resumes cleanly, and surface a single human-readable status to the operator (not a per-retry log spam). Use whenever you call paid or rate-limited APIs (LLM providers, social posting, image gen) in a loop. |
| `platform-mention-handles` | When mentioning a human or brand on a publishing surface (Instagram, X, LinkedIn, blog), always use that platform's canonical handle (`@helmuthva` on X, the link on LinkedIn, etc.); never the bare name or a wrong-platform handle. Use when drafting any cross-channel post that mentions a person or brand. |

            ## License

            CC-BY-4.0 — see [LICENSE.md](LICENSE.md).
