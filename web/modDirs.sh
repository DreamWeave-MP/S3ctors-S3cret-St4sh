#!/usr/bin/env sh
find "$1" -maxdepth 1 -type d -printf "%f\n" \
    | grep -v "\.\|.git\|web" \
    | sort \
    | tr '\n' ' '
