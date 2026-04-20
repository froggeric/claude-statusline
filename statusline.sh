#!/bin/bash
# Claude Code 컨텍스트 윈도우 상태 표시줄 v6
# v6: 개별 항목 on/off 환경변수 지원
# 형식: [Model] [진행률바] 퍼센트 (토큰) $비용 ⚡캐시 ~남은시간
#
# === 환경변수 설정 ===
# 표시 항목 (1=on, 0=off, 기본값=1):
#   CLAUDE_SL_MODEL    - 모델명 [Opus 4.5]
#   CLAUDE_SL_BAR      - 진행률 바 [████░░░░░░]
#   CLAUDE_SL_PERCENT  - 사용률 % (45%)
#   CLAUDE_SL_TOKENS   - 토큰 수 (450K/1M)
#   CLAUDE_SL_COST     - 비용 $1.25
#   CLAUDE_SL_CACHE    - 캐시 효율 ⚡99%
#   CLAUDE_SL_TIME     - 남은 시간 ~12m
#
# 언어 설정:
#   CLAUDE_SL_LANG     - 언어 (ko/en, 기본값=ko)
#
# 기타:
#   NO_COLOR           - 색상 비활성화
#   CLAUDE_STATUSLINE_DEBUG - 디버그 모드 (1=on)
#
# 예시: CLAUDE_SL_MODEL=0 CLAUDE_SL_TIME=0 으로 모델명과 시간 숨기기

input=$(cat)

# ============================================
# 설정 파일 로드 (없으면 기본값으로 자동 생성)
# ============================================
CONFIG_FILE="$HOME/.claude/statusline/statusline.env"

# 외부 환경변수 백업 (source가 덮어쓰기 전에)
_EXT_MODEL=${CLAUDE_SL_MODEL:-}
_EXT_BAR=${CLAUDE_SL_BAR:-}
_EXT_PERCENT=${CLAUDE_SL_PERCENT:-}
_EXT_TOKENS=${CLAUDE_SL_TOKENS:-}
_EXT_COST=${CLAUDE_SL_COST:-}
_EXT_CACHE=${CLAUDE_SL_CACHE:-}
_EXT_TIME=${CLAUDE_SL_TIME:-}
_EXT_LANG=${CLAUDE_SL_LANG:-}

if [ ! -f "$CONFIG_FILE" ]; then
    cat > "$CONFIG_FILE" << 'EOF'
# Claude Code Statusline 설정
# 1=표시, 0=숨김
export CLAUDE_SL_MODEL=1
export CLAUDE_SL_BAR=1
export CLAUDE_SL_PERCENT=1
export CLAUDE_SL_TOKENS=1
export CLAUDE_SL_COST=1
export CLAUDE_SL_CACHE=1
export CLAUDE_SL_TIME=1
# 언어 설정 (ko/en)
export CLAUDE_SL_LANG=en
EOF
fi
source "$CONFIG_FILE"

# 외부 환경변수가 있으면 우선 적용
[ -n "$_EXT_MODEL" ] && CLAUDE_SL_MODEL="$_EXT_MODEL"
[ -n "$_EXT_BAR" ] && CLAUDE_SL_BAR="$_EXT_BAR"
[ -n "$_EXT_PERCENT" ] && CLAUDE_SL_PERCENT="$_EXT_PERCENT"
[ -n "$_EXT_TOKENS" ] && CLAUDE_SL_TOKENS="$_EXT_TOKENS"
[ -n "$_EXT_COST" ] && CLAUDE_SL_COST="$_EXT_COST"
[ -n "$_EXT_CACHE" ] && CLAUDE_SL_CACHE="$_EXT_CACHE"
[ -n "$_EXT_TIME" ] && CLAUDE_SL_TIME="$_EXT_TIME"
[ -n "$_EXT_LANG" ] && CLAUDE_SL_LANG="$_EXT_LANG"

# ============================================
# 표시 옵션 (환경변수, 기본값=1)
# ============================================
SHOW_MODEL=${CLAUDE_SL_MODEL:-1}
SHOW_BAR=${CLAUDE_SL_BAR:-1}
SHOW_PERCENT=${CLAUDE_SL_PERCENT:-1}
SHOW_TOKENS=${CLAUDE_SL_TOKENS:-1}
SHOW_COST=${CLAUDE_SL_COST:-1}
SHOW_CACHE=${CLAUDE_SL_CACHE:-1}
SHOW_TIME=${CLAUDE_SL_TIME:-1}
LANG_CODE=${CLAUDE_SL_LANG:-en}

