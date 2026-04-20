# Claude Code Statusline v6

Claude Code CLI 하단에 표시되는 커스텀 상태줄입니다.

## 미리보기

```
[Opus 4.5] [████░░░░░░] 40% (81K/200K) $1.25 ⚡96% ~7m
```

| 항목 | 설명 |
|------|------|
| `[Opus 4.5]` | 현재 모델명 |
| `[████░░░░░░]` | 컨텍스트 사용률 바 (10칸) |
| `40%` | 컨텍스트 사용률 퍼센트 |
| `(81K/200K)` | 사용 토큰 / 전체 컨텍스트 |
| `$1.25` | 누적 비용 |
| `⚡96%` | 캐시 히트율 |
| `~7m` | 예상 남은 시간 |

## 설치

### 빠른 설치

```bash
# 파일 다운로드
curl -fsSL https://gist.githubusercontent.com/inchan/b7e63d8c1cb29c83960944d833422d04/raw/statusline.sh -o ~/.claude/statusline/statusline.sh
curl -fsSL https://gist.githubusercontent.com/inchan/b7e63d8c1cb29c83960944d833422d04/raw/statusline-config.sh -o ~/.claude/statusline/statusline-config.sh

# 실행 권한 부여
chmod +x ~/.claude/statusline/statusline.sh ~/.claude/statusline/statusline-config.sh
```

### Claude Code 설정

`~/.claude/settings.json`에 추가:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline/statusline.sh"
  }
}
```

또는 Claude Code 내에서 `/statusline` 명령어로 설정.

## 파일 구조

```
~/.claude/statusline/
├── statusline.sh          # 메인 상태줄 스크립트
├── statusline-config.sh   # 인터랙티브 설정 도구
└── statusline.env         # 설정 파일 (자동 생성)
```

## 설정 방법

### 1. 인터랙티브 설정 (권장)

```bash
~/.claude/statusline/statusline-config.sh
```

| 키 | 동작 |
|----|------|
| `↑` / `↓` | 항목 이동 |
| `Space` / `Enter` | 켜기/끄기 토글 |
| `s` | 저장 |
| `q` | 나가기 (저장 안 함) |

### 2. 환경변수 직접 설정

`~/.claude/statusline/statusline.env` 파일을 직접 편집:

```bash
# 1=표시, 0=숨김
export CLAUDE_SL_MODEL=1      # 모델명
export CLAUDE_SL_BAR=1        # 진행률 바
export CLAUDE_SL_PERCENT=1    # 사용률 %
export CLAUDE_SL_TOKENS=1     # 토큰 수
export CLAUDE_SL_COST=1       # 비용
export CLAUDE_SL_CACHE=1      # 캐시 효율
export CLAUDE_SL_TIME=1       # 남은 시간
```

### 3. 임시 설정 (세션 단위)

```bash
CLAUDE_SL_MODEL=0 CLAUDE_SL_TIME=0 claude
```

## 설정 예시

### 미니멀 (퍼센트 + 토큰만)

```bash
export CLAUDE_SL_MODEL=0
export CLAUDE_SL_BAR=0
export CLAUDE_SL_COST=0
export CLAUDE_SL_CACHE=0
export CLAUDE_SL_TIME=0
```

결과: `40% (81K/200K)`

### 비용 중심

```bash
export CLAUDE_SL_BAR=0
export CLAUDE_SL_PERCENT=0
export CLAUDE_SL_CACHE=0
export CLAUDE_SL_TIME=0
```

결과: `[Opus 4.5] (81K/200K) $1.25`

## 기타 옵션

| 환경변수 | 설명 |
|----------|------|
| `NO_COLOR=1` | 색상 비활성화 |
| `CLAUDE_STATUSLINE_DEBUG=1` | 디버그 모드 (`/tmp/claude_statusline_debug.json` 생성) |

## 색상 규칙

| 사용률 | 색상 |
|--------|------|
| 0-50% | 🟢 초록 |
| 51-80% | 🟡 노랑 |
| 81-100% | 🔴 빨강 |
| 100%+ | 🔴 빨강 볼드 + "압축됨" |

## 의존성

- `jq` - JSON 파싱
- `awk` - 숫자 포맷팅

macOS/Linux 대부분의 환경에서 기본 설치되어 있습니다.

## 토큰 계산 방식

```
컨텍스트 사용량 = input_tokens + cache_read_input_tokens + cache_creation_input_tokens
```

- `current_usage` 기준 (실제 컨텍스트 점유율)
- `total_*` 값은 누적 비용 계산용 (별도)

## 버전 히스토리

| 버전 | 변경 사항 |
|------|----------|
| v3 | 비용, 캐시, 소진률 추가 |
| v4 | 토큰 계산 버그 수정 (current_usage 기준) |
| v5 | M 단위 지원, NO_COLOR 표준 |
| v6 | 개별 항목 on/off 토글, 인터랙티브 설정 도구 |

## 라이선스

MIT
