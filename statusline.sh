#!/bin/bash
# Claude Code Statusline v8
# Best-in-class statusline with layout modes, git caching, rate limits,
# code velocity, and 5-band color gradient.
#
# Layout modes: compact (default), detailed, multi-line
#
# Environment variables (1=show, 0=hide):
#   CLAUDE_SL_LAYOUT   - Layout mode: compact/detailed/multiline (default: compact)
#   CLAUDE_SL_CWD      - Full working directory path
#   CLAUDE_SL_PROJECT  - Project name
#   CLAUDE_SL_BRANCH   - Git branch (cached, 5s TTL)
#   CLAUDE_SL_SESSION  - Custom session name
#   CLAUDE_SL_WORKTREE - Worktree info
#   CLAUDE_SL_MODEL    - Model name
#   CLAUDE_SL_AGENT    - Agent name (when in agent mode)
#   CLAUDE_SL_BAR      - Context progress bar
#   CLAUDE_SL_PERCENT  - Context usage percentage
#   CLAUDE_SL_TOKENS   - Token counts (used/total)
#   CLAUDE_SL_COST     - Session cost
#   CLAUDE_SL_VELOCITY - Code velocity (+added/-removed)
#   CLAUDE_SL_RATE_5H  - 5-hour rate limit %
#   CLAUDE_SL_RATE_7D  - 7-day rate limit %
#   CLAUDE_SL_DURATION - Session wall-clock duration
#   CLAUDE_SL_CACHE    - Cache hit rate (opt-in)
#   CLAUDE_SL_LANG     - Language: ko/en (default: en)
#   NO_COLOR           - Disable all colors
#   CLAUDE_STATUSLINE_DEBUG - Debug mode (1=on)

input=$(cat)

# ============================================
# Configuration loading
# ============================================
CONFIG_FILE="$HOME/.claude/statusline/statusline.env"

# Backup external env vars before sourcing
_EXT_LAYOUT=${CLAUDE_SL_LAYOUT:-}
_EXT_CWD=${CLAUDE_SL_CWD:-}
_EXT_PROJECT=${CLAUDE_SL_PROJECT:-}
_EXT_BRANCH=${CLAUDE_SL_BRANCH:-}
_EXT_SESSION=${CLAUDE_SL_SESSION:-}
_EXT_WORKTREE=${CLAUDE_SL_WORKTREE:-}
_EXT_MODEL=${CLAUDE_SL_MODEL:-}
_EXT_AGENT=${CLAUDE_SL_AGENT:-}
_EXT_BAR=${CLAUDE_SL_BAR:-}
_EXT_PERCENT=${CLAUDE_SL_PERCENT:-}
_EXT_TOKENS=${CLAUDE_SL_TOKENS:-}
_EXT_COST=${CLAUDE_SL_COST:-}
_EXT_VELOCITY=${CLAUDE_SL_VELOCITY:-}
_EXT_RATE_5H=${CLAUDE_SL_RATE_5H:-}
_EXT_RATE_7D=${CLAUDE_SL_RATE_7D:-}
_EXT_DURATION=${CLAUDE_SL_DURATION:-}
_EXT_CACHE=${CLAUDE_SL_CACHE:-}
_EXT_LANG=${CLAUDE_SL_LANG:-}

# Auto-generate config if missing
if [ ! -f "$CONFIG_FILE" ]; then
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" << 'DEFENV'
# Claude Code Statusline v8 Configuration
# Layout mode: compact / detailed / multiline
# Toggle items are only written here when changed from layout defaults.
export CLAUDE_SL_LAYOUT=compact
# Language (ko/en)
export CLAUDE_SL_LANG=en
DEFENV
fi
source "$CONFIG_FILE"

