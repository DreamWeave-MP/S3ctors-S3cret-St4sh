#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-all}"
CROWBAR="${2:-crowbar.png}"

FONT_REG="${FONT_REG:-./OperationNapalm-Regular.ttf}"
FONT_ITAL="${FONT_ITAL:-./OperationNapalm-Italic.ttf}"
FONT_UI="${FONT_UI:-./DejaVuLGCSansMono.ttf}"

W=1300
H=372

BG="#090909"
IVORY="#e8e1d2"
PAPER="#cfc6bc"
PURPLE="#5c2a75"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

check_file() {
    [[ -f "$1" ]] || {
        echo "Missing file: $1" >&2
        exit 1
    }
}

check_file "$CROWBAR"
check_file "$FONT_REG"
check_file "$FONT_ITAL"

make_base() {

    magick -size ${W}x${H} xc:"$BG" \
        \
        -fill none \
        -stroke "$IVORY" \
        -strokewidth 2 \
        -draw "rectangle 10,10 1290,362" \
        \
        -fill none \
        -stroke "$IVORY" \
        -strokewidth 1 \
        -draw "rectangle 25,25 1275,347" \
        \
        -stroke "$IVORY" \
        -strokewidth 1 \
        -draw "line 54,91 1246,91" \
        -draw "line 54,314 1246,314" \
        \
        "$TMP/base.png"
}

make_left_text() {

    magick -size ${W}x${H} xc:none \
        \
        -fill "$IVORY" \
        -font "$FONT_REG" \
        -pointsize 30 \
        -annotate +55+56 \
            'H3 // AUXILIARY SYSTEMS' \
        \
        -fill "$IVORY" \
        -font "$FONT_UI" \
        -pointsize 12 \
        -annotate +56+80 \
            'OPENMW AUXILIARY DEVELOPMENT MATERIAL' \
        \
        -fill "$IVORY" \
        -font "$FONT_REG" \
        -pointsize 78 \
        -annotate +62+190 \
            'H3LP YOURS3LF' \
        \
        -fill "$IVORY" \
        -font "$FONT_UI" \
        -pointsize 18 \
        -annotate +66+226 \
            'UNAUTHORIZED STANDARD LIBRARY' \
        \
        -fill "$IVORY" \
        -font "$FONT_UI" \
        -pointsize 11 \
        -annotate +66+338 \
            'CONTROL: H3-OMW-001    DISTRIBUTION: UNRESTRICTED' \
        \
        "$TMP/left_text.png"
}

# Dossier panel
make_panel() {

    # Manila
    magick -size ${W}x${H} xc:none \
        -fill "$PAPER" \
        -stroke none \
        -draw "polygon \
            860,100 \
            1235,104 \
            1241,294 \
            872,298" \
        "$TMP/panel_backer.png"

    # Black
    magick -size ${W}x${H} xc:none \
        -fill "#050505" \
        -stroke none \
        -draw "polygon \
            880,119 \
            1216,122 \
            1221,275 \
            890,278" \
        "$TMP/panel_black.png"

    # Window mask
    magick -size ${W}x${H} xc:none \
        -fill white \
        -stroke none \
        -draw "polygon \
            880,119 \
            1216,122 \
            1221,275 \
            890,278" \
        "$TMP/panel_mask.png"
}

make_h3() {

    magick -size ${W}x${H} xc:none \
        -fill "$IVORY" \
        -font "$FONT_REG" \
        -kerning 3 \
        -pointsize 168 \
        -gravity northwest \
        -annotate +950+135 \
            'H3' \
        "$TMP/h3_full.png"

    magick \
        "$TMP/h3_full.png" \
        "$TMP/panel_mask.png" \
        -compose DstIn \
        -composite \
        "$TMP/h3_clipped.png"
}

make_crowbar() {

    magick "$CROWBAR" \
        -resize "205x255" \
        -background none \
        -rotate -5 \
        "$TMP/crowbar_raw.png"

    magick \
        "$TMP/crowbar_raw.png" \
        \( \
            +clone \
            -background black \
            -shadow 30x3+3+4 \
        \) \
        +swap \
        -background none \
        -layers merge \
        +repage \
        "$TMP/crowbar.png"
}

make_h3_front() {

    magick -size ${W}x${H} xc:none \
        -fill white \
        -stroke none \
        -draw "rectangle 968,94 1016,198" \
        "$TMP/h3_front_mask.png"

    magick \
        "$TMP/h3_clipped.png" \
        "$TMP/h3_front_mask.png" \
        -compose DstIn \
        -composite \
        "$TMP/h3_front.png"
}

build_clean() {

    make_base
    make_left_text
    make_panel
    make_h3
    make_crowbar
    make_h3_front

    magick \
        "$TMP/base.png" \
        "$TMP/left_text.png" \
        -composite \
        "$TMP/clean_01.png"

    magick \
        "$TMP/clean_01.png" \
        "$TMP/panel_backer.png" \
        -composite \
        "$TMP/clean_02.png"

    magick \
        "$TMP/clean_02.png" \
        "$TMP/panel_black.png" \
        -composite \
        "$TMP/clean_03.png"

    magick \
        "$TMP/clean_03.png" \
        "$TMP/h3_clipped.png" \
        -composite \
        "$TMP/clean_04.png"

    magick \
        "$TMP/clean_04.png" \
        "$TMP/crowbar.png" \
        -geometry +1015+70 \
        -composite \
        "$TMP/clean_05.png"

    magick \
        "$TMP/clean_05.png" \
        "$TMP/h3_front.png" \
        -composite \
        "./nexusHeaderClean.png"
}

make_approved() {

    magick \
        -background none \
        -fill "$PURPLE" \
        -font "$FONT_ITAL" \
        -pointsize 25 \
        label:'APPROVED? LOL' \
        -rotate -2 \
        "$TMP/approved.png"
}

make_dust() {

    magick -size ${W}x${H} xc:black \
        +noise Random \
        -colorspace Gray \
        -threshold 86% \
        -transparent black \
        -fill "$IVORY" \
        -opaque white \
        -channel a \
        -evaluate set 6% \
        +channel \
        "$TMP/dust.png"
}

build_classified() {

    [[ -f "./nexusHeaderClean.png" ]] || build_clean

    make_approved
    make_dust

    magick \
        "./nexusHeaderClean.png" \
        \
        "$TMP/approved.png" \
            -gravity southwest \
            -geometry +57+66 \
            -composite \
        \
        "$TMP/dust.png" \
            -gravity northwest \
            -compose over \
            -composite \
        \
        -attenuate 0.012 \
        +noise Gaussian \
        \
        "./nexusHeader.png"

    rm ./nexusHeaderClean.png
    echo "Wrote: ./nexusHeader.png"
}

build_classified
