#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-all}"
CROWBAR="${2:-crowbar.png}"

FONT_REG="${FONT_REG:-./OperationNapalm-Regular.ttf}"
FONT_ITAL="${FONT_ITAL:-./OperationNapalm-Italic.ttf}"
FONT_UI="${FONT_UI:-./DejaVuLGCSansMono.ttf}"
OUTDIR="${OUTDIR:-out}"

W=1600
H=1600

BG="#0a0a0a"
IVORY="#e8e1d2"
PAPER="#cfc6bc"

RED="#8f1d2c"
PURPLE="#5c2a75"

HEADER_X=120
HEADER_Y=145

SUBHEAD_X=120
SUBHEAD_Y=176

BOTTOM_TITLE_Y=215
BOTTOM_SUB_Y=150
BOTTOM_META_Y=102

H3_POINTSIZE=520
H3_KERNING=8
H3_OFFSET_Y=-55

CROWBAR_SIZE="1080x1080"
CROWBAR_ROTATE="-4"
CROWBAR_GEOM="+250+210"

ICON_W=512
ICON_H=512

ICON_H3_POINTSIZE=215
ICON_CROWBAR_SIZE="345x345"
ICON_CROWBAR_ROTATE="-4"
ICON_CROWBAR_GEOM="+78+58"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

need() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "Missing dependency: $1" >&2
        exit 1
    }
}

check_file() {
    [[ -f "$1" ]] || {
        echo "Missing file: $1" >&2
        exit 1
    }
}

need magick
check_file "$CROWBAR"
check_file "$FONT_REG"
check_file "$FONT_ITAL"

mkdir -p "$OUTDIR"

make_base_badge() {

    magick -size ${W}x${H} xc:"$BG" \
        -stroke "$IVORY" -strokewidth 4 -fill none \
            -draw "rectangle 48,48 1552,1552" \
        -stroke "$IVORY" -strokewidth 2 -fill none \
            -draw "rectangle 78,78 1522,1522" \
        -stroke "$IVORY" -strokewidth 2 \
            -draw "line 120,195 1480,195" \
            -draw "line 120,1410 1480,1410" \
        -stroke "$IVORY" -strokewidth 2 -fill none \
            -draw "rectangle 210,265 1390,1170" \
        "$TMP/base.png"
}

make_badge_text() {

    magick -size ${W}x${H} xc:none \
        \
        -fill "$IVORY" \
        -font "$FONT_REG" \
        -pointsize 52 \
        -annotate +${HEADER_X}+${HEADER_Y} \
            'H3 // AUXILIARY SYSTEMS' \
        \
        -fill "$IVORY" \
        -font "$FONT_UI" \
        -pointsize 24 \
        -annotate +${SUBHEAD_X}+${SUBHEAD_Y} \
            'OPENMW AUXILIARY DEVELOPMENT MATERIAL' \
        \
        -fill "$IVORY" \
        -font "$FONT_REG" \
        -pointsize 96 \
        -gravity south \
        -annotate +0+${BOTTOM_TITLE_Y} \
            'H3LP YOURS3LF' \
        \
        -fill "$IVORY" \
        -font "$FONT_UI" \
        -pointsize 28 \
        -gravity south \
        -annotate +0+${BOTTOM_SUB_Y} \
            'UNAUTHORIZED STANDARD LIBRARY' \
        \
        -fill "$IVORY" \
        -font "$FONT_UI" \
        -pointsize 22 \
        -gravity south \
        -annotate +0+${BOTTOM_META_Y} \
            'CONTROL: H3-OMW-001    DISTRIBUTION: UNRESTRICTED' \
        \
        "$TMP/text.png"
}

make_panel_layers() {

    # manila
    magick -size ${W}x${H} xc:none \
        -fill "$PAPER" \
        -stroke none \
        -draw "polygon \
            230,275 \
            1335,272 \
            1352,1145 \
            248,1158" \
        "$TMP/panel_backer.png"

    # black
    magick -size ${W}x${H} xc:none \
        -fill "#050505" \
        -stroke none \
        -draw "polygon \
            265,305 \
            1305,300 \
            1318,1112 \
            282,1124" \
        "$TMP/panel_fill.png"

    # alpha mask
    magick -size ${W}x${H} xc:none \
        -fill white \
        -stroke none \
        -draw "polygon \
            265,305 \
            1305,300 \
            1318,1112 \
            282,1124" \
        "$TMP/panel_mask.png"
}

