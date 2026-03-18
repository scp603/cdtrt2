#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: dotify.sh <directory>"
    exit 1
fi

target="$(realpath "$1")"

if [ ! -d "$target" ]; then
    echo "Error: '$1' is not a directory"
    exit 1
fi

count=0
for item in "$target"/*; do
    [ -e "$item" ] || continue
    base="$(basename "$item")"
    # skip if already dotted
    if [[ "$base" == .* ]]; then
        continue
    fi
    mv "$item" "$target/.$base"
    ((count++))
done

echo "Dotified $count items in $target"
