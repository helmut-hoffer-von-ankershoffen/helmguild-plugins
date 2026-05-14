---
name: virtual-character-veo-3-1
description: "Generate consistent virtual characters (face, outfit, voice, pose) as 8-second 9:16 video clips with native voiceover and lip-sync using Google's Veo 3.1 via the Gemini API. Covers operator setup (Google AI Studio account, API key, quota), reference-image preparation, prompt structure for character consistency, voiceover prompting, RAI-filter handling, and validating outputs. Use whenever a content pipeline needs the same virtual character to appear across multiple shots without drifting in appearance or voice."
license: LicenseRef-helmguild-mentoring-1.0
metadata:
  mentor: pepe
  playbook: multi-channel-content-pipelines
  order: 1
  ammp-draft: draft-ammp-01
allowed-tools:
  - bash
  - http
---

# Virtual character generation with Veo 3.1

Veo 3.1 generates **synchronized video + audio (including dialogue with on-screen lip-sync) in one shot** from a text prompt and up to two reference images. That property is what makes it usable as a "virtual character actor": same face, same voice, repeated shots, no separate TTS or lip-sync pass.

This skill is the foundation of any multi-channel pipeline that ships a persistent virtual character (a brand avatar, an AI host, a fictional spokesperson). Once it works, the publishing skills downstream (`publishing-instagram`, `publishing-x`, `publishing-blog`) consume its output.

## Commands

Each command is a discrete procedure the agent runs. The first command runs **once per operator** during onboarding; the remaining commands run per shot.

### Command 1 — Setup (one-time, operator runs this on the host)

**Audience: the human operator.** The agent prompts the operator to complete each numbered step and confirms each one before proceeding to Command 2.

