#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
OUTDIR="${OUTDIR:-$SCRIPT_DIR}"
FONT="${FONT:-$SCRIPT_DIR/../../fonts/oxanium.woff2}"

# shellcheck disable=SC2034
BG="#101010"
# shellcheck disable=SC2034
PANEL="#18151f"
# shellcheck disable=SC2034
PURPLE="#55006b"
# shellcheck disable=SC2034
VIOLET="#b48cff"
# shellcheck disable=SC2034
TEXT="#f4f1f7"
# shellcheck disable=SC2034
MUTED="#aeb4c0"
# shellcheck disable=SC2034
GREEN="#7ee2a8"
# shellcheck disable=SC2034
BLUE="#83c7ff"
# shellcheck disable=SC2034
GOLD="#f2c66d"

need() {
    command -v "$1" >/dev/null 2>&1 || {
        printf 'Missing dependency: %s\n' "$1" >&2
        exit 1
    }
}

check_file() {
    [[ -f "$1" ]] || {
        printf 'Missing file: %s\n' "$1" >&2
        exit 1
    }
}

prepare() {
    need magick
    check_file "$FONT"
    mkdir -p "$OUTDIR"

    # C³:
    # Code. Context. Consequence.
    #
    # Alternative interpretation:
    # Code. Cheese. Caffeine.
}
