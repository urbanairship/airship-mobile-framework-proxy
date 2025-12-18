#!/usr/bin/env bash
set -e

# Centralized Plugin Release Script
# Updates all framework plugins (React Native, Cordova, Flutter, Capacitor)
# Creates PRs in each repo with version updates and changelogs
#
# Usage: ./update_all_plugins.sh <proxy_version> [ios_version] [android_version] [options]
#
# Options:
#   --test              Add -test suffix to branch names for testing
#   --skip-react-native Skip React Native plugin
#   --skip-cordova      Skip Cordova plugin
#   --skip-flutter      Skip Flutter plugin
#   --skip-capacitor    Skip Capacitor plugin
#
# Compatible with bash 3.2+ (uses indexed arrays instead of associative arrays)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source shared utilities
source "$SCRIPT_DIR/lib/version_utils.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Check gh CLI is installed and authenticated
check_gh_auth() {
    if ! command -v gh &>/dev/null; then
        echo -e "${RED}Error: gh CLI not installed${NC}"
        echo "Install: https://cli.github.com/"
        exit 1
    fi
    if ! gh auth status &>/dev/null; then
        echo -e "${RED}Error: gh CLI not authenticated${NC}"
        echo "Run: gh auth login"
        exit 1
    fi
}

check_gh_auth

# Source changelog generation library
CHANGELOG_LIB="$SCRIPT_DIR/lib/generate_changelog.sh"
if [ ! -f "$CHANGELOG_LIB" ]; then
    echo -e "${RED}Error: Missing $CHANGELOG_LIB${NC}"
    exit 1
fi
source "$CHANGELOG_LIB"

# Parse arguments
PROXY_VERSION=""
IOS_VERSION=""
ANDROID_VERSION=""
TEST_MODE=false
SKIP_REACT_NATIVE=false
SKIP_CORDOVA=false
SKIP_FLUTTER=false
SKIP_CAPACITOR=false

for arg in "$@"; do
    case "$arg" in
        --test)
            TEST_MODE=true
            ;;
        --skip-react-native)
            SKIP_REACT_NATIVE=true
            ;;
        --skip-cordova)
            SKIP_CORDOVA=true
            ;;
        --skip-flutter)
            SKIP_FLUTTER=true
            ;;
        --skip-capacitor)
            SKIP_CAPACITOR=true
            ;;
        *)
            if [ -z "$PROXY_VERSION" ]; then
                PROXY_VERSION="$arg"
            elif [ -z "$IOS_VERSION" ]; then
                IOS_VERSION="$arg"
            elif [ -z "$ANDROID_VERSION" ]; then
                ANDROID_VERSION="$arg"
            fi
            ;;
    esac
done

if [ "$TEST_MODE" = true ]; then
    echo -e "${YELLOW}🧪 TEST MODE - Branches will have -test suffix${NC}"
    echo ""
fi

# Plugin configuration using parallel indexed arrays (bash 3.2+ compatible)
# Order: react-native, cordova, flutter, capacitor
PLUGIN_KEYS=("react-native" "cordova" "flutter" "capacitor")
REPO_NAMES=("react-native-airship" "urbanairship-cordova" "airship-flutter" "capacitor-airship")
DISPLAY_NAMES=("React Native" "Cordova" "Flutter" "Capacitor")
BRANCH_PREFIXES=("release" "cordova" "flutter" "capacitor")
NEW_VERSIONS=("" "" "" "")
PR_URLS=("" "" "" "")

# Helper functions to work with indexed arrays
get_index() {
    local key="$1"
    local i
    for i in "${!PLUGIN_KEYS[@]}"; do
        if [ "${PLUGIN_KEYS[$i]}" = "$key" ]; then
            echo "$i"
            return 0
        fi
    done
    return 1
}

get_repo_name() {
    local idx=$(get_index "$1")
    echo "${REPO_NAMES[$idx]}"
}

get_display_name() {
    local idx=$(get_index "$1")
    echo "${DISPLAY_NAMES[$idx]}"
}

get_branch_prefix() {
    local idx=$(get_index "$1")
    echo "${BRANCH_PREFIXES[$idx]}"
}

