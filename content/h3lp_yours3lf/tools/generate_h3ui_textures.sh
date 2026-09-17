#!/usr/bin/env bash
# Material photo -> unpacked frame sources. Atlas packing: recompose_chrome_atlases.sh.

set -euo pipefail

OUTPUT="$(pwd)/h3ui-textures"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAGICK_BIN="${MAGICK_BIN:-}"
MATERIAL_SOURCE="$SCRIPT_DIR/source/coral_fort_wall_02.webp"
MATERIAL_CROP=""
SEED=3301
SIZE=512

usage() {
    cat <<'USAGE'
Usage: generate_h3ui_textures.sh [options]

Options:
  -o, --output DIR    Output root (default: ./h3ui-textures)
  -m, --magick PATH   ImageMagick 7 'magick' binary
       --material PATH  Material photo baked into the chrome sources
                        (default: <script-dir>/source/coral_fort_wall_02.webp)
       --material-crop X,Y
                        Origin of the square sampled from the material photo
                        (default: random each run; the chosen origin is
                        printed so a good roll can be pinned)
       --seed N        Noise seed for auxiliary textures (default: 3301)
  -h, --help          Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--output) OUTPUT="$2"; shift 2 ;;
        -m|--magick) MAGICK_BIN="$2"; shift 2 ;;
        --material) MATERIAL_SOURCE="$2"; shift 2 ;;
        --material-crop) MATERIAL_CROP="$2"; shift 2 ;;
        --seed) SEED="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
done

