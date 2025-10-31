#!/bin/bash

# Script to update version numbers in Airship Mobile Framework Proxy

set -e

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Emojis
ROCKET="🚀"
CHECK="✅"
WARN="⚠️"
INFO="ℹ️"
ERROR="❌"
SPARKLE="✨"

echo -e "${BLUE}${BOLD}${ROCKET} Airship Mobile Framework Proxy Version Bumper ${ROCKET}${NC}\n"

# Fetch latest release version from GitHub
fetch_latest_release() {
  local repo=$1
  local version=$(curl -s "https://api.github.com/repos/${repo}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')

  # If API call fails or rate limited, try gh CLI as fallback
  if [ -z "$version" ] && command -v gh &> /dev/null; then
    version=$(gh release view --repo "${repo}" --json tagName -q .tagName 2>/dev/null | sed 's/^v//')
  fi

  echo "$version"
}

# Get latest SDK releases from GitHub
get_latest_releases() {
  echo -e "${INFO} Checking latest SDK releases from GitHub..."

  IOS_SDK_LATEST=$(fetch_latest_release "urbanairship/ios-library")
  ANDROID_SDK_LATEST=$(fetch_latest_release "urbanairship/android-library")

  if [ -z "$IOS_SDK_LATEST" ]; then
    IOS_SDK_LATEST="unknown"
  fi

  if [ -z "$ANDROID_SDK_LATEST" ]; then
    ANDROID_SDK_LATEST="unknown"
  fi

  echo ""
}

# Get current versions
get_current_versions() {
  echo -e "${INFO} Detecting current versions..."

  # Check iOS SDK version from podspec dependency
  IOS_SDK_CURRENT=$(grep "s.dependency.*'Airship'" AirshipFrameworkProxy.podspec | grep -o "[0-9]*\.[0-9]*\.[0-9]*" | head -1 || echo "unknown")

  # Check Android SDK version from libs.versions.toml
  ANDROID_SDK_CURRENT=$(grep "^airship =" android/gradle/libs.versions.toml | grep -o "[0-9]*\.[0-9]*\.[0-9]*" | head -1 || echo "unknown")

  # Check proxy version from podspec (only the first s.version line, not s.source)
  PROXY_CURRENT=$(grep "^[[:space:]]*s\.version" AirshipFrameworkProxy.podspec | grep -o "[0-9]*\.[0-9]*\.[0-9]*" | head -1 || echo "unknown")

  echo -e "${CHECK} Version comparison:"
  echo ""
  printf "   ${BOLD}%-20s %-15s %-15s${NC}\n" "Component" "Current" "Latest"
  printf "   %-20s %-15s %-15s\n" "--------------------" "---------------" "---------------"
  printf "   %-20s %-15s %-15s\n" "Proxy" "${PROXY_CURRENT}" "N/A"

  # Show iOS SDK comparison
  if [ "$IOS_SDK_LATEST" != "unknown" ] && [ "$IOS_SDK_CURRENT" != "$IOS_SDK_LATEST" ]; then
    printf "   %-20s %-15s ${GREEN}%-15s${NC}\n" "iOS SDK" "${IOS_SDK_CURRENT}" "${IOS_SDK_LATEST} ⬆"
  else
    printf "   %-20s %-15s %-15s\n" "iOS SDK" "${IOS_SDK_CURRENT}" "${IOS_SDK_LATEST}"
  fi

  # Show Android SDK comparison
  if [ "$ANDROID_SDK_LATEST" != "unknown" ] && [ "$ANDROID_SDK_CURRENT" != "$ANDROID_SDK_LATEST" ]; then
    printf "   %-20s %-15s ${GREEN}%-15s${NC}\n" "Android SDK" "${ANDROID_SDK_CURRENT}" "${ANDROID_SDK_LATEST} ⬆"
  else
    printf "   %-20s %-15s %-15s\n" "Android SDK" "${ANDROID_SDK_CURRENT}" "${ANDROID_SDK_LATEST}"
  fi

  echo ""
}

# Function to prompt for version with a fallback
prompt_version() {
  local current=$1
  local name=$2
  local default=$3

  if [ -z "$default" ]; then
    default=$current
  fi

  read -p "$name version [$default]: " version >&2
  version=${version:-$default}
  echo $version
}

# Update the versions in all appropriate files
update_versions() {
  local proxy_version=$1
  local ios_sdk_version=$2
  local android_sdk_version=$3
  
  echo -e "\n${INFO} Updating to these versions:"
  echo -e "   ${BOLD}Proxy:${NC}        ${proxy_version}"
  echo -e "   ${BOLD}iOS SDK:${NC}      ${ios_sdk_version}"
  echo -e "   ${BOLD}Android SDK:${NC}  ${android_sdk_version}"
  
  echo -e "\n${SPARKLE} Updating files..."
  
  # Podspec file
  if [ -f "AirshipFrameworkProxy.podspec" ]; then
    echo -e "${INFO} Updating AirshipFrameworkProxy.podspec"
    # Match version pattern more flexibly (handles numbers or corrupted values)
    sed -i '' "s/\(s.version[[:space:]]*=[[:space:]]*\)\"[^\"]*\"/\1\"${proxy_version}\"/" AirshipFrameworkProxy.podspec
    sed -i '' "s/\(s.dependency[[:space:]]*'Airship',[[:space:]]*\)\"[^\"]*\"/\1\"${ios_sdk_version}\"/" AirshipFrameworkProxy.podspec
  else
    echo -e "${WARN} AirshipFrameworkProxy.podspec not found"
  fi
  
  # Package.swift
  if [ -f "Package.swift" ]; then
    echo -e "${INFO} Updating Package.swift"
    sed -i '' "s/\(from: \)\"[^\"]*\"/\1\"${ios_sdk_version}\"/" Package.swift
  else
    echo -e "${WARN} Package.swift not found"
  fi

  # Android libs.versions.toml
  if [ -f "android/gradle/libs.versions.toml" ]; then
    echo -e "${INFO} Updating android/gradle/libs.versions.toml"
    # Match version pattern more flexibly (handles numbers or corrupted values)
    sed -i '' "s/\(^airshipProxy = \)'[^']*'/\1'${proxy_version}'/" android/gradle/libs.versions.toml
    sed -i '' "s/\(^airship = \)'[^']*'/\1'${android_sdk_version}'/" android/gradle/libs.versions.toml
  else
    echo -e "${WARN} android/gradle/libs.versions.toml not found"
  fi
  
  echo -e "\n${CHECK} ${GREEN}All files updated successfully!${NC}"
}

# Verify changes
verify_changes() {
  echo -e "\n${INFO} Verifying changes..."

  git diff --color AirshipFrameworkProxy.podspec Package.swift android/gradle/libs.versions.toml

  echo -e "\n${INFO} Next steps:"
  echo -e "   1. Review the changes above"
  echo -e "   2. Commit and push the changes"
  echo -e "   3. Create a PR"
}

# Main execution
get_latest_releases
get_current_versions

echo -e "${BLUE}${BOLD}Enter new versions (press Enter to keep current)${NC}"
PROXY_VERSION=$(prompt_version "$PROXY_CURRENT" "Proxy")
IOS_SDK_VERSION=$(prompt_version "$IOS_SDK_CURRENT" "iOS SDK")
ANDROID_SDK_VERSION=$(prompt_version "$ANDROID_SDK_CURRENT" "Android SDK")

update_versions "$PROXY_VERSION" "$IOS_SDK_VERSION" "$ANDROID_SDK_VERSION"
verify_changes

echo -e "\n${ROCKET} ${GREEN}${BOLD}Version bump complete!${NC} ${ROCKET}"