# ============================================
# 언어별 텍스트 정의
# ============================================
if [ "$LANG_CODE" = "ko" ]; then
    TEXT_COMPRESSED="압축됨"
else
    TEXT_COMPRESSED="Compressed"
fi

# 디버그 모드
if [ "${CLAUDE_STATUSLINE_DEBUG:-0}" = "1" ]; then
    echo "$input" > /tmp/claude_statusline_debug.json
fi

# ============================================
# JSON 파싱 (단일 jq 호출)
# ============================================
IFS=$'\t' read -r MODEL CONTEXT_SIZE \
    CURRENT_INPUT CURRENT_OUTPUT CACHE_READ CACHE_CREATION \
    TOTAL_COST TOTAL_DURATION_MS \
    TOTAL_INPUT TOTAL_OUTPUT \
    <<< "$(echo "$input" | jq -r '[
        .model.display_name // "Claude",
        .context_window.context_window_size // 200000,
        .context_window.current_usage.input_tokens // 0,
        .context_window.current_usage.output_tokens // 0,
        .context_window.current_usage.cache_read_input_tokens // 0,
        .context_window.current_usage.cache_creation_input_tokens // 0,
        .cost.total_cost_usd // 0,
        .cost.total_duration_ms // 0,
        .context_window.total_input_tokens // 0,
        .context_window.total_output_tokens // 0
    ] | @tsv')"

# ============================================
# 방어적 처리
# ============================================
CONTEXT_SIZE=${CONTEXT_SIZE:-200000}
CURRENT_INPUT=${CURRENT_INPUT:-0}
CURRENT_OUTPUT=${CURRENT_OUTPUT:-0}
CACHE_READ=${CACHE_READ:-0}
CACHE_CREATION=${CACHE_CREATION:-0}
TOTAL_COST=${TOTAL_COST:-0}
TOTAL_DURATION_MS=${TOTAL_DURATION_MS:-0}

[ "$CONTEXT_SIZE" -eq 0 ] 2>/dev/null && CONTEXT_SIZE=200000

# ============================================
# 토큰 계산 (current_usage 기준)
# ============================================
CONTEXT_TOKENS=$((CURRENT_INPUT + CACHE_READ + CACHE_CREATION))

if [ "$CONTEXT_SIZE" -gt 0 ]; then
    PERCENT=$((CONTEXT_TOKENS * 100 / CONTEXT_SIZE))
else
    PERCENT=0
fi

# ============================================
# K/M 단위 변환 함수
# ============================================
format_tokens() {
    local num=${1:-0}
    if [ "$num" -ge 1000000 ] 2>/dev/null; then
        local int_part=$((num / 1000000))
        local dec_part=$(( (num % 1000000) / 100000 ))
        [ "$dec_part" -eq 0 ] && echo "${int_part}M" || echo "${int_part}.${dec_part}M"
    elif [ "$num" -ge 100000 ] 2>/dev/null; then
        echo "$((num / 1000))K"
    elif [ "$num" -ge 1000 ] 2>/dev/null; then
        local int_part=$((num / 1000))
        local dec_part=$(( (num % 1000) / 100 ))
        [ "$dec_part" -eq 0 ] && echo "${int_part}K" || echo "${int_part}.${dec_part}K"
    else
        echo "${num}"
    fi
}

USED_K=$(format_tokens $CONTEXT_TOKENS)
TOTAL_K=$(format_tokens $CONTEXT_SIZE)

# ============================================
# 비용 계산
# ============================================
COST_STR=$(awk -v cost="$TOTAL_COST" 'BEGIN { printf "$%.2f", cost }')
COST_POSITIVE=$(awk -v cost="$TOTAL_COST" 'BEGIN { print (cost > 0) ? 1 : 0 }')

# ============================================
# 캐시 효율 계산
# ============================================
CACHE_TOTAL=$((CACHE_READ + CACHE_CREATION))
if [ "$CACHE_TOTAL" -gt 0 ] 2>/dev/null; then
    CACHE_HIT_RATE=$((CACHE_READ * 100 / CACHE_TOTAL))
    CACHE_STR="⚡${CACHE_HIT_RATE}%"
else
    CACHE_STR=""
fi

# ============================================
# 남은 시간 계산
# ============================================
TIME_STR=""
duration_min=$((TOTAL_DURATION_MS / 60000))

