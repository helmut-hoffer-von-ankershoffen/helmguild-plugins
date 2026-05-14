#!/usr/bin/env bash
# test-scripts-blog-post-scaffold.sh — exercises the bundled
# blog-post-scaffold helper.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER="$SCRIPT_DIR/../scripts/blog-post-scaffold.sh"
[[ -x "$HELPER" ]] || { echo "helper missing or not executable: $HELPER" >&2; exit 1; }

pass=0; fail=0
ok()  { printf '✓ %s\n' "$*"; pass=$((pass+1)); }
err() { printf '✗ %s\n' "$*" >&2; fail=$((fail+1)); }

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# 1. Happy path EN.
if "$HELPER" \
     --slug "hello-world" \
     --title "Hello, world" \
     --summary "First post" \
     --blog-root "$tmpdir" >/dev/null; then
  if [[ -f "$tmpdir/blog/hello-world/index.md" && -f "$tmpdir/blog/hello-world/index.html" ]]; then
    ok "EN scaffold creates both files"
  else
    err "EN scaffold missing one file"
  fi
else
  err "EN scaffold exit non-zero"
fi

# 2. Markdown carries frontmatter.
if grep -q '^title: Hello, world$' "$tmpdir/blog/hello-world/index.md"; then
  ok "frontmatter title present"
else
  err "frontmatter title missing"
fi

# 3. HTML carries canonical link.
if grep -q '<link rel="canonical"' "$tmpdir/blog/hello-world/index.html"; then
  ok "HTML canonical link present"
else
  err "HTML canonical link missing"
fi

# 4. HTML carries og:title.
if grep -q 'og:title' "$tmpdir/blog/hello-world/index.html"; then
  ok "HTML og:title present"
else
  err "HTML og:title missing"
fi

# 5. DE locale.
if "$HELPER" \
     --slug "hallo-welt" \
     --title "Hallo, Welt" \
     --summary "Erster Beitrag" \
     --blog-root "$tmpdir" \
     --locale "de" >/dev/null; then
  if [[ -f "$tmpdir/de/blog/hallo-welt/index.md" ]]; then
    ok "DE locale uses /de/blog/ prefix"
  else
    err "DE locale did not write to /de/blog/"
  fi
else
  err "DE scaffold exit non-zero"
fi

# 6. Invalid slug rejected.
if "$HELPER" \
     --slug "Bad_Slug!" \
     --title "x" \
     --summary "x" \
     --blog-root "$tmpdir" >/dev/null 2>&1; then
  err "invalid slug should be rejected"
else
  ok "invalid slug rejected"
fi

# 7. Refuses to overwrite existing post.
if "$HELPER" \
     --slug "hello-world" \
     --title "Hello again" \
     --summary "Duplicate" \
     --blog-root "$tmpdir" >/dev/null 2>&1; then
  err "overwrite should be rejected"
else
  ok "overwrite rejected"
fi

# 8. Missing args trip exit 2.
code=0
"$HELPER" --slug "x" >/dev/null 2>&1 || code=$?
if [[ "$code" == 2 ]]; then
  ok "missing required args exits 2"
else
  err "missing required args should exit 2 (got $code)"
fi

# 9. BLOG_AUTHOR env var honoured.
BLOG_AUTHOR="Pepe Arturo AI" "$HELPER" \
  --slug "author-test" \
  --title "Author test" \
  --summary "x" \
  --blog-root "$tmpdir" >/dev/null
if grep -q '^author: Pepe Arturo AI$' "$tmpdir/blog/author-test/index.md"; then
  ok "BLOG_AUTHOR env var sets author"
else
  err "BLOG_AUTHOR env var did not propagate"
fi

# 10. --author flag overrides env.
BLOG_AUTHOR="From Env" "$HELPER" \
  --slug "author-override" \
  --title "Author override" \
  --summary "x" \
  --blog-root "$tmpdir" \
  --author "From Flag" >/dev/null
if grep -q '^author: From Flag$' "$tmpdir/blog/author-override/index.md"; then
  ok "--author flag overrides env"
else
  err "--author flag should override env"
fi

# Summary.
printf '\n%d passed, %d failed\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
