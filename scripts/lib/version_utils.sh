#!/usr/bin/env bash
# Shared utilities for version management scripts

# Portable sed -i (macOS vs GNU)
sedi() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

# Determine bump type (major, minor, patch)
determine_bump_type() {
    local old=$1
    local new=$2

    IFS='.' read -r old_major old_minor old_patch <<< "$old"
    IFS='.' read -r new_major new_minor new_patch <<< "$new"

    if [ "$new_major" -gt "$old_major" ]; then
        echo "major"
    elif [ "$new_minor" -gt "$old_minor" ]; then
        echo "minor"
    elif [ "$new_patch" -gt "$old_patch" ]; then
        echo "patch"
    else
        echo "none"
    fi
}
