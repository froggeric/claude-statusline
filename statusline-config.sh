#!/bin/bash
# Claude Code Statusline Configuration Tool v7
# Section-grouped display, layout mode cycling, 17 toggle items
# Keyboard: arrows to move, space/enter to toggle, L to cycle layout, s to save, q to quit

CONFIG_FILE="$HOME/.claude/statusline/statusline.env"

# ============================================
# Configuration loading
# ============================================
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
    CLAUDE_SL_LAYOUT=${CLAUDE_SL_LAYOUT:-compact}
    CLAUDE_SL_CWD=${CLAUDE_SL_CWD:-}
    CLAUDE_SL_PROJECT=${CLAUDE_SL_PROJECT:-}
    CLAUDE_SL_BRANCH=${CLAUDE_SL_BRANCH:-}
    CLAUDE_SL_GIT_STATUS=${CLAUDE_SL_GIT_STATUS:-}
    CLAUDE_SL_SESSION=${CLAUDE_SL_SESSION:-}
    CLAUDE_SL_WORKTREE=${CLAUDE_SL_WORKTREE:-}
    CLAUDE_SL_MODEL=${CLAUDE_SL_MODEL:-}
    CLAUDE_SL_AGENT=${CLAUDE_SL_AGENT:-}
    CLAUDE_SL_BAR=${CLAUDE_SL_BAR:-}
    CLAUDE_SL_PERCENT=${CLAUDE_SL_PERCENT:-}
    CLAUDE_SL_TOKENS=${CLAUDE_SL_TOKENS:-}
    CLAUDE_SL_COST=${CLAUDE_SL_COST:-}
    CLAUDE_SL_VELOCITY=${CLAUDE_SL_VELOCITY:-}
    CLAUDE_SL_RATE_5H=${CLAUDE_SL_RATE_5H:-}
    CLAUDE_SL_RATE_7D=${CLAUDE_SL_RATE_7D:-}
    CLAUDE_SL_DURATION=${CLAUDE_SL_DURATION:-}
    CLAUDE_SL_CACHE=${CLAUDE_SL_CACHE:-}
    CLAUDE_SL_LANG=${CLAUDE_SL_LANG:-en}
}

# ============================================
# Layout defaults
# ============================================
# Format: var_name:compact:detailed:multiline
LAYOUT_DEFAULTS=(
    "CLAUDE_SL_CWD:0:1:1"
    "CLAUDE_SL_PROJECT:1:1:1"
    "CLAUDE_SL_BRANCH:1:1:1"
    "CLAUDE_SL_GIT_STATUS:1:1:1"
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

# Supported languages: code, display name (in native script)
LANGS=(en ko zh ja es)
LANG_DISPLAY=("English" "한국어" "中文" "日本語" "Español")

# Resolve a var to its effective value for the current layout
resolve_var() {
    local var_name="$1"
    local val="${!var_name}"
    if [ -n "$val" ]; then
        echo "$val"
        return
    fi
    # Use layout default
    local layout_idx=1
    case "$CLAUDE_SL_LAYOUT" in
        detailed)  layout_idx=2 ;;
        multiline) layout_idx=3 ;;
    esac
    for entry in "${LAYOUT_DEFAULTS[@]}"; do
        IFS=':' read -r vn c d m <<< "$entry"
        if [ "$vn" = "$var_name" ]; then
            local defaults=("$c" "$d" "$m")
            echo "${defaults[$((layout_idx-1))]}"
            return
        fi
    done
    echo "1"
}

