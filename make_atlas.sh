#!/usr/bin/env bash

# Texture Atlas with Progressive White-to-Black Conversion
# For doing health bars and shit.
# Usage: ./atlas.sh input_image output_image rows cols

MASK=false
MASK_WIDTH=false
MASK_REMOVE=false
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
        -m|--mask)
            MASK=true
            shift 1
            ;;
        -w|--width)
            MASK_WIDTH=true
            shift 1
            ;;
        -d|--delete)
            MASK_REMOVE=true
            shift 1
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
if [[ "$MASK" == true ]]; then
    if [[ "$MASK_REMOVE" == true ]]; then
        echo "Pixel mode: REMOVE white pixels"
    else
        echo "Pixel mode: MASK white pixels with black"
    fi
    if [[ "$MASK_WIDTH" == true ]]; then
        echo "Direction: HORIZONTAL (width)"
    else
        echo "Direction: VERTICAL (height)"
    fi
else
    echo "Mode: SIMPLE duplication"
fi

# Create temporary directory for processed tiles
TEMP_DIR=$(mktemp -d)
echo "Using temporary directory: $TEMP_DIR"

ORIG_WIDTH=$(magick "$INPUT_IMAGE" -format "%w" info:)
ORIG_HEIGHT=$(magick "$INPUT_IMAGE" -format "%h" info:)

# Process each tile with progressive white-to-black conversion
files=()
for ((i=0; i < TOTAL_TILES; i++)); do
    temp_tile="${TEMP_DIR}/tile_${i}.png"
    
    if [[ "$MASK" == false ]]; then
        cp "$INPUT_IMAGE" "$temp_tile"
    else
        if [[ $i -eq 0 ]]; then
            cp "$INPUT_IMAGE" "$temp_tile"
        else
            percentage=$(( (i * 100) / (TOTAL_TILES - 1) ))

            if [[ "$MASK_REMOVE" == true ]]; then
                if [[ $i -eq $((TOTAL_TILES - 1)) ]]; then
                magick -background transparent \
                    -extent ${ORIG_WIDTH}x${ORIG_HEIGHT} \
                    "$temp_tile"
                elif [[ "$MASK_WIDTH" == true ]]; then
                    # Remove horizontal portion
                    keep_width=$((ORIG_WIDTH - (percentage * ORIG_WIDTH / 100) ))
                    magick "$INPUT_IMAGE" \
                        -crop ${keep_width}x${ORIG_HEIGHT}+$((ORIG_WIDTH - keep_width))+0 \
                        -background transparent \
                        -gravity East \
                        -extent ${ORIG_WIDTH}x${ORIG_HEIGHT} \
                        "$temp_tile"
                else
                    # Remove vertical portion  
                    keep_height=$((ORIG_HEIGHT - (percentage * ORIG_HEIGHT / 100) ))
                    echo $keep_height
                    magick "$INPUT_IMAGE" \
                        -crop ${ORIG_WIDTH}x${keep_height}+0+$((ORIG_HEIGHT - keep_height)) +repage \
                        -background transparent \
                        -gravity South \
                        -extent ${ORIG_WIDTH}x${ORIG_HEIGHT} \
                        "$temp_tile"
                fi
            else
                # Original masking behavior
                if [[ "$MASK_WIDTH" == true ]]; then
                    crop_width=$(( (percentage * ORIG_WIDTH) / 100 ))

                    magick "$INPUT_IMAGE" \
                        \( -clone 0 -crop ${crop_width}x${ORIG_HEIGHT}+0+0 -fill black -colorize 100% \) \
                        -compose darken -composite \
                        "$temp_tile"
                else
                    crop_height=$(( (percentage * ORIG_HEIGHT) / 100 ))

                    magick "$INPUT_IMAGE" \
                        \( -clone 0 -crop ${ORIG_WIDTH}x${crop_height}+0+0 -fill black -colorize 100% \) \
                        -compose darken -composite \
                        "$temp_tile"
                fi
            fi
        fi
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