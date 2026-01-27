#!/usr/bin/env bash
# test-ccpm.sh - Unit tests for ccpm (Claude Code Plugin Manager)
#
# Usage: ./tests/test-ccpm.sh
#
# Tests run in an isolated environment using temporary directories
# to avoid affecting the real ~/.claude and ~/.config directories.

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
# YELLOW='\033[1;33m'  # Reserved for future use
BLUE='\033[0;34m'
DIM='\033[2m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Paths
CCPM="$HOME/bin/ccpm"

# Temporary test environment
TEST_DIR=""
TEST_PLUGINS_DIR=""
TEST_INSTALLED_JSON=""

# ============================================================================
# Test Framework
# ============================================================================

setup_test_env() {
    TEST_DIR=$(mktemp -d)
    # TEST_CONFIG is set but read by ccpm via HOME
    TEST_PLUGINS_DIR="$TEST_DIR/.claude/plugins/marketplaces"
    TEST_INSTALLED_JSON="$TEST_DIR/.claude/plugins/installed_plugins.json"

    export HOME="$TEST_DIR"
    mkdir -p "$TEST_PLUGINS_DIR"
    mkdir -p "$TEST_DIR/.config"

    # Create empty installed_plugins.json
    echo '{"plugins":{}}' > "$TEST_INSTALLED_JSON"
}

