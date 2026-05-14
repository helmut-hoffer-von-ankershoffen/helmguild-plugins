#!/usr/bin/env bash
# brand-identity-scaffold.sh — create the empty templates the
# `brand-visual-identity` skill's Setup (Command 1) walks an operator
# through filling in. Lower-friction entry for a new operator: instead
# of "build this directory and these files by hand", the scaffolder
# creates the skeleton + opens it for editing.
#
# Output: a directory tree at <BRAND_STYLE_GUIDE_PATH> with empty
# templates for character.md, disciplines/, palette.md, typography.md,
# scenes/, voice.md, off-brand.md, redo-criteria.md, refs/character/.
#
# Read-only beyond writing the templates. Refuses to overwrite an
# existing brand-identity store.
#
# Usage:
#   brand-identity-scaffold.sh --path <BRAND_STYLE_GUIDE_PATH> [--brand <name>]
#   BRAND_STYLE_GUIDE_PATH=~/Obsidian/vaults/MyBrand brand-identity-scaffold.sh
#
# Exit codes:
#   0 — created.
#   1 — path already populated, refusing to overwrite.
#   2 — usage error.

set -euo pipefail

path="${BRAND_STYLE_GUIDE_PATH:-}"
brand=""
disciplines_default="talking-head suit candid"
force=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --path) path="$2"; shift 2;;
    --brand) brand="$2"; shift 2;;
    --disciplines) disciplines_default="$2"; shift 2;;
    --force) force=1; shift;;
    --help|-h)
      sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
      exit 0;;
    *) echo "brand-identity-scaffold: unknown arg $1" >&2; exit 2;;
  esac
done

if [[ -z "$path" ]]; then
  echo "brand-identity-scaffold: --path or BRAND_STYLE_GUIDE_PATH required" >&2
  exit 2
fi
if [[ -z "$brand" ]]; then
  brand=$(basename "$path")
fi

# Refuse to overwrite unless --force.
if [[ -e "$path/character.md" && "$force" -eq 0 ]]; then
  echo "brand-identity-scaffold: $path/character.md already exists; pass --force to overwrite" >&2
  exit 1
fi

mkdir -p "$path"/{disciplines,scenes,refs/character}

cat > "$path/character.md" <<EOF
# $brand — character one-pager

<!-- Fill in: who is the brand's character? A single paragraph + the
     headshot grid below. -->

## One-paragraph identity