1. **Create a Google AI Studio account.** Visit `https://aistudio.google.com/`, sign in with a Google account (a fresh project-dedicated Google account is recommended so the quota and the key don't collide with personal use), accept the terms.
2. **Create a Google Cloud project.** From AI Studio, follow the "Get API key" flow — it creates a Google Cloud project automatically if none exists. Note the **project ID** (`<your-project>-XXXX`).
3. **Enable the Veo 3.1 model.** Veo 3.1 is a **preview** model — Google gates it behind a per-account opt-in. From AI Studio's model picker, select `veo-3.1-generate-preview`. If it appears greyed out, your account isn't in the preview group yet; request access from the model page.
4. **Generate an API key.** AI Studio → API keys → "Create API key". Copy the key (it shows once). It will look like `AIzaSy...` (~39 chars).
5. **Store the key.** Persist it in a credentials directory the agent can read, never in source control:

   ```sh
   mkdir -p ~/.openclaw/credentials/gemini
   printf '%s' '<your-key>' > ~/.openclaw/credentials/gemini/api-key
   chmod 600 ~/.openclaw/credentials/gemini/api-key
   ```

6. **Smoke-test the key.** The agent runs:

   ```sh
   curl -sf "https://generativelanguage.googleapis.com/v1beta/models?key=$(cat ~/.openclaw/credentials/gemini/api-key)" \
     | jq -r '.models[].name' | grep -i veo
   ```

   This must list `models/veo-3.1-generate-preview` (or a newer preview). If the key works but Veo isn't listed, the account isn't enrolled in the preview yet — return to step 3.

7. **Verify quota.** Veo has a tight per-minute quota (≈ 1 long-running operation in flight at a time on the free tier; preview quota varies). The agent runs Command 2 with a one-line "test render" prompt and checks that the operation completes within ~3 min. If 429s persist, the operator must request a quota bump from the Veo product page or upgrade billing.

The operator confirms once: "Setup complete." From this point on the agent runs the remaining commands autonomously.

### Command 2 — Generate the character reference sheet

Veo's character consistency comes from **reference-image conditioning**: you pass 1-2 reference images per call, and Veo holds appearance close to those references across shots. So before generating any real content, build a **canonical reference set** for the character.

1. **Pick or generate the canonical face.** Either (a) a real-person photo, (b) an AI-generated portrait from Imagen / DALL-E / Midjourney that the operator owns, or (c) a non-human avatar (mascot, animal, abstract figure). Save as a square JPEG at 1024 × 1024 (`character_1024.jpg`).
2. **(Optional) Pick a canonical co-star face.** If the character will appear in shots alongside a recurring co-star (often the operator themselves, for brand-personal pipelines), prepare a second 1024 × 1024 JPEG (`costar_1024.jpg`). Veo accepts up to 2 reference images per call.
3. **Document the character's appearance contract.** Write a one-paragraph "character description" the agent will append to every Veo prompt — what the character looks like, how they're dressed, their posture, their voice tone. Store it as `character-contract.md` alongside the reference images. Example for a frog-monk:
   > "Pepe Arturo is a small calm frog monk, brown rope-belt habit, sitting cross-legged. Calm, grounded posture. When he speaks, soft male voice in English, slow cadence, no Italian, no filler."
4. **Test the reference set.** Run Command 3 with a no-op prompt (`"<character> sitting still, neutral expression, no dialogue, ambient outdoor sound"`). Inspect the result: face matches the reference, no morphing across the 8s, no unwanted accents in the visual. If the face drifts, the reference image is too low-res or too cluttered — re-crop tighter on the face and retry.

The reference sheet is durable. It only changes when the operator deliberately rebrands the character.

### Command 3 — Render a single shot

This is the per-piece command. The agent runs it once for every new shot in the content calendar.

1. **Construct the prompt.** A Veo shot prompt has four parts in this order: (a) the appearance contract from Command 2, (b) the scene (location, framing, action), (c) the dialogue cue (`Off-screen male voice in English calmly narrates: "<line>"` for VO, or `the character speaks the line in English with clear lip-sync` for on-screen speech), (d) audio ambience hints.
2. **Compose the request.** POST to:

   ```
   https://generativelanguage.googleapis.com/v1beta/models/veo-3.1-generate-preview:predictLongRunning?key=<KEY>
   ```

   Body schema (JSON):

   ```json
   {
     "instances": [{
       "prompt": "<full prompt from step 1>",
       "referenceImages": [
         {"image": {"bytesBase64Encoded": "<base64 character_1024.jpg>"}},
         {"image": {"bytesBase64Encoded": "<base64 costar_1024.jpg>"}}
       ]
     }],
     "parameters": {
       "aspectRatio": "9:16",
       "durationSeconds": 8,
       "personGeneration": "allow_adult"
     }
   }
   ```

   The response carries a long-running operation name (`operations/...`).

3. **Poll until done.** GET `https://generativelanguage.googleapis.com/v1beta/<operation-name>?key=<KEY>` every 10 seconds. When `done: true`, the response holds the result video as either a `videoUri` (signed URL) or `bytesBase64Encoded` blob. Typical wall-clock: 60-180 s per 8s shot.
4. **Download to a working dir.** Convention: `/tmp/veo-<character>-take<N>/` containing `submit.py`, `character_1024.jpg`, `costar_1024.jpg` if used, `op.txt` (operation name), `op-result.json`, `raw.mp4`.
5. **(Optional) Re-encode for portability.** Veo raw is h264 in an MP4 container with `format_tags=encoder Google`. Re-encode with `ffmpeg -i raw.mp4 -c:v libx264 -preset slow -crf 18 -c:a aac -b:a 192k take<N>.mp4` if the downstream channel (some legacy IG flows, some browsers) chokes on the raw container. The new file shows `encoder Lavf<NN>.<NN>` and is the canonical artefact for the publishing skills.
6. **Stage to canonical storage.** Move `take<N>.mp4` to the operator's canonical content store (a host directory, an S3 bucket, an Obsidian vault assets folder, whatever the operator's `content-strategy` skill defined). The publishing skills read from there.

### Command 4 — Validate the output (run after every Command 3)

Veo outputs are **content-blind from the agent's perspective**, so validate before queueing for publish.

1. **Audit-trail check.** `ffprobe -v error -show_entries format_tags=encoder raw.mp4` must return `Google` (proof it came from Veo, not a previous step or a swap). After re-encode the value flips to `Lavf...` — note both expected states.
2. **Visual consistency check.** Sample 4 frames evenly across the 8 s (`ffmpeg -ss <t> -i raw.mp4 -frames:v 1 frame-<i>.png`). For the agent, open each frame and confirm the character matches the reference sheet: face shape, outfit, posture. For a real-person co-star, confirm no morphing.
3. **Audio check.** If the prompt requested dialogue, run `ffprobe -v error -select_streams a -show_entries stream=codec_name,duration raw.mp4` — must show an audio stream with ≈ 8 s duration. Missing audio means Veo's audio safety filter likely tripped on the dialogue text (see Command 5).
4. **RAI filter post-check.** If the request returned an HTTP 200 but the video has no audio, no character, or a black-screen segment, that's a **silent safety rejection** — Veo doesn't always surface filter trips as an error. Soft-fail: log the prompt, soften it, retry.