# Restore external env vars (they take priority)
[ -n "$_EXT_LAYOUT" ]   && CLAUDE_SL_LAYOUT="$_EXT_LAYOUT"
[ -n "$_EXT_CWD" ]      && CLAUDE_SL_CWD="$_EXT_CWD"
[ -n "$_EXT_PROJECT" ]  && CLAUDE_SL_PROJECT="$_EXT_PROJECT"
[ -n "$_EXT_BRANCH" ]   && CLAUDE_SL_BRANCH="$_EXT_BRANCH"
[ -n "$_EXT_SESSION" ]  && CLAUDE_SL_SESSION="$_EXT_SESSION"
[ -n "$_EXT_WORKTREE" ] && CLAUDE_SL_WORKTREE="$_EXT_WORKTREE"
[ -n "$_EXT_MODEL" ]    && CLAUDE_SL_MODEL="$_EXT_MODEL"
[ -n "$_EXT_AGENT" ]    && CLAUDE_SL_AGENT="$_EXT_AGENT"
[ -n "$_EXT_BAR" ]      && CLAUDE_SL_BAR="$_EXT_BAR"
[ -n "$_EXT_PERCENT" ]  && CLAUDE_SL_PERCENT="$_EXT_PERCENT"
[ -n "$_EXT_TOKENS" ]   && CLAUDE_SL_TOKENS="$_EXT_TOKENS"
[ -n "$_EXT_COST" ]     && CLAUDE_SL_COST="$_EXT_COST"
[ -n "$_EXT_VELOCITY" ] && CLAUDE_SL_VELOCITY="$_EXT_VELOCITY"
[ -n "$_EXT_RATE_5H" ]  && CLAUDE_SL_RATE_5H="$_EXT_RATE_5H"
[ -n "$_EXT_RATE_7D" ]  && CLAUDE_SL_RATE_7D="$_EXT_RATE_7D"
[ -n "$_EXT_DURATION" ] && CLAUDE_SL_DURATION="$_EXT_DURATION"
[ -n "$_EXT_CACHE" ]    && CLAUDE_SL_CACHE="$_EXT_CACHE"
[ -n "$_EXT_LANG" ]     && CLAUDE_SL_LANG="$_EXT_LANG"

# ============================================
# Resolve show/hide settings per layout mode
# ============================================
LAYOUT=${CLAUDE_SL_LAYOUT:-compact}

# Defaults by layout mode (compact|detailed|multiline)
# Format: var_name:compact_default:detailed_default:multiline_default
LAYOUT_DEFAULTS=(
    "CLAUDE_SL_CWD:0:1:1"
    "CLAUDE_SL_PROJECT:1:1:1"
    "CLAUDE_SL_BRANCH:1:1:1"
    "CLAUDE_SL_SESSION:0:1:1"
    "CLAUDE_SL_WORKTREE:0:1:1"
    "CLAUDE_SL_MODEL:1:1:1"
    "CLAUDE_SL_AGENT:0:1:1"
    "CLAUDE_SL_BAR:1:1:1"
    "CLAUDE_SL_PERCENT:1:1:1"
    "CLAUDE_SL_TOKENS:0:1:1"
    "CLAUDE_SL_COST:1:1:1"
    "CLAUDE_SL_VELOCITY:0:1:1"
    "CLAUDE_SL_RATE_5H:0:1:1"
    "CLAUDE_SL_RATE_7D:0:1:1"
    "CLAUDE_SL_DURATION:0:1:1"
    "CLAUDE_SL_CACHE:0:0:0"
)

# Map layout name to index
case "$LAYOUT" in
    detailed)  LAYOUT_IDX=2 ;;
    multiline) LAYOUT_IDX=3 ;;
    *)         LAYOUT_IDX=1 ;;
esac

# Resolve each setting: if explicitly set in config, use that; otherwise use layout default
for entry in "${LAYOUT_DEFAULTS[@]}"; do
    IFS=':' read -r var_name c_def d_def m_def <<< "$entry"
    defaults=("$c_def" "$d_def" "$m_def")
    # Check if the var was explicitly set in config (exists in the sourced file)
    if grep -q "^export ${var_name}=" "$CONFIG_FILE" 2>/dev/null; then
        # Use the value from the env (already sourced)
        eval "resolved=\${$var_name:-}"
        [ -z "$resolved" ] && resolved="${defaults[$((LAYOUT_IDX-1))]}"
    else
        resolved="${defaults[$((LAYOUT_IDX-1))]}"
    fi
    eval "${var_name}=\"${resolved:-${defaults[$((LAYOUT_IDX-1))]}}\""
