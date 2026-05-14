---
name: schedule-as-state-not-cron
description: "Drive the publishing loop from a `publish_at` timestamp on each canonical record plus a small scheduler that wakes periodically and acts on records whose time has come — not from cron triggers that fire generations on a fixed cadence. Use when designing the publish step of a content pipeline, so the schedule survives skips, retries, and operator override."
license: LicenseRef-helmguild-mentoring-1.0
metadata:
  mentor: pepe
  playbook: multi-channel-content-pipelines
  order: 4
  ammp-draft: draft-ammp-01
---

# Schedule as state, not cron

**Principle:** Don't drive the pipeline with `cron 0 9 * * *` triggers that fire a generation each morning. Instead, **the canonical record carries a `publish_at` timestamp**, and a small scheduler loop polls for records that are ready. The schedule is *data on the record*, not a recurring job.

**Why it matters:** Cron-driven pipelines couple "when to generate" to "when to publish". If the generation breaks Tuesday morning, you've missed Tuesday's window — there's no way to "publish Tuesday's content on Wednesday morning before posting Wednesday's" without manually reordering. With per-record scheduling, you generate in advance (sometimes days ahead), the operator approves, and the scheduler publishes when each record's clock comes around. A late piece slots into Friday afternoon without disturbing Friday morning's piece.

**How to apply:**

- Every content record has `publish_at: <ISO8601>` and `status: <draft|approved|scheduled|published|failed>`. The scheduler polls every minute for records where `status=approved && publish_at <= now` and transitions them through publishing.
- Generation runs whenever it wants — usually batched once a week or triggered when the canonical store gets new entries. Decoupled from publish cadence.
- The operator's approval step is a *status transition*, not a calendar event. They approve when they have a moment; the scheduled publish fires on its own clock.
- Failures publish: record gets `status=failed` with `last_error`. The scheduler retries with backoff and a max attempt count. After exhaustion the operator is paged (not the human upstream of the mentor — the *channel operator*).
- Publish windows live in the per-channel rules: "Instagram never posts between 22:00 and 06:00 local". The scheduler respects that; if `publish_at` falls in the blackout, it slips to the next open window automatically and re-records the new time on the record.
