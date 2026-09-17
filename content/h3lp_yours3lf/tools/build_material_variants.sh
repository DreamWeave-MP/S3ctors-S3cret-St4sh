#!/usr/bin/env bash
# Build named H3UI chrome variants from the materials catalog.
#
# Each catalog row pins a material photo plus the sampled crop, so rebuilding
# is byte-identical. Atlas coordinates match across variants; only grain
# differs. Morrowind output is unrelated to material choice and is never
# built here. The site data file is regenerated alongside so docs stay synced.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAGICK_BIN="${MAGICK_BIN:-$(command -v magick || true)}"
MATERIALS="$SCRIPT_DIR/../textures/h3ui/chrome/materials.tsv"
INSTALL_DIR="$SCRIPT_DIR/../textures/h3ui"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
RANDOM_CROP=0

usage() {
    cat <<'USAGE'
Usage: build_material_variants.sh [options] [stem ...]

Builds the materials.tsv rows (or the named stems) into chrome/<stem>.dds
variants installed next to the default textures. Crops come from the
manifest; --random-crop rolls fresh ones instead (development only: record
any keeper with its printed coordinates). MATERIAL_CROP="X,Y" pins one crop
for every variant built in this run.

Options:
  -m, --magick PATH   ImageMagick 7 'magick' binary
       --random-crop  Ignore pinned crops and roll fresh ones
  -h, --help          Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -m|--magick) MAGICK_BIN="$2"; shift 2 ;;
        --random-crop) RANDOM_CROP=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) break ;;
    esac
done

if [[ -z "$MAGICK_BIN" ]] || ! "$MAGICK_BIN" -version >/dev/null 2>&1; then
    echo "ImageMagick 7 'magick' is required." >&2
    exit 1
fi
[[ -f "$MATERIALS" ]] || { echo "Missing materials manifest: $MATERIALS" >&2; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

wanted=("$@")
built=0
mkdir -p "$ROOT/static/img/h3ui/chrome"
while IFS=$'\t' read -r stem family _name photo cropX cropY _url _author _license; do
    [[ "$stem" == stem || -z "$stem" ]] && continue
    if (( ${#wanted[@]} > 0 )); then
        keep=0
        for index in "${!wanted[@]}"; do
            [[ "${wanted[$index]}" == "$stem" ]] && keep=1
        done
        (( keep )) || continue
    fi
    if (( RANDOM_CROP )) && [[ -z "${MATERIAL_CROP:-}" ]]; then
        cropArgs=()
    elif [[ -n "${MATERIAL_CROP:-}" ]]; then
        cropArgs=(--material-crop "$MATERIAL_CROP")
    else
        cropArgs=(--material-crop "$cropX,$cropY")
    fi

    echo "=== variant: $stem"
    genOut="$WORK/gen-$stem"
    atlasOut="$WORK/atlas-$stem"
    bash "$SCRIPT_DIR/generate_h3ui_textures.sh" \
        --magick "$MAGICK_BIN" --material "$SCRIPT_DIR/source/$photo" "${cropArgs[@]}" \
        --output "$genOut"
    bash "$SCRIPT_DIR/recompose_chrome_atlases.sh" \
        --magick "$MAGICK_BIN" --h3ui "$genOut/Textures/h3ui" \
        --output "$atlasOut"
    mkdir -p "$INSTALL_DIR/chrome"
    cp "$atlasOut/Textures/h3ui/h3ui_chrome.dds" "$INSTALL_DIR/chrome/$stem.dds"
    echo "installed: chrome/$stem.dds"
    "$MAGICK_BIN" "$atlasOut/Textures/h3ui/h3ui_chrome.dds" \
        -quality 85 "$ROOT/static/img/h3ui/chrome/$stem.webp"
    built=$((built + 1))
done < "$MATERIALS"

(( built )) || { echo "No materials matched." >&2; exit 1; }
echo "Built $built variant(s)."

{
    printf '{\n  "materials": [\n'
    awk -F'\t' '
      NR == 1 { next }
      NF >= 9 {
        if (n++) printf ",\n"
        printf "    {\"id\": \"%s\", \"family\": \"%s\", \"name\": \"%s\", \"photo\": \"%s\", \"crop\": [%s, %s], \"url\": \"%s\", \"author\": \"%s\", \"license\": \"%s\"}", $1, $2, $3, $4, $5, $6, $7, $8, $9
      }' "$SCRIPT_DIR/../textures/h3ui/chrome/materials.tsv"
    printf '\n  ]\n}\n'
} > "$ROOT/data/h3_materials.json"
echo "Wrote site data: data/h3_materials.json"