teardown_test_env() {
    if [[ -n "$TEST_DIR" ]] && [[ -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
}

# Run a test function
run_test() {
    local test_name="$1"
    local test_func="$2"

    ((TESTS_RUN++))

    # Setup fresh environment for each test
    setup_test_env

    echo -n "  $test_name... "

    local output
    local exit_code=0

    # Capture output and exit code
    if output=$($test_func 2>&1); then
        exit_code=0
    else
        exit_code=$?
    fi

    if [[ $exit_code -eq 0 ]]; then
        echo -e "${GREEN}PASS${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}FAIL${NC}"
        echo -e "    ${DIM}$output${NC}"
        ((TESTS_FAILED++))
    fi

    teardown_test_env
}

# Assert helpers
assert_equals() {
    local expected="$1"
    local actual="$2"
    local msg="${3:-}"

    if [[ "$expected" != "$actual" ]]; then
        echo "Expected: '$expected', Got: '$actual' $msg"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local msg="${3:-}"

    if [[ "$haystack" != *"$needle"* ]]; then
        echo "Expected to contain: '$needle' $msg"
        echo "Actual: '$haystack'"
        return 1
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local msg="${3:-}"

    if [[ "$haystack" == *"$needle"* ]]; then
        echo "Expected NOT to contain: '$needle' $msg"
        return 1
    fi
}

assert_file_exists() {
    local path="$1"
    if [[ ! -f "$path" ]]; then
        echo "Expected file to exist: $path"
        return 1
    fi
}

assert_exit_code() {
    local expected="$1"
    local actual="$2"
    local msg="${3:-}"

    if [[ "$expected" != "$actual" ]]; then
        echo "Expected exit code: $expected, Got: $actual $msg"
        return 1
    fi
}

# ============================================================================
# Test Fixtures
# ============================================================================

# Create a mock marketplace directory with git repo
create_mock_marketplace() {
    local alias="$1"
    local repo="${2:-testorg/$alias}"
    local marketplace_dir="$TEST_DIR/.claude/plugins/marketplaces/$alias"

    mkdir -p "$marketplace_dir"

    # Initialize git repo
    git -C "$marketplace_dir" init -q
    git -C "$marketplace_dir" config user.email "test@test.com"
    git -C "$marketplace_dir" config user.name "Test"

    # Set remote
    git -C "$marketplace_dir" remote add origin "git@github.com:$repo.git"

    # Create initial commit
    echo "# $alias" > "$marketplace_dir/README.md"
    git -C "$marketplace_dir" add README.md
    git -C "$marketplace_dir" commit -q -m "Initial commit"
}

# Create a mock plugin in a marketplace
create_mock_plugin() {
    local marketplace_alias="$1"
    local plugin_name="$2"
    local version="${3:-1.0.0}"
    local description="${4:-A test plugin}"

    local plugin_dir="$TEST_DIR/.claude/plugins/marketplaces/$marketplace_alias/$plugin_name"

    mkdir -p "$plugin_dir/.claude-plugin"

    cat > "$plugin_dir/.claude-plugin/plugin.json" << EOF
{
    "name": "$plugin_name",
    "version": "$version",
    "description": "$description"
}
EOF
}

# Mark a plugin as installed in installed_plugins.json
mark_plugin_installed() {
    local plugin_name="$1"
    local marketplace_alias="$2"
    local version="${3:-1.0.0}"
    local git_hash="${4:-abc1234}"

    local installed_json="$TEST_DIR/.claude/plugins/installed_plugins.json"

    # Ensure the file exists
    if [[ ! -f "$installed_json" ]]; then
        echo '{"plugins":{}}' > "$installed_json"
    fi

    # Use jq to add the plugin
    local tmp_file
    tmp_file=$(mktemp)
    jq --arg key "$plugin_name@$marketplace_alias" \
       --arg version "$version" \
       --arg hash "$git_hash" \
       '.plugins[$key] = [{"version": $version, "gitCommitSha": $hash}]' \
       "$installed_json" > "$tmp_file"
    mv "$tmp_file" "$installed_json"
}

# Add marketplace to config
add_to_config() {
    local repo="$1"
    local alias="$2"
    local config="$TEST_DIR/.config/ccpm.yaml"

    if [[ ! -f "$config" ]]; then
        cat > "$config" << EOF
marketplaces:
  $repo: $alias
EOF
    else
        # Append to existing config
        echo "  $repo: $alias" >> "$config"
    fi
}

# ============================================================================
# Tests: Config Management
# ============================================================================

test_config_shows_default_path() {
    local output
    output=$("$CCPM" config 2>&1)

    assert_contains "$output" "Config file:"
    assert_contains "$output" "ccpm.yaml"
}

test_config_custom_path() {
    local custom_config="$TEST_DIR/custom-ccpm.yaml"
    echo "marketplaces: {}" > "$custom_config"

    local output
    output=$("$CCPM" --config "$custom_config" config 2>&1)

    assert_contains "$output" "$custom_config"
}

test_add_marketplace() {
    local output
    output=$("$CCPM" add "testorg/test-plugins" "test-mp" 2>&1)

    assert_contains "$output" "Added"
    assert_file_exists "$TEST_DIR/.config/ccpm.yaml"

    local config_content
    config_content=$(cat "$TEST_DIR/.config/ccpm.yaml")
    assert_contains "$config_content" "testorg/test-plugins"
    assert_contains "$config_content" "test-mp"
}

test_remove_marketplace() {
    # First add a marketplace
    "$CCPM" add "testorg/test-plugins" "test-mp" >/dev/null 2>&1

    # Then remove it
    local output
    output=$("$CCPM" remove "testorg/test-plugins" 2>&1)

    assert_contains "$output" "Removed"

    local config_content
    config_content=$(cat "$TEST_DIR/.config/ccpm.yaml")
    assert_not_contains "$config_content" "testorg/test-plugins"
}

test_remove_nonexistent_marketplace() {
    "$CCPM" add "testorg/test-plugins" "test-mp" >/dev/null 2>&1

    local output
    local exit_code=0
    output=$("$CCPM" remove "nonexistent/repo" 2>&1) || exit_code=$?

    assert_exit_code 1 "$exit_code"
    assert_contains "$output" "not found"
}

# ============================================================================
# Tests: List Command
# ============================================================================

test_list_no_config() {
    local output
    output=$("$CCPM" list 2>&1)

    assert_contains "$output" "No marketplaces configured"
}

test_list_shows_marketplaces() {
    add_to_config "testorg/test-plugins" "test-mp"
    create_mock_marketplace "test-mp" "testorg/test-plugins"

    local output
    output=$("$CCPM" list 2>&1)

    assert_contains "$output" "test-mp"
    assert_contains "$output" "testorg/test-plugins"
    assert_contains "$output" "installed"
}

test_list_shows_plugins() {
    add_to_config "testorg/test-plugins" "test-mp"
    create_mock_marketplace "test-mp" "testorg/test-plugins"
    create_mock_plugin "test-mp" "my-plugin" "1.2.3"
    mark_plugin_installed "my-plugin" "test-mp" "1.2.3"

    local output
    output=$("$CCPM" list 2>&1)

    assert_contains "$output" "my-plugin"
    assert_contains "$output" "v1.2.3"
}

test_list_filter_by_alias() {
    add_to_config "org1/plugins1" "mp1"
    add_to_config "org2/plugins2" "mp2"
    create_mock_marketplace "mp1" "org1/plugins1"
    create_mock_marketplace "mp2" "org2/plugins2"

    local output
    output=$("$CCPM" list mp1 2>&1)

    assert_contains "$output" "mp1"
    assert_not_contains "$output" "mp2"
}

test_list_filter_nonexistent() {
    add_to_config "testorg/test-plugins" "test-mp"

    local output
    local exit_code=0
    output=$("$CCPM" list nonexistent 2>&1) || exit_code=$?

    assert_exit_code 1 "$exit_code"
    assert_contains "$output" "not found"
}

# ============================================================================
# Tests: Search Command
# ============================================================================

test_search_no_query() {
    local output
    local exit_code=0
    output=$("$CCPM" search 2>&1) || exit_code=$?

    assert_exit_code 1 "$exit_code"
    assert_contains "$output" "No search query"
}

test_search_finds_by_name() {
    add_to_config "testorg/test-plugins" "test-mp"
    create_mock_marketplace "test-mp" "testorg/test-plugins"
    create_mock_plugin "test-mp" "security-scanner" "1.0.0" "Scans for security issues"

    local output
    output=$("$CCPM" search "security" 2>&1)

    assert_contains "$output" "security-scanner"
    assert_contains "$output" "test-mp"
}

test_search_finds_by_description() {
    add_to_config "testorg/test-plugins" "test-mp"
    create_mock_marketplace "test-mp" "testorg/test-plugins"
    create_mock_plugin "test-mp" "my-tool" "1.0.0" "Helps with vulnerability scanning"

    local output
    output=$("$CCPM" search "vulnerability" 2>&1)

    assert_contains "$output" "my-tool"
}

test_search_no_results() {
    add_to_config "testorg/test-plugins" "test-mp"
    create_mock_marketplace "test-mp" "testorg/test-plugins"
    create_mock_plugin "test-mp" "my-plugin" "1.0.0"

    local output
    output=$("$CCPM" search "nonexistent" 2>&1)

    assert_contains "$output" "No plugins found"
}

test_search_shows_installed_marker() {
    add_to_config "testorg/test-plugins" "test-mp"
    create_mock_marketplace "test-mp" "testorg/test-plugins"
    create_mock_plugin "test-mp" "installed-plugin" "1.0.0"
    mark_plugin_installed "installed-plugin" "test-mp"

    local output
    output=$("$CCPM" search "installed" 2>&1)

    assert_contains "$output" "[installed]"
}

test_search_verbose_shows_description() {
    add_to_config "testorg/test-plugins" "test-mp"
    create_mock_marketplace "test-mp" "testorg/test-plugins"
    create_mock_plugin "test-mp" "my-plugin" "1.0.0" "A very detailed description"

    local output
    output=$("$CCPM" search "my-plugin" -v 2>&1)

    assert_contains "$output" "A very detailed description"
}

# ============================================================================
# Tests: Discover Command
# ============================================================================

test_discover_finds_marketplaces() {
    create_mock_marketplace "discovered-mp" "someorg/discovered-plugins"

    local output
    output=$("$CCPM" discover 2>&1)

    assert_contains "$output" "discovered-mp"
    assert_contains "$output" "someorg/discovered-plugins"
    assert_file_exists "$TEST_DIR/.config/ccpm.yaml"
}

test_discover_skips_already_configured() {
    add_to_config "someorg/discovered-plugins" "discovered-mp"
    create_mock_marketplace "discovered-mp" "someorg/discovered-plugins"

    local output
    output=$("$CCPM" discover 2>&1)

    assert_contains "$output" "already configured"
}

# ============================================================================
# Tests: Update Command
# ============================================================================

test_update_no_marketplaces() {
    local output
    local exit_code=0
    output=$("$CCPM" update 2>&1) || exit_code=$?

    assert_contains "$output" "No marketplaces configured"
}

test_update_shows_up_to_date() {
    add_to_config "testorg/test-plugins" "test-mp"
    create_mock_marketplace "test-mp" "testorg/test-plugins"

    local output
    output=$("$CCPM" update 2>&1)

    assert_contains "$output" "up to date"
}

# ============================================================================
# Tests: Help and Usage
# ============================================================================

test_help_shows_usage() {
    local output
    output=$("$CCPM" help 2>&1)

    assert_contains "$output" "Usage:"
    assert_contains "$output" "Commands:"
    assert_contains "$output" "discover"
    assert_contains "$output" "update"
    assert_contains "$output" "upgrade"
    assert_contains "$output" "search"
    assert_contains "$output" "list"
}

test_no_args_shows_help() {
    local output
    output=$("$CCPM" 2>&1)

    assert_contains "$output" "Usage:"
}

test_unknown_command_error() {
    local output
    local exit_code=0
    output=$("$CCPM" unknowncommand 2>&1) || exit_code=$?

    assert_exit_code 1 "$exit_code"
    assert_contains "$output" "Unknown command"
}

# ============================================================================
# Tests: Edge Cases
# ============================================================================

test_marketplace_not_git_repo() {
    add_to_config "testorg/test-plugins" "test-mp"
    mkdir -p "$TEST_DIR/.claude/plugins/marketplaces/test-mp"
    # Don't initialize git

    local output
    output=$("$CCPM" update 2>&1)

    assert_contains "$output" "not a git repo"
}

test_marketplace_not_installed() {
    add_to_config "testorg/test-plugins" "test-mp"
    # Don't create the directory

    local output
    output=$("$CCPM" list 2>&1)

    assert_contains "$output" "not installed"
}

# ============================================================================
# Tests: Conflict Detection
# ============================================================================

test_check_conflicts_no_conflicts() {
    add_to_config "testorg/test-plugins" "test-mp"
    create_mock_marketplace "test-mp" "testorg/test-plugins"
    create_mock_plugin "test-mp" "unique-plugin" "1.0.0"
    mark_plugin_installed "unique-plugin" "test-mp"

    local output
    output=$("$CCPM" check-conflicts 2>&1)

    assert_contains "$output" "No conflicts detected"
}

test_check_conflicts_multi_marketplace() {
    # Install same plugin in two marketplaces
    add_to_config "org1/plugins1" "mp1"
    add_to_config "org2/plugins2" "mp2"
    create_mock_marketplace "mp1" "org1/plugins1"
    create_mock_marketplace "mp2" "org2/plugins2"
    create_mock_plugin "mp1" "shared-plugin" "1.0.0"
    create_mock_plugin "mp2" "shared-plugin" "2.0.0"
    mark_plugin_installed "shared-plugin" "mp1" "1.0.0"
    mark_plugin_installed "shared-plugin" "mp2" "2.0.0"

    local output
    local exit_code=0
    output=$("$CCPM" check-conflicts 2>&1) || exit_code=$?

    assert_exit_code 1 "$exit_code"
    assert_contains "$output" "shared-plugin"
    assert_contains "$output" "conflict"
}

test_multi_marketplace_uninstall_requires_explicit() {
    # Install same plugin in two marketplaces
    add_to_config "org1/plugins1" "mp1"
    add_to_config "org2/plugins2" "mp2"
    create_mock_marketplace "mp1" "org1/plugins1"
    create_mock_marketplace "mp2" "org2/plugins2"
    mark_plugin_installed "shared-plugin" "mp1" "1.0.0"
    mark_plugin_installed "shared-plugin" "mp2" "2.0.0"

    local output
    local exit_code=0
    output=$("$CCPM" uninstall shared-plugin 2>&1) || exit_code=$?

    # Should fail because ambiguous
    assert_contains "$output" "Ambiguous"
    assert_contains "$output" "multiple marketplaces"
}

test_list_plugins_flag() {
    add_to_config "testorg/test-plugins" "test-mp"
    create_mock_marketplace "test-mp" "testorg/test-plugins"
    mark_plugin_installed "security-scanner" "test-mp" "1.0.0"
    mark_plugin_installed "code-helper" "test-mp" "1.0.0"

    local output
    output=$("$CCPM" list --plugins security 2>&1)

    assert_contains "$output" "security-scanner"
    assert_not_contains "$output" "code-helper"
}

test_add_warns_on_plugin_collision() {
    # First install a plugin named "trivy"
    mark_plugin_installed "trivy" "existing-mp" "1.0.0"

    local output
    output=$("$CCPM" add "someorg/trivy-plugins" "trivy" 2>&1)

    assert_contains "$output" "Warning"
    assert_contains "$output" "matches installed plugin"
}

# ============================================================================
# Main Test Runner
# ============================================================================

main() {
    echo -e "${BLUE}=== ccpm Unit Tests ===${NC}"
    echo

    # Verify ccpm exists
    if [[ ! -x "$CCPM" ]]; then
        echo -e "${RED}Error:${NC} ccpm not found at $CCPM"
        exit 1
    fi

    echo -e "${BLUE}Config Management:${NC}"
    run_test "config shows default path" test_config_shows_default_path
    run_test "config with custom path" test_config_custom_path
    run_test "add marketplace" test_add_marketplace
    run_test "remove marketplace" test_remove_marketplace
    run_test "remove nonexistent marketplace" test_remove_nonexistent_marketplace

    echo
    echo -e "${BLUE}List Command:${NC}"
    run_test "list with no config" test_list_no_config
    run_test "list shows marketplaces" test_list_shows_marketplaces
    run_test "list shows plugins" test_list_shows_plugins
    run_test "list filter by alias" test_list_filter_by_alias
    run_test "list filter nonexistent" test_list_filter_nonexistent

    echo
    echo -e "${BLUE}Search Command:${NC}"
    run_test "search with no query" test_search_no_query
    run_test "search finds by name" test_search_finds_by_name
    run_test "search finds by description" test_search_finds_by_description
    run_test "search no results" test_search_no_results
    run_test "search shows installed marker" test_search_shows_installed_marker
    run_test "search verbose shows description" test_search_verbose_shows_description

    echo
    echo -e "${BLUE}Discover Command:${NC}"
    run_test "discover finds marketplaces" test_discover_finds_marketplaces
    run_test "discover skips already configured" test_discover_skips_already_configured

    echo
    echo -e "${BLUE}Update Command:${NC}"
    run_test "update with no marketplaces" test_update_no_marketplaces
    run_test "update shows up to date" test_update_shows_up_to_date

    echo
    echo -e "${BLUE}Help and Usage:${NC}"
    run_test "help shows usage" test_help_shows_usage
    run_test "no args shows help" test_no_args_shows_help
    run_test "unknown command error" test_unknown_command_error

    echo
    echo -e "${BLUE}Edge Cases:${NC}"
    run_test "marketplace not git repo" test_marketplace_not_git_repo
    run_test "marketplace not installed" test_marketplace_not_installed

    echo
    echo -e "${BLUE}Conflict Detection:${NC}"
    run_test "check-conflicts no conflicts" test_check_conflicts_no_conflicts
    run_test "check-conflicts multi-marketplace" test_check_conflicts_multi_marketplace
    run_test "uninstall requires explicit when ambiguous" test_multi_marketplace_uninstall_requires_explicit
    run_test "list --plugins flag" test_list_plugins_flag
    run_test "add warns on plugin collision" test_add_warns_on_plugin_collision

    # Summary
    echo
    echo -e "${BLUE}=== Summary ===${NC}"
    echo -e "Tests run: $TESTS_RUN"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"

    if [[ $TESTS_FAILED -gt 0 ]]; then
        exit 1
    fi
}

main "$@"
