#!/bin/bash
# Test runner for Claude Code Statusline v7
# Usage: bash tests/run-tests.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
STATUSLINE="$PROJECT_DIR/statusline.sh"
TESTS_DIR="$SCRIPT_DIR"

# Colors for test output
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BOLD='\033[1m'
RESET='\033[0m'

passed=0
failed=0
errors=()

# Run statusline with mock JSON and specific env vars, capture output
run_statusline() {
    local mock="$1"
    shift
    # Source the mock JSON, pipe to statusline.sh with provided env vars
    # Use a temp config file to avoid user's real config interfering
    local tmp_config
    tmp_config=$(mktemp)
    echo "export CLAUDE_SL_LAYOUT=compact" > "$tmp_config"

    env -i \
        HOME="$HOME" \
        PATH="$PATH" \
        TERM="$TERM" \
        CLAUDE_STATUSLINE_CONFIG="$tmp_config" \
        "$@" \
        bash "$STATUSLINE" < "$mock" 2>/dev/null
    rm -f "$tmp_config"
}

# Strip ANSI escape codes for assertion
strip_ansi() {
    sed $'s/\033\[[0-9;]*[a-zA-Z]//g'
}

assert_contains() {
    local output="$1"
    local expected="$2"
    local label="$3"
    local stripped
    stripped=$(echo "$output" | strip_ansi)
    if echo "$stripped" | grep -qF "$expected"; then
        echo -e "  ${GREEN}PASS${RESET} $label"
        ((passed++))
    else
        echo -e "  ${RED}FAIL${RESET} $label"
        echo -e "    Expected to contain: '$expected'"
        echo -e "    Got: '$stripped'"
        errors+=("$label: expected '$expected' in '$stripped'")
        ((failed++))
    fi
}

assert_not_contains() {
    local output="$1"
    local expected="$2"
    local label="$3"
    local stripped
    stripped=$(echo "$output" | strip_ansi)
    if echo "$stripped" | grep -qF "$expected"; then
        echo -e "  ${RED}FAIL${RESET} $label"
        echo -e "    Expected NOT to contain: '$expected'"
        echo -e "    Got: '$stripped'"
        errors+=("$label: expected NOT '$expected' in '$stripped'")
        ((failed++))
    else
        echo -e "  ${GREEN}PASS${RESET} $label"
        ((passed++))
    fi
}

# ============================================================
echo -e "${BOLD}═══ Claude Code Statusline v7 Test Suite ═══${RESET}"
echo ""

# ============================================================
echo -e "${BOLD}[Compact Mode]${RESET}"
# ============================================================

output=$(run_statusline "$TESTS_DIR/mock-compact.json" \
    CLAUDE_SL_LAYOUT=compact \
    CLAUDE_SL_PROJECT=1 \
    CLAUDE_SL_BRANCH=0 \
    CLAUDE_SL_GIT_STATUS=0 \
    CLAUDE_SL_MODEL=1 \
    CLAUDE_SL_BAR=1 \
    CLAUDE_SL_PERCENT=1 \
    CLAUDE_SL_TOKENS=0 \
    CLAUDE_SL_COST=1 \
    NO_COLOR=1)

assert_contains "$output" "my-app" "compact: shows project name"
assert_contains "$output" "Opus 4.5" "compact: shows model"
assert_contains "$output" "62%" "compact: shows usage percent"
assert_contains "$output" '3.47' "compact: shows cost"
assert_contains "$output" "|" "compact: shows pipe separator"

echo ""

# ============================================================
echo -e "${BOLD}[Detailed Mode]${RESET}"
# ============================================================

output=$(run_statusline "$TESTS_DIR/mock-detailed.json" \
    CLAUDE_SL_LAYOUT=detailed \
    CLAUDE_SL_PROJECT=1 \
    CLAUDE_SL_CWD=1 \
    CLAUDE_SL_BRANCH=0 \
    CLAUDE_SL_GIT_STATUS=0 \
    CLAUDE_SL_SESSION=1 \
    CLAUDE_SL_WORKTREE=1 \
    CLAUDE_SL_MODEL=1 \
    CLAUDE_SL_AGENT=1 \
    CLAUDE_SL_BAR=1 \
    CLAUDE_SL_PERCENT=1 \
    CLAUDE_SL_TOKENS=1 \
    CLAUDE_SL_COST=1 \
    CLAUDE_SL_VELOCITY=1 \
    CLAUDE_SL_RATE_5H=1 \
    CLAUDE_SL_RATE_7D=1 \
    CLAUDE_SL_DURATION=1 \
    NO_COLOR=1)

