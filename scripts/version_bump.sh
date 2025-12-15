#!/usr/bin/env bash

# Script to update version numbers in Airship Mobile Framework Proxy

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared utilities
source "$SCRIPT_DIR/lib/version_utils.sh"

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

# Get current versions
get_current_versions() {
  echo -e "${INFO} Detecting current versions..."
  
  # Check iOS SDK version from Podfile
  IOS_SDK_CURRENT=$(grep "pod 'Airship'" ios/Podfile | grep -o "[0-9]*\.[0-9]*\.[0-9]*" || echo "unknown")
  
  # Check Android SDK version from libs.versions.toml
  ANDROID_SDK_CURRENT=$(grep "airship =" android/gradle/libs.versions.toml | grep -o "[0-9]*\.[0-9]*\.[0-9]*" || echo "unknown")
  
  # Check proxy version from podspec
  PROXY_CURRENT=$(grep "s.version" AirshipFrameworkProxy.podspec | grep -o "[0-9]*\.[0-9]*\.[0-9]*" || echo "unknown")
  
  echo -e "${CHECK} Current versions detected:"
  echo -e "   ${BOLD}Proxy:${NC}        ${PROXY_CURRENT}"
  echo -e "   ${BOLD}iOS SDK:${NC}      ${IOS_SDK_CURRENT}"
  echo -e "   ${BOLD}Android SDK:${NC}  ${ANDROID_SDK_CURRENT}"
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
  
  read -p "$name version [$default]: " version
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
    sedi "s/s.version[[:space:]]*=[[:space:]]*\"[0-9]*\.[0-9]*\.[0-9]*\"/s.version                 = \"${proxy_version}\"/" AirshipFrameworkProxy.podspec
    sedi "s/s.dependency[[:space:]]*'Airship',[[:space:]]*\"[0-9]*\.[0-9]*\.[0-9]*\"/s.dependency                'Airship', \"${ios_sdk_version}\"/" AirshipFrameworkProxy.podspec
  else
    echo -e "${WARN} AirshipFrameworkProxy.podspec not found"
  fi

  # Package.swift
  if [ -f "Package.swift" ]; then
    echo -e "${INFO} Updating Package.swift"
    sedi "s/from: \"[0-9]*\.[0-9]*\.[0-9]*\"/from: \"${ios_sdk_version}\"/" Package.swift
  else
    echo -e "${WARN} Package.swift not found"
  fi

  # iOS Podfile
  if [ -f "ios/Podfile" ]; then
    echo -e "${INFO} Updating ios/Podfile"
    sedi "s/pod 'Airship', '[0-9]*\.[0-9]*\.[0-9]*'/pod 'Airship', '${ios_sdk_version}'/" ios/Podfile
  else
    echo -e "${WARN} ios/Podfile not found"
  fi

  # Android libs.versions.toml
  if [ -f "android/gradle/libs.versions.toml" ]; then
    echo -e "${INFO} Updating android/gradle/libs.versions.toml"
    sedi "s/airshipProxy = '[0-9]*\.[0-9]*\.[0-9]*'/airshipProxy = '${proxy_version}'/" android/gradle/libs.versions.toml
    sedi "s/airship = '[0-9]*\.[0-9]*\.[0-9]*'/airship = '${android_sdk_version}'/" android/gradle/libs.versions.toml
  else
    echo -e "${WARN} android/gradle/libs.versions.toml not found"
  fi
  
  echo -e "\n${CHECK} ${GREEN}All files updated successfully!${NC}"
}

# Verify changes
verify_changes() {
  echo -e "\n${INFO} Verifying changes..."
  
  git diff --color AirshipFrameworkProxy.podspec Package.swift ios/Podfile android/gradle/libs.versions.toml
  
  echo -e "\n${INFO} Next steps:"
  echo -e "   1. Review the changes above"
  echo -e "   2. Run 'pod install' in the ios directory"
  echo -e "   3. PR the changes"
}

# Main execution
get_current_versions

echo -e "${BLUE}${BOLD}Enter new versions (press Enter to keep current)${NC}"
PROXY_VERSION=$(prompt_version "$PROXY_CURRENT" "Proxy" "14.1.1")
IOS_SDK_VERSION=$(prompt_version "$IOS_SDK_CURRENT" "iOS SDK" "19.2.1")
ANDROID_SDK_VERSION=$(prompt_version "$ANDROID_SDK_CURRENT" "Android SDK" "19.5.1")

update_versions "$PROXY_VERSION" "$IOS_SDK_VERSION" "$ANDROID_SDK_VERSION"
verify_changes

echo -e "\n${ROCKET} ${GREEN}${BOLD}Version bump complete!${NC} ${ROCKET}"
