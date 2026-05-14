---
name: publishing-instagram
description: "Publish reels, Stories, and image/carousel posts to Instagram from an autonomous content pipeline via the Meta Graph API. Covers operator setup (Meta Business + IG Professional account + Facebook Page link + long-lived access token + IG user ID), reel posting with collaborator invites and Story mirror, caption authoring under per-account voice rules, hashtag discipline, rate-limit handling, and post-publish verification. Use whenever the pipeline needs Instagram as a publishing surface."
license: LicenseRef-helmguild-mentoring-1.0
metadata:
  mentor: pepe
  playbook: multi-channel-content-pipelines
  order: 4
  ammp-draft: draft-ammp-01
allowed-tools:
  - bash
  - http
---

# Publishing to Instagram

Instagram's public publishing API is the **Meta Graph API** with an **IG Professional account linked to a Facebook Page**. Personal accounts cannot publish via API. Most of the operator-side setup is one-time Meta Business plumbing — the moment it's wired correctly, the agent can post reels, image posts, carousels, and Stories autonomously.

This skill assumes the upstream `virtual-character-veo-3-1` (or any other production skill) has staged a finished MP4 in the operator's canonical content store.

## Commands

### Command 1 — Setup (one-time, operator runs this on the host)

**Audience: the human operator.** The agent walks the operator through each numbered step in sequence and verifies each before proceeding.