make_h3_layers() {

    magick -size ${W}x${H} xc:none \
        -fill "$IVORY" \
        -font "$FONT_REG" \
        -kerning "$H3_KERNING" \
        -pointsize "$H3_POINTSIZE" \
        -gravity center \
        -annotate +0${H3_OFFSET_Y} 'H3' \
        "$TMP/h3_full.png"

    # Clip H3 into central black placard
    magick \
        "$TMP/h3_full.png" \
        "$TMP/panel_mask.png" \
        -compose DstIn \
        -composite \
        "$TMP/h3_clipped.png"

    # Foreground pieces of H3 that pass over crowbar
    magick -size ${W}x${H} xc:none \
        -fill white \
        -stroke none \
        -draw "rectangle 400,470 640,955" \
        -draw "rectangle 900,470 1105,625" \
        -draw "rectangle 835,770 1115,1010" \
        "$TMP/h3_frontmask.png"

    magick \
        "$TMP/h3_clipped.png" \
        "$TMP/h3_frontmask.png" \
        -compose DstIn \
        -composite \
        "$TMP/h3_front.png"
}

prepare_crowbar() {

    magick "$CROWBAR" \
        -resize "$CROWBAR_SIZE" \
        -background none \
        -rotate "$CROWBAR_ROTATE" \
        "$TMP/crowbar_scaled.png"

    magick \
        "$TMP/crowbar_scaled.png" \
        \( \
            +clone \
            -background black \
            -shadow 40x5+5+7 \
        \) \
        +swap \
        -background none \
        -layers merge \
        +repage \
        "$TMP/crowbar_shadowed.png"
}

build_clean_badge() {

    make_base_badge
    make_badge_text
    make_panel_layers
    make_h3_layers
    prepare_crowbar

    magick \
        "$TMP/base.png" \
        "$TMP/text.png" \
        -composite \
        "$TMP/clean_01.png"

    magick \
        "$TMP/clean_01.png" \
        "$TMP/panel_backer.png" \
        -composite \
        "$TMP/clean_02.png"

    magick \
        "$TMP/clean_02.png" \
        "$TMP/panel_fill.png" \
        -composite \
        "$TMP/clean_03.png"

    magick \
        "$TMP/clean_03.png" \
        "$TMP/h3_clipped.png" \
        -composite \
        "$TMP/clean_04.png"

    cp "$TMP/clean_04.png" "$TMP/clean_05.png"

    magick \
        "$TMP/clean_05.png" \
        "$TMP/crowbar_shadowed.png" \
        -geometry "$CROWBAR_GEOM" \
        -composite \
        "$TMP/clean_06.png"

    magick \
        "$TMP/clean_06.png" \
        "$TMP/h3_front.png" \
        -composite \
        "$OUTDIR/h3_badge_clean_v6.png"

    echo "Wrote: $OUTDIR/h3_badge_clean_v6.png"
}