(Write a single paragraph: name, visible-age range, body type, signature
visual marks, default posture, voice tone. Example for Pepe Arturo:
"Pepe Arturo is a small calm frog monk in a brown rope-belt habit.
Sitting cross-legged is the default posture. Soft male English voice,
slow cadence.")

## Headshot grid

(Drop 3-6 reference images under refs/character/ — different lighting +
moods. List each with a one-line description here.)

- refs/character/<file>.jpg — (description)
EOF

cat > "$path/voice.md" <<EOF
# $brand — voice + tone

## Spoken voice across surfaces

(One paragraph describing the brand's spoken voice. Example for Pepe:
"calm, grounded, succinct, sport-flavoured English, no Italian, no
filler, slow cadence". Be specific.)

## On-brand phrases

(Verbatim phrases that are signature for the brand.)

-

## Off-brand phrases

(Phrases the brand never uses.)

-

## Brand emoji signature

(One emoji + optional context emojis used on every public post. Example
for Pepe: 🍝 on every post; sport cameos pair with 🏊‍♂️ / 🏃‍♂️ / 🚴‍♂️ / 🏋️‍♂️.)

- Primary:
EOF

cat > "$path/palette.md" <<EOF
# $brand — colour palette

## Primary (3)

| Name | Hex | Use |
|------|-----|-----|

## Secondary (2)

| Name | Hex | Use |
|------|-----|-----|

(Hex codes — used by the blog CSS, by image-generation prompts when
ordering hero/thumbnail images, and by physical merch if/when shipped.)
EOF

cat > "$path/typography.md" <<EOF
# $brand — typography

## Headline typeface

-

## Body typeface

-

(Used by the blog. Used in image-gen prompts that order text-on-image.)
EOF

cat > "$path/off-brand.md" <<EOF
# $brand — off-brand list

(What the brand never does. Each entry: one-line description; optionally
a "before/after" pair — wrong example + on-brand replacement.)

## Outfit / gear combinations that are off-brand

-

## Lighting setups that misrepresent the brand

-

## Character poses / expressions that contradict the voice

-

## Backgrounds that pull focus

-

## Third-party logos / trademarks

-
EOF

cat > "$path/redo-criteria.md" <<EOF
# $brand — redo criteria

(Binary, not feelings. A generated shot trips one of these → redo.)

- [ ] Face drifts mid-shot.
- [ ] Outfit doesn't match the discipline contract.
- [ ] Audio missing when the prompt asked for VO (likely Veo RAI rejection; soften + retry).
- [ ] Background pulls focus from the character.
- [ ] An entry from off-brand.md is present.
- [ ] Frame-rate stutter.
- [ ] (Add brand-specific criteria here.)

None of the above + on-brand within the discipline contract → ship.
EOF

# Discipline templates.
for d in $disciplines_default; do
  if [[ ! -e "$path/disciplines/$d.md" ]]; then
    cat > "$path/disciplines/$d.md" <<EOF
# $brand discipline: $d

<!-- One paragraph contract per discipline. The Veo prompt assembly reads
     this to compose the per-shot prompt fragment. -->

## Setting + framing

-

## Outfit / gear (brand-name-softened)

(Example: instead of "Nike running cap" write "a black running cap" —
Veo's RAI filter trips on literal embroidered brand names.)

-

## Lighting + camera

(Focal length, shot type, time-of-day lighting, mood.)

-

## Voice cadence + tone for spoken lines

-

## Audio ambience hints

-
EOF
  fi
done

# One empty scene template for the operator to clone.
cat > "$path/scenes/_template.md" <<EOF
# $brand scene template: <slug>

<!-- Copy this file to scenes/<your-slug>.md and fill in. Each scene is a
     recurring visual motif the brand revisits. -->

## Sketch in words

(3-5 sentences. What does this scene look like?)

## Where it works

(Which arc, what hook.)

## Pre-resolved gear / refs / cameos

(What's already known about this scene — discipline contract, cameo, etc.)

## Stock Veo prompt fragment

\`\`\`
(Paste a tested Veo prompt fragment here.)
\`\`\`
EOF

cat > "$path/refs/character/README.md" <<EOF
# Character reference images

Drop 3-6 JPEGs here, 1024×1024 each. Different lighting, different
moods. The Veo prompt assembly references these by filename.

Conventions:
- File name: descriptive-slug_1024.jpg
- Aspect: square, 1024 × 1024.
- Format: JPEG (Veo prefers; convert HEIC / PNG with sips / ffmpeg).
EOF

cat > "$path/README.md" <<EOF
# $brand — visual identity

Authored per the brand-visual-identity skill in the pepe-multi-channel-content-pipelines plugin.

## Files

- character.md — character one-pager + headshot grid.
- voice.md — voice + tone rules + emoji signature.
- palette.md — colour palette (hex codes).
- typography.md — headline + body typefaces.
- disciplines/ — one .md per recurring scene category.
- scenes/ — scene template library; clone _template.md for each.
- off-brand.md — what the brand never does.
- redo-criteria.md — binary redo criteria.
- refs/character/ — character reference images (1024 × 1024 JPEG).

## Authored

$(date -u +"%Y-%m-%d") via brand-identity-scaffold.sh.
EOF

echo "brand-identity-scaffold: wrote skeleton to $path"
echo ""
echo "Next steps:"
echo "  1. Open $path/character.md and write the one-paragraph identity."
echo "  2. Drop 3-6 character reference JPEGs into $path/refs/character/."
echo "  3. Fill in each $path/disciplines/<name>.md contract."
echo "  4. Author $path/voice.md, palette.md, typography.md, off-brand.md, redo-criteria.md."
echo "  5. Clone $path/scenes/_template.md to scenes/<slug>.md for each recurring scene."
echo "  6. Persist BRAND_STYLE_GUIDE_PATH=$path in ~/.openclaw/credentials/brand/env."
echo "  7. Run scripts/setup-doctor.sh --channel brand-identity to verify (once that probe is wired)."
exit 0