get_new_version() {
    local idx=$(get_index "$1")
    echo "${NEW_VERSIONS[$idx]}"
}

set_new_version() {
    local key="$1"
    local value="$2"
    local idx=$(get_index "$key")
    NEW_VERSIONS[$idx]="$value"
}

get_pr_url() {
    local idx=$(get_index "$1")
    echo "${PR_URLS[$idx]}"
}

set_pr_url() {
    local key="$1"
    local value="$2"
    local idx=$(get_index "$key")
    PR_URLS[$idx]="$value"
}

# Check if a plugin should be skipped
should_skip_plugin() {
    local plugin="$1"
    case "$plugin" in
        react-native) [ "$SKIP_REACT_NATIVE" = true ] ;;
        cordova) [ "$SKIP_CORDOVA" = true ] ;;
        flutter) [ "$SKIP_FLUTTER" = true ] ;;
        capacitor) [ "$SKIP_CAPACITOR" = true ] ;;
        *) return 1 ;;
    esac
}

# Check if a branch exists on remote
# Returns: 0 if exists, 1 if doesn't exist, 2 on error
branch_exists_remote() {
    local branch="$1"
    local output

    output=$(git ls-remote --heads origin "$branch" 2>&1)
    if [ $? -ne 0 ]; then
        echo "  ⚠️  Cannot check remote: $output" >&2
        return 2  # Error - caller should abort
    fi

    echo "$output" | grep -q "refs/heads/${branch}$"
}

# Check if a branch exists locally
branch_exists_local() {
    local branch="$1"
    git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null
}

# Get unique branch name for the release
# In test mode: release-X.Y.Z-test, release-X.Y.Z-test-2, release-X.Y.Z-test-3, ...
# In non-test mode: release-X.Y.Z (fails if exists - real releases shouldn't have duplicates)
# Returns: 0 success, 1 no available branch, 2 on error
get_unique_branch_name() {
    local plugin="$1"
    local version="$2"
    local base_name="$(get_branch_prefix "$plugin")-${version}"

    if [ "$TEST_MODE" = true ]; then
        # Test mode: find first available -test or -test-N suffix
        local candidate="${base_name}-test"
        local attempt=2
        local max_attempts=20

        while true; do
            branch_exists_remote "$candidate"
            local status=$?

            [ $status -eq 2 ] && return 2  # Propagate error

            if [ $status -eq 1 ] && ! branch_exists_local "$candidate"; then
                echo "$candidate"
                return 0
            fi

            candidate="${base_name}-test-${attempt}"
            attempt=$((attempt + 1))
            [ $attempt -gt $max_attempts ] && return 1
        done
    else
        # Non-test mode: use base name, fail if exists
        branch_exists_remote "$base_name"
        local status=$?

        [ $status -eq 2 ] && return 2  # Propagate error
        [ $status -eq 0 ] && return 1  # Branch exists

        echo "$base_name"
    fi
}

