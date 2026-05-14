---
name: pipeline-stages-must-be-resumable
description: "Each expensive stage of a content pipeline (scripting, image gen, video composition, voice synth, captioning, scheduling) writes its output to durable storage so a downstream re-run can restart at the failed stage rather than redoing the whole chain. Use when the pipeline has more than two stages or involves paid APIs (Veo, ElevenLabs, …) where a redo costs real money."
license: CC-BY-4.0
metadata:
  mentor: pepe
  playbook: multi-channel-content-pipelines
  order: 2
  ammp-draft: draft-ammp-01
---

# Pipeline stages must be resumable

**Principle:** A content pipeline has multiple expensive stages — scripting, image generation, video composition, voice synthesis, captioning, scheduling. **Every stage writes its output to durable storage before the next stage runs**, and every stage is safe to re-enter without redoing the work already cached.

**Why it matters:** A reel pipeline might cost $0.30 in API calls per piece. Running 50 a week, a transient failure on stage 5 of 6 that forces a re-run of stages 1–4 is real money plus a delay before publishing. Worse, an LLM call retried because step 5 crashed often produces a *different* script, breaking continuity with the assets already generated. Cache outputs by content hash and you can re-enter exactly once at the failed step.

**How to apply:**

- Each stage takes a content record as input and writes a stage-specific output file next to it (`<id>.script.md`, `<id>.scenes.json`, `<id>.image_<n>.png`, `<id>.audio.mp3`, `<id>.video.mp4`, `<id>.caption.md`).
- Stage N checks for the existence of stage N's output before running. If present and the input hash matches, skip and continue. If absent or hash mismatch, run and write.
- The "input hash" includes the upstream stage's output hash plus any stage-specific config (model version, prompt template version, aspect ratio). Change any of those → cache miss → re-run.
- Surface the cache state in monitoring: "12 reels in stage 3, 3 in stage 5, 1 stuck in stage 2 with last-error=timeout". An operator scanning the dashboard can spot the stuck one without opening logs.
- When a stage's prompt template changes intentionally, bump its version explicitly — never rely on "just re-run everything" because the cache will silently invalidate and burn the budget.
