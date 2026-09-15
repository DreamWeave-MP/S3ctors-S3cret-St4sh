#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

prepare

W=512
H=512

magick -size "${W}x${H}" xc:"$BG" \
    -fill none \
    -stroke "$VIOLET" \
    -strokewidth 4 \
    -draw 'rectangle 24,24 488,488' \
    -strokewidth 2 \
    -stroke "$PURPLE" \
    -draw 'rectangle 42,42 470,470' \
    -draw 'line 72,104 440,104' \
    -draw 'line 72,410 440,410' \
    -fill "$VIOLET" \
    -stroke none \
    -font "$FONT" \
    -pointsize 188 \
    -gravity center \
    -annotate +0-18 'C³' \
    -fill "$TEXT" \
    -pointsize 24 \
    -annotate +0+178 'CODE / CONTEXT / CONSEQUENCE' \
    -fill "$MUTED" \
    -pointsize 17 \
    -annotate +0+206 'COD3X' \
    "$OUTDIR/icon.png"

magick -size 1600x1600 xc:"$BG" \
    -fill none \
    -stroke "$VIOLET" \
    -strokewidth 5 \
    -draw 'rectangle 58,58 1542,1542' \
    -strokewidth 2 \
    -stroke "$PURPLE" \
    -draw 'rectangle 88,88 1512,1512' \
    -draw 'line 150,290 1450,290' \
    -draw 'line 150,1343 1450,1343' \
    -fill "$VIOLET" \
    -stroke none \
    -font "$FONT" \
    -pointsize 560 \
    -gravity center \
    -annotate +0-80 'C³' \
    -fill "$TEXT" \
    -pointsize 38 \
    -annotate +0+510 'CODE · CONTEXT · CONSEQUENCE' \
    -fill "$MUTED" \
    -pointsize 31 \
    -annotate +0+575 'COD3X / THE OPENMW LUA FIELD MANUAL' \
    -fill "$TEXT" \
    -pointsize 22 \
    -annotate +0+700 'WRITE BETTER OPENMW LUA. UNDERSTAND WHY IT WORKS.' \
    -fill "$MUTED" \
    -pointsize 18 \
    -annotate +0+1455 'API REFERENCE   //   LUALS   //   ENGINEERING   //   PERFORMANCE' \
    "$OUTDIR/badge.png"
