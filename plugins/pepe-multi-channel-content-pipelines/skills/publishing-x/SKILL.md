---
name: publishing-x
description: "Publish posts, threads, replies, and reposted reels to X (formerly Twitter) from an autonomous content pipeline. Covers operator setup (X developer account + project + app + OAuth 2.0 with PKCE + bearer/access tokens), single-post publishing with media, thread chaining, cross-posting from Instagram reels (with X's 140-second video cap + caption truncation rules), reply etiquette, rate-limit handling, and post-publish verification. Use whenever the pipeline needs X as a publishing surface."
license: LicenseRef-helmguild-mentoring-1.0
metadata:
  mentor: pepe
  playbook: multi-channel-content-pipelines
  order: 5
  ammp-draft: draft-ammp-01
allowed-tools:
  - bash
  - http
---

# Publishing to X

X's developer platform is **the X API v2** with **OAuth 2.0 Authorization Code with PKCE**. Posting requires a paid developer tier (Basic at minimum as of 2025) — the free tier is read-only. The operator must accept this cost up front.

Compared to Instagram, X is simpler: no business-account-linked-to-page plumbing, no two-step container/publish dance — one POST per tweet. The complexity is in **media-attached posting** (videos must be chunk-uploaded) and in **thread chaining** (each subsequent tweet references the parent via `in_reply_to_tweet_id`).

## Commands

### Command 1 — Setup (one-time, operator runs this on the host)

**Audience: the human operator.** The agent walks each step in sequence and verifies before proceeding.

1. **Sign up for the X Developer Platform.** Visit `https://developer.x.com/` → sign in with the brand X account → apply for developer access (free tier first; the upgrade to Basic happens in step 4).
2. **Create a project + app.** Developer Portal → Projects → Add project → name it `<brand>-content-pipeline`. Add an app under that project, name it the same. Note the **App ID**.
3. **Confirm the use case.** When prompted: "Making a bot" / "Publishing and analytics" — be honest. Lying about the use case is a TOS violation and X has terminated dev accounts retroactively for misrepresentation.
4. **Upgrade to the paid Basic tier (≈ USD 100 / month as of 2025).** The free tier blocks `POST /2/tweets`. The operator confirms they understand the recurring cost before continuing — this is the only paid skill in the playbook.
5. **Configure OAuth 2.0 settings.** App settings → User authentication settings → set up. Pick OAuth 2.0 (not 1.0a). App permissions: `Read and write`. Type of App: `Web App, Automated App or Bot`. Callback URI: `http://127.0.0.1:8765/oauth/callback` (local) or the operator's chosen HTTPS callback. Website URL: the brand's homepage.
6. **Generate OAuth 2.0 credentials.** App → Keys and tokens → OAuth 2.0 Client ID and Client Secret. Copy both.
7. **Perform the one-time OAuth Authorization Code flow with PKCE.** This grants the agent a refresh token. Procedure:
   1. Generate a PKCE verifier + challenge (43-128 random chars verifier; SHA-256 → base64url challenge).
   2. Open in browser:

      ```
      https://twitter.com/i/oauth2/authorize?response_type=code&client_id=<CLIENT_ID>&redirect_uri=http://127.0.0.1:8765/oauth/callback&scope=tweet.read%20tweet.write%20users.read%20offline.access&state=<RANDOM>&code_challenge=<CHALLENGE>&code_challenge_method=S256
      ```

      Sign in as the brand X account → Authorize.
   3. The browser redirects to the callback with `?code=<AUTH_CODE>&state=<RANDOM>`. Capture the code (a one-shot listener on 127.0.0.1:8765 or a manual URL paste).
   4. Exchange for a refresh + access token pair:

      ```sh
      curl -sf -X POST "https://api.x.com/2/oauth2/token" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -u "<CLIENT_ID>:<CLIENT_SECRET>" \
        -d "grant_type=authorization_code" \
        -d "code=<AUTH_CODE>" \
        -d "redirect_uri=http://127.0.0.1:8765/oauth/callback" \
        -d "code_verifier=<VERIFIER>"
      ```

      Response: `{access_token, refresh_token, expires_in: 7200, scope, token_type: "bearer"}`. The access token lasts 2 hours; the refresh token rotates on every refresh and lasts ~6 months.
8. **Store credentials.**

   ```sh
   mkdir -p ~/.openclaw/credentials/x
   cat > ~/.openclaw/credentials/x/env <<EOF
   X_CLIENT_ID=<CLIENT_ID>
   X_CLIENT_SECRET=<CLIENT_SECRET>
   X_REFRESH_TOKEN=<REFRESH_TOKEN>
   X_USER_ID=<USER_ID>
   EOF
   chmod 600 ~/.openclaw/credentials/x/env
   ```

   The access token is **not** persisted — it's refreshed at the start of every batch run (see Command 2.1). The refresh token is rotated on every refresh, so the agent writes the new refresh token back to disk after each refresh.
