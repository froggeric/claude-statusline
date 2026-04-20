#!/bin/bash
# Claude Code Statusline 설정 도구 v2
# 키보드 방향키로 이동, 스페이스/엔터로 토글
# 설정은 ~/.claude/statusline/statusline.env 에 저장됨

CONFIG_FILE="$HOME/.claude/statusline/statusline.env"

# 현재 설정 로드 (기본값 1)
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
    CLAUDE_SL_MODEL=${CLAUDE_SL_MODEL:-1}
    CLAUDE_SL_BAR=${CLAUDE_SL_BAR:-1}
    CLAUDE_SL_PERCENT=${CLAUDE_SL_PERCENT:-1}
    CLAUDE_SL_TOKENS=${CLAUDE_SL_TOKENS:-1}
    CLAUDE_SL_COST=${CLAUDE_SL_COST:-1}
    CLAUDE_SL_CACHE=${CLAUDE_SL_CACHE:-1}
    CLAUDE_SL_TIME=${CLAUDE_SL_TIME:-1}
    CLAUDE_SL_LANG=${CLAUDE_SL_LANG:-en}
}

# 다국어 텍스트 설정 (레이블은 12칸 정렬)
set_i18n() {
    if [ "$CLAUDE_SL_LANG" = "ko" ]; then
        # 한국어 - 표시너비 12칸 정렬 (한글 1자=2칸)
        I18N_TITLE="Claude Code Statusline 설정"
        I18N_HELP="↑/↓: 이동  |  Space/Enter: 토글  |  s: 저장  |  q: 나가기"
        I18N_PREVIEW="미리보기:"
        I18N_ALL_HIDDEN="(모든 항목이 숨겨짐)"
        I18N_SAVED="설정이 저장되었습니다."
        I18N_NOT_SAVED="변경 사항이 저장되지 않았습니다."
        I18N_LANG_VALUE="한국어"
        # 항목 레이블 (표시너비 12칸 정렬)
        L_MODEL="모델명      "    # 6 + 6공백 = 12
        L_BAR="진행률 바   "      # 9 + 3공백 = 12
        L_PERCENT="사용률 %    "  # 8 + 4공백 = 12
        L_TOKENS="토큰 수     "   # 7 + 5공백 = 12
        L_COST="비용        "     # 4 + 8공백 = 12
        L_CACHE="캐시 효율   "    # 8 + 4공백 = 12
        L_TIME="남은 시간   "     # 8 + 4공백 = 12
        L_LANG="언어        "     # 4 + 8공백 = 12
    else
        # 영어 (기본)
        I18N_TITLE="Claude Code Statusline Settings"
        I18N_HELP="↑/↓: Move  |  Space/Enter: Toggle  |  s: Save  |  q: Quit"
        I18N_PREVIEW="Preview:"
        I18N_ALL_HIDDEN="(All items hidden)"
        I18N_SAVED="Settings saved."
        I18N_NOT_SAVED="Changes not saved."
        I18N_LANG_VALUE="English"
        # 항목 레이블 (12칸 정렬)
        L_MODEL="Model       "
        L_BAR="Progress Bar"
        L_PERCENT="Usage %     "
        L_TOKENS="Tokens      "
        L_COST="Cost        "
        L_CACHE="Cache       "
        L_TIME="Time Left   "
        L_LANG="Language    "
    fi
}

# 설정 저장
save_config() {
    cat > "$CONFIG_FILE" << EOF
# Claude Code Statusline 설정
# 1=표시, 0=숨김
export CLAUDE_SL_MODEL=$CLAUDE_SL_MODEL
export CLAUDE_SL_BAR=$CLAUDE_SL_BAR
export CLAUDE_SL_PERCENT=$CLAUDE_SL_PERCENT
export CLAUDE_SL_TOKENS=$CLAUDE_SL_TOKENS
export CLAUDE_SL_COST=$CLAUDE_SL_COST
export CLAUDE_SL_CACHE=$CLAUDE_SL_CACHE
export CLAUDE_SL_TIME=$CLAUDE_SL_TIME
# 언어 설정 (ko/en)
export CLAUDE_SL_LANG=$CLAUDE_SL_LANG
EOF
    echo ""
    echo "$I18N_SAVED"
}

# 색상
RED='\033[31m'
GREEN='\033[32m'
CYAN='\033[36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'
REVERSE='\033[7m'

# 현재 선택 인덱스
current=0
total=8

# 값 토글
toggle_value() {
    local var_name=$1
    local current_value=${!var_name}
    # 언어 설정은 ko/en 토글
    if [ "$var_name" = "CLAUDE_SL_LANG" ]; then
        if [ "$current_value" = "ko" ]; then
            eval "$var_name=en"
        else
            eval "$var_name=ko"
        fi
    # 나머지는 0/1 토글
    elif [ "$current_value" = "1" ]; then
        eval "$var_name=0"
    else
        eval "$var_name=1"
    fi
}

