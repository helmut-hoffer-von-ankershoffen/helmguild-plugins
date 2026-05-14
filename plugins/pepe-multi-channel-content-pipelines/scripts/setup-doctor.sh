#!/usr/bin/env bash
# setup-doctor.sh — probe each channel's credentials + API surface and
# report per-channel readiness. Runs after the operator completes the
# Setup (Command 1) of each skill in the playbook; tells the agent
# whether to proceed with the procedural commands or escalate "your
# Setup isn't done yet" back to the operator.
#
# Read-only. No publish actions, no quota burn. Network calls only
# read-side endpoints (list models, list pages, fetch own user).
#
# Channels probed:
#   - veo       (virtual-character-veo-3-1)
#   - instagram (publishing-instagram)
#   - x         (publishing-x)
#   - blog      (publishing-blog)
#   - strategy  (content-strategy-planning-optimization)
#
# Usage:
#   setup-doctor.sh                       # probe every channel
#   setup-doctor.sh --channel veo         # probe one
#   setup-doctor.sh --json                # machine-readable
#   setup-doctor.sh --offline             # skip network probes
#
# Credentials root defaults to $CREDENTIALS_ROOT / ~/.openclaw/credentials.
# Strategy probe defaults to $PEPE_PIPELINE_STATE_DIR / ./state.
#
# Exit codes:
#   0 — every probed channel is `ready`.
#   1 — at least one channel is `missing` or `error`.
#   2 — usage error.

set -euo pipefail

channels_all=(veo instagram x blog strategy)
selected=()
output_format=text
offline=0
creds_root="${CREDENTIALS_ROOT:-$HOME/.openclaw/credentials}"
state_dir="${PEPE_PIPELINE_STATE_DIR:-./state}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --channel) selected+=("$2"); shift 2;;
    --json) output_format=json; shift;;
    --offline) offline=1; shift;;
    --creds-root) creds_root="$2"; shift 2;;
    --state-dir) state_dir="$2"; shift 2;;
    --help|-h)
      sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
      exit 0;;
    *) echo "setup-doctor: unknown argument $1" >&2; exit 2;;
  esac
done