9. **Define per-account voice rules.** Same shape as `publishing-instagram` Command 1.12 but tuned to X's 280-char limit + thread norms: tone, language, hashtag policy (typically lighter on X — 1-3 hashtags vs IG's 10), emoji signature, banned phrases. Persist as `~/.openclaw/credentials/x/voice-rules.json`.
10. **Smoke-test.** Run Command 2 with a draft text-only post. Verify the first publish lands as drafted. `X_FIRST_PUBLISH_GATE=1` holds the post as a draft (saved-but-not-tweeted) until the operator confirms — set to `0` after the first round-trip.

11. **Run the doctor to confirm.** `scripts/setup-doctor.sh --channel x`. Exit 0 + `✓ x ready — OAuth 2.0 refresh-token chain valid` means the refresh exchange succeeded; the doctor cached the result for 60 s so re-runs don't burn the OAuth-refresh budget. Anything else → return to the step the doctor reports as the gap.

Operator confirms: "Setup complete."

### Command 2 — Refresh the access token (run at the start of every batch)

X's access token lives for 2 hours; the agent refreshes it once per batch run.

```sh
curl -sf -X POST "https://api.x.com/2/oauth2/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -u "<X_CLIENT_ID>:<X_CLIENT_SECRET>" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=<X_REFRESH_TOKEN>"
```

Response carries a new access token + a **new refresh token**. **Write the new refresh token back to `~/.openclaw/credentials/x/env`** — if the agent loses it, the operator must redo Command 1.7.

### Command 3 — Post a text tweet

```sh
curl -sf -X POST "https://api.x.com/2/tweets" \
  -H "Authorization: Bearer <ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"text": "<TWEET_TEXT>"}'
```

* **Length cap:** 280 chars. Pin a soft limit at 270 to leave margin for an auto-appended emoji signature.
* **Response:** `{data: {id, text, edit_history_tweet_ids}}`. Log the `id` — analytics + thread chaining consume it.
* **Persist:** append to `state/publish-log.jsonl` with `{ts, channel:"x", media_type:"tweet", tweet_id, text_hash}`.

### Command 4 — Post a tweet with media (image / GIF / short video)

X has a separate media upload endpoint. For videos, X caps **uploads at 140 seconds** for the public API (Basic tier) — longer videos must be trimmed.

1. **Trim if needed.** If the source MP4 exceeds 140 s, the agent cuts it (`ffmpeg -i source.mp4 -t 140 -c copy x-trimmed.mp4`) and logs the truncation event. Aspect 9:16 reels under 140 s pass through as-is.
2. **Initialize the chunked upload.**

   ```sh
   curl -sf -X POST "https://upload.x.com/1.1/media/upload.json" \
     -H "Authorization: Bearer <ACCESS_TOKEN>" \
     -d "command=INIT" \
     -d "media_type=video/mp4" \
     -d "media_category=tweet_video" \
     -d "total_bytes=$(stat -f %z x-trimmed.mp4)"
   ```

   Response: `{media_id_string}`.
3. **Upload chunks** (5 MB each, indexed from 0):

   ```sh
   curl -sf -X POST "https://upload.x.com/1.1/media/upload.json" \
     -H "Authorization: Bearer <ACCESS_TOKEN>" \
     -F "command=APPEND" \
     -F "media_id=<MEDIA_ID>" \
     -F "segment_index=<N>" \
     -F "media=@chunk-<N>.bin"
   ```

4. **Finalize.**

   ```sh
   curl -sf -X POST "https://upload.x.com/1.1/media/upload.json" \
     -H "Authorization: Bearer <ACCESS_TOKEN>" \
     -d "command=FINALIZE" \
     -d "media_id=<MEDIA_ID>"
   ```

   Response includes a `processing_info` block — poll for `state=succeeded` (or `failed`) before tweeting:

   ```sh
   curl -sf "https://upload.x.com/1.1/media/upload.json?command=STATUS&media_id=<MEDIA_ID>" \
     -H "Authorization: Bearer <ACCESS_TOKEN>"
   ```

5. **Tweet with the media attached.**

   ```sh
   curl -sf -X POST "https://api.x.com/2/tweets" \
     -H "Authorization: Bearer <ACCESS_TOKEN>" \
     -H "Content-Type: application/json" \
     -d '{"text": "<TWEET_TEXT>", "media": {"media_ids": ["<MEDIA_ID>"]}}'
   ```

### Command 5 — Post a thread

A thread is a chain where each subsequent tweet references the prior tweet's ID via `in_reply_to_tweet_id`.

1. **Post the head** (Command 3 or 4). Capture `tweet_id_0`.
2. **Post each follow-up:**

   ```sh
   curl -sf -X POST "https://api.x.com/2/tweets" \
     -H "Authorization: Bearer <ACCESS_TOKEN>" \
     -H "Content-Type: application/json" \
     -d '{"text": "<NEXT_TWEET>", "reply": {"in_reply_to_tweet_id": "<PREV_ID>"}}'
   ```

   Capture each new tweet's ID; chain forward.