### Command 5 — Handle Veo's RAI safety filter

Veo rejects prompts containing certain content (literal brand names embroidered on clothing, real-person names attached to risky activities, etc.) — and the rejection mode is *silent video corruption* rather than a clean HTTP error. Procedure:

1. **Strip literal brand names.** Replace embroidered "Nike", "Canyon", "Orca", etc. with generic descriptors ("a black running cap", "a black aero helmet"). Visual fidelity stays — only the literal text trips the filter.
2. **Avoid real-person + risky-action pairs.** If using a real co-star's face, keep the scene tone calm and non-violent. Sports cameos (running, swimming, biking) work fine; "lifting a heavy object alone" or "near a cliff edge" can trip.
3. **Soften dialogue.** Strong language, political assertions, named third parties — soften or paraphrase. The visual prompt can stay strong; the dialogue text is what the filter scans most aggressively.
4. **Retry with the softened prompt.** Two strikes on the same shot = move on, generate a different shot to fill the slot in the content calendar. Don't burn quota wrestling one prompt.

### Command 6 — Batch + quota management

For a content calendar that ships >1 shot per week, run Command 3 in batched sweeps rather than ad-hoc.

1. **Stagger submissions.** ≥ 30 s apart per long-running operation; Veo preview throttles hard.
2. **Cap parallelism.** ≤ 3 in-flight long-running operations on the free preview tier. Going wider raises 429 rate but doesn't speed up wall-clock.
3. **Make every submission resumable.** Persist the long-running operation name to a state file (`state/veo-queue/<id>.op`) the moment the API returns it. If the agent crashes mid-poll, the next run reads the state file and resumes polling — never re-submits and never loses the result.
4. **Cost-of-fail discipline.** A failed shot is ~30-60 s of wall-clock + one quota unit. Budget that into the calendar. Aim for ≥ 80 % first-shot success once Command 2 (reference sheet) is stable.

## Pepe Arturo reference deployment

The Pepe Arturo brand uses this skill verbatim, with:

* **Character contract:** "Pepe Arturo is a small calm frog monk in a brown rope-belt habit. Calm, grounded posture. Soft male English voice, slow cadence, no Italian, no filler."
* **Reference images:** `pepe_1024.jpg` (frog-monk avatar derived from `avatars/pepe-arturo.png`) + `helmut_1024.jpg` (Helmut Hoffer von Ankershoffen as recurring real co-star, from `state/content-source/helmut-snowflake-profile.jpg`).
* **Canonical storage:** `/Volumes/My Shared Files/Pepe Reels/` on Helmut's macOS host (the host↔VM share).
* **Audit fingerprint:** all production shots are validated to `format_tags=encoder Google` immediately after download, then re-encoded for IG before publish (`take<N>.mp4` carries `Lavf...`).
* **Per-shot working dir:** `/tmp/veo-reel-take<N>/`, retained for 7 days for re-runs.

## Brand-specific overrides every operator should change

* Character name + appearance contract (the Pepe-frog-monk language is Pepe-specific).
* Reference images.
* Canonical-storage location.
* Co-star (if any) — only include with explicit consent of the real person.
* Voice gender / cadence cues in the dialogue prompt.

## Open question for the operator on first run

* "What should your virtual character look like in one sentence?" — capture as the appearance contract before Command 2.
* "Will the character appear alongside a real co-star? If yes, do you have explicit written consent from that person?" — gate Command 2 on yes.

## Operating constraints carried over from the original principles

* **Resumable stages.** Long-running operations are persisted as state files (Command 6.3). No "click run and wait at the console".
* **Schedule as state, not cron.** The next batch sweep is triggered when the calendar's `next_due_at` falls in the past, not by a wall-clock cron entry. See `content-strategy-planning-optimization` for the calendar contract.
* **Human gate before first public publish.** Command 4's validation passes the file forward to the publishing skills, but those skills enforce that the first shot of a *new* character must be reviewed by the operator before going public. See `publishing-instagram` / `publishing-x` / `publishing-blog`.