[[ "$OUTPUT" != /* ]] && OUTPUT="$(pwd)/$OUTPUT"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
case "$OUTPUT" in
    ''|'/') echo "Refusing to build into '$OUTPUT'." >&2; exit 1 ;;
esac
if [[ "$OUTPUT" == "$SCRIPT_DIR" || "$OUTPUT" == "$REPO_ROOT" ]]; then
    echo "Refusing to build into '$OUTPUT'." >&2
    exit 1
fi

if [[ -z "$MAGICK_BIN" ]]; then
    MAGICK_BIN="$(command -v magick || true)"
fi
if [[ -z "$MAGICK_BIN" ]] || ! "$MAGICK_BIN" -version >/dev/null 2>&1; then
    echo "ImageMagick 7 'magick' is required." >&2
    exit 1
fi

TEXTURE_DIR="$OUTPUT/Textures/h3ui"
TMP="$OUTPUT/.tmp-h3ui"
rm -rf "$OUTPUT"
mkdir -p "$TEXTURE_DIR" "$TMP"
DDS=( -define dds:mipmaps=0 -define dds:compression=None )

# Sampling one square of the material photo, desaturated and high-passed:
# broad photographic lighting would blotch stretched borders, so low
# frequencies are divided out and only grain remains.

make_material_field() {    local out="$1"

    if [[ ! -f "$MATERIAL_SOURCE" ]]; then
        echo "Missing material photo: $MATERIAL_SOURCE" >&2
        echo "Place the photo there or pass --material PATH." >&2
        exit 1
    fi

    local srcW srcH cropX cropY cropSize=1024
    read -r srcW srcH < <("$MAGICK_BIN" identify -format '%w %h\n' "$MATERIAL_SOURCE")
    (( srcW < cropSize )) && cropSize=$srcW
    (( srcH < cropSize )) && cropSize=$srcH
    if [[ -n "$MATERIAL_CROP" ]]; then
        cropX="${MATERIAL_CROP%%,*}"
        cropY="${MATERIAL_CROP##*,}"
    else
        cropX=$((RANDOM % (srcW - cropSize + 1)))
        cropY=$((RANDOM % (srcH - cropSize + 1)))
    fi
    if (( cropX < 0 || cropY < 0 || cropX + cropSize > srcW || cropY + cropSize > srcH )); then
        echo "Material crop ${cropX},${cropY} does not fit ${srcW}x${srcH} photo." >&2
        exit 1
    fi
    echo "Material crop: ${cropX},${cropY} (pin with --material-crop ${cropX},${cropY})"

    "$MAGICK_BIN" "$MATERIAL_SOURCE" \
        -crop ${cropSize}x${cropSize}+${cropX}+${cropY} +repage \
        -colorspace Gray -clamp \
        -resize ${SIZE}x${SIZE}! \
        \( +clone -blur 0x12 \) \
        -compose Mathematics -define compose:args='0,1,-1,0.5' -composite \
        -contrast-stretch 1%x1% -colorspace Gray -clamp \
        -sigmoidal-contrast 2.0,50% -colorspace Gray -clamp \
        "$out"
}

make_material_field "$TMP/material.png"

# Wide tone windows so micro-contrast survives runtime tint multiplication.
tone_material() {
    local out="$1" low="$2" high="$3"
    local slope intercept
    slope="$(awk -v lo="$low" -v hi="$high" 'BEGIN { printf "%.6f", (hi-lo)/100 }')"
    intercept="$(awk -v lo="$low" 'BEGIN { printf "%.6f", lo/100 }')"
    "$MAGICK_BIN" "$TMP/material.png" \
        -function polynomial "${slope},${intercept}" \
        -colorspace Gray -clamp "$out"
}

tone_material "$TMP/frame_outer.png"     50 100
tone_material "$TMP/control_outer.png"   48 96
tone_material "$TMP/control_inner.png"   56 100
tone_material "$TMP/control_pressed.png" 30 68

# Raised relief: light top/left, shadow bottom/right, inverse groove where
# the ring meets its content. Corners belong to the horizontal bands, so
# every pixel takes one coat.
shade_raised() {
    local file="$1" width="$2" height="$3" margin="$4" strength="${5:-100}"
    local inner=$((margin - 1))
    local bottom=$((height - 1)) right=$((width - 1))
    local grooveB=$((height - margin)) grooveR=$((width - margin))
    local grooveIn1=$((inner + 1)) grooveB1=$((grooveB - 1))
    local hi lo glo ghi
    hi=$(awk -v s="$strength" 'BEGIN { printf "%.2f", 0.22*s/100 }')
    lo=$(awk -v s="$strength" 'BEGIN { printf "%.2f", 0.28*s/100 }')
    glo=$(awk -v s="$strength" 'BEGIN { printf "%.2f", 0.20*s/100 }')
    ghi="$glo"
    local bandB=$((height - margin)) bandR=$((width - margin))
    local bandMidB=$((height - margin - 1))
    "$MAGICK_BIN" "$file" \
        -fill "rgba(255,255,255,${hi})" -stroke none \
        -draw "rectangle 0,0 ${right},$((margin - 1))" \
        -draw "rectangle 0,${margin} $((margin - 1)),${bandMidB}" \
        -fill "rgba(0,0,0,${lo})" -stroke none \
        -draw "rectangle 0,${bandB} ${right},${bottom}" \
        -draw "rectangle ${bandR},${margin} ${right},${bandMidB}" \
        -fill "rgba(0,0,0,${glo})" -stroke none \
        -draw "rectangle ${inner},${inner} ${grooveR},${inner}" \
        -draw "rectangle ${inner},${grooveIn1} ${inner},${grooveB}" \
        -fill "rgba(255,255,255,${ghi})" -stroke none \
        -draw "rectangle ${margin},${grooveB} ${grooveR},${grooveB}" \
        -draw "rectangle ${grooveR},${margin} ${grooveR},${grooveB1}" \
        "$file"
}

# Flat median ring first so grain cannot spot the edges, then the same
# shadow on all four sides.
shade_lowered() {
    local file="$1" width="$2" height="$3" strength="${4:-100}"
    local bottom=$((height - 1)) right=$((width - 1))
    local midB=$((height - 2))
    local sh facePct
    sh=$(awk -v s="$strength" 'BEGIN { printf "%.2f", 0.25*s/100 }')
    facePct=$("$MAGICK_BIN" "$file" -format '%[fx:median*100]' info:)
    "$MAGICK_BIN" "$file" \
        -fill "gray(${facePct}%)" -stroke none \
        -draw "rectangle 0,0 ${right},0" -draw "rectangle 0,${bottom} ${right},${bottom}" \
        -draw "rectangle 0,1 0,${midB}" -draw "rectangle ${right},1 ${right},${midB}" \
        -fill "rgba(0,0,0,${sh})" -stroke none \
        -draw "rectangle 0,0 ${right},0" -draw "rectangle 0,${bottom} ${right},${bottom}" \
        -draw "rectangle 0,1 0,${midB}" -draw "rectangle ${right},1 ${right},${midB}" \
        "$file"
}

# Recessed relief for pressed controls: flat median ring, shadow up top.
shade_recessed() {
    local file="$1" width="$2" height="$3" strength="${4:-100}"
    local bottom=$((height - 1)) right=$((width - 1))
    local midB=$((height - 2))
    local sh hi facePct
    sh=$(awk -v s="$strength" 'BEGIN { printf "%.2f", 0.25*s/100 }')
    hi=$(awk -v s="$strength" 'BEGIN { printf "%.2f", 0.20*s/100 }')
    facePct=$("$MAGICK_BIN" "$file" -format '%[fx:median*100]' info:)
    "$MAGICK_BIN" "$file" \
        -fill "gray(${facePct}%)" -stroke none \
        -draw "rectangle 0,0 ${right},0" -draw "rectangle 0,${bottom} ${right},${bottom}" \
        -draw "rectangle 0,1 0,${midB}" -draw "rectangle ${right},1 ${right},${midB}" \
        -fill "rgba(0,0,0,${sh})" -stroke none \
        -draw "rectangle 0,0 ${right},0" -draw "rectangle 0,1 0,${midB}" \
        -fill "rgba(255,255,255,${hi})" -stroke none \
        -draw "rectangle 0,${bottom} ${right},${bottom}" -draw "rectangle ${right},1 ${right},${midB}" \
        "$file"
}

# Uniform shade for window borders: same shadow plus groove on all sides.
shade_uniform() {
    local file="$1" width="$2" height="$3" margin="$4" strength="${5:-100}"
    local bottom=$((height - 1)) right=$((width - 1))
    local bandB=$((height - margin)) bandR=$((width - margin))
    local bandMidB=$((height - margin - 1))
    local grooveT=$((margin - 1)) grooveB=$((height - margin))
    local grooveL=$((margin - 1)) grooveR=$((width - margin))
    local sh
    sh=$(awk -v s="$strength" 'BEGIN { printf "%.2f", 0.25*s/100 }')
    "$MAGICK_BIN" "$file" \
        -fill "rgba(0,0,0,${sh})" -stroke none \
        -draw "rectangle 0,0 ${right},$((margin - 1))" \
        -draw "rectangle 0,${bandB} ${right},${bottom}" \
        -draw "rectangle 0,${margin} $((margin - 1)),${bandMidB}" \
        -draw "rectangle ${bandR},${margin} ${right},${bandMidB}" \
        -draw "rectangle 0,${grooveT} ${right},${grooveT}" \
        -draw "rectangle 0,${grooveB} ${right},${grooveB}" \
        -draw "rectangle ${grooveL},${margin} ${grooveL},${bandMidB}" \
        -draw "rectangle ${grooveR},${margin} ${grooveR},${bandMidB}" \
        "$file"
}

# make_two_tone_frame OUT WIDTH HEIGHT MARGIN OUTER_BAND OUTER_TILE INNER_TILE [SHADING]
# Tile a full material square, ring the inner tone over it, shade, then mask
# the center transparent so nested atlas regions show through. SHADING is
# uniform (default) or raised; controls take raised, window borders uniform.
make_two_tone_frame() {
    local out="$1" width="$2" height="$3" margin="$4" outer_band="$5"
    local outer_tile="$6" inner_tile="$7" shading="${8:-uniform}"

    if (( outer_band <= 0 || outer_band >= margin )); then
        echo "Invalid outer band $outer_band for margin $margin" >&2
        exit 2
    fi

    local outer="$TMP/${out%.dds}_outer.png"
    local inner="$TMP/${out%.dds}_inner.png"
    local alpha="$TMP/${out%.dds}_alpha.png"
    local inner_w=$((width - outer_band * 2))
    local inner_h=$((height - outer_band * 2))
    local center_w=$((width - margin * 2))
    local center_h=$((height - margin * 2))

    if (( center_w <= 0 || center_h <= 0 )); then
        echo "Invalid margin $margin for ${width}x${height} frame" >&2
        exit 2
    fi

    "$MAGICK_BIN" -size "${width}x${height}" "tile:${outer_tile}" "$outer"
    "$MAGICK_BIN" -size "${inner_w}x${inner_h}" "tile:${inner_tile}" "$inner"
    "$MAGICK_BIN" "$outer" "$inner" \
        -geometry "+${outer_band}+${outer_band}" \
        -compose Over -composite "$outer"
    if [[ "$shading" == raised ]]; then
        shade_raised "$outer" "$width" "$height" "$margin"
    else
        shade_uniform "$outer" "$width" "$height" "$margin"
    fi
    "$MAGICK_BIN" -size "${width}x${height}" xc:white \
        -fill black -stroke none \
        -draw "rectangle ${margin},${margin} $((width - margin - 1)),$((height - margin - 1))" \
        "$alpha"
    "$MAGICK_BIN" "$outer" "$alpha" -compose CopyOpacity -composite \
        "${DDS[@]}" "$TEXTURE_DIR/$out"
}

# make_filled_frame OUT WIDTH HEIGHT MARGIN OUTER_BAND OUTER INNER CENTER [SHADING]
# SHADING is raised (default), recessed, or lowered (dark on all four edges,
# non-directional), optionally suffixed with :STRENGTH (percent, default 100).
# Small pieces take higher strength so 1px relief survives at their scale.
make_filled_frame() {
    local out="$1" width="$2" height="$3" margin="$4" outer_band="$5"
    local outer_tile="$6" inner_tile="$7" center_tile="$8" shading="${9:-raised}"
    local shadeKind="${shading%%:*}" shadeStrength=100
    [[ "$shading" == *:* ]] && shadeStrength="${shading##*:}"

    local base="$TMP/${out%.dds}_base.png"
    local inner="$TMP/${out%.dds}_inner.png"
    local center="$TMP/${out%.dds}_center.png"
    local inner_w=$((width - outer_band * 2))
    local inner_h=$((height - outer_band * 2))
    local center_w=$((width - margin * 2))
    local center_h=$((height - margin * 2))

    "$MAGICK_BIN" -size "${width}x${height}" "tile:${outer_tile}" "$base"
    "$MAGICK_BIN" -size "${inner_w}x${inner_h}" "tile:${inner_tile}" "$inner"
    "$MAGICK_BIN" "$base" "$inner" \
        -geometry "+${outer_band}+${outer_band}" \
        -compose Over -composite "$base"

    "$MAGICK_BIN" -size "${center_w}x${center_h}" "tile:${center_tile}" "$center"
    "$MAGICK_BIN" "$base" "$center" \
        -geometry "+${margin}+${margin}" \
        -compose Over -composite "$base"

    if [[ "$shadeKind" == recessed ]]; then
        shade_recessed "$base" "$width" "$height" "$shadeStrength"
    elif [[ "$shadeKind" == lowered ]]; then
        shade_lowered "$base" "$width" "$height" "$shadeStrength"
    else
        shade_raised "$base" "$width" "$height" "$margin" "$shadeStrength"
    fi
    "$MAGICK_BIN" "$base" "${DDS[@]}" "$TEXTURE_DIR/$out"
}

# The nested atlas layout is designed around these exact source dimensions:
#   thick: 512x512, occupying the whole atlas
#   thin:  504x504 at +4,+4, entirely inside thick's unused center
#   controls/glyphs live inside thin's unused center.
#
# Source margins equal rendered thickness (2 px thin/caption/pins,
# 4 px thick/button) so the source art is geometrically the thing rendered.
make_two_tone_frame frame_thick.dds  512 512 4 2 "$TMP/frame_outer.png"   "$TMP/frame_outer.png"
make_two_tone_frame frame_thin.dds   504 504 2 1 "$TMP/frame_outer.png"   "$TMP/frame_outer.png"
make_two_tone_frame frame_button.dds 136 24  4 2 "$TMP/control_outer.png" "$TMP/control_outer.png" raised

make_filled_frame frame_caption.dds 260 20 2 1 \
    "$TMP/frame_outer.png" "$TMP/frame_outer.png" "$TMP/frame_outer.png" lowered:160

make_filled_frame frame_pin_up.dds 20 20 2 1 \
    "$TMP/control_inner.png" "$TMP/control_inner.png" "$TMP/control_outer.png" raised:140
make_filled_frame frame_pin_down.dds 20 20 2 1 \
    "$TMP/control_inner.png" "$TMP/control_inner.png" "$TMP/control_pressed.png" recessed:140

# Scroll glyphs drawn natively at 16x16.
make_arrow() {
    local direction="$1" out="$2"
    local outer_points inner_points
    case "$direction" in
        up)
            outer_points='1.5,12.5 8,2 14.5,12.5'
            inner_points='3.5,11.5 8,4.5 12.5,11.5'
            ;;
        down)
            outer_points='1.5,3.5 8,14 14.5,3.5'
            inner_points='3.5,4.5 8,11.5 12.5,4.5'
            ;;
        left)
            outer_points='12.5,1.5 2,8 12.5,14.5'
            inner_points='11.5,3.5 4.5,8 11.5,12.5'
            ;;
        right)
            outer_points='3.5,1.5 14,8 3.5,14.5'
            inner_points='4.5,3.5 11.5,8 4.5,12.5'
            ;;
        *) echo "Unknown arrow direction: $direction" >&2; exit 2 ;;
    esac

    "$MAGICK_BIN" -size 16x16 xc:none \
        -tile "$TMP/control_inner.png" -draw "polygon ${outer_points}" \
        -tile "$TMP/control_outer.png" -draw "polygon ${inner_points}" \
        "${DDS[@]}" "$TEXTURE_DIR/$out"
}

make_arrow up    arrow_up.dds
make_arrow down  arrow_down.dds
make_arrow left  arrow_left.dds
make_arrow right arrow_right.dds

# Auxiliary textures.
"$MAGICK_BIN" -size 16x8 gradient:'gray(96%)-gray(36%)' \
    -seed $((SEED + 20)) +noise Gaussian -attenuate 0.035 -colorspace Gray -clamp \
    "${DDS[@]}" "$TEXTURE_DIR/meter_fill.dds"
"$MAGICK_BIN" -size 8x8 xc:white "${DDS[@]}" "$TEXTURE_DIR/flat_white.dds"

rm -rf "$TMP"

echo "Generated H3UI chrome sources in: $TEXTURE_DIR"
