#!/usr/bin/env bash
# Pack H3UI and/or Morrowind chrome into nested 512x512 atlases.
#
# Layout strategy:
#   - thick frame owns the full 512x512 atlas
#   - thin frame is nested at +4,+4 inside thick's unused center
#   - button/caption/pin/arrow assets are packed inside thin's unused center
#
# nineSlice only samples each frame's source margins, so these nested regions do
# not conflict even though their bounding rectangles overlap geometrically.
#
# H3UI input is the modern full-frame source set:
#   frame_thick.dds, frame_thin.dds, frame_button.dds, frame_caption.dds,
#   frame_pin_up.dds, frame_pin_down.dds, arrow_{up,down,left,right}.dds
#
# Morrowind input remains the original split chrome resources. The script
# reconstructs thick/thin frames while preserving native border thickness, strips
# source color, then packs OpenMW's native arrows and the remaining controls.

set -euo pipefail

MAGICK_BIN="${MAGICK_BIN:-$(command -v magick || true)}"
H3UI_DIR=""
MORROWIND_DIR=""
OPENMW_DIR=""
OUTPUT="$(pwd)/chrome-atlases"
# Validated Morrowind policy: strip color, lift to tintable whites. Frozen as
# a regression baseline; tune nothing here without revalidating in-game.
MORROWIND_BRIGHTNESS=150

usage() {
    cat <<'USAGE'
Usage: recompose_chrome_atlases.sh [options]

Packs H3UI and/or Morrowind source chrome into nested 512x512 atlases.

Options:
  -m, --magick PATH       ImageMagick 7 'magick' binary
       --h3ui DIR          Unpacked H3UI frame/glyph sources
       --morrowind DIR     Morrowind Data Files Textures directory
       --openmw-textures DIR  OpenMW data textures (scroll arrows)
  -o, --output DIR        Output root (default: ./chrome-atlases)
  -h, --help              Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -m|--magick) MAGICK_BIN="$2"; shift 2 ;;
        --h3ui) H3UI_DIR="$2"; shift 2 ;;
        --morrowind) MORROWIND_DIR="$2"; shift 2 ;;
        --openmw-textures) OPENMW_DIR="$2"; shift 2 ;;
        -o|--output) OUTPUT="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
done

