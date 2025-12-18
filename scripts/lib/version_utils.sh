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

# Get proxy version from a plugin's latest release
# Uses GitHub API to fetch file contents from the release tag
# Args: $1 = repo (e.g., "urbanairship/react-native-airship"), $2 = plugin type
get_proxy_version_from_release() {
    local repo="$1"
    local plugin="$2"

    # Get latest release tag
    local tag=$(gh api "repos/${repo}/releases/latest" --jq '.tag_name' 2>/dev/null)
    if [ -z "$tag" ]; then
        # Fallback to tags if no releases
        tag=$(gh api "repos/${repo}/tags" --jq '.[0].name' 2>/dev/null)
    fi

    if [ -z "$tag" ]; then
        echo "0.0.0"  # Default if no releases found
        return 0
    fi

    # Fetch proxy version from appropriate file based on plugin type
    local proxy_version=""
    case "$plugin" in
        react-native)
            # From react-native-airship.podspec: s.dependency "AirshipFrameworkProxy", "X.Y.Z"
            proxy_version=$(gh api "repos/${repo}/contents/react-native-airship.podspec?ref=${tag}" \
                --jq '.content' 2>/dev/null | base64 -d | \
                grep -o 'AirshipFrameworkProxy.*"[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"' | \
                grep -o '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*' | head -1)
            ;;
        cordova)
            # From cordova-airship/plugin.xml: pod name="AirshipFrameworkProxy" spec="X.Y.Z"
            proxy_version=$(gh api "repos/${repo}/contents/cordova-airship/plugin.xml?ref=${tag}" \
                --jq '.content' 2>/dev/null | base64 -d | \
                grep -o 'AirshipFrameworkProxy.*spec="[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"' | \
                grep -o '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*' | head -1)
            ;;
        flutter)
            # From ios/airship_flutter.podspec: s.dependency "AirshipFrameworkProxy", "X.Y.Z"
            proxy_version=$(gh api "repos/${repo}/contents/ios/airship_flutter.podspec?ref=${tag}" \
                --jq '.content' 2>/dev/null | base64 -d | \
                grep -o 'AirshipFrameworkProxy.*"[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"' | \
                grep -o '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*' | head -1)
            ;;
        capacitor)
            # From UaCapacitorAirship.podspec: s.dependency "AirshipFrameworkProxy", "X.Y.Z"
            proxy_version=$(gh api "repos/${repo}/contents/UaCapacitorAirship.podspec?ref=${tag}" \
                --jq '.content' 2>/dev/null | base64 -d | \
                grep -o 'AirshipFrameworkProxy.*"[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"' | \
                grep -o '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*' | head -1)
            ;;
    esac

    if [ -z "$proxy_version" ]; then
        echo "0.0.0"  # Default if parsing failed
    else
        echo "$proxy_version"
    fi
}

# Determine plugin bump type based on proxy major version change
# Compares proxy version at plugin's last release vs current proxy version
# Args: $1 = old proxy version, $2 = new proxy version
determine_plugin_bump_type() {
    local old_proxy="$1"
    local new_proxy="$2"

    IFS='.' read -r old_major old_minor old_patch <<< "$old_proxy"
    IFS='.' read -r new_major new_minor new_patch <<< "$new_proxy"

    # Major version change in proxy = major bump for plugin
    if [ "$new_major" -gt "$old_major" ]; then
        echo "major"
    # Minor version change in proxy = minor bump for plugin
    elif [ "$new_minor" -gt "$old_minor" ]; then
        echo "minor"
    # Patch version change in proxy = patch bump for plugin
    elif [ "$new_patch" -gt "$old_patch" ]; then
        echo "patch"
    else
        echo "none"
    fi
}
