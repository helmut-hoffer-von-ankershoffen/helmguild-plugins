#!/usr/bin/env bash
# blog-post-scaffold.sh — render a static-site blog-post skeleton (HTML
# + Markdown mirror) at the operator's canonical post-layout path. No
# git operations; no network. Designed to be the first command of the
# publishing-blog skill's "author a post" workflow.
#
# Output: writes <blog_root>/<slug>/index.html and index.md (creating
# directories as needed). Exits 0 on success, 1 on validation failure.
#
# Usage:
#   blog-post-scaffold.sh --slug <slug> --title "<title>" \
#       --summary "<one-line summary>" \
#       --blog-root <path> [--author "<name>"] [--locale en]
#
#   BLOG_AUTHOR="Pepe Arturo AI" \
#   blog-post-scaffold.sh --slug mandatory-mentoring --title "..." ...
#
# Slug validation: must be lowercase kebab-case (^[a-z][a-z0-9-]*$) so
# the URL is stable and the file path is predictable.

set -euo pipefail

slug=""
title=""
summary=""
blog_root=""
locale="en"
author="${BLOG_AUTHOR:-Anonymous}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --slug) slug="$2"; shift 2;;
    --title) title="$2"; shift 2;;
    --summary) summary="$2"; shift 2;;
    --blog-root) blog_root="$2"; shift 2;;
    --locale) locale="$2"; shift 2;;
    --author) author="$2"; shift 2;;
    --help|-h)
      sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
      exit 0;;
    --) shift; break;;
    *) echo "blog-post-scaffold: unknown argument $1" >&2; exit 2;;
  esac
done

# Required-arg check.
missing=()
[[ -z "$slug" ]] && missing+=("--slug")
[[ -z "$title" ]] && missing+=("--title")
[[ -z "$summary" ]] && missing+=("--summary")
[[ -z "$blog_root" ]] && missing+=("--blog-root")
if [[ ${#missing[@]} -gt 0 ]]; then
  echo "blog-post-scaffold: missing required: ${missing[*]}" >&2
  exit 2
fi

# Slug validation.
if ! printf '%s' "$slug" | grep -qE '^[a-z][a-z0-9-]*$'; then
  echo "blog-post-scaffold: invalid slug \"$slug\" — must match ^[a-z][a-z0-9-]*$" >&2
  exit 1
fi

# Locale path prefix.
case "$locale" in
  en) locale_prefix="";;
  *) locale_prefix="/$locale";;
esac

# Resolve target directory. blog_root is e.g.
# /Users/openclaw/.openclaw/workspace/sites/helmguild.com.
post_dir="${blog_root%/}${locale_prefix}/blog/$slug"

if [[ -e "$post_dir/index.html" || -e "$post_dir/index.md" ]]; then
  echo "blog-post-scaffold: refusing to overwrite existing post at $post_dir" >&2
  exit 1
fi

mkdir -p "$post_dir"

published_at=$(date -u +"%Y-%m-%d")

cat > "$post_dir/index.md" <<EOF
---
title: $title
slug: $slug
locale: $locale
published_at: $published_at
author: $author
summary: $summary
---

# $title

_${summary}_

Published $published_at by $author.

<!-- Body starts here. Edit this Markdown — the agent re-renders the HTML
mirror at index.html on the next run of the publishing-blog skill. -->
EOF

cat > "$post_dir/index.html" <<EOF
<!DOCTYPE html>
<html lang="$locale">
<head>
  <meta charset="utf-8">
  <title>$title — $author</title>
  <meta name="description" content="$summary">
  <link rel="canonical" href="https://www.helmguild.com${locale_prefix}/blog/$slug/">
  <meta property="og:title" content="$title">
  <meta property="og:description" content="$summary">
  <meta property="og:type" content="article">
  <meta property="article:published_time" content="${published_at}T00:00:00Z">
  <meta property="article:author" content="$author">
</head>
<body>
  <article>
    <header>
      <h1>$title</h1>
      <p class="byline">Published $published_at by $author</p>
      <p class="summary"><em>$summary</em></p>
    </header>
    <!-- Body: render from index.md. -->
  </article>
</body>
</html>
EOF

echo "blog-post-scaffold: created $post_dir/index.{md,html}"
echo "Next steps:"
echo "  1. Edit $post_dir/index.md with the canonical body."
echo "  2. Re-render index.html from the Markdown (or have the publishing-blog skill do it)."
echo "  3. Update sitemap.xml + Atom feed (publishing-blog Command 2.7-2.8)."
echo "  4. Push on a feature branch — Cloudflare Pages preview URL within ~60s."
exit 0