# ============================================
# i18n
# ============================================
set_i18n() {
    case "$CLAUDE_SL_LANG" in
        ko)
            I18N_TITLE="Claude Code Statusline 설정 v7"
            I18N_TITLE_PAD="                              "
            I18N_HELP="↑↓ 이동 | Space 토글 | L 레이아웃 | ←→ 언어 | s 저장 | q 나가기"
            I18N_PREVIEW="미리보기:"
            I18N_ALL_HIDDEN="(모든 항목이 숨겨짐)"
            I18N_SAVED="설정이 저장되었습니다."
            I18N_NOT_SAVED="변경 사항이 저장되지 않았습니다."
            I18N_SECTION_IDENTITY="[ 아이덴티티 ]"
            I18N_SECTION_CAPABILITY="[ 기능 ]"
            I18N_SECTION_HEALTH="[ 상태 ]"
            I18N_SECTION_ACTIVITY="[ 활동 ]"
            I18N_LAYOUT_LABEL="레이아웃"

            L_CWD="작업 디렉토리  "
            L_PROJECT="프로젝트        "
            L_BRANCH="Git 브랜치     "
            L_GIT_STATUS="Git 상태       "
            L_SESSION="세션 이름      "
            L_WORKTREE="워크트리       "
            L_MODEL="모델명          "
            L_AGENT="에이전트        "
            L_BAR="진행률 바       "
            L_PERCENT="사용률 %        "
            L_TOKENS="토큰 수         "
            L_COST="비용            "
            L_VELOCITY="코드 속도      "
            L_RATE_5H="5시간 제한     "
            L_RATE_7D="7일 제한       "
            L_DURATION="세션 시간      "
            L_CACHE="캐시 효율       "
            ;;
        zh)
            I18N_TITLE="Claude Code Statusline 设置 v7"
            I18N_TITLE_PAD="                              "
            I18N_HELP="↑↓ 移动 | Space 切换 | L 布局 | ←→ 语言 | s 保存 | q 退出"
            I18N_PREVIEW="预览："
            I18N_ALL_HIDDEN="(所有项目已隐藏)"
            I18N_SAVED="设置已保存。"
            I18N_NOT_SAVED="更改未保存。"
            I18N_SECTION_IDENTITY="[ 身份 ]"
            I18N_SECTION_CAPABILITY="[ 能力 ]"
            I18N_SECTION_HEALTH="[ 状态 ]"
            I18N_SECTION_ACTIVITY="[ 活动 ]"
            I18N_LAYOUT_LABEL="布局"

            L_CWD="工作目录    "
            L_PROJECT="项目        "
            L_BRANCH="Git 分支    "
            L_GIT_STATUS="Git 状态    "
            L_SESSION="会话名称    "
            L_WORKTREE="工作树      "
            L_MODEL="模型        "
            L_AGENT="代理        "
            L_BAR="进度条      "
            L_PERCENT="使用率 %    "
            L_TOKENS="令牌数      "
            L_COST="费用        "
            L_VELOCITY="代码速度    "
            L_RATE_5H="5小时限制   "
            L_RATE_7D="7天限制     "
            L_DURATION="会话时长    "
            L_CACHE="缓存效率    "
            ;;
        ja)
            I18N_TITLE="Claude Code Statusline 設定 v7"
            I18N_TITLE_PAD="                              "
            I18N_HELP="↑↓ 移動 | Space 切替 | L レイアウト | ←→ 言語 | s 保存 | q 終了"
            I18N_PREVIEW="プレビュー："
            I18N_ALL_HIDDEN="(全項目非表示)"
            I18N_SAVED="設定を保存しました。"
            I18N_NOT_SAVED="変更は保存されませんでした。"
            I18N_SECTION_IDENTITY="[ アイデンティティ ]"
            I18N_SECTION_CAPABILITY="[ 機能 ]"
            I18N_SECTION_HEALTH="[ 状態 ]"
            I18N_SECTION_ACTIVITY="[ アクティビティ ]"
            I18N_LAYOUT_LABEL="レイアウト"

            L_CWD="作業ディレクトリ"
            L_PROJECT="プロジェクト    "
            L_BRANCH="Git ブランチ   "
            L_GIT_STATUS="Git ステータス "
            L_SESSION="セッション名   "
            L_WORKTREE="ワークツリー   "
            L_MODEL="モデル          "
            L_AGENT="エージェント    "
            L_BAR="進捗バー        "
            L_PERCENT="使用率 %        "
            L_TOKENS="トークン数      "
            L_COST="コスト          "
            L_VELOCITY="コード速度     "
            L_RATE_5H="5時間制限      "
            L_RATE_7D="7日間制限      "
            L_DURATION="セッション時間"
            L_CACHE="キャッシュ効率  "
            ;;
        es)
            I18N_TITLE="Claude Code Statusline Configuración v7"
            I18N_TITLE_PAD="                     "
            I18N_HELP="↑↓ Mover | Space Alternar | L Diseño | ←→ Idioma | s Guardar | q Salir"
            I18N_PREVIEW="Vista previa:"
            I18N_ALL_HIDDEN="(Todos los elementos ocultos)"
            I18N_SAVED="Configuración guardada."
            I18N_NOT_SAVED="Cambios no guardados."
            I18N_SECTION_IDENTITY="[ IDENTIDAD ]"
            I18N_SECTION_CAPABILITY="[ CAPACIDAD ]"
            I18N_SECTION_HEALTH="[ SALUD ]"
            I18N_SECTION_ACTIVITY="[ ACTIVIDAD ]"
            I18N_LAYOUT_LABEL="Diseño"

            L_CWD="Directorio  "
            L_PROJECT="Proyecto    "
            L_BRANCH="Rama Git    "
            L_GIT_STATUS="Estado Git  "
            L_SESSION="Sesión      "
            L_WORKTREE="Worktree    "
            L_MODEL="Modelo      "
            L_AGENT="Agente      "
            L_BAR="Barra progr."
            L_PERCENT="Uso %       "
            L_TOKENS="Tokens      "
            L_COST="Costo       "
            L_VELOCITY="Velocidad   "
            L_RATE_5H="Lím. 5h     "
            L_RATE_7D="Lím. 7d     "
            L_DURATION="Duración    "
            L_CACHE="Caché       "
            ;;
        *)
            I18N_TITLE="Claude Code Statusline Settings v7"
            I18N_TITLE_PAD="                          "
            I18N_HELP="↑↓ Move | Space Toggle | L Layout | ←→ Language | s Save | q Quit"
            I18N_PREVIEW="Preview:"
            I18N_ALL_HIDDEN="(All items hidden)"
            I18N_SAVED="Settings saved."
            I18N_NOT_SAVED="Changes not saved."
            I18N_SECTION_IDENTITY="[ IDENTITY ]"
            I18N_SECTION_CAPABILITY="[ CAPABILITY ]"
            I18N_SECTION_HEALTH="[ HEALTH ]"
            I18N_SECTION_ACTIVITY="[ ACTIVITY ]"
            I18N_LAYOUT_LABEL="Layout"

            L_CWD="Directory   "
            L_PROJECT="Project     "
            L_BRANCH="Git Branch  "
            L_GIT_STATUS="Git Status   "
            L_SESSION="Session     "
            L_WORKTREE="Worktree    "
            L_MODEL="Model       "
            L_AGENT="Agent       "
            L_BAR="Progress Bar"
            L_PERCENT="Usage %     "
            L_TOKENS="Tokens      "
            L_COST="Cost        "
            L_VELOCITY="Velocity    "
            L_RATE_5H="5h Rate     "
            L_RATE_7D="7d Rate     "
            L_DURATION="Duration    "
            L_CACHE="Cache       "
            ;;
    esac
}

