#!/usr/bin/env bash
set -e

# Prepare proxy release: update versions, dependencies, changelog
# Usage: ./prep_proxy_release.sh [--test]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source shared utilities
source "$SCRIPT_DIR/lib/version_utils.sh"

# Parse arguments
TEST_MODE=false
if [ "$1" = "--test" ]; then
    TEST_MODE=true
    echo "🧪 TEST MODE - No changes will be made"
    echo ""
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BLUE}${BOLD}Preparing Proxy Release${NC}\n"

# Run detection script to get versions
DETECT_OUTPUT=$("$SCRIPT_DIR/detect_sdk_versions.sh")
echo "$DETECT_OUTPUT"
echo ""

# Extract versions from output
PROXY_VERSION=$(echo "$DETECT_OUTPUT" | grep "^PROXY_VERSION=" | cut -d'=' -f2)
IOS_VERSION=$(echo "$DETECT_OUTPUT" | grep "^IOS_VERSION=" | cut -d'=' -f2)
ANDROID_VERSION=$(echo "$DETECT_OUTPUT" | grep "^ANDROID_VERSION=" | cut -d'=' -f2)
BUMP_TYPE=$(echo "$DETECT_OUTPUT" | grep "^BUMP_TYPE=" | cut -d'=' -f2)

if [ -z "$PROXY_VERSION" ] || [ "$BUMP_TYPE" = "none" ]; then
    echo -e "${RED}No version bump needed${NC}"
    exit 1
fi

echo -e "${BLUE}Updating files...${NC}"

# Update AirshipFrameworkProxy.podspec
if [ "$TEST_MODE" = "false" ]; then
    sedi "s/s.version[[:space:]]*=[[:space:]]*\"[0-9]*\.[0-9]*\.[0-9]*\"/s.version                 = \"${PROXY_VERSION}\"/" "$REPO_ROOT/AirshipFrameworkProxy.podspec"
    sedi "s/s.dependency[[:space:]]*'Airship',[[:space:]]*\"[0-9]*\.[0-9]*\.[0-9]*\"/s.dependency                'Airship', \"${IOS_VERSION}\"/" "$REPO_ROOT/AirshipFrameworkProxy.podspec"
    echo "✓ Updated AirshipFrameworkProxy.podspec"
else
    echo "  Would update AirshipFrameworkProxy.podspec:"
    echo "    version: $PROXY_VERSION"
    echo "    iOS SDK: $IOS_VERSION"
fi

# Update Package.swift
if [ "$TEST_MODE" = "false" ]; then
    sedi "s/from: \"[0-9]*\.[0-9]*\.[0-9]*\"/from: \"${IOS_VERSION}\"/" "$REPO_ROOT/Package.swift"
    echo "✓ Updated Package.swift"
else
    echo "  Would update Package.swift:"
    echo "    iOS SDK: $IOS_VERSION"
fi

# Update android/gradle/libs.versions.toml
if [ "$TEST_MODE" = "false" ]; then
    sedi "s/airshipProxy = '[0-9]*\.[0-9]*\.[0-9]*'/airshipProxy = '${PROXY_VERSION}'/" "$REPO_ROOT/android/gradle/libs.versions.toml"
    sedi "s/airship = '[0-9]*\.[0-9]*\.[0-9]*'/airship = '${ANDROID_VERSION}'/" "$REPO_ROOT/android/gradle/libs.versions.toml"
    echo "✓ Updated android/gradle/libs.versions.toml"
else
    echo "  Would update android/gradle/libs.versions.toml:"
    echo "    proxy version: $PROXY_VERSION"
    echo "    Android SDK: $ANDROID_VERSION"
fi

echo -e "\n${GREEN}${BOLD}✓ Proxy release prepared${NC}"
echo -e "Version: ${BOLD}${PROXY_VERSION}${NC}"
echo -e "iOS SDK: ${BOLD}${IOS_VERSION}${NC}"
echo -e "Android SDK: ${BOLD}${ANDROID_VERSION}${NC}"

if [ "$TEST_MODE" = "false" ]; then
    echo -e "\n${BLUE}Next steps:${NC}"
    echo "1. Review changes: git diff"
    echo "2. Commit and push to branch"
    echo "3. Create PR"
fi
