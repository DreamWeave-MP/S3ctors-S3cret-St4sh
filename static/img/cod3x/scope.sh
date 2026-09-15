#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

prepare

W=1300
H=900

magick -size "${W}x${H}" xc:"$BG" \
    -fill none \
    -stroke "$VIOLET" \
    -strokewidth 2 \
    -draw 'rectangle 20,20 1280,880' \
    -strokewidth 1 \
    -draw 'line 38,38 1262,38' \
    -draw 'line 38,862 1262,862' \
    -stroke "$PURPLE" \
    -draw 'line 64,188 1236,188' \
    -draw 'line 64,832 1236,832' \
    -fill "$TEXT" \
    -stroke none \
    -font "$FONT" \
    -pointsize 22 \
    -annotate +64+82 'C³ / CODE · CONTEXT · CONSEQUENCE' \
    -fill "$VIOLET" \
    -pointsize 62 \
    -annotate +64+155 'WHAT COD3X CONTAINS' \
    -fill "$MUTED" \
    -pointsize 16 \
    -annotate +68+224 'A field manual for writing, understanding, and repairing OpenMW Lua.' \
    "$OUTDIR/scope-base.png"

declare -a titles=(
    'ZERO TO HERO'
    'API REFERENCE'
    'LUALS TOOLING'
    'GOOD DESIGNS'
    'PERFORMANCE'
    'PAID FOR WITH BLOOD'
)
declare -a details=(
    'Start with Lua. Build a working mod.'
    'Know what exists before inventing it.'
    'Make the editor understand OpenMW.'
    'Follow abstractions that earned their name.'
    'Measure the work shape, not the mythology.'
    'Learn from the failures that survived.'
)
declare -a colors=("$GREEN" "$VIOLET" "$BLUE" "$GOLD" '#ff8f70' "$MUTED")

layout="$OUTDIR/scope-cards.png"
magick -size "${W}x${H}" xc:none \
    -fill none \
    -stroke "$PURPLE" \
    -strokewidth 1 \
    -draw 'roundrectangle 64,270 608,410 6,6' \
    -draw 'roundrectangle 692,270 1236,410 6,6' \
    -draw 'roundrectangle 64,440 608,580 6,6' \
    -draw 'roundrectangle 692,440 1236,580 6,6' \
    -draw 'roundrectangle 64,610 608,750 6,6' \
    -draw 'roundrectangle 692,610 1236,750 6,6' \
    "$layout"

for index in "${!titles[@]}"; do
    if (( index % 2 == 0 )); then
        x=64
    else
        x=692
    fi
    y=$((270 + (index / 2) * 170))

    magick "$layout" \
        -fill "${colors[$index]}" \
        -stroke none \
        -font "$FONT" \
        -pointsize 20 \
        -annotate "+$((x + 24))+$((y + 46))" "${titles[$index]}" \
        -fill "$TEXT" \
        -pointsize 15 \
        -annotate "+$((x + 24))+$((y + 88))" "${details[$index]}" \
        "$layout.next"
    mv "$layout.next" "$layout"
done

magick "$OUTDIR/scope-base.png" "$layout" -compose over -composite "$OUTDIR/scope.png"
rm "$OUTDIR/scope-base.png" "$layout"