# ============================================
# Colors
# ============================================
RED='\033[31m'
GREEN='\033[32m'
CYAN='\033[36m'
YELLOW='\033[33m'
MAGENTA='\033[35m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'
REVERSE='\033[7m'

# ============================================
# Item definitions (ordered by section)
# ============================================
# Format: var_name:label_var:example_text
ITEMS=(
    # Identity
    "CLAUDE_SL_CWD:L_CWD:~/github/app    "
    "CLAUDE_SL_PROJECT:L_PROJECT:my-app         "
    "CLAUDE_SL_BRANCH:L_BRANCH:main            "
    "CLAUDE_SL_GIT_STATUS:L_GIT_STATUS:+2~5            "
    "CLAUDE_SL_SESSION:L_SESSION:feature-auth   "
    "CLAUDE_SL_WORKTREE:L_WORKTREE:wt:feat-x      "
    # Capability
    "CLAUDE_SL_MODEL:L_MODEL:[Opus 4.5]      "
    "CLAUDE_SL_AGENT:L_AGENT:reviewer          "
    # Health
    "CLAUDE_SL_BAR:L_BAR:[████░░░░░░]"
    "CLAUDE_SL_PERCENT:L_PERCENT:62%             "
    "CLAUDE_SL_TOKENS:L_TOKENS:(124K/200K)     "
    "CLAUDE_SL_COST:L_COST:\$3.47            "
    "CLAUDE_SL_VELOCITY:L_VELOCITY:+156/-23        "
    "CLAUDE_SL_RATE_5H:L_RATE_5H:5h:24%           "
    "CLAUDE_SL_RATE_7D:L_RATE_7D:7d:41%           "
    "CLAUDE_SL_DURATION:L_DURATION:12m             "
    "CLAUDE_SL_CACHE:L_CACHE:⚡96%           "
)

