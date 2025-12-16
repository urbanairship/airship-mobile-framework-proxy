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

# Get highest semver version from a GitHub repo
# Uses releases API (preferred), falls back to tags
# Filters for valid semver, strips 'v' prefix, sorts semantically
get_latest_release_version() {
    local repo="$1"
    local error_file=$(mktemp)
    local versions

    # Try releases API first (preferred - explicitly published versions)
    versions=$(gh api "repos/${repo}/releases" --paginate --jq '.[].tag_name' 2>"$error_file")

    # Fallback to tags if no releases found
    if [ -z "$versions" ]; then
        versions=$(gh api "repos/${repo}/tags" --paginate --jq '.[].name' 2>"$error_file")
    fi

    # Check for API errors
    if [ -z "$versions" ] && [ -s "$error_file" ]; then
        echo "  API error: $(cat "$error_file")" >&2
        rm -f "$error_file"
        return 1
    fi
    rm -f "$error_file"

    # Filter to valid semver, strip 'v' prefix, sort semantically, get highest
    local result=$(echo "$versions" | \
        grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$' | \
        sed 's/^v//' | \
        sort -t. -k1,1n -k2,2n -k3,3n | \
        tail -1)

    # Validate result is a proper version
    if ! [[ "$result" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "  No valid semver releases found" >&2
        return 1
    fi

    echo "$result"
}