assert_contains "$output" "webapp" "detailed: shows project name"
assert_contains "$output" "Sonnet 4.6" "detailed: shows model"
assert_contains "$output" "reviewer" "detailed: shows agent"
assert_contains "$output" "feature-auth" "detailed: shows session name"
assert_contains "$output" "wt-auth" "detailed: shows worktree"
assert_contains "$output" "87%" "detailed: shows usage percent"
assert_contains "$output" "+" "detailed: shows velocity"
assert_contains "$output" "5h:85%" "detailed: shows 5h rate limit"
assert_contains "$output" "7d:62%" "detailed: shows 7d rate limit"
assert_contains "$output" '5.89' "detailed: shows cost"
assert_contains "$output" "|" "detailed: shows pipe separators"

echo ""

# ============================================================
echo -e "${BOLD}[Compressed Context]${RESET}"
# ============================================================

output=$(run_statusline "$TESTS_DIR/mock-compressed.json" \
    CLAUDE_SL_LAYOUT=compact \
    CLAUDE_SL_PROJECT=1 \
    CLAUDE_SL_MODEL=1 \
    CLAUDE_SL_BAR=1 \
    CLAUDE_SL_PERCENT=1 \
    CLAUDE_SL_TOKENS=1 \
    CLAUDE_SL_COST=1 \
    NO_COLOR=1)

assert_contains "$output" "COMPRESSED" "compressed: shows COMPRESSED label"
assert_contains "$output" "COMPRESSED" "compressed: shows COMPRESSED label with token counts"
assert_contains "$output" "180K/200K" "compressed: shows token counts"

echo ""

# ============================================================
echo -e "${BOLD}[NO_COLOR Mode]${RESET}"
# ============================================================

output=$(run_statusline "$TESTS_DIR/mock-compact.json" \
    CLAUDE_SL_LAYOUT=compact \
    CLAUDE_SL_PROJECT=1 \
    CLAUDE_SL_MODEL=1 \
    CLAUDE_SL_BAR=1 \
    CLAUDE_SL_PERCENT=1 \
    CLAUDE_SL_COST=1 \
    NO_COLOR=1)

assert_not_contains "$output" $'\033[' "no_color: no ANSI escape codes"
assert_contains "$output" "|" "no_color: shows pipe separator (ASCII)"

echo ""

# ============================================================
echo -e "${BOLD}[Rate Limit Countdown]${RESET}"
# ============================================================

# Test with mock-detailed which has resets_at timestamps
output=$(run_statusline "$TESTS_DIR/mock-detailed.json" \
    CLAUDE_SL_LAYOUT=detailed \
    CLAUDE_SL_PROJECT=1 \
    CLAUDE_SL_RATE_5H=1 \
    CLAUDE_SL_RATE_7D=1 \
    NO_COLOR=1)

# Countdown format is ↓XhYm — check for the down arrow or the countdown format
# Note: countdown depends on current time vs resets_at, so we check for the rate display
assert_contains "$output" "5h:" "countdown: shows 5h rate prefix"
assert_contains "$output" "7d:" "countdown: shows 7d rate prefix"

echo ""

# ============================================================
echo -e "${BOLD}[Minimal / No Rate Limits]${RESET}"
# ============================================================

output=$(run_statusline "$TESTS_DIR/mock-minimal.json" \
    CLAUDE_SL_LAYOUT=compact \
    CLAUDE_SL_PROJECT=1 \
    CLAUDE_SL_MODEL=1 \
    CLAUDE_SL_BAR=1 \
    CLAUDE_SL_PERCENT=1 \
    CLAUDE_SL_RATE_5H=1 \
    CLAUDE_SL_RATE_7D=1 \
    NO_COLOR=1)

assert_contains "$output" "Haiku 4.5" "minimal: shows model"
assert_contains "$output" "12%" "minimal: shows low usage"
assert_not_contains "$output" "5h:" "minimal: hides empty 5h rate"
assert_not_contains "$output" "7d:" "minimal: hides empty 7d rate"

echo ""

# ============================================================
echo -e "${BOLD}[Config Tool Syntax]${RESET}"
# ============================================================

if bash -n "$PROJECT_DIR/statusline-config.sh" 2>/dev/null; then
    echo -e "  ${GREEN}PASS${RESET} config tool: valid bash syntax"
    ((passed++))
else
    echo -e "  ${RED}FAIL${RESET} config tool: bash syntax error"
    errors+=("config tool: syntax error")
    ((failed++))
fi

if bash -n "$STATUSLINE" 2>/dev/null; then
    echo -e "  ${GREEN}PASS${RESET} statusline: valid bash syntax"
    ((passed++))
else
    echo -e "  ${RED}FAIL${RESET} statusline: bash syntax error"
    errors+=("statusline: syntax error")
    ((failed++))
fi

echo ""

