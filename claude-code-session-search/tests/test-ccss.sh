#!/usr/bin/env bash
# test-ccss.sh - Unit tests for ccss date range filtering
#
# Usage: ./claude-code-session-search/tests/test-ccss.sh
#
# Tests run in an isolated environment using temporary directories
# with mock session data to avoid using real user sessions.

# shellcheck disable=SC1090  # Can't follow non-constant source (intentional for testing)

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
DIM='\033[2m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Paths
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CCSS="$SCRIPT_DIR/ccss"

# Temporary test environment
TEST_DIR=""
ORIG_HOME=""

# ============================================================================
# Test Framework
# ============================================================================

setup_test_env() {
    TEST_DIR=$(mktemp -d)
    ORIG_HOME="$HOME"
    export HOME="$TEST_DIR"

    # Create mock projects directory
    mkdir -p "$TEST_DIR/.claude/projects"
}

teardown_test_env() {
    export HOME="$ORIG_HOME"
    if [[ -n "$TEST_DIR" ]] && [[ -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
}

run_test() {
    local test_name="$1"
    local test_func="$2"

    ((TESTS_RUN++))
    setup_test_env

    echo -n "  $test_name... "

    local output
    local exit_code=0

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
# Test Fixtures - Mock Session Data
# ============================================================================

# Create a mock session JSONL file
# Args: project_name, session_id, timestamp, summary, mtime_override (optional)
create_mock_session() {
    local project_name="$1"
    local session_id="$2"
    local timestamp="$3"  # ISO format UTC: 2025-12-01T10:30:00.000Z
    local summary="${4:-Test session}"
    local mtime_date="${5:-}"  # Optional: set file mtime to this date (YYYY-MM-DD)

    # Encode project path (simulating how ccss encodes paths)
    local project_dir="$TEST_DIR/.claude/projects/-Users-jane-workspace-github-com-acme-${project_name}"
    mkdir -p "$project_dir"

    local session_file="$project_dir/${session_id}.jsonl"

    # Create minimal JSONL structure
    cat > "$session_file" << EOF
{"type":"summary","summary":"$summary"}
{"type":"user","timestamp":"$timestamp","message":{"content":"test prompt"},"cwd":"/Users/jane/workspace/github.com/acme/$project_name"}
{"type":"assistant","timestamp":"$timestamp","message":{"content":"test response"}}
EOF

    # Set file modification time if specified
    if [[ -n "$mtime_date" ]]; then
        touch -t "$(date -j -f "%Y-%m-%d" "$mtime_date" "+%Y%m%d0000" 2>/dev/null)" "$session_file"
    fi

    echo "$session_file"
}

# ============================================================================
# Tests: parse_date() Function - YYYY Format
# ============================================================================

test_parse_date_yyyy_from() {
    # Source the script functions
    source "$CCSS"

    local result
    result=$(parse_date "2025" "from")

    # Should be Jan 1, 2025 00:00:00 local time
    local expected
    expected=$(date -j -f "%Y-%m-%d" "2025-01-01" +%s)

    assert_equals "$expected" "$result" "YYYY from mode"
}

test_parse_date_yyyy_to() {
    source "$CCSS"

    local result
    result=$(parse_date "2025" "to")

    # Should be Dec 31, 2025 23:59:59 local time
    local expected
    expected=$(date -j -f "%Y-%m-%d %H:%M:%S" "2025-12-31 23:59:59" +%s)

    assert_equals "$expected" "$result" "YYYY to mode"
}

# ============================================================================
# Tests: parse_date() Function - YYYY.MM Format
# ============================================================================

test_parse_date_yyyy_mm_from() {
    source "$CCSS"

    local result
    result=$(parse_date "2025.12" "from")

    # Should be Dec 1, 2025 00:00:00
    local expected
    expected=$(date -j -f "%Y-%m-%d" "2025-12-01" +%s)

    assert_equals "$expected" "$result" "YYYY.MM from mode"
}

test_parse_date_yyyy_mm_to() {
    source "$CCSS"

    local result
    result=$(parse_date "2025.12" "to")

    # Should be Dec 31, 2025 23:59:59 (end of month)
    # Calculated as Jan 1, 2026 00:00:00 minus 1 second
    local jan1_2026
    jan1_2026=$(date -j -f "%Y-%m-%d" "2026-01-01" +%s)
    local expected=$((jan1_2026 - 1))

    assert_equals "$expected" "$result" "YYYY.MM to mode (Dec)"
}

test_parse_date_yyyy_mm_to_february() {
    source "$CCSS"

    local result
    result=$(parse_date "2025.02" "to")

    # Feb 2025 ends on 28th (not a leap year)
    local mar1_2025
    mar1_2025=$(date -j -f "%Y-%m-%d" "2025-03-01" +%s)
    local expected=$((mar1_2025 - 1))

    assert_equals "$expected" "$result" "YYYY.MM to mode (Feb non-leap)"
}

test_parse_date_yyyy_mm_to_leap_year() {
    source "$CCSS"

    local result
    result=$(parse_date "2024.02" "to")

    # Feb 2024 ends on 29th (leap year)
    local mar1_2024
    mar1_2024=$(date -j -f "%Y-%m-%d" "2024-03-01" +%s)
    local expected=$((mar1_2024 - 1))

    assert_equals "$expected" "$result" "YYYY.MM to mode (Feb leap year)"
}

test_parse_date_yyyy_mm_single_digit_month() {
    source "$CCSS"

    local result
    result=$(parse_date "2025.1" "from")

    # Should handle single digit month
    local expected
    expected=$(date -j -f "%Y-%m-%d" "2025-01-01" +%s)

    assert_equals "$expected" "$result" "YYYY.M single digit month"
}

# ============================================================================
# Tests: parse_date() Function - YYYY.MM.DD Format
# ============================================================================

test_parse_date_yyyy_mm_dd_from() {
    source "$CCSS"

    local result
    result=$(parse_date "2025.12.15" "from")

    # Should be Dec 15, 2025 00:00:00
    local expected
    expected=$(date -j -f "%Y-%m-%d" "2025-12-15" +%s)

    assert_equals "$expected" "$result" "YYYY.MM.DD from mode"
}

test_parse_date_yyyy_mm_dd_to() {
    source "$CCSS"

    local result
    result=$(parse_date "2025.12.15" "to")

    # Should be Dec 15, 2025 23:59:59
    local expected
    expected=$(date -j -f "%Y-%m-%d %H:%M:%S" "2025-12-15 23:59:59" +%s)

    assert_equals "$expected" "$result" "YYYY.MM.DD to mode"
}

test_parse_date_yyyy_mm_dd_single_digits() {
    source "$CCSS"

    local result
    result=$(parse_date "2025.1.5" "from")

    # Should handle single digit month and day
    local expected
    expected=$(date -j -f "%Y-%m-%d" "2025-01-05" +%s)

    assert_equals "$expected" "$result" "YYYY.M.D single digits"
}

# ============================================================================
# Tests: parse_date() Function - Legacy Formats
# ============================================================================

test_parse_date_iso_from() {
    source "$CCSS"

    local result
    result=$(parse_date "2025-12-15" "from")

    local expected
    expected=$(date -j -f "%Y-%m-%d" "2025-12-15" +%s)

    assert_equals "$expected" "$result" "ISO format from"
}

test_parse_date_iso_to() {
    source "$CCSS"

    local result
    result=$(parse_date "2025-12-15" "to")

    local expected
    expected=$(date -j -f "%Y-%m-%d %H:%M:%S" "2025-12-15 23:59:59" +%s)

    assert_equals "$expected" "$result" "ISO format to"
}

test_parse_date_us_format() {
    source "$CCSS"

    local result
    result=$(parse_date "12/15/2025" "from")

    local expected
    expected=$(date -j -f "%Y-%m-%d" "2025-12-15" +%s)

    assert_equals "$expected" "$result" "US format MM/DD/YYYY"
}

test_parse_date_month_name() {
    source "$CCSS"

    local result
    result=$(parse_date "December 15 2025" "from")

    local expected
    expected=$(date -j -f "%Y-%m-%d" "2025-12-15" +%s)

    assert_equals "$expected" "$result" "Full month name"
}

test_parse_date_month_abbrev() {
    source "$CCSS"

    local result
    result=$(parse_date "Dec 15 2025" "from")

    local expected
    expected=$(date -j -f "%Y-%m-%d" "2025-12-15" +%s)

    assert_equals "$expected" "$result" "Abbreviated month name"
}

test_parse_date_ordinal_suffix() {
    source "$CCSS"

    local result
    result=$(parse_date "December 1st 2025" "from")

    local expected
    expected=$(date -j -f "%Y-%m-%d" "2025-12-01" +%s)

    assert_equals "$expected" "$result" "Ordinal suffix (1st)"
}

test_parse_date_invalid() {
    source "$CCSS"

    local exit_code=0
    parse_date "invalid-date" "from" >/dev/null 2>&1 || exit_code=$?

    assert_exit_code 1 "$exit_code" "Invalid date should fail"
}

# ============================================================================
# Tests: Date Range Filtering Integration
# ============================================================================

test_filter_from_only() {
    # Create sessions in November and December
    create_mock_session "webapp" "session-nov" "2025-11-15T10:00:00.000Z" "November session" "2025-11-15"
    create_mock_session "webapp" "session-dec" "2025-12-15T10:00:00.000Z" "December session" "2025-12-15"

    local output
    output=$("$CCSS" -n 10 --from 2025.12 2>&1)

    assert_contains "$output" "December session"
    assert_not_contains "$output" "November session"
}

test_filter_to_only() {
    # Create sessions in November and December
    create_mock_session "webapp" "session-nov" "2025-11-15T10:00:00.000Z" "November session" "2025-11-15"
    create_mock_session "webapp" "session-dec" "2025-12-15T10:00:00.000Z" "December session" "2025-12-15"

    local output
    output=$("$CCSS" -n 10 --to 2025.11 2>&1)

    assert_contains "$output" "November session"
    assert_not_contains "$output" "December session"
}

test_filter_from_and_to() {
    # Create sessions across multiple months
    create_mock_session "webapp" "session-oct" "2025-10-15T10:00:00.000Z" "October session" "2025-10-15"
    create_mock_session "webapp" "session-nov" "2025-11-15T10:00:00.000Z" "November session" "2025-11-15"
    create_mock_session "webapp" "session-dec" "2025-12-15T10:00:00.000Z" "December session" "2025-12-15"

    local output
    output=$("$CCSS" -n 10 --from 2025.11 --to 2025.11 2>&1)

    assert_contains "$output" "November session"
    assert_not_contains "$output" "October session"
    assert_not_contains "$output" "December session"
}

test_filter_year_only() {
    # Create sessions in 2024 and 2025
    create_mock_session "webapp" "session-2024" "2024-06-15T10:00:00.000Z" "2024 session" "2024-06-15"
    create_mock_session "webapp" "session-2025" "2025-06-15T10:00:00.000Z" "2025 session" "2025-06-15"

    local output
    output=$("$CCSS" -n 10 --from 2025 --to 2025 2>&1)

    assert_contains "$output" "2025 session"
    assert_not_contains "$output" "2024 session"
}

test_filter_specific_days() {
    # Create sessions on consecutive days
    create_mock_session "webapp" "session-d1" "2025-12-01T10:00:00.000Z" "Dec 1 session" "2025-12-01"
    create_mock_session "webapp" "session-d2" "2025-12-02T10:00:00.000Z" "Dec 2 session" "2025-12-02"
    create_mock_session "webapp" "session-d3" "2025-12-03T10:00:00.000Z" "Dec 3 session" "2025-12-03"
    create_mock_session "webapp" "session-d4" "2025-12-04T10:00:00.000Z" "Dec 4 session" "2025-12-04"
    create_mock_session "webapp" "session-d5" "2025-12-05T10:00:00.000Z" "Dec 5 session" "2025-12-05"

    local output
    output=$("$CCSS" -n 10 --from 2025.12.02 --to 2025.12.04 2>&1)

    assert_contains "$output" "Dec 2 session"
    assert_contains "$output" "Dec 3 session"
    assert_contains "$output" "Dec 4 session"
    assert_not_contains "$output" "Dec 1 session"
    assert_not_contains "$output" "Dec 5 session"
}

test_filter_no_results() {
    create_mock_session "webapp" "session-nov" "2025-11-15T10:00:00.000Z" "November session" "2025-11-15"

    local output
    local exit_code=0
    output=$("$CCSS" -n 10 --from 2025.12 --to 2025.12 2>&1) || exit_code=$?

    assert_exit_code 1 "$exit_code" "Should exit with error when no sessions found"
    assert_contains "$output" "No sessions found"
}

# ============================================================================
# Tests: --by-start vs --by-last Filtering
# ============================================================================

test_filter_by_last_default() {
    # Session started in November but last modified in December
    local session_file
    session_file=$(create_mock_session "webapp" "long-session" "2025-11-01T10:00:00.000Z" "Long running session" "2025-12-15")

    # Default is --by-last, so December filter should find it
    local output
    output=$("$CCSS" -n 10 --from 2025.12 2>&1)

    assert_contains "$output" "Long running session"
}

test_filter_by_start() {
    # Session started in November but last modified in December
    create_mock_session "webapp" "long-session" "2025-11-01T10:00:00.000Z" "Long running session" "2025-12-15"

    # --by-start should use start timestamp, so December filter should NOT find it
    local output
    local exit_code=0
    output=$("$CCSS" -n 10 --from 2025.12 --by-start 2>&1) || exit_code=$?

    # Session started in November, so December --by-start should not find it
    assert_exit_code 1 "$exit_code"
    assert_contains "$output" "No sessions found"
}

test_filter_by_start_finds_session() {
    # Session started in November
    create_mock_session "webapp" "nov-session" "2025-11-15T10:00:00.000Z" "Started in Nov" "2025-12-15"

    # --by-start November should find it
    local output
    output=$("$CCSS" -n 10 --from 2025.11 --to 2025.11 --by-start 2>&1)

    assert_contains "$output" "Started in Nov"
}

# ============================================================================
# Tests: JSON Output with Dates
# ============================================================================

test_json_output_includes_dates() {
    create_mock_session "webapp" "test-session" "2025-12-15T10:30:00.000Z" "JSON test" "2025-12-16"

    local output
    output=$("$CCSS" -j -n 1 2>&1)

    assert_contains "$output" '"started":'
    assert_contains "$output" '"modified":'
}

# ============================================================================
# Tests: Error Handling
# ============================================================================

test_invalid_from_date_error() {
    local output
    local exit_code=0
    output=$("$CCSS" --from "invalid" 2>&1) || exit_code=$?

    assert_exit_code 1 "$exit_code"
    assert_contains "$output" "Could not parse date"
}

test_invalid_to_date_error() {
    local output
    local exit_code=0
    output=$("$CCSS" --to "garbage" 2>&1) || exit_code=$?

    assert_exit_code 1 "$exit_code"
    assert_contains "$output" "Could not parse date"
}

test_help_shows_date_formats() {
    local output
    output=$("$CCSS" --help 2>&1)

    assert_contains "$output" "YYYY"
    assert_contains "$output" "YYYY.MM"
    assert_contains "$output" "YYYY.MM.DD"
    assert_contains "$output" "--from"
    assert_contains "$output" "--to"
    assert_contains "$output" "--by-start"
    assert_contains "$output" "--by-last"
}

# ============================================================================
# Tests: Edge Cases
# ============================================================================

test_year_boundary_december_to_january() {
    source "$CCSS"

    # December 2025 "to" should be Dec 31 23:59:59
    local dec_end
    dec_end=$(parse_date "2025.12" "to")

    # January 2026 "from" should be Jan 1 00:00:00
    local jan_start
    jan_start=$(parse_date "2026.1" "from")

    # They should be 1 second apart
    local diff=$((jan_start - dec_end))
    assert_equals "1" "$diff" "Year boundary should be 1 second apart"
}

test_month_boundary() {
    source "$CCSS"

    # November 2025 "to" should be Nov 30 23:59:59
    local nov_end
    nov_end=$(parse_date "2025.11" "to")

    # December 2025 "from" should be Dec 1 00:00:00
    local dec_start
    dec_start=$(parse_date "2025.12" "from")

    # They should be 1 second apart
    local diff=$((dec_start - nov_end))
    assert_equals "1" "$diff" "Month boundary should be 1 second apart"
}

test_combined_search_and_date_filter() {
    create_mock_session "webapp" "session-nov" "2025-11-15T10:00:00.000Z" "Auth feature November" "2025-11-15"
    create_mock_session "webapp" "session-dec" "2025-12-15T10:00:00.000Z" "Auth feature December" "2025-12-15"

    local output
    output=$("$CCSS" -n 10 -g "Auth" --from 2025.12 2>&1)

    assert_contains "$output" "Auth feature December"
    assert_not_contains "$output" "Auth feature November"
}

# ============================================================================
# Main Test Runner
# ============================================================================

main() {
    echo -e "${BLUE}=== ccss Date Range Tests ===${NC}"
    echo

    # Verify script exists
    if [[ ! -x "$CCSS" ]]; then
        echo -e "${RED}Error:${NC} ccss not found at $CCSS"
        exit 1
    fi

    echo -e "${BLUE}parse_date() - YYYY Format:${NC}"
    run_test "YYYY from mode (start of year)" test_parse_date_yyyy_from
    run_test "YYYY to mode (end of year)" test_parse_date_yyyy_to

    echo
    echo -e "${BLUE}parse_date() - YYYY.MM Format:${NC}"
    run_test "YYYY.MM from mode (start of month)" test_parse_date_yyyy_mm_from
    run_test "YYYY.MM to mode (end of month - Dec)" test_parse_date_yyyy_mm_to
    run_test "YYYY.MM to mode (Feb non-leap year)" test_parse_date_yyyy_mm_to_february
    run_test "YYYY.MM to mode (Feb leap year)" test_parse_date_yyyy_mm_to_leap_year
    run_test "YYYY.M single digit month" test_parse_date_yyyy_mm_single_digit_month

    echo
    echo -e "${BLUE}parse_date() - YYYY.MM.DD Format:${NC}"
    run_test "YYYY.MM.DD from mode" test_parse_date_yyyy_mm_dd_from
    run_test "YYYY.MM.DD to mode" test_parse_date_yyyy_mm_dd_to
    run_test "YYYY.M.D single digits" test_parse_date_yyyy_mm_dd_single_digits

    echo
    echo -e "${BLUE}parse_date() - Legacy Formats:${NC}"
    run_test "ISO format from (YYYY-MM-DD)" test_parse_date_iso_from
    run_test "ISO format to (YYYY-MM-DD)" test_parse_date_iso_to
    run_test "US format (MM/DD/YYYY)" test_parse_date_us_format
    run_test "Full month name" test_parse_date_month_name
    run_test "Abbreviated month name" test_parse_date_month_abbrev
    run_test "Ordinal suffix (1st, 2nd, etc)" test_parse_date_ordinal_suffix
    run_test "Invalid date returns error" test_parse_date_invalid

    echo
    echo -e "${BLUE}Date Range Filtering:${NC}"
    run_test "--from only" test_filter_from_only
    run_test "--to only" test_filter_to_only
    run_test "--from and --to" test_filter_from_and_to
    run_test "Filter by year only" test_filter_year_only
    run_test "Filter specific days" test_filter_specific_days
    run_test "No results in range" test_filter_no_results

    echo
    echo -e "${BLUE}--by-start vs --by-last:${NC}"
    run_test "--by-last (default) uses mtime" test_filter_by_last_default
    run_test "--by-start filters by start timestamp" test_filter_by_start
    run_test "--by-start finds session by start date" test_filter_by_start_finds_session

    echo
    echo -e "${BLUE}JSON Output:${NC}"
    run_test "JSON includes started/modified fields" test_json_output_includes_dates

    echo
    echo -e "${BLUE}Error Handling:${NC}"
    run_test "Invalid --from date error" test_invalid_from_date_error
    run_test "Invalid --to date error" test_invalid_to_date_error
    run_test "Help shows date formats" test_help_shows_date_formats

    echo
    echo -e "${BLUE}Edge Cases:${NC}"
    run_test "Year boundary (Dec 31 → Jan 1)" test_year_boundary_december_to_january
    run_test "Month boundary continuity" test_month_boundary
    run_test "Combined search + date filter" test_combined_search_and_date_filter

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