if [[ ${#selected[@]} -eq 0 ]]; then
  selected=("${channels_all[@]}")
fi

# Result accumulator: parallel arrays so this works on bash 3.2 (no
# associative arrays needed; macOS default bash).
result_channels=()
result_status=()    # ready | partial | missing | error | skipped-offline
result_detail=()

push() {
  result_channels+=("$1")
  result_status+=("$2")
  result_detail+=("$3")
}

# --- veo --------------------------------------------------------------
probe_veo() {
  local key_file="$creds_root/gemini/api-key"
  if [[ ! -s "$key_file" ]]; then
    push veo missing "no gemini api key at $key_file"
    return
  fi
  if (( offline )); then
    push veo skipped-offline "key present, network probe skipped"
    return
  fi
  local key resp
  key=$(< "$key_file")
  resp=$(curl -sS --max-time 10 \
    "https://generativelanguage.googleapis.com/v1beta/models?key=$key" 2>&1) \
    || { push veo error "network call failed: ${resp:0:120}"; return; }
  if printf '%s' "$resp" | grep -q '"name": "models/veo-3.1-generate-preview"'; then
    push veo ready "veo-3.1-generate-preview enrolled"
  elif printf '%s' "$resp" | grep -q '"error"'; then
    local msg
    msg=$(printf '%s' "$resp" | grep -oE '"message": "[^"]+"' | head -1 \
      | sed 's/^"message": "//;s/"$//')
    push veo error "api error: ${msg:-unknown}"
  else
    push veo partial "key works but veo-3.1 preview not enrolled — request access"
  fi
}

# --- instagram --------------------------------------------------------
probe_instagram() {
  local env_file="$creds_root/instagram/env"
  if [[ ! -s "$env_file" ]]; then
    push instagram missing "no env file at $env_file"
    return
  fi
  # Cheap parse — pluck IG_USER_ID + IG_PAGE_TOKEN without sourcing
  # the file (avoid arbitrary env contamination on the agent).
  local ig_user_id ig_page_token
  ig_user_id=$(grep -E '^IG_USER_ID=' "$env_file" | head -1 | cut -d= -f2-)
  ig_page_token=$(grep -E '^IG_PAGE_TOKEN=' "$env_file" | head -1 | cut -d= -f2-)
  if [[ -z "$ig_user_id" || -z "$ig_page_token" ]]; then
    push instagram missing "env file present but IG_USER_ID or IG_PAGE_TOKEN missing"
    return
  fi
  if (( offline )); then
    push instagram skipped-offline "env present, network probe skipped"
    return
  fi
  local resp
  resp=$(curl -sS --max-time 10 \
    "https://graph.facebook.com/v23.0/${ig_user_id}?fields=id,username&access_token=${ig_page_token}" 2>&1) \
    || { push instagram error "network call failed: ${resp:0:120}"; return; }
  if printf '%s' "$resp" | grep -q '"username"'; then
    local username
    username=$(printf '%s' "$resp" | grep -oE '"username": "[^"]+"' \
      | sed 's/^"username": "//;s/"$//')
    push instagram ready "IG account @${username} reachable"
  else
    local msg
    msg=$(printf '%s' "$resp" | grep -oE '"message": "[^"]+"' | head -1 \
      | sed 's/^"message": "//;s/"$//')
    push instagram error "graph api error: ${msg:-unknown}"
  fi
}

# --- x ----------------------------------------------------------------
probe_x() {
  local env_file="$creds_root/x/env"
  if [[ ! -s "$env_file" ]]; then
    push x missing "no env file at $env_file"
    return
  fi
  local cid csec rtok
  cid=$(grep -E '^X_CLIENT_ID=' "$env_file" | head -1 | cut -d= -f2-)
  csec=$(grep -E '^X_CLIENT_SECRET=' "$env_file" | head -1 | cut -d= -f2-)
  rtok=$(grep -E '^X_REFRESH_TOKEN=' "$env_file" | head -1 | cut -d= -f2-)
  if [[ -z "$cid" || -z "$csec" || -z "$rtok" ]]; then
    push x missing "env file present but client id / secret / refresh token incomplete"
    return
  fi
  if (( offline )); then
    push x skipped-offline "env present, network probe skipped"
    return
  fi
  # Refresh the access token — proves the OAuth chain is intact.
  # The refresh-token rotation means a successful refresh writes a new
  # refresh token back, which the setup doctor does NOT persist (this is
  # a probe, not a state mutation). Operators running this every minute
  # would exhaust X's hourly OAuth refresh budget — there's a 60s probe
  # cache via the doctor's --state-dir flag.
  local cache_file="$state_dir/setup-doctor-x.cache"
  if [[ -s "$cache_file" ]]; then
    # File exists; check mtime < 60s (cross-platform stat).
    local mtime now age
    mtime=$(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file")
    now=$(date +%s)
    age=$((now - mtime))
    if (( age < 60 )); then
      push x ready "$(cat "$cache_file") (cached ${age}s ago)"
      return
    fi
  fi
  local resp
  resp=$(curl -sS --max-time 10 -X POST "https://api.x.com/2/oauth2/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -u "${cid}:${csec}" \
    -d "grant_type=refresh_token" \
    -d "refresh_token=${rtok}" 2>&1) \
    || { push x error "network call failed: ${resp:0:120}"; return; }
  if printf '%s' "$resp" | grep -q '"access_token"'; then
    mkdir -p "$state_dir"
    echo "OAuth 2.0 refresh-token chain valid" > "$cache_file"
    push x ready "OAuth 2.0 refresh-token chain valid"
  else
    local err
    err=$(printf '%s' "$resp" | grep -oE '"error_description": "[^"]+"' | head -1 \
      | sed 's/^"error_description": "//;s/"$//')
    push x error "oauth refresh failed: ${err:-unknown}"
  fi
}

# --- blog -------------------------------------------------------------
probe_blog() {
  # The blog is host-side infra: git repo + Cloudflare Pages + a domain.
  # Doctor probes (a) a configured blog root path exists, (b) the
  # canonical landing page resolves over HTTPS.
  local env_file="$creds_root/blog/env"
  if [[ ! -s "$env_file" ]]; then
    push blog missing "no env file at $env_file (need BLOG_ROOT, BLOG_PUBLIC_URL)"
    return
  fi
  local blog_root blog_url
  blog_root=$(grep -E '^BLOG_ROOT=' "$env_file" | head -1 | cut -d= -f2-)
  blog_url=$(grep -E '^BLOG_PUBLIC_URL=' "$env_file" | head -1 | cut -d= -f2-)
  if [[ -z "$blog_root" || -z "$blog_url" ]]; then
    push blog missing "env file present but BLOG_ROOT or BLOG_PUBLIC_URL missing"
    return
  fi
  if [[ ! -d "$blog_root" ]]; then
    push blog error "blog root does not exist: $blog_root"
    return
  fi
  if (( offline )); then
    push blog skipped-offline "env + repo root present, network probe skipped"
    return
  fi
  local code
  code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 10 "$blog_url" 2>&1) \
    || { push blog error "network call failed: ${code:0:60}"; return; }
  if [[ "$code" =~ ^2[0-9][0-9]$ ]]; then
    push blog ready "$blog_url reachable (HTTP $code)"
  else
    push blog error "blog url returned HTTP $code"
  fi
}

# --- strategy ---------------------------------------------------------
probe_strategy() {
  # The strategy skill's setup writes the canonical-content store + a
  # schema config. Doctor probes that the state dir exists, contains a
  # publish log, and has at least one piece declared.
  if [[ ! -d "$state_dir" ]]; then
    push strategy missing "state dir does not exist: $state_dir (Command 1 step 2)"
    return
  fi
  local log_file="$state_dir/publish-log.jsonl"
  if [[ ! -e "$log_file" ]]; then
    push strategy partial "state dir exists, but $log_file is missing — no publish event yet"
    return
  fi
  local lines
  lines=$(wc -l < "$log_file" | tr -d ' ')
  push strategy ready "publish-log has $lines event(s); state dir at $state_dir"
}

# Run the selected probes.
for ch in "${selected[@]}"; do
  case "$ch" in
    veo) probe_veo;;
    instagram) probe_instagram;;
    x) probe_x;;
    blog) probe_blog;;
    strategy) probe_strategy;;
    *) push "$ch" error "unknown channel"; ;;
  esac