# ============================================================
echo -e "${BOLD}[Smart Auto-Hide]${RESET}"
# ============================================================

# With compressed mock (95% 5h rate), compact mode should auto-show rate limit
# even if not explicitly enabled — but only if user hasn't set it explicitly
output=$(run_statusline "$TESTS_DIR/mock-compressed.json" \
    CLAUDE_SL_LAYOUT=compact \
    CLAUDE_SL_PROJECT=1 \
    CLAUDE_SL_MODEL=1 \
    CLAUDE_SL_PERCENT=1 \
    CLAUDE_SL_BAR=1 \
    CLAUDE_SL_RATE_5H=0 \
    CLAUDE_SL_RATE_7D=0 \
    NO_COLOR=1)

# When explicitly set to 0, user choice should be respected
assert_not_contains "$output" "5h:95%" "auto-hide: respects explicit CLAUDE_SL_RATE_5H=0"

echo ""

# ============================================================
echo -e "${BOLD}[CWD — Subdirectory]${RESET}"
# ============================================================

# current_dir is a subdirectory of project_dir → relative path is shorter
output=$(run_statusline "$TESTS_DIR/mock-cwd-subdir.json" \
    CLAUDE_SL_LAYOUT=detailed \
    CLAUDE_SL_PROJECT=1 \
    CLAUDE_SL_CWD=1 \
    CLAUDE_SL_MODEL=1 \
    CLAUDE_SL_BAR=0 \
    CLAUDE_SL_PERCENT=0 \
    NO_COLOR=1)

assert_contains "$output" "src/components" "cwd-subdir: shows relative path (shorter than absolute)"
assert_not_contains "$output" "/home/user/github/my-app/src/components" "cwd-subdir: does not show full absolute path"

echo ""

# ============================================================
echo -e "${BOLD}[CWD — Same as project]${RESET}"
# ============================================================

# current_dir == project_dir → CWD_DISPLAY should be empty (PROJECT_NAME handles it)
output=$(run_statusline "$TESTS_DIR/mock-compact.json" \
    CLAUDE_SL_LAYOUT=detailed \
    CLAUDE_SL_PROJECT=1 \
    CLAUDE_SL_CWD=1 \
    CLAUDE_SL_MODEL=1 \
    CLAUDE_SL_BAR=0 \
    CLAUDE_SL_PERCENT=0 \
    NO_COLOR=1)

assert_contains "$output" "my-app" "cwd-same: shows project name"
# When current_dir == project_dir, CWD is hidden (redundant with project name)
assert_not_contains "$output" "/home/user/github/my-app" "cwd-same: hides redundant CWD (same as project)"

echo ""

# ============================================================
echo -e "${BOLD}[CWD — External directory]${RESET}"
# ============================================================

# current_dir is outside project_dir → shows absolute path (with ~ for home)
output=$(run_statusline "$TESTS_DIR/mock-cwd-external.json" \
    CLAUDE_SL_LAYOUT=detailed \
    CLAUDE_SL_PROJECT=1 \
    CLAUDE_SL_CWD=1 \
    CLAUDE_SL_MODEL=1 \
    CLAUDE_SL_BAR=0 \
    CLAUDE_SL_PERCENT=0 \
    NO_COLOR=1)

assert_contains "$output" "/tmp/other-project" "cwd-external: shows absolute path for external dir"
assert_contains "$output" "my-app" "cwd-external: also shows project name"

echo ""

# ============================================================
echo -e "${BOLD}[CWD — Smart auto-show in compact]${RESET}"
# ============================================================

# When current_dir differs from project_dir, CWD auto-shows in compact even if default is off
output=$(run_statusline "$TESTS_DIR/mock-cwd-subdir.json" \
    CLAUDE_SL_LAYOUT=compact \
    CLAUDE_SL_PROJECT=1 \
    CLAUDE_SL_MODEL=1 \
    CLAUDE_SL_BAR=0 \
    CLAUDE_SL_PERCENT=0 \
    NO_COLOR=1)

assert_contains "$output" "src/components" "cwd-auto: auto-shows CWD when it differs from project"

echo ""

# ============================================================
# Summary
# ============================================================
echo -e "${BOLD}════════════════════════════════════════${RESET}"
total=$((passed + failed))
echo -e "  ${GREEN}${passed}${RESET}/${total} passed"
if [ "$failed" -gt 0 ]; then
    echo -e "  ${RED}${failed}${RESET}/${total} failed"
    echo ""
    echo -e "${RED}Failures:${RESET}"
    for err in "${errors[@]}"; do
        echo -e "  ${RED}•${RESET} $err"
    done
    exit 1
else
    echo -e "  ${GREEN}All tests passed!${RESET}"
    exit 0
fi