build_icon() {

    local IW=$ICON_W
    local IH=$ICON_H

    magick -size ${IW}x${IH} xc:none \
        -stroke "$IVORY" \
        -strokewidth 3 \
        -fill "$BG" \
        -draw "rectangle 18,18 494,494" \
        -stroke "$IVORY" \
        -strokewidth 1.5 \
        -fill none \
        -draw "rectangle 30,30 482,482" \
        "$TMP/icon_base.png"

    # dossier sheet
    magick -size ${IW}x${IH} xc:none \
        -fill "$PAPER" \
        -stroke none \
        -draw "polygon \
            70,80 \
            430,78 \
            436,420 \
            76,430" \
        "$TMP/icon_panel_backer.png"

    # black window
    magick -size ${IW}x${IH} xc:none \
        -fill "#050505" \
        -stroke none \
        -draw "polygon \
            92,98 \
            406,94 \
            412,402 \
            98,412" \
        "$TMP/icon_panel_fill.png"

    magick -size ${IW}x${IH} xc:none \
        -fill white \
        -stroke none \
        -draw "polygon \
            92,98 \
            406,94 \
            412,402 \
            98,412" \
        "$TMP/icon_panel_mask.png"

    magick -size ${IW}x${IH} xc:none \
        -fill "$IVORY" \
        -font "$FONT_REG" \
        -pointsize "$ICON_H3_POINTSIZE" \
        -gravity center \
        -annotate +0-5 'H3' \
        "$TMP/icon_h3_full.png"

    magick \
        "$TMP/icon_h3_full.png" \
        "$TMP/icon_panel_mask.png" \
        -compose DstIn \
        -composite \
        "$TMP/icon_h3_clipped.png"

    magick -size ${IW}x${IH} xc:none \
        -fill white \
        -stroke none \
        -draw "rectangle 125,125 210,310" \
        -draw "rectangle 285,128 378,184" \
        -draw "rectangle 255,270 404,365" \
        "$TMP/icon_frontmask.png"

    magick \
        "$TMP/icon_h3_clipped.png" \
        "$TMP/icon_frontmask.png" \
        -compose DstIn \
        -composite \
        "$TMP/icon_h3_front.png"

    magick "$CROWBAR" \
        -resize "$ICON_CROWBAR_SIZE" \
        -background none \
        -rotate "$ICON_CROWBAR_ROTATE" \
        "$TMP/icon_crowbar.png"

    magick \
        "$TMP/icon_base.png" \
        "$TMP/icon_panel_backer.png" \
        -composite \
        "$TMP/icon_01.png"

    magick \
        "$TMP/icon_01.png" \
        "$TMP/icon_panel_fill.png" \
        -composite \
        "$TMP/icon_02.png"

    magick \
        "$TMP/icon_02.png" \
        "$TMP/icon_h3_clipped.png" \
        -composite \
        "$TMP/icon_03.png"

    magick \
        "$TMP/icon_03.png" \
        "$TMP/icon_crowbar.png" \
        -geometry "$ICON_CROWBAR_GEOM" \
        -composite \
        "$TMP/icon_04.png"

    magick \
        "$TMP/icon_04.png" \
        "$TMP/icon_h3_front.png" \
        -composite \
        "$OUTDIR/h3_icon_v6.png"

    echo "Wrote: $OUTDIR/h3_icon_v6.png"
}

build_classified_variant() {

    [[ -f "$OUTDIR/h3_badge_clean_v6.png" ]] || build_clean_badge

    magick \
        -background none \
        -fill none \
        -stroke "$RED" \
        -strokewidth 7 \
        -font "$FONT_REG" \
        -pointsize 138 \
        label:'UNAUTHORIZED' \
        -rotate -10 \
        "$TMP/stamp.png"

    magick \
        -background none \
        -fill "$PURPLE" \
        -font "$FONT_ITAL" \
        -pointsize 44 \
        label:'APPROVED? LOL' \
        "$TMP/purple_note_2.png"

    magick -size ${W}x${H} xc:black \
        +noise Random \
        -colorspace Gray \
        -threshold 82% \
        -transparent black \
        -fill "$IVORY" \
        -opaque white \
        -channel a \
        -evaluate set 10% \
        +channel \
        "$TMP/dust.png"

    magick \
    "$OUTDIR/h3_badge_clean_v6.png" \
    \
    "$TMP/stamp.png" \
        -gravity center \
        -geometry +0-5 \
        -composite \
    \
    "$TMP/purple_note_2.png" \
        -gravity southwest \
        -geometry +100+115 \
        -composite \
    \
    "$TMP/dust.png" \
        -gravity northwest \
        -compose over \
        -composite \
    \
    -attenuate 0.02 \
    +noise Gaussian \
    \
    "$OUTDIR/h3_badge_classified_v6.png"

    echo "Wrote: $OUTDIR/h3_badge_classified_v6.png"
}

case "$TARGET" in

    clean)
        build_clean_badge
        ;;

    icon)
        build_icon
        ;;

    classified)
        build_clean_badge
        build_classified_variant
        ;;

    all)
        build_clean_badge
        build_icon
        build_classified_variant
        ;;

    *)
        echo \
            "Usage: $0 {clean|icon|classified|all} /path/to/crowbar.png" \
            >&2
        exit 1
        ;;

esac