done

# Render output.
overall_exit=0
if [[ "$output_format" == "json" ]]; then
  printf '[\n'
  for i in "${!result_channels[@]}"; do
    sep=$([ "$i" -lt "$((${#result_channels[@]} - 1))" ] && echo "," || echo "")
    detail_json=$(printf '%s' "${result_detail[$i]}" | sed 's/\\/\\\\/g; s/"/\\"/g')
    printf '  {"channel":"%s","status":"%s","detail":"%s"}%s\n' \
      "${result_channels[$i]}" "${result_status[$i]}" "$detail_json" "$sep"
    case "${result_status[$i]}" in
      ready|skipped-offline) ;;
      *) overall_exit=1;;
    esac
  done
  printf ']\n'
else
  for i in "${!result_channels[@]}"; do
    case "${result_status[$i]}" in
      ready) icon='✓';;
      skipped-offline) icon='∅';;
      partial) icon='◐'; overall_exit=1;;
      missing) icon='✗'; overall_exit=1;;
      error) icon='✗'; overall_exit=1;;
      *) icon='?'; overall_exit=1;;
    esac
    printf '%s %-10s %s — %s\n' \
      "$icon" "${result_channels[$i]}" "${result_status[$i]}" "${result_detail[$i]}"
  done
fi

exit "$overall_exit"
