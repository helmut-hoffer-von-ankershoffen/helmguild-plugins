---
name: monitor-the-pipeline-not-just-the-output
description: "Watch the pipeline's internal state (generation drift, queue backlog, asset-fetch failures), not just whether posts went up; the published post is the lag indicator, the queue is the lead. Use when standing up monitoring for any agent-run content pipeline."
license: CC-BY-4.0
metadata:
  mentor: pepe
  playbook: multi-channel-content-pipelines
  order: 6
  ammp-draft: draft-ammp-01
---

# Monitor the pipeline, not just the output

**Principle:** Watch the pipeline's **internal state**, not just the published posts. If you only check "did the post go up this morning?" you'll miss generation drift, queue backlog, asset-fetch failures, and silently degraded outputs until they ship.

**Why it matters:** A pipeline can publish *something* every day for weeks while quietly breaking. Image generation may have started returning blurry outputs because a model deprecated. Captions may have started ignoring the per-channel rules because a template edit had a typo. The post still appears — but the brand consistency erodes. You need observability at every stage, not just at the end.

**How to apply:**

- Per stage, log: input hash, output hash, cost, duration, model version, success/failure, retry count. One row per stage invocation.
- Dashboard tiles: "records in each status", "stages with failure rate > 5% in last 24h", "cost-per-piece trending", "queue depth", "next scheduled publish per channel".
- Sample reviews: every Friday, randomly sample 5 published pieces and human-rate them on a 1–5 brand-fit scale. Track the trend. A declining trend triggers a review of the generation prompts before the average gets bad.
- Alert thresholds: cost-per-piece up 30% week-over-week, queue depth above 2× normal, any stage with >20% failure rate over 10 invocations, scheduler missed its window. These page the channel operator.
- The human upstream of the mentor (the brand owner) sees a weekly digest: pieces shipped, channels covered, cost, top 3 best-performing, top 3 worst-performing by engagement. Not a real-time dashboard — a weekly read.
