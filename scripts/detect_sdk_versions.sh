#!/usr/bin/env bash
set -e

# Detect SDK versions and calculate proxy version bump
# Outputs: PROXY_VERSION, IOS_VERSION, ANDROID_VERSION, BUMP_TYPE

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source shared utilities
source "$SCRIPT_DIR/lib/version_utils.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Check gh CLI authentication
if ! gh auth status &>/dev/null; then
    echo -e "${RED}Error: gh CLI not authenticated${NC}"
    echo "Run: gh auth login"
    exit 1
fi

echo -e "${BLUE}${BOLD}Detecting SDK Versions${NC}\n"

# Get current proxy version from podspec
CURRENT_PROXY_VERSION=$(grep "s.version" "$REPO_ROOT/AirshipFrameworkProxy.podspec" | grep -o "[0-9]*\.[0-9]*\.[0-9]*")
echo -e "Current proxy version: ${BOLD}$CURRENT_PROXY_VERSION${NC}"

# Get current iOS SDK dependency
CURRENT_IOS_VERSION=$(grep "s.dependency.*'Airship'" "$REPO_ROOT/AirshipFrameworkProxy.podspec" | grep -o "[0-9]*\.[0-9]*\.[0-9]*")
echo -e "Current iOS SDK:       ${BOLD}$CURRENT_IOS_VERSION${NC}"

# Get current Android SDK dependency
CURRENT_ANDROID_VERSION=$(grep "airship =" "$REPO_ROOT/android/gradle/libs.versions.toml" | grep -o "[0-9]*\.[0-9]*\.[0-9]*")
echo -e "Current Android SDK:   ${BOLD}$CURRENT_ANDROID_VERSION${NC}"

echo -e "\n${BLUE}Fetching latest SDK tags...${NC}"

# Fetch latest iOS SDK tag
LATEST_IOS_VERSION=$(gh api repos/urbanairship/ios-library/tags --jq '.[0].name' 2>/dev/null || echo "")
LATEST_IOS_VERSION="${LATEST_IOS_VERSION#v}"  # Strip 'v' prefix if present
if [ -z "$LATEST_IOS_VERSION" ]; then
    echo -e "${RED}Failed to fetch iOS SDK tags${NC}"
    exit 1
fi
echo -e "Latest iOS SDK:        ${BOLD}$LATEST_IOS_VERSION${NC}"

# Fetch latest Android SDK tag
LATEST_ANDROID_VERSION=$(gh api repos/urbanairship/android-library/tags --jq '.[0].name' 2>/dev/null || echo "")
LATEST_ANDROID_VERSION="${LATEST_ANDROID_VERSION#v}"  # Strip 'v' prefix if present
if [ -z "$LATEST_ANDROID_VERSION" ]; then
    echo -e "${RED}Failed to fetch Android SDK tags${NC}"
    exit 1
fi
echo -e "Latest Android SDK:    ${BOLD}$LATEST_ANDROID_VERSION${NC}"

# Determine bump types for each SDK
IOS_BUMP=$(determine_bump_type "$CURRENT_IOS_VERSION" "$LATEST_IOS_VERSION")
ANDROID_BUMP=$(determine_bump_type "$CURRENT_ANDROID_VERSION" "$LATEST_ANDROID_VERSION")

echo -e "\n${BLUE}SDK Changes:${NC}"
echo -e "iOS:     ${CURRENT_IOS_VERSION} → ${LATEST_IOS_VERSION} (${BOLD}${IOS_BUMP}${NC})"
echo -e "Android: ${CURRENT_ANDROID_VERSION} → ${LATEST_ANDROID_VERSION} (${BOLD}${ANDROID_BUMP}${NC})"

# Determine overall bump type (max of both)
if [ "$IOS_BUMP" = "major" ] || [ "$ANDROID_BUMP" = "major" ]; then
    BUMP_TYPE="major"
elif [ "$IOS_BUMP" = "minor" ] || [ "$ANDROID_BUMP" = "minor" ]; then
    BUMP_TYPE="minor"
elif [ "$IOS_BUMP" = "patch" ] || [ "$ANDROID_BUMP" = "patch" ]; then
    BUMP_TYPE="patch"
else
    BUMP_TYPE="none"
fi

# Calculate new proxy version
IFS='.' read -r major minor patch <<< "$CURRENT_PROXY_VERSION"
case "$BUMP_TYPE" in
    major)
        major=$((major + 1))
        minor=0
        patch=0
        ;;
    minor)
        minor=$((minor + 1))
        patch=0
        ;;
    patch)
        patch=$((patch + 1))
        ;;
    none)
        echo -e "\n${YELLOW}No SDK version changes detected. No proxy bump needed.${NC}"
        exit 0
        ;;
esac

NEW_PROXY_VERSION="$major.$minor.$patch"

echo -e "\n${GREEN}${BOLD}Bump Decision:${NC}"
echo -e "Type:        ${BOLD}${BUMP_TYPE}${NC}"
echo -e "New version: ${BOLD}${NEW_PROXY_VERSION}${NC}"

# Output for GitHub Actions / scripts
echo ""
echo "PROXY_VERSION=$NEW_PROXY_VERSION"
echo "IOS_VERSION=$LATEST_IOS_VERSION"
echo "ANDROID_VERSION=$LATEST_ANDROID_VERSION"
echo "BUMP_TYPE=$BUMP_TYPE"

# If running in GitHub Actions, set outputs
if [ -n "$GITHUB_OUTPUT" ]; then
    echo "proxy_version=$NEW_PROXY_VERSION" >> "$GITHUB_OUTPUT"
    echo "ios_version=$LATEST_IOS_VERSION" >> "$GITHUB_OUTPUT"
    echo "android_version=$LATEST_ANDROID_VERSION" >> "$GITHUB_OUTPUT"
    echo "bump_type=$BUMP_TYPE" >> "$GITHUB_OUTPUT"
fi