if [ "$duration_min" -gt 0 ] && [ "$CONTEXT_TOKENS" -gt 0 ] 2>/dev/null; then
    tokens_per_min=$((CONTEXT_TOKENS / duration_min))
    remaining_tokens=$((CONTEXT_SIZE - CONTEXT_TOKENS))

    if [ "$tokens_per_min" -gt 0 ] && [ "$remaining_tokens" -gt 0 ]; then
        remaining_min=$((remaining_tokens / tokens_per_min))
        if [ "$remaining_min" -ge 60 ]; then
            TIME_STR="~$((remaining_min / 60))h"
        elif [ "$remaining_min" -gt 0 ]; then
            TIME_STR="~${remaining_min}m"
        fi
    fi
fi

# ============================================
# ANSI 색상 (NO_COLOR 지원)
# ============================================
if [ -n "${NO_COLOR:-}" ]; then
    RED='' GREEN='' YELLOW='' CYAN='' MAGENTA='' DIM='' BOLD='' RESET=''
else
    RED='\033[31m' GREEN='\033[32m' YELLOW='\033[33m'
    CYAN='\033[36m' MAGENTA='\033[35m'
    DIM='\033[2m' BOLD='\033[1m' RESET='\033[0m'
fi

# ============================================
# 사용량에 따른 색상 결정
# ============================================
if [ "$PERCENT" -gt 100 ] 2>/dev/null; then
    COLOR="${RED}${BOLD}"
    STATUS="$TEXT_COMPRESSED"
elif [ "$PERCENT" -gt 80 ] 2>/dev/null; then
    COLOR="${RED}"
    STATUS="${PERCENT}%"
elif [ "$PERCENT" -gt 50 ] 2>/dev/null; then
    COLOR="${YELLOW}"
    STATUS="${PERCENT}%"
else
    COLOR="${GREEN}"
    STATUS="${PERCENT}%"
fi

# ============================================
# 진행률 바 생성
# ============================================
BAR_WIDTH=10
[ "$PERCENT" -gt 100 ] 2>/dev/null && FILLED=$BAR_WIDTH || FILLED=$((PERCENT * BAR_WIDTH / 100))
EMPTY=$((BAR_WIDTH - FILLED))

BAR=""
for ((i=0; i<FILLED; i++)); do BAR="${BAR}█"; done
for ((i=0; i<EMPTY; i++)); do BAR="${BAR}░"; done

# ============================================
# 최종 출력 조합 (조건부)
# ============================================
OUTPUT=""

# 모델명
if [ "$SHOW_MODEL" = "1" ]; then
    OUTPUT="${CYAN}[${MODEL}]${RESET}"
fi

# 진행률 바
if [ "$SHOW_BAR" = "1" ]; then
    [ -n "$OUTPUT" ] && OUTPUT="${OUTPUT} "
    OUTPUT="${OUTPUT}${COLOR}[${BAR}]${RESET}"
fi

# 퍼센트
if [ "$SHOW_PERCENT" = "1" ]; then
    [ -n "$OUTPUT" ] && OUTPUT="${OUTPUT} "
    OUTPUT="${OUTPUT}${COLOR}${STATUS}${RESET}"
fi

# 토큰 수
if [ "$SHOW_TOKENS" = "1" ]; then
    [ -n "$OUTPUT" ] && OUTPUT="${OUTPUT} "
    OUTPUT="${OUTPUT}${DIM}(${USED_K}/${TOTAL_K})${RESET}"
fi

# 비용 (값이 있을 때만)
if [ "$SHOW_COST" = "1" ] && [ "$COST_POSITIVE" = "1" ]; then
    [ -n "$OUTPUT" ] && OUTPUT="${OUTPUT} "
    OUTPUT="${OUTPUT}${MAGENTA}${COST_STR}${RESET}"
fi

# 캐시 효율 (값이 있을 때만)
if [ "$SHOW_CACHE" = "1" ] && [ -n "$CACHE_STR" ]; then
    [ -n "$OUTPUT" ] && OUTPUT="${OUTPUT} "
    OUTPUT="${OUTPUT}${CYAN}${CACHE_STR}${RESET}"
fi

# 남은 시간 (값이 있을 때만)
if [ "$SHOW_TIME" = "1" ] && [ -n "$TIME_STR" ]; then
    [ -n "$OUTPUT" ] && OUTPUT="${OUTPUT} "
    OUTPUT="${OUTPUT}${DIM}${TIME_STR}${RESET}"
fi

echo -e "$OUTPUT"
