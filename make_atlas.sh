#!/usr/bin/env bash

# Texture Atlas with Progressive White-to-Black Conversion
# For doing health bars and shit.
# Usage: ./atlas.sh input_image output_image rows cols

# Parse named arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--input)
            INPUT_IMAGE="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT="$2"
            shift 2
            ;;
        -r|--rows)
            ROWS="$2"
            shift 2
            ;;
        -c|--cols)
            COLS="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 -i input_image -o output_image -r rows -c cols"
            exit 1
            ;;
    esac
done

# Validate required arguments
if [[ -z "$INPUT_IMAGE" || -z "$OUTPUT" || -z "$ROWS" || -z "$COLS" ]]; then
    echo "Error: Missing required arguments"
    echo "Usage: $0 -i input_image -o output_image -r rows -c cols"
    exit 1
fi

TOTAL_TILES=$((ROWS * COLS))

# Verify input file exists
if [[ ! -f "$INPUT_IMAGE" ]]; then
    echo "Error: Input file '$INPUT_IMAGE' not found"
    exit 1
fi

echo "Creating ${ROWS}x${COLS} atlas from: ${INPUT_IMAGE}"

# Create temporary directory for processed tiles
TEMP_DIR=$(mktemp -d)
echo "Using temporary directory: $TEMP_DIR"

# Process each tile with progressive white-to-black conversion
files=()
for ((i=0; i < TOTAL_TILES; i++)); do
    temp_tile="${TEMP_DIR}/tile_${i}.png"
    
    if [[ $i -eq 0 ]]; then
        cp "$INPUT_IMAGE" "$temp_tile"
    else
        percentage=$(( (i * 100) / (TOTAL_TILES - 1) ))
        echo "Converting $percentage% of white pixels to black"
        
        height=$(magick "$INPUT_IMAGE" -format "%h" info:)
        crop_height=$(( (percentage * height) / 100 ))
        
        magick "$INPUT_IMAGE" \
            \( +clone -crop x${crop_height}+0+0 -fill black -fuzz 0% -opaque white \) \
            -geometry +0+0 -composite \
            "$temp_tile"
    fi
    
    files+=("$temp_tile")
done

# Create montage
magick montage \
    "${files[@]}" \
    -tile "${COLS}x${ROWS}" \
    -geometry +0+0 \
    -background transparent \
    -define dds:compression=none \
    -define dds:mipmaps=0 \
    "$OUTPUT"

echo "Successfully created atlas: $OUTPUT"

# Clean up
rm -rf "$TEMP_DIR"
echo "Cleanup complete"