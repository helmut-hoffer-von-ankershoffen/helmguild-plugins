---
name: publishing-blog
description: "Publish long-form blog posts to a static-site brand domain via a Git-backed deployment (GitHub repo + Cloudflare Pages or equivalent). Covers operator setup (domain registration, GitHub repo, Cloudflare Pages project, DNS, build pipeline), authoring posts in localised pairs (e.g. EN + DE) from a canonical source, sitemap.xml + robots.txt + Atom feed maintenance, CSS cache-bust discipline on style additions, preview-before-publish, and post-deploy verification. Use whenever the content pipeline needs a long-form authoritative surface (the canonical home for articles linked from IG / X)."
license: LicenseRef-helmguild-mentoring-1.0
metadata:
  mentor: pepe
  playbook: multi-channel-content-pipelines
  order: 4
  ammp-draft: draft-ammp-01
allowed-tools:
  - bash
  - git
---

# Publishing to the brand blog (static-site, Git-backed)

A blog is the **authoritative long-form surface** in a multi-channel pipeline: every reel, every X thread, every newsletter can link back to a permanent canonical page. Unlike IG and X, the blog is **operator-owned infrastructure** — no platform can deprecate the surface, throttle the reach, or rewrite the rules.

This skill is opinionated toward a **static-site, Git-backed, CDN-deployed** stack. The reference deployment is `helmguild.com` (static HTML + Markdown sources, served by Cloudflare Pages). The same pattern works for Vercel, Netlify, GitHub Pages, Cloudflare Workers, etc.

## Commands

### Command 1 — Setup (one-time, operator runs this on the host)

**Audience: the human operator.**

1. **Register the brand domain.** Any registrar (Cloudflare, Namecheap, Porkbun). Buy the apex (`<brand>.com`); the `www` subdomain comes for free.
2. **Move DNS to Cloudflare** (recommended — the rest of this skill assumes Cloudflare). Cloudflare → Add a site → enter the domain → follow the nameserver-change instructions at the registrar. DNS propagation: 5-30 min usually.
3. **Create a GitHub repo for the site.** Name it after the domain (`<brand>.com`). Public or private — Cloudflare Pages reads from either. The repo's top level is the site root; the deployment is "everything in `main` after build is the published site".
4. **Pick a site framework.** Three sane choices:
   * **Pure static HTML + Markdown** (helmguild.com). No build step. Edit `.html` directly; Markdown sources alongside for the agent to author. Best for full visual control + zero toolchain surface.
   * **Astro / Eleventy / Hugo.** Markdown sources, templating, build step. Build a `dist/` from `src/`.
   * **Next.js / Nuxt.** Component-heavy; overkill for a blog unless the brand also needs an app surface.
   The agent's authoring flow (Commands 2-6) is identical across frameworks; only the file layout changes.
5. **Create a Cloudflare Pages project.** Cloudflare → Workers & Pages → Create application → Pages → Connect to Git → pick the GitHub repo. Build settings:
   * Framework preset: matches step 4.
   * Build command: `npm run build` (Astro/Eleventy/Hugo/Next) or empty (pure static).
   * Build output: `dist` / `_site` / `public` / repo root.
   * Branch: `main`.
6. **Wire the custom domain.** Cloudflare Pages → Custom domains → Add → `<brand>.com`. Cloudflare creates the DNS records (orange-cloud, not grey — see memory:`cloudflare_tunnel_orange_cloud` for why grey CNAMEs to internal endpoints don't resolve). Add `www` as well; HTTP redirect rule for `www → apex` (or apex → www, operator's choice).
7. **Add Cloudflare Pages preview deployments.** Pages → Settings → Preview deployments → enabled on all branches. Every PR gets a unique preview URL (`<sha>.<project>.pages.dev`). Commands 5-6 verify on preview before merging.
8. **Set up `robots.txt` + `sitemap.xml`.** At the site root:
   * `robots.txt` — `User-agent: *` + `Allow: /` + `Sitemap: https://<brand>.com/sitemap.xml`.
   * `sitemap.xml` — XML sitemap listing every canonical URL with `<lastmod>`. For multi-locale sites, use `xhtml:link` `hreflang` alternates.
9. **Set up an Atom (or RSS) feed.** `/feed.xml` (or `/atom.xml`). Update on every new post. Newsletter integrations, RSS readers, IndieWeb consumers all read this.
10. **Define the post layout convention.** Operator picks ONE — the agent uses it for every post:
    * **Pure HTML:** `blog/<slug>/index.html` + a Markdown mirror `blog/<slug>/index.md` (the canonical source).
    * **Markdown-only (built sites):** `src/content/blog/<slug>.md`.