[[ "$OUTPUT" != /* ]] && OUTPUT="$(pwd)/$OUTPUT"
case "$OUTPUT" in
    ''|'/') echo "Refusing to build into '$OUTPUT'." >&2; exit 1 ;;
esac

[[ -n "$MAGICK_BIN" ]] || { echo "ImageMagick 'magick' was not found." >&2; exit 1; }
if [[ -z "$H3UI_DIR" && -z "$MORROWIND_DIR" ]]; then
    echo "One of --h3ui or --morrowind is required." >&2
    exit 1
fi
if [[ -n "$H3UI_DIR" && ! -d "$H3UI_DIR" ]]; then
    echo "H3UI texture directory does not exist." >&2
    exit 1
fi
if [[ -n "$MORROWIND_DIR" && ! -d "$MORROWIND_DIR" ]]; then
    echo "Morrowind texture directory does not exist." >&2
    exit 1
fi
if [[ -n "$MORROWIND_DIR" && -z "$OPENMW_DIR" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    OPENMW_DIR="$SCRIPT_DIR/../../../openmw/files/data/textures"
fi
if [[ -n "$MORROWIND_DIR" && ! -d "$OPENMW_DIR" ]]; then
    echo "OpenMW texture directory is required for Morrowind arrows." >&2
    exit 1
fi
"$MAGICK_BIN" -version >/dev/null 2>&1 || {
    echo "ImageMagick '$MAGICK_BIN' could not start." >&2
    exit 1
}

ROOT="$OUTPUT"
TEXTURE_DIR="$ROOT/Textures/h3ui"
TMP="$ROOT/.tmp-chrome-atlas"
case "$ROOT" in
    ''|'/') echo "Refusing to build into '$ROOT'." >&2; exit 1 ;;
esac
rm -rf "$ROOT"
mkdir -p "$TEXTURE_DIR" "$TMP/h3ui"
[[ -n "$MORROWIND_DIR" ]] && mkdir -p "$TMP/morrowind"

DDS=( -define dds:mipmaps=0 -define dds:compression=None )

ATLAS_SIZE=512

# One normalized layout for every chrome atlas. Thin nests inside thick's
# center; source borders equal rendered thickness (2 px thin, 4 px thick).
declare -A atlasX=(
    [thick]=0
    [thin]=4
    [button]=56
    [caption]=56
    [pinUp]=328
    [pinDown]=400
    [scrollUp]=320
    [scrollDown]=356
    [scrollLeft]=392
    [scrollRight]=428
)
declare -A atlasY=(
    [thick]=0
    [thin]=4
    [button]=56
    [caption]=160
    [pinUp]=56
    [pinDown]=56
    [scrollUp]=128
    [scrollDown]=128
    [scrollLeft]=128
    [scrollRight]=128
)

declare -A regionWidth regionHeight regionSource regionSourceBorder

find_source() {
    local directory="$1" basename="$2" extension
    for extension in dds bmp tga png; do
        if [[ -f "$directory/$basename.$extension" ]]; then
            printf '%s\n' "$directory/$basename.$extension"
            return 0
        fi
    done
    return 1
}

find_corner_source() {
    local directory="$1" prefix="$2" corner="$3"
    if find_source "$directory" "${prefix}_${corner}_corner"; then return 0; fi
    find_source "$directory" "${prefix}_${corner}"
}

find_scroll_source() {
    local directory="$1" direction="$2"
    if find_source "$directory" "menu_scroll_$direction"; then return 0; fi
    find_source "$directory" "omw_menu_scroll_$direction"
}

assert_size() {
    local file="$1" expectedW="$2" expectedH="$3" label="$4"
    local w h
    read -r w h < <("$MAGICK_BIN" identify -format '%w %h\n' "$file")
    if [[ "$w" -ne "$expectedW" || "$h" -ne "$expectedH" ]]; then
        echo "$label must be ${expectedW}x${expectedH}; got ${w}x${h}: $file" >&2
        exit 1
    fi
}

copy_h3ui_frame() {
    local key="$1" filename="$2" width="$3" height="$4" sourceBorder="$5"
    local source
    source="$(find_source "$H3UI_DIR" "$filename")" || {
        echo "Missing H3UI source: $filename" >&2
        exit 1
    }
    assert_size "$source" "$width" "$height" "H3UI $key"
    local output="$TMP/h3ui/$key.png"
    "$MAGICK_BIN" "$source" "$output"
    regionWidth[h3ui:$key]=$width
    regionHeight[h3ui:$key]=$height
    regionSource[h3ui:$key]="$output"
    regionSourceBorder[h3ui:$key]=$sourceBorder
}

copy_h3ui_arrow() {
    local key="$1" filename="$2"
    local source
    source="$(find_source "$H3UI_DIR" "$filename")" || {
        echo "Missing H3UI source: $filename" >&2
        exit 1
    }
    local output="$TMP/h3ui/$key.png"
    "$MAGICK_BIN" "$source" "$output"
    read -r regionWidth[h3ui:$key] regionHeight[h3ui:$key] < <(
        "$MAGICK_BIN" identify -format '%w %h\n' "$output"
    )
    regionSource[h3ui:$key]="$output"
    regionSourceBorder[h3ui:$key]=0
}

gray_morrowind_source() {
    local source="$1" key="$2"
    local output="$TMP/morrowind/${key}.png"
    "$MAGICK_BIN" "$source" -modulate "${MORROWIND_BRIGHTNESS},0,100" "$output"
    printf '%s\n' "$output"
}

# Reconstruct a legacy split frame at a requested target size.
# Corner dimensions remain native. Edge/center pieces are resized only along
# their stretchable axes to fill the requested rectangle.
compose_legacy_frame() {
    local theme="$1" key="$2" directory="$3" prefix="$4"
    local targetW="$5" targetH="$6" centerName="${7:-}"

    local tl top tr left right bl bottom br center=""
    tl="$(find_corner_source "$directory" "$prefix" top_left)"
    top="$(find_source "$directory" "${prefix}_top")"
    tr="$(find_corner_source "$directory" "$prefix" top_right)"
    left="$(find_source "$directory" "${prefix}_left")"
    right="$(find_source "$directory" "${prefix}_right")"
    bl="$(find_corner_source "$directory" "$prefix" bottom_left)"
    bottom="$(find_source "$directory" "${prefix}_bottom")"
    br="$(find_corner_source "$directory" "$prefix" bottom_right)"

    if [[ "$theme" == morrowind ]]; then
        tl="$(gray_morrowind_source "$tl" "${key}_top_left")"
        top="$(gray_morrowind_source "$top" "${key}_top")"
        tr="$(gray_morrowind_source "$tr" "${key}_top_right")"
        left="$(gray_morrowind_source "$left" "${key}_left")"
        right="$(gray_morrowind_source "$right" "${key}_right")"
        bl="$(gray_morrowind_source "$bl" "${key}_bottom_left")"
        bottom="$(gray_morrowind_source "$bottom" "${key}_bottom")"
        br="$(gray_morrowind_source "$br" "${key}_bottom_right")"
    fi

    local leftW topH rightW bottomH
    read -r leftW topH < <("$MAGICK_BIN" identify -format '%w %h\n' "$tl")
    read -r rightW _ < <("$MAGICK_BIN" identify -format '%w %h\n' "$tr")
    read -r _ bottomH < <("$MAGICK_BIN" identify -format '%w %h\n' "$bl")

    local centerW=$((targetW - leftW - rightW))
    local centerH=$((targetH - topH - bottomH))
    if (( centerW <= 0 || centerH <= 0 )); then
        echo "Target ${targetW}x${targetH} is too small for $prefix borders." >&2
        exit 1
    fi

    local output="$TMP/$theme/$key.png"
    local topR="$TMP/$theme/${key}_top.png"
    local bottomR="$TMP/$theme/${key}_bottom.png"
    local leftR="$TMP/$theme/${key}_left.png"
    local rightR="$TMP/$theme/${key}_right.png"

    "$MAGICK_BIN" "$top" -resize "${centerW}x${topH}!" "$topR"
    "$MAGICK_BIN" "$bottom" -resize "${centerW}x${bottomH}!" "$bottomR"
    "$MAGICK_BIN" "$left" -resize "${leftW}x${centerH}!" "$leftR"
    "$MAGICK_BIN" "$right" -resize "${rightW}x${centerH}!" "$rightR"

    "$MAGICK_BIN" -size "${targetW}x${targetH}" xc:none \
        "$tl" -geometry +0+0 -composite \
        "$topR" -geometry +${leftW}+0 -composite \
        "$tr" -geometry +$((targetW - rightW))+0 -composite \
        "$leftR" -geometry +0+${topH} -composite \
        "$rightR" -geometry +$((targetW - rightW))+${topH} -composite \
        "$bl" -geometry +0+$((targetH - bottomH)) -composite \
        "$bottomR" -geometry +${leftW}+$((targetH - bottomH)) -composite \
        "$br" -geometry +$((targetW - rightW))+$((targetH - bottomH)) -composite \
        "$output"

    if [[ -n "$centerName" ]]; then
        center="$(find_source "$directory" "${prefix}_${centerName}")"
        local centerR="$TMP/$theme/${key}_center.png"
        if [[ "$theme" == morrowind ]]; then
            center="$(gray_morrowind_source "$center" "${key}_center_source")"
        fi
        "$MAGICK_BIN" "$center" -resize "${centerW}x${centerH}!" "$centerR"
        "$MAGICK_BIN" "$output" "$centerR" \
            -geometry +${leftW}+${topH} -compose Over -composite "$output"
    fi

    regionWidth[$theme:$key]=$targetW
    regionHeight[$theme:$key]=$targetH
    regionSource[$theme:$key]="$output"

    # Current Morrowind/OpenMW chrome uses symmetric square corner thickness.
    if [[ "$leftW" -ne "$topH" || "$rightW" -ne "$leftW" || "$bottomH" -ne "$topH" ]]; then
        echo "Non-uniform source borders are not supported for $prefix." >&2
        exit 1
    fi
    regionSourceBorder[$theme:$key]=$leftW
}

# Compose a legacy frame at its natural dimensions.
compose_legacy_natural() {
    local theme="$1" key="$2" directory="$3" prefix="$4" centerName="${5:-}"
    local tl top left
    tl="$(find_corner_source "$directory" "$prefix" top_left)"
    top="$(find_source "$directory" "${prefix}_top")"
    left="$(find_source "$directory" "${prefix}_left")"

    local cw ch ew eh
    read -r cw ch < <("$MAGICK_BIN" identify -format '%w %h\n' "$tl")
    read -r ew _ < <("$MAGICK_BIN" identify -format '%w %h\n' "$top")
    read -r _ eh < <("$MAGICK_BIN" identify -format '%w %h\n' "$left")

    compose_legacy_frame "$theme" "$key" "$directory" "$prefix" \
        $((cw + ew + cw)) $((ch + eh + ch)) "$centerName"
}

copy_morrowind_scroll() {
    local key="$1" direction="$2"
    local source
    source="$(find_scroll_source "$OPENMW_DIR" "$direction")"
    local output="$TMP/morrowind/$key.png"
    "$MAGICK_BIN" "$source" "$output"
    read -r regionWidth[morrowind:$key] regionHeight[morrowind:$key] < <(
        "$MAGICK_BIN" identify -format '%w %h\n' "$output"
    )
    regionSource[morrowind:$key]="$output"
    regionSourceBorder[morrowind:$key]=0
}

prepare_h3ui() {
    copy_h3ui_frame thick frame_thick 512 512 4
    copy_h3ui_frame thin frame_thin 504 504 2
    copy_h3ui_frame button frame_button 136 24 4
    copy_h3ui_frame caption frame_caption 260 20 2
    copy_h3ui_frame pinUp frame_pin_up 20 20 2
    copy_h3ui_frame pinDown frame_pin_down 20 20 2
    copy_h3ui_arrow scrollUp arrow_up
    copy_h3ui_arrow scrollDown arrow_down
    copy_h3ui_arrow scrollLeft arrow_left
    copy_h3ui_arrow scrollRight arrow_right
}

prepare_morrowind() {
    # Only the outer two frames are normalized in size. Everything else stays at
    # its native source dimensions and is simply packed into the available center.
    compose_legacy_frame morrowind thick "$MORROWIND_DIR" menu_thick_border 512 512
    compose_legacy_frame morrowind thin "$MORROWIND_DIR" menu_thin_border 504 504
    compose_legacy_natural morrowind button "$MORROWIND_DIR" menu_button_frame
    compose_legacy_natural morrowind caption "$MORROWIND_DIR" menu_head_block middle
    compose_legacy_natural morrowind pinUp "$MORROWIND_DIR" menu_rightbuttonup center
    compose_legacy_natural morrowind pinDown "$MORROWIND_DIR" menu_rightbuttondown center

    copy_morrowind_scroll scrollUp up
    copy_morrowind_scroll scrollDown down
    copy_morrowind_scroll scrollLeft left
    copy_morrowind_scroll scrollRight right
}

pack_theme() {
    local theme="$1"
    local canvas="$TMP/$theme/atlas.png"

    # Thick first because it intentionally owns the whole atlas. Its unused
    # center is then overwritten by the nested regions below.
    "$MAGICK_BIN" -size ${ATLAS_SIZE}x${ATLAS_SIZE} xc:none \
        "${regionSource[$theme:thick]}" -geometry +0+0 -compose Over -composite \
        "$canvas"

    for key in thin button caption pinUp pinDown scrollUp scrollDown scrollLeft scrollRight; do
        local source="${regionSource[$theme:$key]}"
        local x="${atlasX[$key]}" y="${atlasY[$key]}"
        local w="${regionWidth[$theme:$key]}" h="${regionHeight[$theme:$key]}"

        if (( x < 0 || y < 0 || x + w > ATLAS_SIZE || y + h > ATLAS_SIZE )); then
            echo "$theme/$key does not fit in 512x512 atlas: ${w}x${h} at +${x}+${y}" >&2
            exit 1
        fi

        "$MAGICK_BIN" "$canvas" "$source" \
            -geometry +${x}+${y} -compose Over -composite "$canvas"
    done

    "$MAGICK_BIN" "$canvas" "${DDS[@]}" "$TEXTURE_DIR/${theme}_chrome.dds"
}

if [[ -n "$H3UI_DIR" ]]; then
    prepare_h3ui
    pack_theme h3ui
fi
if [[ -n "$MORROWIND_DIR" ]]; then
    prepare_morrowind
    pack_theme morrowind
    # The Morrowind atlas doubles as the classic entry of the H3UI material
    # library, so it is also emitted under the chrome/ material directory.
    mkdir -p "$TEXTURE_DIR/chrome"
    cp "$TEXTURE_DIR/morrowind_chrome.dds" "$TEXTURE_DIR/chrome/morrowind.dds"
fi

# -----------------------------------------------------------------------------
# Generated Lua manifest
# -----------------------------------------------------------------------------
cat > "$ROOT/h3ui_chrome_manifest.lua" <<'LUA'
-- Generated by recompose_chrome_atlases.sh.
local util = require 'openmw.util'

local function region(path, x, y, width, height, sourceBorder, thickness, center, tintable)
  return {
    path = path,
    offset = util.vector2(x, y),
    size = util.vector2(width, height),
    sourceBorder = sourceBorder,
    thickness = thickness,
    center = center,
    tintable = tintable,
  }
end

return {
LUA

themes=(h3ui)
[[ -n "$MORROWIND_DIR" ]] && themes+=(morrowind)

for theme in "${themes[@]}"; do
    path="textures/h3ui/${theme}_chrome.dds"
    tintable=true

    printf '  %s = {\n    frame = {\n' "$theme" >> "$ROOT/h3ui_chrome_manifest.lua"

    for key in thin thick button caption pinUp pinDown; do
        case "$key" in
            thin) thickness=2 ;;
            thick|button) thickness=4 ;;
            caption|pinUp|pinDown) thickness=2 ;;
        esac
        [[ "$key" == caption || "$key" == pinUp || "$key" == pinDown ]] && center=true || center=false
        sourceKey="$theme:$key"

        printf '      %s = region(\x27%s\x27, %s, %s, %s, %s, %s, %s, %s, %s),\n' \
            "$key" "$path" "${atlasX[$key]}" "${atlasY[$key]}" \
            "${regionWidth[$sourceKey]}" "${regionHeight[$sourceKey]}" \
            "${regionSourceBorder[$sourceKey]}" "$thickness" "$center" "$tintable" \
            >> "$ROOT/h3ui_chrome_manifest.lua"
    done

    printf '    },\n    scroll = {\n' >> "$ROOT/h3ui_chrome_manifest.lua"
    for direction in up down left right; do
        key="scroll${direction^}"
        sourceKey="$theme:$key"
        printf '      %s = region(\x27%s\x27, %s, %s, %s, %s, nil, nil, false, %s),\n' \
            "$direction" "$path" "${atlasX[$key]}" "${atlasY[$key]}" \
            "${regionWidth[$sourceKey]}" "${regionHeight[$sourceKey]}" "$tintable" \
            >> "$ROOT/h3ui_chrome_manifest.lua"
    done
    printf '    },\n  },\n' >> "$ROOT/h3ui_chrome_manifest.lua"
done
printf '}\n' >> "$ROOT/h3ui_chrome_manifest.lua"

rm -rf "$TMP"
echo "Generated nested 512x512 chrome atlases in: $TEXTURE_DIR"
echo "Manifest: $ROOT/h3ui_chrome_manifest.lua"
