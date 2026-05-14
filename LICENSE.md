# Helmguild Mentoring License v1.0

Copyright © 2026 Helmut Hoffer von Ankershoffen. All rights reserved.

This License governs the works in this repository — including every plugin manifest (`.claude-plugin/plugin.json`), MCP configuration (`.mcp.json`), skill body (`SKILL.md`), bundled script, bundled MCP server, and any associated text or media — collectively the **"Work"**.

## 1. Distribution

The Work is **proprietary**. The only authorised channels of distribution are:

1. The `helmguild-plugins` marketplace clone running under helmguild infrastructure.
2. The Agentic Mentor-Mentee Protocol (AMMP) reference server at `mcp.helmguild.com/ammp` (and successor endpoints operated by helmguild), delivered to a mentee through the `GetPluginArchive` operation (or any successor AMMP wire op) as part of an active mentoring engagement.
3. A helmguild mentor handing the Work directly to a mentee within an established mentor/mentee relationship that exists at the time of transfer.

Any other form of distribution — including but not limited to publishing the Work on a public or private code-hosting service, registry, marketplace, package index, blog post, mirror, or backup outside of (1)-(3) — is **expressly prohibited**.

## 2. Permitted use by a mentee

A mentee who has received the Work through an authorised channel listed in §1 may:

1. **Install** the Work into their own agent runtime (e.g. Claude Code, Claude Cowork, OpenClaw, or any other AgentSkills- / Claude-plugin-compatible client) for personal use during the mentoring engagement.
2. **Execute** the Work in support of carrying out instructions received from the helmguild mentor whose plugin it is.
3. **Read, study, and adapt internally** the Work — including the skill bodies and bundled scripts — for the same purpose, so long as no adapted copy is redistributed.

## 3. Restrictions

The mentee MUST NOT:

1. **Redistribute** the Work, in original or modified form, to any third party.
2. **Re-publish** the Work on any other marketplace, repository, registry, website, or shared filesystem outside the channels in §1.
3. **Use** the Work outside an active mentoring engagement brokered by helmguild.
4. **Train, fine-tune, evaluate, or distil** any machine-learning model on the Work, including but not limited to language models, embedding models, or autonomous agents that are not party to the mentoring engagement.
5. **Sublicense, sell, lease, or transfer** any of the rights granted by this License.
6. **Remove or alter** copyright, license, or attribution metadata inside the Work, including the `license` fields in `plugin.json`, `marketplace.json`, and `SKILL.md` frontmatter.

## 4. Termination

All rights granted under this License terminate automatically:

1. Upon termination of the mentoring engagement under which the Work was delivered.
2. Upon any breach of §1 or §3.

Upon termination, the mentee MUST promptly uninstall and delete all copies of the Work from their systems and from any backup they control. The obligations in §3 (non-redistribution, non-training, non-sublicensing) survive termination indefinitely with respect to copies retained in violation of this paragraph.

## 5. No warranty

THE WORK IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION WITH THE WORK OR THE USE OR OTHER DEALINGS IN THE WORK.

## 6. Contact

For licensing exceptions, to establish a mentoring engagement, or for any other licensing question, write to:

```
Helmut Hoffer von Ankershoffen
helmuthva@gmail.com
https://helmut.hoffer-von-ankershoffen.me/
```

---

**SPDX identifier:** `LicenseRef-helmguild-mentoring-1.0` (custom; not on the SPDX list).

This License is referenced from `helmguild-plugins/.claude-plugin/marketplace.json`, every plugin's `.claude-plugin/plugin.json`, and every skill's `SKILL.md` frontmatter `license:` field.