11. **Define the per-locale layout** (if the brand publishes in multiple languages):
    * **Path-prefix convention** (helmguild.com): `/blog/<slug>/` is EN, `/de/blog/<slug>/` is DE, `/fr/blog/<slug>/` is FR. Every locale-equivalent post has a `<link rel="alternate" hreflang="<lang>" href="<URL>">` to its siblings + an `hreflang="x-default"` pointing at the primary locale.
    * **Domain-per-locale convention:** `<brand>.com` for primary, `<brand>.de` etc. — heavier infrastructure, only worth it for SEO-aggressive multi-market brands.
12. **Smoke-test with a placeholder post.** Run Command 2 with a draft slug `hello-world` → push to a feature branch → preview URL renders → merge → live URL renders within 30 s of merge → sitemap.xml lists the post → Atom feed includes it.

Operator confirms: "Setup complete."

### Command 2 — Author a post

The blog post is **derived** from the canonical content source (see `content-strategy-planning-optimization`). Do not handwrite the body directly into the site repo — handwrite the canonical source and have the agent render it into the site.

1. **Read the canonical source.** Field shape: `{id, title, summary, body_md, hero_image, locale, published_at, author, tags[]}`.
2. **Create the post directory / file.** For pure-HTML: `blog/<slug>/index.html` + `blog/<slug>/index.md`. For Markdown-only sites: `src/content/blog/<slug>.md`.
3. **Render the body.** The HTML version inherits the site's base template; the Markdown version is the canonical body. Both must round-trip — `pandoc index.md -o /tmp/test.html && diff /tmp/test.html <(extract-article-body index.html)` is a useful integrity check during authoring.
4. **Author the locale siblings.** For each additional locale defined in Command 1.11, create the mirror at `<locale>/blog/<slug>/index.html` + the Markdown mirror. Translate the body; keep field-shape parity. Each locale page **must** carry `hreflang` alternates linking to the others — symmetric (see memory:`canonical_links_symmetric`).
5. **Add the hero image.** Optimised: WebP for hero, JPEG fallback. Path convention: `blog/<slug>/hero.webp` + `hero.jpg`. Width ~ 1600 px; height ratio 16:9 or 4:3.
6. **Update the blog index page.** `blog/index.html` (or the framework's auto-generated index) lists posts newest-first. Update the listing in the same commit.
7. **Update sitemap.xml.** Add an entry for every locale of the new post, with `<xhtml:link rel="alternate" hreflang="<lang>" href="..."/>` siblings.
8. **Update the Atom feed** (`feed.xml` / `atom.xml`) with the new post's `<entry>` (id, title, published, updated, summary, content, author, link).
9. **Update `lastmod` on the homepage entry** of sitemap.xml — anything that links to the new post is itself "modified" for SEO purposes.

### Command 3 — Cache-bust CSS on every style addition

**Cache-bust is correctness, not optimisation.** A static-site CDN's CSS caching defeats edits silently if the filename doesn't change. The fix is filename-versioned CSS — every rule addition bumps the filename.

* Convention: `assets/style_<N>.css`, where `<N>` is a monotonic integer. New selector → new file → bump every reference in the site's HTML (head `<link href>`). Track the current N in a top-level `STYLE_VERSION` file or in the build config.
* The agent's authoring flow adds CSS only via this discipline. **Never** edit `style_<N>.css` in place after the first publish — bump N, copy + edit, update references.
* `sed`-renaming references across paths trips on multi-level relative paths (see memory:`sed_relative_path_quantifier`). Bump references by **filename**, not by pattern.

### Command 4 — Preview before publish

Cloudflare Pages preview URLs are the gate. Procedure:

1. **Push to a feature branch** (e.g. `post-<slug>`). Cloudflare Pages builds the preview within ~60 s.
2. **Open the preview URL** (`<sha>.<project>.pages.dev/blog/<slug>/`). The agent fetches it with `curl -sS -I` and `curl -sS` and verifies:
   * HTTP 200.
   * Title + hero render.
   * Hreflang alternates link correctly.
   * Sitemap.xml on the preview lists the post.
   * Atom feed includes the post.
3. **If the operator is in the loop** (first post, major design change), surface the preview URL to the operator and wait for sign-off. Otherwise the agent may merge autonomously after the checks pass.

### Command 5 — Publish (merge to main)

1. **Squash-merge** the feature branch to `main`. Squashing keeps the git log readable as one commit per post.
2. **Push.** Cloudflare Pages builds + deploys the production URL within ~60 s.
3. **Verify the live URL** (same shape as Command 4.2 but against the public URL). Live within 30-60 s after merge.
4. **Persist the publish event** to `state/publish-log.jsonl` with `{ts, channel:"blog", media_type:"post", slug, locale, url}`. The analytics skill consumes this.
5. **Memory: deployed-site changes must commit AND push, same turn.** A working-tree edit that the operator can't see on the deployed site is not a deploy — the agent flags any unpushed change as a publishing failure (see memory:`deployed_site_commit_and_push`).

### Command 6 — Cross-link to the new post from upstream channels

A new blog post is the canonical anchor for a content arc. The agent updates:

1. **Instagram caption** of any reel that drove traffic to this post — add the URL (IG strips clickability outside bio, but the URL is still copy-pasteable + serves as the SEO citation).
2. **X cross-posts** of the same reel — append the post URL (X auto-links).
3. **Newsletter** (if the brand runs one) — schedule the post into the next issue.
4. **The blog index** (already updated in Command 2.6) — re-deployed in Command 5.

### Command 7 — Update an existing post (corrections, additions)

Posts are versioned but not branched. Workflow:

1. **Edit the canonical source.** Bump the `updated_at` field.
2. **Re-render the HTML + locale siblings** (same as Command 2.3-2.4).
3. **Bump `<lastmod>` in sitemap.xml** for that URL.
4. **(Major rewrites)** add an "Updated YYYY-MM-DD" line near the top of the post. Honest about changes is a brand asset, not a liability.
5. **Push.** Same flow as Command 4-5.
6. **Optional Atom update.** Minor edits don't warrant a new feed entry; major rewrites do (use the `<published>` of the original entry + bump `<updated>`).

### Command 8 — Handle deploy failures

1. **Cloudflare Pages build fails.** Read the build log from the Pages dashboard or `gh api`. Fix the source error (broken HTML, missing asset, framework lint), push again.
2. **DNS / certificate errors.** Cloudflare Pages auto-provisions Let's Encrypt; first deploy after adding a custom domain can take 5-15 min for the cert. The agent flags this as "expected delay, not a failure" if the cert isn't ready yet.
3. **Stale CDN.** Cloudflare's CDN caches at the edge. After deploy, hard-purge:

   ```sh
   curl -sf -X POST "https://api.cloudflare.com/client/v4/zones/<ZONE_ID>/purge_cache" \
     -H "Authorization: Bearer <CF_API_TOKEN>" \
     -H "Content-Type: application/json" \
     -d '{"purge_everything":true}'
   ```

   Or purge only the affected URLs (`{"files":["https://...","https://..."]}`) — preferred for production.

## Pepe Arturo reference deployment

* **Domain:** `www.helmguild.com` (apex redirects to `www`).
* **Repo:** `helmut-hoffer-von-ankershoffen/helmguild.com`.
* **Stack:** pure static HTML + Markdown mirrors. No build step.
* **Locales:** EN primary at `/blog/<slug>/`, DE mirror at `/de/blog/<slug>/`.
* **Sitemap:** `/sitemap.xml` lists every canonical URL with hreflang alternates.
* **Atom feeds:** `/feed.xml` (EN), `/de/feed.xml` (DE).
* **Style versioning:** `assets/style_<N>.css`, current N tracked at top of `assets/`. New selector → bump.
* **Authored by:** "Pepe Arturo AI" byline on AI-generated posts; "Helmut Hoffer von Ankershoffen" on personal essays.
* **Recent posts:** see `/blog/` for the live index.

## Brand-specific overrides every operator should change

* Domain.
* Repo.
* Framework choice (Command 1.4).
* Locale set.
* Style versioning scheme (or framework's built-in cache-bust if the framework provides one).
* CDN purge command (specific to the operator's hosting choice).

## Operating constraints carried over

* **One canonical source, many surfaces** — Command 2.1 reads from the canonical store; the blog post is a projection, not an independent authoring.
* **Resumable stages** — every post is a separate feature branch; an interrupted publish resumes by pushing the branch again.
* **Schedule as state** — `published_at` in the canonical source drives when the agent runs Command 2 for that post.
* **Human gate** — Command 4 surfaces the preview URL to the operator for first posts + major design changes.
* **Symmetric canonical links** — every locale of a post links to every sibling; cross-channel posts include the canonical blog URL.
* **Commit AND push same turn** — a working-tree edit that's not pushed is not a deploy.