# Section break indices (insert section header before these item indices)
SECTION_HEADERS="0:6:8:14"
SECTION_LABELS_VAR="I18N_SECTION_IDENTITY:I18N_SECTION_CAPABILITY:I18N_SECTION_HEALTH:I18N_SECTION_ACTIVITY"

# ============================================
# Navigation state
# ============================================
current=0
total=${#ITEMS[@]}

# ============================================
# Toggle value
# ============================================
toggle_value() {
    local var_name="$1"
    local current_val
    current_val=$(resolve_var "$var_name")
    if [ "$current_val" = "1" ]; then
        eval "$var_name=0"
    else
        eval "$var_name=1"
    fi
}

# ============================================
# Layout cycling
# ============================================
cycle_layout() {
    case "$CLAUDE_SL_LAYOUT" in
        compact)   CLAUDE_SL_LAYOUT=detailed ;;
        detailed)  CLAUDE_SL_LAYOUT=multiline ;;
        multiline) CLAUDE_SL_LAYOUT=compact ;;
    esac
}

# ============================================
# Language cycling
# ============================================
cycle_lang_next() {
    local i
    for i in "${!LANGS[@]}"; do
        if [ "$CLAUDE_SL_LANG" = "${LANGS[$i]}" ]; then
            local next=$(( (i + 1) % ${#LANGS[@]} ))
            CLAUDE_SL_LANG="${LANGS[$next]}"
            set_i18n
            return
        fi
    done
    CLAUDE_SL_LANG="${LANGS[0]}"
    set_i18n
}

cycle_lang_prev() {
    local i
    for i in "${!LANGS[@]}"; do
        if [ "$CLAUDE_SL_LANG" = "${LANGS[$i]}" ]; then
            local prev=$(( (i - 1 + ${#LANGS[@]}) % ${#LANGS[@]} ))
            CLAUDE_SL_LANG="${LANGS[$prev]}"
            set_i18n
            return
        fi
    done
    CLAUDE_SL_LANG="${LANGS[0]}"
    set_i18n
}

# ============================================
# Save configuration
# ============================================
save_config() {
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" << EOF
# Claude Code Statusline v7 Configuration
# Layout mode: compact / detailed / multiline
# Toggle items are only written here when changed from layout defaults.
export CLAUDE_SL_LAYOUT=$CLAUDE_SL_LAYOUT

# Customized items (values differ from layout defaults)
EOF
    # Only write items that have been explicitly set (non-empty)
    for entry in "${LAYOUT_DEFAULTS[@]}"; do
        IFS=':' read -r var_name c d m <<< "$entry"
        local val="${!var_name}"
        if [ -n "$val" ]; then
            echo "export ${var_name}=${val}" >> "$CONFIG_FILE"
        fi
    done
    echo "" >> "$CONFIG_FILE"
    echo "# Language (en/ko/zh/ja/es)" >> "$CONFIG_FILE"
    echo "export CLAUDE_SL_LANG=$CLAUDE_SL_LANG" >> "$CONFIG_FILE"

    echo ""
    echo -e "${GREEN}${I18N_SAVED}${RESET}"
}

# ============================================
# Draw menu
# ============================================
draw_menu() {
    set_i18n

    # Layout indicator
    local layout_display
    case "$CLAUDE_SL_LAYOUT" in
        compact)   layout_display="${GREEN}compact${RESET}" ;;
        detailed)  layout_display="${YELLOW}detailed${RESET}" ;;
        multiline) layout_display="${CYAN}multiline${RESET}" ;;
    esac

    clear
    echo -e "${BOLD}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}║  ${I18N_TITLE}${I18N_TITLE_PAD}║${RESET}"
    echo -e "${BOLD}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${DIM}  ${I18N_HELP}${RESET}"
    echo -e "  ${I18N_LAYOUT_LABEL}: ${layout_display}"
    echo ""

    # Language bar — each language in its own script, active one highlighted
    local lang_bar="  "
    for i in "${!LANGS[@]}"; do
        if [ "$CLAUDE_SL_LANG" = "${LANGS[$i]}" ]; then
            lang_bar="${lang_bar}${BOLD}${CYAN}${LANG_DISPLAY[$i]}${RESET}  "
        else
            lang_bar="${lang_bar}${DIM}${LANG_DISPLAY[$i]}${RESET}  "
        fi
    done
    echo -e "$lang_bar"
    echo ""

    # Parse section headers
    local -a sec_indices sec_labels
    IFS=':' read -ra sec_indices <<< "$SECTION_HEADERS"
    IFS=':' read -ra sec_label_vars <<< "$SECTION_LABELS_VAR"

    local sec_idx=0
    local item_idx=0

    for i in "${!ITEMS[@]}"; do
        # Check if we need a section header
        if [ "$sec_idx" -lt "${#sec_indices[@]}" ] && [ "$i" -eq "${sec_indices[$sec_idx]}" ]; then
            local sec_label_var="${sec_label_vars[$sec_idx]}"
            local sec_label="${!sec_label_var}"
            echo -e "  ${DIM}${sec_label}${RESET}"
            ((sec_idx++))
        fi

        IFS=':' read -r var_name label_var example <<< "${ITEMS[$i]}"
        local label="${!label_var}"
        local val
        val=$(resolve_var "$var_name")

        # Checkbox
        local checkbox
        if [ "$val" = "1" ]; then
            checkbox="${GREEN}[✓]${RESET}"
        else
            checkbox="${RED}[ ]${RESET}"
        fi

        # Highlight current selection
        if [ "$i" -eq "$current" ]; then
            echo -e "  ${REVERSE} ${checkbox} ${label}${RESET} ${DIM}${example}${RESET}"
        else
            echo -e "   ${checkbox} ${label} ${DIM}${example}${RESET}"
        fi
    done

    echo ""
    echo -e "${DIM}──────────────────────────────────────────────────────────────────${RESET}"
    echo ""

    # Preview (chunk-based layout matching v7)
    echo -e "${CYAN}${I18N_PREVIEW}${RESET}"

    local show_cwd=$(resolve_var CLAUDE_SL_CWD)
    local show_project=$(resolve_var CLAUDE_SL_PROJECT)
    local show_branch=$(resolve_var CLAUDE_SL_BRANCH)
    local show_git_status=$(resolve_var CLAUDE_SL_GIT_STATUS)
    local show_session=$(resolve_var CLAUDE_SL_SESSION)
    local show_worktree=$(resolve_var CLAUDE_SL_WORKTREE)
    local show_model=$(resolve_var CLAUDE_SL_MODEL)
    local show_agent=$(resolve_var CLAUDE_SL_AGENT)
    local show_bar=$(resolve_var CLAUDE_SL_BAR)
    local show_percent=$(resolve_var CLAUDE_SL_PERCENT)
    local show_tokens=$(resolve_var CLAUDE_SL_TOKENS)
    local show_cost=$(resolve_var CLAUDE_SL_COST)
    local show_velocity=$(resolve_var CLAUDE_SL_VELOCITY)
    local show_rate_5h=$(resolve_var CLAUDE_SL_RATE_5H)
    local show_rate_7d=$(resolve_var CLAUDE_SL_RATE_7D)
    local show_duration=$(resolve_var CLAUDE_SL_DURATION)
    local show_cache=$(resolve_var CLAUDE_SL_CACHE)

    local SEP="${DIM}│${RESET}"
    local chunk_identity="" chunk_capability="" chunk_health="" chunk_activity=""

    # Identity chunk
    [ "$show_project" = "1" ] && chunk_identity="${chunk_identity}${BOLD}my-app${RESET} "
    [ "$show_cwd" = "1" ] && chunk_identity="${chunk_identity}${DIM}~/github/app${RESET} "
    [ "$show_branch" = "1" ] && chunk_identity="${chunk_identity}main"
    [ "$show_git_status" = "1" ] && chunk_identity="${chunk_identity} ${GREEN}+2${RESET}${YELLOW}~5${RESET}"
    [ "$show_branch" = "1" ] || [ "$show_git_status" = "1" ] && chunk_identity="${chunk_identity} "
    [ "$show_session" = "1" ] && chunk_identity="${chunk_identity}${CYAN}feature-auth${RESET} "
    [ "$show_worktree" = "1" ] && chunk_identity="${chunk_identity}${YELLOW}wt:feat-x${RESET} "
    chunk_identity="${chunk_identity% }"

    # Capability chunk
    [ "$show_model" = "1" ] && chunk_capability="${chunk_capability}${CYAN}[Opus 4.5${RESET}"
    [ "$show_agent" = "1" ] && chunk_capability="${chunk_capability}${MAGENTA}/reviewer${RESET}"
    [ "$show_model" = "1" ] && chunk_capability="${chunk_capability}${CYAN}]${RESET}"

    # Health chunk
    [ "$show_bar" = "1" ] && chunk_health="${chunk_health}${GREEN}[████░░░░░░]${RESET} "
    [ "$show_percent" = "1" ] && chunk_health="${chunk_health}${GREEN}62%${RESET} "
    [ "$show_tokens" = "1" ] && chunk_health="${chunk_health}${DIM}(124K/200K)${RESET} "
    [ "$show_cost" = "1" ] && chunk_health="${chunk_health}${MAGENTA}\$3.47${RESET} "
    chunk_health="${chunk_health% }"

    # Activity chunk
    [ "$show_velocity" = "1" ] && chunk_activity="${chunk_activity}${GREEN}+156${RESET}${RED}-23${RESET} "
    [ "$show_rate_5h" = "1" ] && chunk_activity="${chunk_activity}${DIM}5h:24%${RESET} "
    [ "$show_rate_7d" = "1" ] && chunk_activity="${chunk_activity}${DIM}7d:41%${RESET} "
    [ "$show_duration" = "1" ] && chunk_activity="${chunk_activity}${DIM}12m${RESET} "
    [ "$show_cache" = "1" ] && chunk_activity="${chunk_activity}${CYAN}⚡96%${RESET} "
    chunk_activity="${chunk_activity% }"

    # Join non-empty chunks with separator
    local preview=""
    for chunk in "$chunk_identity" "$chunk_capability" "$chunk_health" "$chunk_activity"; do
        if [ -n "$chunk" ]; then
            if [ -n "$preview" ]; then
                preview="${preview} ${SEP} ${chunk}"
            else
                preview="${chunk}"
            fi
        fi
    done

    if [ -z "$preview" ]; then
        echo -e "  ${DIM}${I18N_ALL_HIDDEN}${RESET}"
    else
        echo -e "  $preview"
    fi

    # Multiline second line preview
    if [ "$CLAUDE_SL_LAYOUT" = "multiline" ]; then
        local line2=""
        [ "$show_velocity" = "1" ] && line2="${line2}${GREEN}+156${RESET}${RED}-23${RESET}"
        [ "$show_rate_5h" = "1" ] && line2="${line2:+${line2} · }${DIM}5h:24%${RESET}"
        [ "$show_rate_7d" = "1" ] && line2="${line2:+${line2} }${DIM}7d:41%${RESET}"
        [ "$show_duration" = "1" ] && line2="${line2:+${line2} · }${DIM}12m${RESET}"
        [ "$show_cache" = "1" ] && line2="${line2:+${line2} · }${CYAN}⚡96%${RESET}"
        [ -n "$line2" ] && echo -e "  $line2"
    fi
}

# ============================================
# Key input
# ============================================
read_key() {
    local key
    IFS= read -rsn1 key

    if [[ $key == $'\x1b' ]]; then
        read -rsn2 key
        case "$key" in
            '[A') echo "UP" ;;
            '[B') echo "DOWN" ;;
            '[C') echo "LANG_NEXT" ;;
            '[D') echo "LANG_PREV" ;;
            *) echo "" ;;
        esac
    elif [[ $key == '' || $key == ' ' ]]; then
        echo "TOGGLE"
    elif [[ $key == 'l' || $key == 'L' || $key == 'ㅣ' ]]; then
        echo "LAYOUT"
    elif [[ $key == 's' || $key == 'S' || $key == 'ㄴ' ]]; then
        echo "SAVE"
    elif [[ $key == 'q' || $key == 'Q' || $key == 'ㅂ' ]]; then
        echo "QUIT"
    else
        echo ""
    fi
}

# ============================================
# Main loop
# ============================================
main() {
    load_config
    set_i18n

    # Get item var names for toggling
    ITEM_VARS=()
    for item in "${ITEMS[@]}"; do
        IFS=':' read -r var_name rest <<< "$item"
        ITEM_VARS+=("$var_name")
    done

    stty -echo
    trap 'stty echo; exit' INT TERM

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
            LAYOUT)
                cycle_layout
                ;;
            LANG_NEXT)
                cycle_lang_next
                ;;
            LANG_PREV)
                cycle_lang_prev
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
