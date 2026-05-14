#!/usr/bin/env bash
# veo-prompt-skeleton.sh — render a Veo 3 video prompt skeleton from a
# one-line content brief. Read-only; deterministic; no API calls.
#
# Pepe's house style for Veo prompts (per the
# `content-strategy-planning-optimization` skill in this plugin):
#
#   - SHOT — single, declared (medium / close-up / wide / overhead).
#   - SUBJECT — what's on screen, one clause.
#   - ACTION — verb-led, present tense.
#   - LIGHTING — explicit (golden hour, overcast, neon, candle, …).
#   - LENS — focal length or aesthetic hint (35mm, 85mm portrait, …).
#   - CAMERA — static / slow push / handheld / orbit.
#   - PACE — slow / medium / brisk (Pepe defaults to slow; agentic
#     content reads as composed, not frenetic).
#   - SOUND — described in words, not a music genre.
#   - DURATION — 5s / 8s / 10s (Veo 3 supports up to 60s on Pro).
#
# Usage:
#   veo-prompt-skeleton.sh "<brief in one line>"
#   veo-prompt-skeleton.sh --duration 10 "<brief>"
#   veo-prompt-skeleton.sh --shot wide --lighting "golden hour" "<brief>"
#
# Output: a Veo-ready prompt block on stdout. Exit 0.

set -euo pipefail

shot="medium"
lighting="overcast — flat, even, no harsh shadows"
lens="35mm"
camera="static, no movement"
pace="slow, composed"
sound="diegetic only — quiet room tone"
duration="8"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --shot)     shot="$2";     shift 2 ;;
    --lighting) lighting="$2"; shift 2 ;;
    --lens)     lens="$2";     shift 2 ;;
    --camera)   camera="$2";   shift 2 ;;
    --pace)     pace="$2";     shift 2 ;;
    --sound)    sound="$2";    shift 2 ;;
    --duration) duration="$2"; shift 2 ;;
    -h|--help)
      sed -n '1,/^set/p' "$0" | grep -E '^# ?' | sed 's/^# \{0,1\}//'
      exit 0 ;;
    --) shift; break ;;
    -*)
      echo "unknown option: $1" >&2; exit 64 ;;
    *)
      brief="$1"; shift ;;
  esac
done

brief="${brief:-}"
if [[ -z "$brief" ]]; then
  echo "usage: veo-prompt-skeleton.sh [--shot ...] [--duration ...] \"<brief>\"" >&2
  exit 64
fi

cat <<EOF
SHOT: ${shot}
SUBJECT: ${brief}
ACTION: $(printf '%s' "${brief}" | awk '{print tolower($1)}'), present-tense, single beat
LIGHTING: ${lighting}
LENS: ${lens}
CAMERA: ${camera}
PACE: ${pace}
SOUND: ${sound}
DURATION: ${duration}s
EOF
