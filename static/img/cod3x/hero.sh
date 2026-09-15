#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

prepare

W=1300
H=372

magick -size "${W}x${H}" xc:"$BG" \
    -fill none \
    -stroke "$VIOLET" \
    -strokewidth 2 \
    -draw 'rectangle 10,10 1290,362' \
    -strokewidth 1 \
    -draw 'rectangle 25,25 1275,347' \
    -stroke "$PURPLE" \
    -draw 'line 54,78 1246,78' \
    -draw 'line 54,315 1246,315' \
    -fill "$TEXT" \
    -stroke none \
    -gravity northeast \
    -font "$FONT" \
    -pointsize 92 \
    -annotate +56+102 'COD3X' \
    -fill "$VIOLET" \
    -pointsize 20 \
    -annotate +60+195 'THE OPENMW LUA FIELD MANUAL' \
    -fill "$TEXT" \
    -pointsize 14 \
    -annotate +60+255 'WRITE BETTER OPENMW LUA. UNDERSTAND WHY IT WORKS.' \
    -fill "$MUTED" \
    -pointsize 11 \
    -annotate +60+327 'API REFERENCE   //   LUALS TOOLING   //   ENGINEERING   //   PERFORMANCE' \
    "$OUTDIR/hero-base.png"
mv "$OUTDIR/hero-base.png" "$OUTDIR/nexusHeader.png"
