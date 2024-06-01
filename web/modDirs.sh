#!/usr/bin/env sh
find "$1" -mindepth 1 -maxdepth 1 -type d \
    | sed 's|.*/||' \
    | grep -v ".git\|web" \
    | sort \
    | tr '\n' ' '