# 화면 그리기
draw_menu() {
    # 언어 텍스트 업데이트 (토글 시 즉시 반영)
    set_i18n

    # 항목 정의 (언어에 따라 동적 설정, 예시는 12칸 정렬)
    local ITEMS=(
        "CLAUDE_SL_MODEL:$L_MODEL:[Opus 4.5]  "
        "CLAUDE_SL_BAR:$L_BAR:[████░░░░░░]"
        "CLAUDE_SL_PERCENT:$L_PERCENT:45%         "
        "CLAUDE_SL_TOKENS:$L_TOKENS:(81K/200K)  "
        "CLAUDE_SL_COST:$L_COST:\$1.25       "
        "CLAUDE_SL_CACHE:$L_CACHE:⚡96%       "
        "CLAUDE_SL_TIME:$L_TIME:~7m         "
        "CLAUDE_SL_LANG:$L_LANG:ko/en       "
    )

    clear
    echo -e "${BOLD}╔══════════════════════════════════════════════════════╗${RESET}"
    printf "${BOLD}║     %-49s║${RESET}\n" "$I18N_TITLE"
    echo -e "${BOLD}╚══════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${DIM}  ${I18N_HELP}${RESET}"
    echo ""

    for i in "${!ITEMS[@]}"; do
        IFS=':' read -r var_name label example <<< "${ITEMS[$i]}"
        local value=${!var_name}

        # 언어 설정은 별도 표시
        if [ "$var_name" = "CLAUDE_SL_LANG" ]; then
            checkbox="${CYAN}[⚙]${RESET}"
            status="${GREEN}${I18N_LANG_VALUE}${RESET}"
        # 체크박스 표시
        elif [ "$value" = "1" ]; then
            checkbox="${GREEN}[✓]${RESET}"
            status="${GREEN}ON ${RESET}"
        else
            checkbox="${RED}[ ]${RESET}"
            status="${RED}OFF${RESET}"
        fi

        # 현재 선택된 항목 하이라이트
        if [ "$i" -eq "$current" ]; then
            echo -e "  ${REVERSE} ${checkbox} ${label}${RESET} ${DIM}${example}${RESET}  ${status}"
        else
            echo -e "   ${checkbox} ${label} ${DIM}${example}${RESET}  ${status}"
        fi
    done

    echo ""
    echo -e "${DIM}──────────────────────────────────────────────────────────${RESET}"
    echo ""

    # 미리보기
    echo -e "${CYAN}${I18N_PREVIEW}${RESET}"
    preview=""

    [ "$CLAUDE_SL_MODEL" = "1" ] && preview="${preview}${CYAN}[Opus 4.5]${RESET} "
    [ "$CLAUDE_SL_BAR" = "1" ] && preview="${preview}${GREEN}[████░░░░░░]${RESET} "
    [ "$CLAUDE_SL_PERCENT" = "1" ] && preview="${preview}${GREEN}40%${RESET} "
    [ "$CLAUDE_SL_TOKENS" = "1" ] && preview="${preview}${DIM}(81K/200K)${RESET} "
    [ "$CLAUDE_SL_COST" = "1" ] && preview="${preview}\033[35m\$1.25${RESET} "
    [ "$CLAUDE_SL_CACHE" = "1" ] && preview="${preview}${CYAN}⚡96%${RESET} "
    [ "$CLAUDE_SL_TIME" = "1" ] && preview="${preview}${DIM}~7m${RESET}"

    if [ -z "$preview" ]; then
        echo -e "  ${DIM}${I18N_ALL_HIDDEN}${RESET}"
    else
        echo -e "  $preview"
    fi
}

# 키 입력 처리
read_key() {
    local key
    IFS= read -rsn1 key

    if [[ $key == $'\x1b' ]]; then
        # 방향키: ESC + [ + A/B
        read -rsn2 key
        case "$key" in
            '[A') echo "UP" ;;
            '[B') echo "DOWN" ;;
            *) echo "" ;;
        esac
    elif [[ $key == '' || $key == ' ' ]]; then
        echo "TOGGLE"
    elif [[ $key == 's' || $key == 'S' || $key == 'ㄴ' ]]; then
        echo "SAVE"
    elif [[ $key == 'q' || $key == 'Q' || $key == 'ㅂ' ]]; then
        echo "QUIT"
    else
        echo ""
    fi
}

# 메인 루프
main() {
    load_config
    set_i18n

    # 터미널 설정 저장 및 raw 모드
    stty -echo
    trap 'stty echo; exit' INT TERM

    # 항목 정의 (토글용)
    ITEM_VARS=(
        "CLAUDE_SL_MODEL"
        "CLAUDE_SL_BAR"
        "CLAUDE_SL_PERCENT"
        "CLAUDE_SL_TOKENS"
        "CLAUDE_SL_COST"
        "CLAUDE_SL_CACHE"
        "CLAUDE_SL_TIME"
        "CLAUDE_SL_LANG"
    )

    while true; do
        draw_menu

        action=$(read_key)

        case $action in
            UP)
                ((current--))
                [ $current -lt 0 ] && current=$((total - 1))
                ;;
            DOWN)
                ((current++))
                [ $current -ge $total ] && current=0
                ;;
            TOGGLE)
                toggle_value "${ITEM_VARS[$current]}"
                ;;
            SAVE)
                stty echo
                save_config
                exit 0
                ;;
            QUIT)
                stty echo
                set_i18n
                echo ""
                echo "$I18N_NOT_SAVED"
                exit 0
                ;;
        esac
    done
}

main
