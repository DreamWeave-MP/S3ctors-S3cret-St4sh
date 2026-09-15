#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-all}"

run_target() {
    case "$1" in
        hero)
            "$SCRIPT_DIR/hero.sh"
            ;;
        scope)
            "$SCRIPT_DIR/scope.sh"
            ;;
        mark)
            "$SCRIPT_DIR/mark.sh"
            ;;
        all)
            "$SCRIPT_DIR/hero.sh"
            "$SCRIPT_DIR/scope.sh"
            "$SCRIPT_DIR/mark.sh"
            ;;
        *)
            printf 'Usage: %s [all|hero|scope|mark]\n' "$0" >&2
            exit 2
            ;;
    esac
}

run_target "$TARGET" "${2:-}" "${3:-}" "${4:-}"