1. **Promote the brand IG account to Professional.** In the IG app: Settings → Account type and tools → Switch to Professional account → choose **Business** (not Creator — Business gets full Graph API publishing rights; Creator's API surface is narrower).
2. **Create a Meta Business account.** Visit `https://business.facebook.com/`, sign in with a Facebook account, create a Business portfolio for the brand. Name it after the brand, not the operator.
3. **Create or claim a Facebook Page for the brand.** Meta Business → Pages → Add → Create. IG publishing requires the IG Professional account to be linked to a Page in the same Business portfolio. Even if the brand has no organic Facebook presence, the Page must exist.
4. **Link the IG account to the Page.** Meta Business → Accounts → Instagram accounts → Add → log in with the brand IG account → check "Allow access via Meta Business Suite". Then Page → Linked accounts → Instagram → connect.
5. **Create a Meta App.** Visit `https://developers.facebook.com/apps/` → Create App → use case "Other" → app type "Business". Name it `<brand>-content-pipeline`. Note the **App ID** and **App Secret**.
6. **Add the Instagram Graph API product.** From the app dashboard → Add product → Instagram → Set up. Then under Instagram → API setup with Instagram login, link the IG account.
7. **Request the publish permissions.** App Review → Permissions and Features → request: `instagram_basic`, `instagram_content_publish`, `pages_show_list`, `pages_read_engagement`, `business_management`. Standard access (no full app review) is enough for first-party publishing, but each permission must still be explicitly added.
8. **Generate a long-lived access token.** The default user-token from Graph API Explorer is 1-hour. Exchange it for a 60-day long-lived token:

   ```sh
   curl -sf "https://graph.facebook.com/v23.0/oauth/access_token?grant_type=fb_exchange_token&client_id=<APP_ID>&client_secret=<APP_SECRET>&fb_exchange_token=<SHORT_TOKEN>" | jq -r '.access_token'
   ```

   Then exchange that for a **page access token** (publishes as the Page, doesn't expire as long as the user account stays alive):

   ```sh
   curl -sf "https://graph.facebook.com/v23.0/me/accounts?access_token=<LONG_LIVED_USER_TOKEN>" | jq '.data[] | {id, name, access_token}'
   ```

   Pick the Page; persist its `access_token`.
9. **Get the IG user ID.** From the Page ID returned in step 8:

   ```sh
   curl -sf "https://graph.facebook.com/v23.0/<PAGE_ID>?fields=instagram_business_account&access_token=<PAGE_TOKEN>" | jq -r '.instagram_business_account.id'
   ```

   This `<IG_USER_ID>` is the publishing target — every API call routes via `/{IG_USER_ID}/media` etc.
10. **Store credentials.** Persist to a credentials directory the agent can read:

    ```sh
    mkdir -p ~/.openclaw/credentials/instagram
    cat > ~/.openclaw/credentials/instagram/env <<EOF
    IG_USER_ID=<IG_USER_ID>
    IG_PAGE_TOKEN=<PAGE_TOKEN>
    IG_APP_ID=<APP_ID>
    IG_APP_SECRET=<APP_SECRET>
    EOF
    chmod 600 ~/.openclaw/credentials/instagram/env
    ```

11. **Configure a public-readable upload bucket.** Reels are posted via a URL the IG Graph API fetches — IG cannot ingest direct binary uploads for video. Wire any HTTPS bucket the API can reach: Cloudflare R2 + public custom domain, S3 + presigned URLs, the brand's own CDN, etc. Persist the bucket name + base URL.
12. **Define per-account voice rules.** The agent prompts the operator for the caption style: tone, language, hashtag policy, emoji signature, banned phrases. Persist as `~/.openclaw/credentials/instagram/voice-rules.json`. The example schema and the Pepe reference values are in `## Brand-specific overrides`.
13. **Smoke-test.** Run Command 2 with a 5-second placeholder reel and a draft caption. The first publish defaults to `IG_FIRST_PUBLISH_GATE=1`, which holds the post in `published: false` state on IG until the operator manually publishes from the IG app. Once you've seen one successful API → IG → app round-trip, set `IG_FIRST_PUBLISH_GATE=0` for normal operation.

14. **Run the doctor to confirm.** `scripts/setup-doctor.sh --channel instagram`. Exit 0 + `✓ instagram ready — IG account @<handle> reachable` means the page token resolves the IG user ID over the Graph API. Anything else → return to the step the doctor names.

Operator confirms: "Setup complete." From this point on the agent runs the remaining commands without operator intervention except where explicitly noted.

### Command 2 — Post a reel

The two-step Meta Graph reel publish: **upload container → publish container.**

1. **Upload the MP4 to the public bucket.** Get a public HTTPS URL.
2. **Create a media container.**

   ```sh
   curl -sf -X POST "https://graph.facebook.com/v23.0/<IG_USER_ID>/media" \
     -d "media_type=REELS" \
     -d "video_url=<PUBLIC_URL>" \
     -d "caption=<URL_ENCODED_CAPTION>" \
     -d "collaborators=<JSON_ENCODED_USERNAME_ARRAY>" \
     -d "share_to_feed=true" \
     -d "access_token=<IG_PAGE_TOKEN>"
   ```

   The response contains a container `id`.
3. **Poll the container until `status_code=FINISHED`.**

   ```sh
   curl -sf "https://graph.facebook.com/v23.0/<CONTAINER_ID>?fields=status_code,status&access_token=<IG_PAGE_TOKEN>"
   ```

   Status flow: `IN_PROGRESS` → `FINISHED` (success), or `ERROR` (failed — read `status` field for the human-readable reason). Typical wall-clock: 30-120 s depending on video length.
4. **Publish the container.**

   ```sh
   curl -sf -X POST "https://graph.facebook.com/v23.0/<IG_USER_ID>/media_publish" \
     -d "creation_id=<CONTAINER_ID>" \
     -d "access_token=<IG_PAGE_TOKEN>"
   ```

   On success, the response contains the **media ID** of the published post — log it; the analytics skill consumes this.
5. **Persist the publish event.** Append to `state/publish-log.jsonl` with `{ts, channel:"instagram", media_type:"reel", media_id, caption_hash, source_video_path}`. The pipeline-status MCP tool surfaces this.

### Command 3 — Auto-mirror to Story (brand-default ON)

For every reel published, also publish it as a Story. Stories are a **parallel reach surface** — followers who skip the feed often see Stories. **Don't disable to "save" API calls.** If rate-limit pressure forces a trade-off, the right move is slower reel spacing, not skipping Stories.

1. **Create a Story container.** Same as Command 2.2 but `media_type=STORIES` (no `caption`, no `collaborators`, no `share_to_feed`).
2. **Poll the container** to `FINISHED` (same as 2.3).
3. **Publish.** Same as 2.4.
4. **Persist as a separate publish event** with `media_type: "story"`. Stories expire in 24 h — analytics treats them differently.

Toggle: `IG_REEL_AS_STORY=0` disables. The agent flags any such override **explicitly** in the publish summary so the operator sees it; never silent.

### Command 4 — Invite collaborators (brand-default ON when a recurring co-star is configured)

If the operator's voice rules declare a default collaborator (e.g. a co-star), pass it via the `collaborators` field on the **reel container** at Command 2.2. The collaborator must accept once per post in the IG app, after which the reel appears on their feed too — doubles reach without duplicate-posting.

* **Format:** JSON-encoded array of IG usernames, no `@` prefix. `["helmut.hoffer.von.ankershoffen"]`.
* **Override:** `IG_COLLABORATORS=""` (empty string) disables for one call.
* **Multi-collaborator:** up to 3.
* **Privacy gate:** if the cameo features a person who isn't the default collaborator, the agent must check the per-person consent doc the operator maintains before auto-tagging or auto-collaborating.

Carousel + image posts use a different field (`collaborators` works only on REELS via Graph API as of v23.0 — for carousel/image use cases, the operator manually adds tags in the IG app post-publish; the agent flags this).

### Command 5 — Lint the caption

Before submitting the container in Command 2.2, run the caption through a lint that pins the per-account voice rules:

1. **Length.** IG caption max is 2 200 chars. Pin a soft limit at 1 800 to leave margin for hashtag appending.
2. **Hook.** First 125 chars must contain the hook — IG truncates here in the feed preview.
3. **Hashtag block.** Trailing block of 3-15 hashtags, on its own line(s) at the end. Hashtags above 15 trip IG's spam heuristic; below 3 loses reach. Pin the brand's mandatory hashtags (`#<brand>`) first, then 3-7 topical, then 2-3 broad-reach.
4. **Emoji signature.** Brand emoji on every post (e.g. 🍝 for Pepe). Sport-cameo signature if applicable. Configured per account in `voice-rules.json`.
5. **Banned phrases.** "link in bio" if the account has no clickable bio link, "DM us" in regions where IG restricts DM CTAs, etc. — configured per account.
6. **Language consistency.** The voice rules declare the primary language. Captions that drift (e.g. half-Italian, half-English) flag for human review.

A reference lint script ships at `scripts/instagram-caption-lint.sh` — runs all of the above with config-driven rules. Exit non-zero on a failure; the agent must either fix and re-run or escalate to the operator.

### Command 6 — Handle rate limits

IG's hourly app-rate-limit is per-app, not per-account; typical sustainable rate is **~25 publish events per hour per app** (one publish event = container + publish = ~2 calls; Story mirror adds another ~2; collaborator field is free).

1. **Default reel spacing:** 90 s. Below this, the agent risks `(#4) Application request limit reached`.
2. **When rate-limited:** wait 5 min, retry once, then back off to 180 s spacing for the next 3 posts.
3. **Don't drop Story mirrors** to "save" calls — slow the cadence first.
4. **Persist the publish queue.** Resumable: a crash mid-batch resumes from the last successfully-published item, not from the start.

### Command 7 — Verify the published post (run after every publish)

1. **Fetch the post by media ID.**

   ```sh
   curl -sf "https://graph.facebook.com/v23.0/<MEDIA_ID>?fields=id,permalink,caption,timestamp,media_type&access_token=<IG_PAGE_TOKEN>"
   ```

   Must return the permalink and the caption verbatim (within 30 s of publish). If the post is missing, IG silently rejected it post-publish (rare but happens) — re-queue.
2. **Open the permalink** (the agent can curl it; IG returns a public HTML page) and confirm the caption + reel render. For collaborator-flagged posts, the response also surfaces a pending-invite state until the collaborator accepts.
3. **Stash the permalink** in the publish-log line for the analytics skill.

### Command 8 — Recover skipped Stories within the 24 h window

If a batch run skipped Stories (rate-limit emergency, ignored override, agent crash), re-mirror the affected reels as Stories **only if** the reel was published less than ~22 h ago — Stories are a 24 h surface, so an old reel mirrored as a Story makes diminishing sense after ~18 h.

1. **Identify candidates** from `state/publish-log.jsonl` — reels with no matching Story event within the same hour.
2. **Re-stage the local MP4** (fetch by source path) and run Command 3 against it.
3. **Spacing:** 60-90 s between Story publishes is fine for the recovery sweep; lower limit than reels.

## Pepe Arturo reference deployment

* **Account:** `@pepe_arturo_ai` (IG Professional Business, linked to a `Pepe Arturo AI` FB Page in the Helmguild Meta Business portfolio).
* **Default collaborator:** `helmut.hoffer.von.ankershoffen`. Override via `IG_COLLABORATORS=""` for one call.
* **Story mirror default:** ON. Tracked failure cost: missing 24 h surface ≈ -40 % reel reach.
* **Emoji signature:** 🍝 on every post. Sport-cameo signature pairs: 🏊‍♂️🍝 (swim), 🏃‍♂️🍝 (run), 🚴‍♂️🍝 (bike), 🏋️‍♂️🍝 (strength). Non-sport cameos: 🍝 + a small context emoji.
* **Voice rules (excerpt):** English only (no Italian), calm and grounded, sport-flavoured, no emojis-only lines, no "link in bio", 3-15 hashtags trailing block.
* **Privacy gate:** if a reel features any family member other than Helmut, the agent must check the per-person consent doc before auto-collaborator-tagging (e.g. couple-reel batches require an explicit per-batch greenlight; see the brand-private memo `feedback_dont_contact_sandra_about_pepe_content`).

## Brand-specific overrides every operator should change

* IG account handle + linked Facebook Page name.
* Voice rules: language, tone descriptors, hashtag policy, banned phrases.
* Default collaborator handle (and the per-person consent rules around it).
* Emoji signature.
* Public upload bucket (every operator brings their own CDN).

## Operating constraints carried over

* **Human gate before first public publish** (Command 1.13 — `IG_FIRST_PUBLISH_GATE=1` until the operator has eyeballed the first round-trip).
* **One canonical source, many surfaces** — the MP4 the agent posts comes from the canonical content store, not a per-channel re-export.
* **Resumable stages** — publish-log is append-only; a crash mid-batch resumes from the next un-published item.
* **Schedule as state, not cron** — the next publish is triggered by the calendar's `next_due_at`, not by a fixed `crontab` entry. See `content-strategy-planning-optimization`.
