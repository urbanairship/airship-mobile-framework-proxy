#!/usr/bin/env bash
# Intelligent changelog generation using Gemini CLI
# Fetches SDK changelogs, analyzes them, and generates appropriate format

# Get script directory
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPT_TEMPLATE="$LIB_DIR/changelog_prompt.txt"

# Source shared utilities
source "$LIB_DIR/version_utils.sh"

# Fetch SDK changelog from GitHub release notes
fetch_github_changelog() {
    local repo="$1"
    local version="$2"

    echo "  📥 Fetching ${repo} ${version} changelog..." >&2

    # Fetch release notes from GitHub API
    local changelog=$(gh api \
        "repos/urbanairship/${repo}/releases/tags/${version}" \
        --jq '.body' 2>/dev/null || echo "")

    if [ -z "$changelog" ]; then
        echo "  ⚠️  No changelog found for ${repo} ${version}" >&2
        return 1
    fi

    echo "  ✓ Fetched ${repo} changelog (${#changelog} chars)" >&2
    echo "$changelog"
}

# Generate simple fallback changelog
generate_simple_changelog() {
    local plugin_version="$1"
    local ios_version="$2"
    local android_version="$3"
    local release_date=$(date +'%B %e, %Y' | sed 's/  / /')

    # Determine release type based on version pattern
    local release_type="Patch"
    if [[ $plugin_version =~ \.0\.0$ ]]; then
        release_type="Major"
    elif [[ $plugin_version =~ \.0$ ]]; then
        release_type="Minor"
    fi

    cat <<EOF
## Version ${plugin_version} - ${release_date}

${release_type} release that updates the Android SDK to ${android_version} and the iOS SDK to ${ios_version}.

### Changes
- Updated Android SDK to [${android_version}](https://github.com/urbanairship/android-library/releases/tag/${android_version})
- Updated iOS SDK to [${ios_version}](https://github.com/urbanairship/ios-library/releases/tag/${ios_version})
EOF
}

# Use Gemini CLI to analyze changelogs and decide format
gemini_analyze_changelog() {
    local plugin_name="$1"
    local plugin_version="$2"
    local ios_version="$3"
    local android_version="$4"
    local ios_changelog="$5"
    local android_changelog="$6"

    # Check if prompt template exists
    if [ ! -f "$PROMPT_TEMPLATE" ]; then
        echo "  ⚠️  Prompt template not found at $PROMPT_TEMPLATE" >&2
        echo "  Using simple changelog format" >&2
        generate_simple_changelog "$plugin_version" "$ios_version" "$android_version"
        return 0
    fi

    # Check if Gemini CLI is available
    if ! command -v gemini &> /dev/null; then
        echo "  ⚠️  Gemini CLI not found, using simple changelog format" >&2
        generate_simple_changelog "$plugin_version" "$ios_version" "$android_version"
        return 0
    fi

    echo "  🤖 Analyzing changelogs with Gemini..." >&2

    # Read template and substitute variables
    local prompt=$(cat "$PROMPT_TEMPLATE")
    local release_date=$(date +'%B %e, %Y' | sed 's/  / /')

    # Perform variable substitutions
    prompt="${prompt//\{\{PLUGIN_NAME\}\}/$plugin_name}"
    prompt="${prompt//\{\{PLUGIN_VERSION\}\}/$plugin_version}"
    prompt="${prompt//\{\{IOS_VERSION\}\}/$ios_version}"
    prompt="${prompt//\{\{ANDROID_VERSION\}\}/$android_version}"
    prompt="${prompt//\{\{RELEASE_DATE\}\}/$release_date}"
    prompt="${prompt//\{\{IOS_CHANGELOG\}\}/$ios_changelog}"
    prompt="${prompt//\{\{ANDROID_CHANGELOG\}\}/$android_changelog}"

    # Call Gemini CLI in non-interactive mode
    local result=$(gemini -p "$prompt" 2>/dev/null)

    # Validate result has expected changelog structure
    if [ -n "$result" ] && echo "$result" | grep -q "## Version"; then
        echo "  ✓ Generated intelligent changelog" >&2
        echo "$result"
        return 0
    fi

    # Check for rate limit error
    if echo "$result" | grep -qi "rate limit"; then
        echo "  ⚠️  Gemini rate limit hit, using simple changelog format" >&2
    else
        echo "  ⚠️  Invalid Gemini response, using simple changelog format" >&2
    fi

    # Fallback to simple format
    generate_simple_changelog "$plugin_version" "$ios_version" "$android_version"
}

# Validate and fix common changelog issues (self-healing)
validate_and_fix() {
    local plugin="$1"
    local plugin_version="$2"
    local ios_version="$3"
    local android_version="$4"
    local changelog_file="CHANGELOG.md"

    echo "  🔍 Validating and fixing changelog..." >&2

    # Read first changelog entry
    local changelog_content=$(awk '/^## Version/{p=1} p{print} /^## Version/ && NR>1{exit}' "$changelog_file")

    # Track if we made any fixes
    local fixes_made=false

    # 1. Fix version format (remove 'v' prefix if present)
    if echo "$changelog_content" | grep -q "Version v[0-9]"; then
        sedi 's/Version v\([0-9]\)/Version \1/g' "$changelog_file"
        echo "    ✓ Fixed version format (removed 'v' prefix)" >&2
        fixes_made=true
    fi

    # 2. Validate version number matches
    local changelog_version=$(echo "$changelog_content" | grep "^## Version" | grep -o "[0-9]*\.[0-9]*\.[0-9]*" | head -1)
    if [ "$changelog_version" != "$plugin_version" ]; then
        echo "    ⚠️  WARNING: Changelog version ($changelog_version) doesn't match expected ($plugin_version)" >&2
    fi

    # 3. Fix malformed GitHub links
    if echo "$changelog_content" | grep -q "github.com/urbanairship/.*releases/tag/[^)]*[^0-9.)]"; then
        # Remove any trailing characters after version number in links
        sedi -E 's|(https://github.com/urbanairship/[^/]+/releases/tag/[0-9.]+)[^)]*|\1|g' "$changelog_file"
        echo "    ✓ Fixed malformed GitHub release links" >&2
        fixes_made=true
    fi

    # 4. Remove trailing whitespace
    if grep -q "[[:space:]]$" "$changelog_file"; then
        sedi 's/[[:space:]]*$//' "$changelog_file"
        echo "    ✓ Removed trailing whitespace" >&2
        fixes_made=true
    fi

    # 5. Ensure proper spacing around headers
    local temp_file=$(mktemp)
    if awk '
        /^## Version/ {
            if (NR > 1 && prev !~ /^[[:space:]]*$/) print ""
            print
            next
        }
        /^### Changes/ {
            if (prev !~ /^[[:space:]]*$/) print ""
            print
            next
        }
        { print }
        { prev = $0 }
    ' "$changelog_file" > "$temp_file" 2>/dev/null; then
        if ! cmp -s "$changelog_file" "$temp_file"; then
            mv "$temp_file" "$changelog_file"
            echo "    ✓ Fixed spacing around headers" >&2
            fixes_made=true
        else
            rm -f "$temp_file"
        fi
    else
        echo "    ⚠️  Spacing fix failed, skipping" >&2
        rm -f "$temp_file"
    fi

    # 6. Validate iOS/Android SDK links are correct
    if [ -n "$ios_version" ]; then
        if ! echo "$changelog_content" | grep -q "ios-library/releases/tag/${ios_version}"; then
            echo "    ⚠️  WARNING: iOS SDK version link missing or incorrect" >&2
        fi
    fi

    if [ -n "$android_version" ]; then
        if ! echo "$changelog_content" | grep -q "android-library/releases/tag/${android_version}"; then
            echo "    ⚠️  WARNING: Android SDK version link missing or incorrect" >&2
        fi
    fi

    # 7. Check markdown structure (warn only, don't fail)
    if ! echo "$changelog_content" | grep -q "^## Version"; then
        echo "    ⚠️  WARNING: Missing version header in changelog" >&2
        echo "    This may indicate Gemini generated an unexpected format" >&2
    fi

    if ! echo "$changelog_content" | grep -q "^### Changes"; then
        echo "    ⚠️  WARNING: Missing Changes section in changelog" >&2
        echo "    This may indicate Gemini generated an unexpected format" >&2
    fi

    if $fixes_made; then
        echo "  ✅ Changelog validated and fixed" >&2
        # Stage the fixes
        git add "$changelog_file"
    else
        echo "  ✅ Changelog validated (no fixes needed)" >&2
    fi

    # Always return success - warnings don't break the workflow
    return 0
}