3. **Spacing.** 1-2 s between tweets is fine — well under X's rate limit. Beyond ~25 tweets in a thread, X's `conversation_id` window starts caching slow; cap practical thread length at 20.
4. **Atomic-thread discipline.** If a mid-thread tweet fails, do **not** retry that single tweet — the thread is now split. Delete from the failure point onward (`DELETE /2/tweets/<id>`) and re-post from there. Persistence: every tweet's ID is in `state/publish-log.jsonl`, so the agent can locate the split.

### Command 6 — Cross-post an Instagram reel to X

After `publishing-instagram` publishes a reel, mirror the same video to X. **Don't re-encode** — use the same MP4 the IG poster used, run it through the X-specific trimmer if needed, post via Command 4. **Don't re-author the caption** — derive from the canonical content source's text the same way Instagram's caption did, but with X's per-account voice rules applied.

1. **Source video path:** read from the IG publish-log line (`source_video_path`).
2. **Trim if > 140 s.** Pepe reels are 8-30 s — never trips this.
3. **Caption:** derive from the same canonical record IG used. X voice rules typically demand:
   - Same hook (first ~125 chars) trimmed to fit 280 chars total.
   - 1-3 hashtags (vs IG's 10) — keep the brand hashtag + 1-2 topical.
   - Same emoji signature.
   - Add `via @<brand_ig_handle>` if cross-posting is explicit in the brand voice (Pepe omits this — the same content stands on its own on each surface).
4. **Run Command 4** to post with media.
5. **Persist with cross-ref** to the IG publish event so analytics can attribute cross-channel reach to one canonical piece.

### Command 7 — Reply etiquette

Replies are tweets with `in_reply_to_tweet_id` set (same shape as thread continuations) but to a tweet not authored by the brand account. **Don't auto-reply at the pipeline level** — replies are part of the operator's engagement loop, not the publishing pipeline. The agent is allowed to:

* **Draft** replies the operator can approve/edit.
* **Schedule** replies for the operator to post manually.
* **Auto-acknowledge** (e.g. "thanks for the comment" canned acks) only when the operator explicitly opts in per account.

The default is **off** — replies are a human surface.

### Command 8 — Handle rate limits

X's Basic tier as of 2025:
* 100 tweets / 24 h per user (resets rolling).
* 50 POST `/2/tweets` / 15 min (rate-limit window).
* Media uploads: separate budget; chunked uploads consume one request per chunk.

1. **Default thread spacing:** 1-2 s between tweets within a thread.
2. **Default standalone-tweet spacing:** 60 s between independent posts to leave room for replies and reposts.
3. **Daily budget:** the calendar in `content-strategy-planning-optimization` must respect the 100/24 h cap; the agent flags an over-budget calendar at planning time, not at publish time.
4. **Headers to watch:** `x-rate-limit-remaining`, `x-rate-limit-reset` — back off when remaining ≤ 5.

### Command 9 — Verify the published tweet

1. **Fetch by ID.**

   ```sh
   curl -sf "https://api.x.com/2/tweets/<TWEET_ID>?tweet.fields=created_at,text,attachments" \
     -H "Authorization: Bearer <ACCESS_TOKEN>"
   ```

2. Confirm the `text` matches the submitted text verbatim. X strips zero-width and odd unicode at submit time — if the response text differs, the agent logs the diff and re-submits the next post with sanitised text.
3. **Open the public URL** `https://x.com/<HANDLE>/status/<TWEET_ID>` — agent fetches it as a sanity check; the page must render the tweet.
4. **Stash the URL** in the publish-log line.

## Pepe Arturo reference deployment

* **Account:** `@pepe_arturo_ai` on X (linked to the same brand identity as the IG account).
* **Cross-post discipline:** every IG reel mirrors to X via Command 6 within 5 min of the IG publish.
* **Voice rules:** same calm/grounded English voice as IG. Hashtag block typically just `#PepeArturo` + 1 topical. Emoji signature: 🍝.
* **Threads:** used for long-form mini-articles when blog isn't warranted (typically 3-7 tweet threads).
* **Replies:** drafted by the agent, posted by Helmut. No auto-reply.

## Brand-specific overrides every operator should change

* X handle.
* Hashtag policy (X tolerates fewer than IG).
* Cross-post strategy (some brands want X-first instead of IG-first; Command 6 inverts cleanly).
* Reply policy.

## Operating constraints carried over

* **Human gate before first public publish** (Command 1.10 — `X_FIRST_PUBLISH_GATE=1` until the first round-trip).
* **One canonical source** — Command 6's caption derives from the same source IG used.
* **Resumable stages** — every tweet ID logged immediately, threads recoverable from the split point.
* **Schedule as state** — the calendar drives `next_due_at`, not a cron.