# Validate inputs
validate_inputs() {
    if [ -z "$PROXY_VERSION" ]; then
        echo -e "${RED}Error: proxy_version required${NC}"
        echo "Usage: $0 <proxy_version> [ios_version] [android_version] [--test] [--skip-*]"
        exit 1
    fi

    if ! [[ "$PROXY_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "${RED}Error: Invalid proxy version format: $PROXY_VERSION${NC}"
        exit 1
    fi

    if [ -n "$IOS_VERSION" ] && ! [[ "$IOS_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "${RED}Error: Invalid iOS version format: $IOS_VERSION${NC}"
        exit 1
    fi

    if [ -n "$ANDROID_VERSION" ] && ! [[ "$ANDROID_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "${RED}Error: Invalid Android version format: $ANDROID_VERSION${NC}"
        exit 1
    fi
}

# Calculate new plugin versions using smart proxy-based bumping
# For each plugin:
# 1. Get the plugin's latest release version
# 2. Get the proxy version that release was built with
# 3. Compare proxy major version changes to determine bump type
calculate_plugin_versions() {
    echo -e "${BLUE}Calculating plugin versions (smart proxy-based bumping)...${NC}"
    echo ""

    for plugin in "${PLUGIN_KEYS[@]}"; do
        local repo=$(get_repo_name "$plugin")
        local full_repo="urbanairship/${repo}"

        # Get plugin's latest release version
        local latest_version=$(get_latest_release_version "$full_repo")
        if [ $? -ne 0 ] || [ -z "$latest_version" ]; then
            echo -e "${RED}Failed to fetch version for ${repo}${NC}"
            exit 1
        fi

        # Get proxy version from that release
        local release_proxy_version=$(get_proxy_version_from_release "$full_repo" "$plugin")

        echo -e "${BOLD}${plugin}${NC}"
        echo -e "  Current version:  ${latest_version}"
        echo -e "  Release proxy:    ${release_proxy_version}"
        echo -e "  New proxy:        ${PROXY_VERSION}"

        # Determine bump type based on proxy version change
        local bump_type=$(determine_plugin_bump_type "$release_proxy_version" "$PROXY_VERSION")

        if [ "$bump_type" = "none" ]; then
            echo -e "  Bump:             ${YELLOW}none (skipping - already up to date)${NC}"
            set_new_version "$plugin" ""
            echo ""
            continue
        fi

        # Apply bump to plugin version
        IFS='.' read -r major minor patch <<< "$latest_version"
        case "$bump_type" in
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
        esac

        local new_version="${major}.${minor}.${patch}"
        set_new_version "$plugin" "$new_version"

        echo -e "  Bump:             ${GREEN}${bump_type}${NC}"
        echo -e "  New version:      ${BOLD}${new_version}${NC}"
        echo ""
    done

    # Check if any plugins need updating
    local any_update=false
    for plugin in "${PLUGIN_KEYS[@]}"; do
        if [ -n "$(get_new_version "$plugin")" ]; then
            any_update=true
            break
        fi
    done

    if [ "$any_update" = false ]; then
        echo -e "${YELLOW}No plugins need updating - all are already on proxy ${PROXY_VERSION}${NC}"
        exit 0
    fi
}

# Clone plugin repositories
clone_plugins() {
    echo -e "${BLUE}Cloning plugin repositories...${NC}"
    WORK_DIR=$(mktemp -d)
    cd "$WORK_DIR"

    # Clone repos in parallel (only non-skipped ones)
    local clone_count=0
    for plugin in "${PLUGIN_KEYS[@]}"; do
        if should_skip_plugin "$plugin"; then
            echo -e "  Skipping ${plugin} (disabled)"
            continue
        fi
        local repo="$(get_repo_name "$plugin")"
        gh repo clone "urbanairship/${repo}" -- --depth 1 &
        clone_count=$((clone_count + 1))
    done

    if [ $clone_count -gt 0 ]; then
        wait
        echo -e "${GREEN}✓ Repositories cloned${NC}"

        # Configure git credential helper for each repo to use gh
        for plugin in "${PLUGIN_KEYS[@]}"; do
            if should_skip_plugin "$plugin"; then
                continue
            fi
            local repo="$(get_repo_name "$plugin")"
            if [ -d "$repo" ]; then
                git -C "$repo" config credential.helper '!gh auth git-credential'
            fi
        done
    else
        echo -e "${YELLOW}No plugins selected to update${NC}"
    fi
    echo ""
}

# Update React Native plugin files
update_react_native_files() {
    local version="$1"
    local repo_path="$2"

    cd "$repo_path"

    # Update package.json version
    npm version "$version" --no-git-tag-version

    # Update iOS Swift version constant
    sedi "s/\(version:\ String *= *\)\".*\"/\1\"$version\"/g" ios/AirshipReactNative.swift
}

# Update Cordova plugin files
update_cordova_files() {
    local version="$1"
    local repo_path="$2"

    cd "$repo_path"

    # Update core package
    npm --prefix cordova-airship version "$version" --no-git-tag-version

    # Update HMS package
    npm --prefix cordova-airship-hms version "$version" --no-git-tag-version

    # Update plugin.xml files
    sedi "s/<plugin id=\"@ua\/cordova-airship\" version=\"[0-9.]*\"/<plugin id=\"@ua\/cordova-airship\" version=\"$version\"/" cordova-airship/plugin.xml
    sedi "s/<plugin id=\"@ua\/cordova-airship-hms\" version=\"[0-9.]*\"/<plugin id=\"@ua\/cordova-airship-hms\" version=\"$version\"/" cordova-airship-hms/plugin.xml
    sedi "s/<dependency id=\"@ua\/cordova-airship\" version=\"[0-9.]*\"\/>/<dependency id=\"@ua\/cordova-airship\" version=\"$version\"\/>/" cordova-airship-hms/plugin.xml

    # Update version constants
    sedi "s/var version = \"[-0-9.a-zA-Z]*\"/var version = \"$version\"/" cordova-airship/src/android/AirshipCordovaVersion.kt
    sedi "s/static let version = \"[-0-9.a-zA-Z]*\"/static let version = \"$version\"/" cordova-airship/src/ios/AirshipCordovaVersion.swift
}

# Update Flutter plugin files
update_flutter_files() {
    local version="$1"
    local repo_path="$2"

    cd "$repo_path"

    # Update pubspec.yaml
    sedi "s/\(^version: *\).*/\1$version/g" pubspec.yaml

    # Update podspec
    sedi "s/\(^AIRSHIP_FLUTTER_VERSION *= *\)\".*\"/\1\"$version\"/g" ios/airship_flutter.podspec

    # Update version constants
    sedi "s/\(pluginVersion *= *\)\".*\"/\1\"$version\"/g" ios/airship_flutter/Sources/airship_flutter/AirshipPluginVersion.swift
    sedi "s/\(AIRSHIP_PLUGIN_VERSION *= *\)\".*\"/\1\"$version\"/g" android/src/main/kotlin/com/airship/flutter/AirshipPluginVersion.kt
}

# Update Capacitor plugin files
update_capacitor_files() {
    local version="$1"
    local repo_path="$2"

    cd "$repo_path"

    # Update package.json
    npm version "$version" --no-git-tag-version

    # Update version constants
    sedi "s/var version = \"[-0-9.a-zA-Z]*\"/var version = \"$version\"/" android/src/main/java/com/airship/capacitor/AirshipCapacitorVersion.kt
    sedi "s/static let version = \"[-0-9.a-zA-Z]*\"/static let version = \"$version\"/" ios/Plugin/AirshipCapacitorVersion.swift
}

# Update proxy dependencies
update_proxy_dependencies() {
    local plugin="$1"
    local proxy_version="$2"

    case "$plugin" in
        react-native)
            sedi -E "s/(Airship_airshipProxyVersion=)([^$]*)/\1$proxy_version/" android/gradle.properties
            sedi -E "s/(s\.dependency *\"AirshipFrameworkProxy\", *\")([^\"]*)(\")/\1$proxy_version\3/" react-native-airship.podspec
            ;;
        cordova)
            sedi -E "s/(pod name=\"AirshipFrameworkProxy\" spec=\")[^\"]*\"/\1$proxy_version\"/" cordova-airship/plugin.xml
            sedi -E "s/(api \"com.urbanairship.android:airship-framework-proxy:)[^\"]*\"/\1$proxy_version\"/" cordova-airship/src/android/build-extras.gradle
            sedi -E "s/(implementation \"com.urbanairship.android:airship-framework-proxy-hms:)[^\"]*\"/\1$proxy_version\"/" cordova-airship-hms/src/android/build-extras.gradle
            ;;
        flutter)
            sedi -E "s/(ext\.airship_framework_proxy_version *= *')([^']*)(')/\1$proxy_version\3/" android/build.gradle
            sedi -E "s/(s\.dependency *\"AirshipFrameworkProxy\", *\")([^\"]*)(\")/\1$proxy_version\3/" ios/airship_flutter.podspec
            sedi -E "s/(\.package\(name: *\"AirshipFrameworkProxy\", *url: *\"[^\"]+\", *from: *\")([^\"]*)(\")/\1$proxy_version\3/" ios/airship_flutter/Package.swift
            ;;
        capacitor)
            sedi "s/s\.dependency.*AirshipFrameworkProxy.*$/s.dependency \"AirshipFrameworkProxy\", \"$proxy_version\"/" UaCapacitorAirship.podspec
            sedi "s/airshipProxyVersion = project\.hasProperty('airshipProxyVersion') ? rootProject\.ext\.airshipProxyVersion : '.*'/airshipProxyVersion = project.hasProperty('airshipProxyVersion') ? rootProject.ext.airshipProxyVersion : '$proxy_version'/" android/build.gradle
            sedi "s/pod 'AirshipFrameworkProxy'.*$/pod 'AirshipFrameworkProxy', '$proxy_version'/" ios/Podfile
            sedi "s/\.package(url: \"https:\/\/github\.com\/urbanairship\/airship-mobile-framework-proxy\.git\", from: \".*\")/.package(url: \"https:\/\/github.com\/urbanairship\/airship-mobile-framework-proxy.git\", from: \"$proxy_version\")/" Package.swift
            ;;
    esac
}

# Generate changelog entry using intelligent Gemini-powered generation
generate_changelog() {
    local plugin="$1"
    local version="$2"

    echo "  📝 Generating changelog..."

    # Use intelligent generation if SDK versions provided
    local changelog_entry
    if [ -n "$IOS_VERSION" ] && [ -n "$ANDROID_VERSION" ]; then
        changelog_entry=$(generate_intelligent_changelog \
            "$(get_display_name "$plugin")" \
            "$version" \
            "$IOS_VERSION" \
            "$ANDROID_VERSION")
    else
        # Fallback to simple format if no SDK versions
        changelog_entry=$(generate_simple_changelog "$version" "$IOS_VERSION" "$ANDROID_VERSION")
    fi

    # Prepend to CHANGELOG.md
    local temp_file=$(mktemp)
    local first_line=$(head -n 1 CHANGELOG.md)

    # Check if file starts with a header we should preserve (e.g., "# Changelog")
    if [[ "$first_line" =~ ^#[[:space:]] ]]; then
        # Preserve header
        echo "$first_line" > "$temp_file"
        echo "" >> "$temp_file"
        echo "$changelog_entry" >> "$temp_file"
        echo "" >> "$temp_file"
        tail -n +2 CHANGELOG.md >> "$temp_file"
    else
        # No header, just prepend
        echo "$changelog_entry" > "$temp_file"
        echo "" >> "$temp_file"
        cat CHANGELOG.md >> "$temp_file"
    fi
    mv "$temp_file" CHANGELOG.md

    echo "  ✓ Changelog updated"

    # Validate and fix the changelog (self-healing)
    # Note: This function always succeeds, it just warns about issues
    validate_and_fix "$plugin" "$version" "$IOS_VERSION" "$ANDROID_VERSION"
}

# Generate PR body
generate_pr_body() {
    local plugin="$1"
    local version="$2"

    cat <<EOF
Automated release preparation for $(get_display_name "$plugin") v${version}

## Version Updates
- Plugin: ${version}
- Framework Proxy: ${PROXY_VERSION}
- iOS SDK: ${IOS_VERSION:-not specified}
- Android SDK: ${ANDROID_VERSION:-not specified}

## Validation Reminder
⚠️ **Note:** Since this release updates the underlying native SDKs, the changelog entries across all framework plugins will be similar. This is expected and correct.

## Changed Files
\`\`\`
$(git diff --name-only HEAD~1 2>/dev/null || git diff --name-only --cached 2>/dev/null || echo "See commit for changed files")
\`\`\`

## Next Steps
1. Review version updates
2. Verify changelog accuracy
3. Merge when ready

---
🤖 Generated by centralized release automation
EOF
}

# Update a single plugin
update_plugin() {
    local plugin="$1"
    local plugin_version="$2"
    local repo_path="$3"

    echo -e "${BLUE}Updating $(get_display_name "$plugin")...${NC}"

    cd "$repo_path"

    # Get unique branch name (handles test mode auto-increment)
    local branch_name
    branch_name=$(get_unique_branch_name "$plugin" "$plugin_version")
    local branch_status=$?

    if [ $branch_status -eq 2 ]; then
        echo "  ✗ Cannot verify branch availability (network/auth error)"
        echo "    Fix the error above and retry"
        return 1
    fi

    if [ -z "$branch_name" ]; then
        if [ "$TEST_MODE" = true ]; then
            echo "  ✗ Failed to find available test branch after 20 attempts"
        else
            echo "  ✗ Branch $(get_branch_prefix "$plugin")-${plugin_version} already exists"
            echo "    For real releases, clean up the existing branch first"
            echo "    Or use --test mode for testing"
        fi
        return 1
    fi

    # Delete local branch if it exists (stale from previous run)
    if branch_exists_local "$branch_name"; then
        git branch -D "$branch_name" 2>/dev/null || true
    fi

    # Create the branch
    git checkout -b "$branch_name"
    echo "  ✓ Created branch: $branch_name"

    # Update version files (plugin-specific)
    case "$plugin" in
        react-native)
            update_react_native_files "$plugin_version" "$repo_path"
            ;;
        cordova)
            update_cordova_files "$plugin_version" "$repo_path"
            ;;
        flutter)
            update_flutter_files "$plugin_version" "$repo_path"
            ;;
        capacitor)
            update_capacitor_files "$plugin_version" "$repo_path"
            ;;
    esac

    # Update proxy dependencies
    if [ -n "$PROXY_VERSION" ]; then
        update_proxy_dependencies "$plugin" "$PROXY_VERSION"
    fi

    # Generate changelog
    generate_changelog "$plugin" "$plugin_version"

    # Commit changes
    git add .
    git commit -m "Release ${plugin_version}

- Updated plugin version to ${plugin_version}
- Updated framework proxy to ${PROXY_VERSION}
${IOS_VERSION:+- Updated iOS SDK to ${IOS_VERSION}}
${ANDROID_VERSION:+- Updated Android SDK to ${ANDROID_VERSION}}

🤖 Generated with centralized release automation"

    # Push to remote with retry logic
    local push_attempts=0
    local max_push_attempts=3
    local push_output
    while [ $push_attempts -lt $max_push_attempts ]; do
        if push_output=$(git push -u origin "$branch_name" 2>&1); then
            echo "  ✓ Pushed branch to remote"
            break
        else
            push_attempts=$((push_attempts + 1))
            if [ $push_attempts -lt $max_push_attempts ]; then
                echo "  ⚠️  Push failed, retrying... (attempt $push_attempts/$max_push_attempts)"
                sleep 5
            else
                echo "  ✗ Failed to push: $push_output"
                return 1
            fi
        fi
    done

    # Create PR and capture URL
    local pr_body=$(generate_pr_body "$plugin" "$plugin_version")

    # Check if PR already exists for this head branch
    local existing_pr=$(gh pr list \
        --repo "urbanairship/$(get_repo_name "$plugin")" \
        --head "$branch_name" \
        --json url \
        --jq '.[0].url' 2>/dev/null || echo "")

    if [ -n "$existing_pr" ]; then
        echo "  ℹ️  PR already exists for branch $branch_name"
        echo "$existing_pr"
        return 0
    fi

    # Create new PR
    local pr_title="Release ${plugin_version}"
    if [ "$TEST_MODE" = true ]; then
        pr_title="[TEST] Release ${plugin_version}"
    fi

    local pr_output
    local pr_exit_code
    pr_output=$(gh pr create \
        --title "$pr_title" \
        --body "$pr_body" \
        --label "release,automated pr" \
        --base main \
        --head "$branch_name" \
        --repo "urbanairship/$(get_repo_name "$plugin")" 2>&1)
    pr_exit_code=$?

    if [ $pr_exit_code -ne 0 ]; then
        # Check for "already exists" which is not an error
        if echo "$pr_output" | grep -q "already exists"; then
            echo "  ℹ️  PR already exists for this branch"
            PR_URL=$(gh pr list --repo "urbanairship/$(get_repo_name "$plugin")" \
                --head "$branch_name" --json url --jq '.[0].url' 2>/dev/null)
            echo "$PR_URL"
            return 0
        fi
        echo "  ✗ Failed to create PR: $pr_output" >&2
        return 1
    fi

    # Extract URL from successful output (URL is typically on its own line)
    PR_URL=$(echo "$pr_output" | grep -oE "https://github.com/[^[:space:]]+" | head -1)

    if [ -z "$PR_URL" ]; then
        echo "  ⚠️  PR created but couldn't extract URL from output" >&2
        PR_URL="CHECK_GITHUB"
    fi

    # Validate PR content
    if [ -n "$PR_URL" ] && [ "$PR_URL" != "CHECK_GITHUB" ]; then
        validate_pr "$plugin" "$plugin_version" "$PR_URL" "urbanairship/$(get_repo_name "$plugin")"
    fi

    echo "$PR_URL"
}

# Main execution
main() {
    echo -e "${BLUE}${BOLD}Centralized Plugin Release System${NC}"
    echo "===================================="
    echo -e "Proxy:   ${BOLD}${PROXY_VERSION}${NC}"
    echo -e "iOS:     ${IOS_VERSION:-not specified}"
    echo -e "Android: ${ANDROID_VERSION:-not specified}"
    echo ""

    # Validate inputs
    validate_inputs

    # Calculate plugin versions
    calculate_plugin_versions

    # Clone all repos
    clone_plugins

    # Update each plugin and collect PR URLs
    # Disable exit-on-error for plugin updates so one failure doesn't kill all
    set +e
    for plugin in "${PLUGIN_KEYS[@]}"; do
        # Skip if plugin is disabled via CLI flag
        if should_skip_plugin "$plugin"; then
            set_pr_url "$plugin" "SKIPPED"
            continue
        fi

        # Skip if no version update needed (empty version = already up to date)
        local plugin_version="$(get_new_version "$plugin")"
        if [ -z "$plugin_version" ]; then
            set_pr_url "$plugin" "UP-TO-DATE"
            continue
        fi

        echo ""

        # Update plugin (with error handling)
        local error_file=$(mktemp)
        if pr_url=$(update_plugin "$plugin" "$plugin_version" "$WORK_DIR/$(get_repo_name "$plugin")" 2>"$error_file"); then
            set_pr_url "$plugin" "$pr_url"
            echo -e "  ${GREEN}✓ PR created: $pr_url${NC}"
        else
            echo -e "  ${RED}✗ Failed to update ${plugin}${NC}"
            echo -e "  Error: $(cat "$error_file")"
            set_pr_url "$plugin" "FAILED"
        fi
        rm -f "$error_file"
    done
    # Re-enable exit-on-error
    set -e

    # Output summary
    echo ""
    echo -e "${GREEN}${BOLD}✅ Release Preparation Complete${NC}"
    echo "===================================="
    echo ""

    for plugin in "${PLUGIN_KEYS[@]}"; do
        local pr_url="$(get_pr_url "$plugin")"
        local plugin_version="$(get_new_version "$plugin")"
        local status_icon="✓"
        local color="$GREEN"
        if [ "$pr_url" = "FAILED" ]; then
            status_icon="✗"
            color="$RED"
        elif [ "$pr_url" = "SKIPPED" ]; then
            status_icon="○"
            color="$YELLOW"
        elif [ "$pr_url" = "UP-TO-DATE" ]; then
            status_icon="="
            color="$BLUE"
        fi
        echo -e "${color}${status_icon} $(get_display_name "$plugin") ${plugin_version:-current}: ${pr_url}${NC}"
    done

    echo ""

    # Output for GitHub Actions
    if [ -n "$GITHUB_OUTPUT" ]; then
        for plugin in "${PLUGIN_KEYS[@]}"; do
            echo "${plugin//-/_}_version=$(get_new_version "$plugin")" >> "$GITHUB_OUTPUT"
            echo "${plugin//-/_}_pr_url=$(get_pr_url "$plugin")" >> "$GITHUB_OUTPUT"
        done
    fi

    # Check if any plugins succeeded (UP-TO-DATE counts as success)
    local any_success=false
    for plugin in "${PLUGIN_KEYS[@]}"; do
        local url="$(get_pr_url "$plugin")"
        if [ "$url" != "FAILED" ] && [ "$url" != "SKIPPED" ] && [ -n "$url" ]; then
            any_success=true
            break
        fi
    done

    if [ "$any_success" = false ]; then
        echo -e "${RED}All plugins failed to update${NC}"
        [ -n "$WORK_DIR" ] && rm -rf "$WORK_DIR"
        exit 1
    fi

    # Cleanup
    [ -n "$WORK_DIR" ] && rm -rf "$WORK_DIR"
}

main "$@"