# Validate PR content for consistency
validate_pr() {
    local plugin="$1"
    local plugin_version="$2"
    local pr_url="$3"
    local repo="$4"

    echo "  🔍 Validating PR content..." >&2

    # Check jq is available (required for PR validation)
    if ! command -v jq &>/dev/null; then
        echo "    ⚠️  jq not installed, skipping PR validation" >&2
        return 0
    fi

    # Extract PR number from URL
    local pr_number=$(echo "$pr_url" | grep -oE '/pull/[0-9]+' | grep -oE '[0-9]+')
    if [ -z "$pr_number" ]; then
        echo "    ⚠️  Could not parse PR number from: $pr_url" >&2
        return 0
    fi

    # Fetch PR details
    local pr_data=$(gh pr view "$pr_number" --repo "$repo" --json title,body 2>/dev/null)

    if [ -z "$pr_data" ]; then
        echo "    ⚠️  Could not fetch PR data for validation" >&2
        return 0
    fi

    local pr_title=$(echo "$pr_data" | jq -r '.title')
    local pr_body=$(echo "$pr_data" | jq -r '.body')

    # Expected title format: "Release X.Y.Z" or "[TEST] Release X.Y.Z"
    local expected_title="Release ${plugin_version}"
    local expected_test_title="[TEST] Release ${plugin_version}"

    if [ "$pr_title" != "$expected_title" ] && [ "$pr_title" != "$expected_test_title" ]; then
        echo "    ⚠️  WARNING: PR title is '$pr_title', expected '$expected_title'" >&2
    fi

    # Validate version appears in body
    if ! echo "$pr_body" | grep -q "$plugin_version"; then
        echo "    ⚠️  WARNING: Plugin version $plugin_version not found in PR body" >&2
    fi

    echo "  ✅ PR validation complete" >&2
}

# Main intelligent changelog generation function
generate_intelligent_changelog() {
    local plugin_name="$1"
    local plugin_version="$2"
    local ios_version="$3"
    local android_version="$4"

    # Fetch SDK changelogs from GitHub
    local ios_changelog=$(fetch_github_changelog "ios-library" "$ios_version")
    local ios_fetch_status=$?

    local android_changelog=$(fetch_github_changelog "android-library" "$android_version")
    local android_fetch_status=$?

    # If either fetch failed, use simple format
    if [ $ios_fetch_status -ne 0 ] || [ $android_fetch_status -ne 0 ]; then
        echo "  ⚠️  Failed to fetch SDK changelogs, using simple format" >&2
        generate_simple_changelog "$plugin_version" "$ios_version" "$android_version"
        return 0
    fi

    # Use Gemini CLI to analyze and decide format
    gemini_analyze_changelog \
        "$plugin_name" \
        "$plugin_version" \
        "$ios_version" \
        "$android_version" \
        "$ios_changelog" \
        "$android_changelog"
}