done

LANG_CODE=${CLAUDE_SL_LANG:-en}

# ============================================
# Language strings
# ============================================
if [ "$LANG_CODE" = "ko" ]; then
    TEXT_COMPRESSED="압축됨"
else
    TEXT_COMPRESSED="COMPRESSED"
fi

# Debug mode
if [ "${CLAUDE_STATUSLINE_DEBUG:-0}" = "1" ]; then
    echo "$input" > /tmp/claude_statusline_debug.json
fi

# ============================================
# JSON parsing (single jq call, all fields)
# ============================================
IFS=$'\x1f' read -r MODEL MODEL_ID \
    CONTEXT_SIZE USED_PCT REMAINING_PCT \
    CURRENT_INPUT CURRENT_OUTPUT CACHE_READ CACHE_CREATION \
    TOTAL_COST TOTAL_DURATION_MS TOTAL_API_DURATION_MS \
    LINES_ADDED LINES_REMOVED \
    CURRENT_DIR PROJECT_DIR \
    SESSION_ID SESSION_NAME \
    EXCEEDS_200K \
    RATE_5H_PCT RATE_5H_RESET \
    RATE_7D_PCT RATE_7D_RESET \
    AGENT_NAME \
    WORKTREE_NAME WORKTREE_BRANCH \
    <<< "$(echo "$input" | jq -r '[
        .model.display_name // "Claude",
        .model.id // "",
        .context_window.context_window_size // 200000,
        (.context_window.used_percentage // 0),
        (.context_window.remaining_percentage // 100),
        .context_window.current_usage.input_tokens // 0,
        .context_window.current_usage.output_tokens // 0,
        .context_window.current_usage.cache_read_input_tokens // 0,
        .context_window.current_usage.cache_creation_input_tokens // 0,
        .cost.total_cost_usd // 0,
        .cost.total_duration_ms // 0,
        .cost.total_api_duration_ms // 0,
        .cost.total_lines_added // 0,
        .cost.total_lines_removed // 0,
        .workspace.current_dir // "",
        .workspace.project_dir // "",
        .session_id // "",
        .session_name // "",
        (.exceeds_200k_tokens // false),
        .rate_limits.five_hour.used_percentage // "",
        .rate_limits.five_hour.resets_at // "",
        .rate_limits.seven_day.used_percentage // "",
        .rate_limits.seven_day.resets_at // "",
        .agent.name // "",
        .worktree.name // "",
        .worktree.branch // ""
    ] | map(tostring) | join("\u001f")')"

# ============================================
# Defensive defaults
# ============================================
CONTEXT_SIZE=${CONTEXT_SIZE:-200000}
USED_PCT=${USED_PCT:-0}
CURRENT_INPUT=${CURRENT_INPUT:-0}
CURRENT_OUTPUT=${CURRENT_OUTPUT:-0}
CACHE_READ=${CACHE_READ:-0}
CACHE_CREATION=${CACHE_CREATION:-0}
TOTAL_COST=${TOTAL_COST:-0}
TOTAL_DURATION_MS=${TOTAL_DURATION_MS:-0}
TOTAL_API_DURATION_MS=${TOTAL_API_DURATION_MS:-0}
LINES_ADDED=${LINES_ADDED:-0}
LINES_REMOVED=${LINES_REMOVED:-0}
CURRENT_DIR=${CURRENT_DIR:-}
PROJECT_DIR=${PROJECT_DIR:-}
SESSION_ID=${SESSION_ID:-}
SESSION_NAME=${SESSION_NAME:-}
EXCEEDS_200K=${EXCEEDS_200K:-false}
RATE_5H_PCT=${RATE_5H_PCT:-}
RATE_7D_PCT=${RATE_7D_PCT:-}
AGENT_NAME=${AGENT_NAME:-}
WORKTREE_NAME=${WORKTREE_NAME:-}
WORKTREE_BRANCH=${WORKTREE_BRANCH:-}

# Truncate float percentages to integer
USED_PCT_INT=$(echo "$USED_PCT" | cut -d. -f1)
[ -z "$USED_PCT_INT" ] && USED_PCT_INT=0

# ============================================
# Project name and CWD
# ============================================
if [ -n "$PROJECT_DIR" ]; then
    PROJECT_NAME=$(basename "$PROJECT_DIR")
elif [ -n "$CURRENT_DIR" ]; then
    PROJECT_NAME=$(basename "$CURRENT_DIR")
else
    PROJECT_NAME=""
fi

if [ -n "$CURRENT_DIR" ]; then
    CWD_DISPLAY="${CURRENT_DIR/#$HOME/~}"
else
    CWD_DISPLAY=""
fi

# ============================================
# Git branch (session-based caching)
# ============================================
get_git_info() {
    local cwd="$1"
    local sid="$2"
    [ -z "$cwd" ] && return

    local cache_file="/tmp/claude-sl-git-${sid}"
    local cache_max_age=5

    # Check cache freshness (cross-platform)
    local cache_is_stale=1
    if [ -f "$cache_file" ]; then
        local now=$(date +%s)
        local mtime
        mtime=$(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null || echo 0)
        if [ $((now - mtime)) -le "$cache_max_age" ]; then
            cache_is_stale=0
        fi
    fi

    if [ "$cache_is_stale" = "1" ]; then
        local branch=""
        if git -C "$cwd" --no-optional-locks rev-parse --git-dir >/dev/null 2>&1; then
            branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null || \
                     git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null || echo "")
        fi
        echo "$branch" > "$cache_file"
    fi

    GIT_BRANCH_CACHED=$(cat "$cache_file" 2>/dev/null || echo "")
}

GIT_BRANCH_CACHED=""
if [ "$CLAUDE_SL_BRANCH" = "1" ]; then
    get_git_info "$CURRENT_DIR" "$SESSION_ID"
fi

# ============================================
# Token formatting (K/M suffix)
# ============================================
format_tokens() {
    local num=${1:-0}
    if [ "$num" -ge 1000000 ] 2>/dev/null; then
        local int_part=$((num / 1000000))
        local dec_part=$(( (num % 1000000) / 100000 ))
        [ "$dec_part" -eq 0 ] && echo "${int_part}M" || echo "${int_part}.${dec_part}M"
    elif [ "$num" -ge 1000 ] 2>/dev/null; then
        local int_part=$((num / 1000))
        local dec_part=$(( (num % 1000) / 100 ))
        [ "$dec_part" -eq 0 ] && echo "${int_part}K" || echo "${int_part}.${dec_part}K"
    else
        echo "${num}"
    fi
}

# Context tokens for display
CONTEXT_TOKENS=$((CURRENT_INPUT + CACHE_READ + CACHE_CREATION))
USED_DISPLAY=$(format_tokens $CONTEXT_TOKENS)
TOTAL_DISPLAY=$(format_tokens $CONTEXT_SIZE)

# ============================================
# Duration formatting
# ============================================
format_duration() {
    local ms=${1:-0}
    local total_sec=$((ms / 1000))
    if [ "$total_sec" -ge 3600 ]; then
        echo "$((total_sec / 3600))h$(((total_sec % 3600) / 60))m"
    elif [ "$total_sec" -ge 60 ]; then
        echo "$((total_sec / 60))m"
    elif [ "$total_sec" -gt 0 ]; then
        echo "${total_sec}s"
    else
        echo "0s"
    fi
}

# ============================================
# ANSI colors (NO_COLOR support)
# ============================================
if [ -n "${NO_COLOR:-}" ]; then
    RED='' GREEN='' BRIGHT_GREEN='' YELLOW='' BRIGHT_RED=''
    CYAN='' MAGENTA='' DIM='' BOLD='' RESET='' BLINK=''
else
    RED='\033[31m'
    GREEN='\033[32m'
    BRIGHT_GREEN='\033[1;32m'
    YELLOW='\033[33m'
    BRIGHT_RED='\033[1;31m'
    CYAN='\033[36m'
    MAGENTA='\033[35m'
    DIM='\033[2m'
    BOLD='\033[1m'
    RESET='\033[0m'
    BLINK='\033[5m'
fi

# ============================================
# Color determination: 5-band gradient
# ============================================
get_context_color() {
    local pct=$1
    if [ "$pct" -gt 100 ]; then
        echo "${RED}${BOLD}"
    elif [ "$pct" -ge 96 ]; then
        echo "${BRIGHT_RED}${BLINK}"
    elif [ "$pct" -ge 81 ]; then
        echo "${BRIGHT_RED}"
    elif [ "$pct" -ge 61 ]; then
        echo "${YELLOW}"
    elif [ "$pct" -ge 31 ]; then
        echo "${BRIGHT_GREEN}"
    else
        echo "${GREEN}"
    fi
}

get_rate_color() {
    local pct=$1
    if [ "$pct" -ge 91 ]; then
        echo "${BRIGHT_RED}"
    elif [ "$pct" -ge 76 ]; then
        echo "${YELLOW}${BOLD}"
    elif [ "$pct" -ge 51 ]; then
        echo "${YELLOW}"
    else
        echo "${DIM}"
    fi
}

CTX_COLOR=$(get_context_color "$USED_PCT_INT")

# ============================================
# Context status text
# ============================================
if [ "$USED_PCT_INT" -gt 100 ]; then
    CTX_STATUS="${RED}${BOLD}${TEXT_COMPRESSED}${RESET}"
elif [ "$USED_PCT_INT" -ge 96 ]; then
    CTX_STATUS="${CTX_COLOR}${USED_PCT_INT}%${RESET}"
else
    CTX_STATUS="${CTX_COLOR}${USED_PCT_INT}%${RESET}"
fi

# ============================================
# Progress bar
# ============================================
BAR_WIDTH=15
if [ "$USED_PCT_INT" -gt 100 ]; then
    FILLED=$BAR_WIDTH
else
    FILLED=$((USED_PCT_INT * BAR_WIDTH / 100))
fi
EMPTY=$((BAR_WIDTH - FILLED))

BAR=""
for ((i=0; i<FILLED; i++)); do BAR="${BAR}█"; done
for ((i=0; i<EMPTY; i++)); do BAR="${BAR}░"; done

# ============================================
# Cost
# ============================================
COST_STR=$(awk -v cost="$TOTAL_COST" 'BEGIN { printf "$%.2f", cost }')
COST_POSITIVE=$(awk -v cost="$TOTAL_COST" 'BEGIN { print (cost > 0) ? 1 : 0 }')

# ============================================
# Cache hit rate
# ============================================
CACHE_TOTAL=$((CACHE_READ + CACHE_CREATION))
if [ "$CACHE_TOTAL" -gt 0 ]; then
    CACHE_HIT_RATE=$((CACHE_READ * 100 / CACHE_TOTAL))
    CACHE_STR="⚡${CACHE_HIT_RATE}%"
else
    CACHE_STR=""
fi

# ============================================
# Code velocity
# ============================================
VELOCITY_STR=""
if [ "$LINES_ADDED" -gt 0 ] 2>/dev/null || [ "$LINES_REMOVED" -gt 0 ] 2>/dev/null; then
    local_vel=""
    [ "$LINES_ADDED" -gt 0 ] && local_vel="${GREEN}+${LINES_ADDED}${RESET}"
    [ "$LINES_REMOVED" -gt 0 ] && local_vel="${local_vel}${RED}-${LINES_REMOVED}${RESET}"
    VELOCITY_STR="$local_vel"
fi

# ============================================
# Rate limits
# ============================================
RATE_5H_STR=""
if [ -n "$RATE_5H_PCT" ] && [ "$RATE_5H_PCT" != "" ]; then
    RATE_5H_INT=$(echo "$RATE_5H_PCT" | cut -d. -f1)
    RATE_5H_COLOR=$(get_rate_color "$RATE_5H_INT")
    RATE_5H_STR="${RATE_5H_COLOR}5h:${RATE_5H_INT}%${RESET}"
fi

RATE_7D_STR=""
if [ -n "$RATE_7D_PCT" ] && [ "$RATE_7D_PCT" != "" ]; then
    RATE_7D_INT=$(echo "$RATE_7D_PCT" | cut -d. -f1)
    RATE_7D_COLOR=$(get_rate_color "$RATE_7D_INT")
    RATE_7D_STR="${RATE_7D_COLOR}7d:${RATE_7D_INT}%${RESET}"
fi

# ============================================
# Duration
# ============================================
DURATION_STR=$(format_duration "$TOTAL_DURATION_MS")

# ============================================
# Model display
# ============================================
if [ "$CLAUDE_SL_AGENT" = "1" ] && [ -n "$AGENT_NAME" ]; then
    MODEL_DISPLAY="${CYAN}${MODEL}/${AGENT_NAME}${RESET}"
else
    MODEL_DISPLAY="${CYAN}${MODEL}${RESET}"
fi

# ============================================
# Helper: append to output with separator
# ============================================
OUTPUT=""
append_output() {
    local segment="$1"
    [ -z "$segment" ] && return
    if [ -n "$OUTPUT" ]; then
        OUTPUT="${OUTPUT} ${segment}"
    else
        OUTPUT="${segment}"
    fi
}

# ============================================
# Identity section: project + branch + session + worktree + cwd
# ============================================
IDENTITY=""

# Project name
if [ "$CLAUDE_SL_PROJECT" = "1" ] && [ -n "$PROJECT_NAME" ]; then
    IDENTITY="${BOLD}${PROJECT_NAME}${RESET}"
fi

# CWD (alternative to project name)
if [ "$CLAUDE_SL_CWD" = "1" ] && [ -n "$CWD_DISPLAY" ]; then
    if [ -n "$IDENTITY" ]; then
        IDENTITY="${IDENTITY} ${DIM}${CWD_DISPLAY}${RESET}"
    else
        IDENTITY="${DIM}${CWD_DISPLAY}${RESET}"
    fi
fi

# Git branch
if [ "$CLAUDE_SL_BRANCH" = "1" ] && [ -n "$GIT_BRANCH_CACHED" ]; then
    if [ -n "$IDENTITY" ]; then
        IDENTITY="${IDENTITY} ${GIT_BRANCH_CACHED}"
    else
        IDENTITY="${GIT_BRANCH_CACHED}"
    fi
fi

# Session name
if [ "$CLAUDE_SL_SESSION" = "1" ] && [ -n "$SESSION_NAME" ]; then
    if [ -n "$IDENTITY" ]; then
        IDENTITY="${IDENTITY} ${CYAN}${SESSION_NAME}${RESET}"
    else
        IDENTITY="${CYAN}${SESSION_NAME}${RESET}"
    fi
fi

# Worktree
if [ "$CLAUDE_SL_WORKTREE" = "1" ] && [ -n "$WORKTREE_NAME" ]; then
    local_wt="${YELLOW}wt:${WORKTREE_NAME}${RESET}"
    if [ -n "$IDENTITY" ]; then
        IDENTITY="${IDENTITY} ${local_wt}"
    else
        IDENTITY="${local_wt}"
    fi
fi

append_output "$IDENTITY"

# ============================================
# Model section
# ============================================
if [ "$CLAUDE_SL_MODEL" = "1" ]; then
    append_output "[${MODEL_DISPLAY}]"
fi

# Agent (shown inside model when model is off)
if [ "$CLAUDE_SL_AGENT" = "1" ] && [ -n "$AGENT_NAME" ] && [ "$CLAUDE_SL_MODEL" != "1" ]; then
    append_output "${MAGENTA}${AGENT_NAME}${RESET}"
fi

# ============================================
# Context health section
# ============================================
if [ "$CLAUDE_SL_BAR" = "1" ]; then
    append_output "${CTX_COLOR}${BAR}${RESET}"
fi

if [ "$CLAUDE_SL_PERCENT" = "1" ]; then
    append_output "$CTX_STATUS"
fi

if [ "$CLAUDE_SL_TOKENS" = "1" ]; then
    append_output "${DIM}(${USED_DISPLAY}/${TOTAL_DISPLAY})${RESET}"
fi

# ============================================
# Cost
# ============================================
if [ "$CLAUDE_SL_COST" = "1" ] && [ "$COST_POSITIVE" = "1" ]; then
    append_output "${MAGENTA}${COST_STR}${RESET}"
fi

# ============================================
# Code velocity (skip on line 1 if multiline — goes to line 2)
# ============================================
if [ "$CLAUDE_SL_VELOCITY" = "1" ] && [ -n "$VELOCITY_STR" ] && [ "$LAYOUT" != "multiline" ]; then
    append_output "$VELOCITY_STR"
fi

# ============================================
# Rate limits (skip on line 1 if multiline — goes to line 2)
# ============================================
if [ "$CLAUDE_SL_RATE_5H" = "1" ] && [ -n "$RATE_5H_STR" ] && [ "$LAYOUT" != "multiline" ]; then
    append_output "$RATE_5H_STR"
fi
if [ "$CLAUDE_SL_RATE_7D" = "1" ] && [ -n "$RATE_7D_STR" ] && [ "$LAYOUT" != "multiline" ]; then
    append_output "$RATE_7D_STR"
fi

# ============================================
# Duration (skip on line 1 if multiline — goes to line 2)
# ============================================
if [ "$CLAUDE_SL_DURATION" = "1" ] && [ "$LAYOUT" != "multiline" ]; then
    append_output "${DIM}${DURATION_STR}${RESET}"
fi

# ============================================
# Cache (opt-in only, skip on line 1 if multiline — goes to line 2)
# ============================================
if [ "$CLAUDE_SL_CACHE" = "1" ] && [ -n "$CACHE_STR" ] && [ "$LAYOUT" != "multiline" ]; then
    append_output "${CYAN}${CACHE_STR}${RESET}"
fi

# ============================================
# Multi-line: second line with supplementary info
# ============================================
if [ "$LAYOUT" = "multiline" ]; then
    LINE2=""
    [ -n "$VELOCITY_STR" ] && [ "$CLAUDE_SL_VELOCITY" = "1" ] && LINE2="${LINE2}${VELOCITY_STR}"
    [ -n "$RATE_5H_STR" ] && [ "$CLAUDE_SL_RATE_5H" = "1" ] && LINE2="${LINE2:+${LINE2} · }${RATE_5H_STR}"
    [ -n "$RATE_7D_STR" ] && [ "$CLAUDE_SL_RATE_7D" = "1" ] && LINE2="${LINE2:+${LINE2} }${RATE_7D_STR}"
    [ "$CLAUDE_SL_DURATION" = "1" ] && LINE2="${LINE2:+${LINE2} · }${DIM}${DURATION_STR}${RESET}"
    [ -n "$CACHE_STR" ] && [ "$CLAUDE_SL_CACHE" = "1" ] && LINE2="${LINE2:+${LINE2} · }${CYAN}${CACHE_STR}${RESET}"

    if [ -n "$LINE2" ]; then
        OUTPUT="${OUTPUT}\n${LINE2}"
    fi
fi

# ============================================
# Output
# ============================================
printf '%b' "$OUTPUT"
