# Claude Code Statusline v9 — Chunked Design

## Context

v8 provides 16 configurable items across 3 layout modes (compact/detailed/multiline) with a 5-band color gradient, session-based git caching, and an interactive TUI config tool. It works well but items blur together without visual grouping — hard to scan for specific info at a glance.

**Goal**: Redesign the statusline with visual chunking (pipe separators) to create clear scan zones, add git file status and rate limit countdowns, and introduce smart auto-hide for compact mode.

**Design principles**: Gestalt proximity (related items grouped), preattentive color (5-band gradient), progressive disclosure (compact hides non-essential items), signal-to-noise (auto-hide zero-value items).

---

## Files to Modify

- **`statusline.sh`** — Add git file status, rate limit countdown, pipe separators, smart auto-hide logic
- **`statusline-config.sh`** — Add `CLAUDE_SL_GIT_STATUS` item, rename sections to chunk names, update preview with `│` separators
- **`README.md`** — Update examples, item inventory, and layout previews

---

## Layout Design

### 4 Chunks

Chunks are separated by a dim pipe character `│` (U+2502, rendered with `\033[2m`). Each chunk groups related information for instant visual parsing.

| Chunk | Contains | Always visible? |
|-------|----------|----------------|
| **Identity** | project, branch, git status, session, worktree | Yes (items auto-hide individually) |
| **Capability** | model, agent | Yes |
| **Health** | bar, %, tokens, cost | Yes |
| **Activity** | velocity, rate limits, duration, cache | Smart auto-hide in compact |

### Compact (default — smart auto-hide)

```
my-app main +2~5 │ Opus 4.5 │ ██████████░░░░░ 62% │ $3.47
```

When rate limits exceed 70%, they auto-show:

```
my-app main │ Opus 4.5 │ ████████████░░░ 82% │ $5.20 5h:76%↓2h
```

### Detailed

```
my-app main +2~5 │ Opus 4.5 │ ██████████░░░░░ 62% (124K/200K) │ $3.47 +156-23 │ 5h:24%↓4h32m 7d:41%↓5d 12m
```

### Multiline

Line 1 uses `│` chunk separators. Line 2 uses `·` dot separators (visually distinct).

```
my-app main +2~5 │ Opus 4.5 │ ██████████░░░░░ 62% │ $3.47
+156-23 · 5h:24%↓4h32m 7d:41%↓5d · 12m
```

---

## Smart Auto-Hide Rules (Compact Mode)

Items not meeting thresholds are removed entirely (not dimmed).

| Item | Auto-show condition | Rationale |
|------|-------------------|-----------|
| Git file counts (`+N~N`) | Any staged or modified files | Need to know what's dirty |
| Rate limits | `used_percentage >= 70%` | Below 70% is safe, no action needed |
| Rate limit countdown | Same as rate limits | Only relevant when concerning |
| Velocity | Never in compact | Only in detailed/multiline |
| Duration | Never in compact | Only in detailed/multiline |
| Tokens | Never in compact | Only in detailed/multiline |
| Cache | Never in any mode (opt-in) | Same as v8 |
| Cost | Only when > $0 | Same as v8 |

---

## New Features

### Git File Status (staged/modified counts)

Displayed inline with branch in the Identity chunk. Color-coded with ANSI codes.

| Element | Example | Color | Logic |
|---------|---------|-------|-------|
| Staged files | `+3` | Green `\033[32m` | Ready to commit |
| Modified files | `~5` | Yellow `\033[33m` | Uncommitted changes |
| Clean | *(nothing)* | — | Zero noise |

Format: `branch +N~N` (space-separated). Staged and modified only appear when count > 0.

**Git caching**: Extended to include file counts. Cache file format: `BRANCH|STAGED|MODIFIED`. Same session-based `/tmp/claude-sl-git-{SESSION_ID}` with 5s TTL.

### Rate Limit Countdown

Shows time remaining until rate limit resets, using `rate_limits.*.resets_at` from JSON.

Format: `5h:24%↓4h32m` — percentage followed by countdown prefixed with `↓`.

Countdown formatting:
- `>24h` → `Xd` (days)
- `1-24h` → `Xh` or `XhYm`
- `<60m` → `Xm`

| Rate % | Example | Color |
|--------|---------|-------|
| <50% | `5h:24%↓4h32m` | Dim `\033[2m` |
| 50-75% | `5h:62%↓2h` | Yellow `\033[33m` |
| 76-90% | `5h:84%↓45m` | Yellow Bold `\033[1;33m` |
| >90% | `5h:94%↓12m` | Bright Red `\033[1;31m` |

---

## Color System

### Context usage — same 5-band gradient as v8

| Range | Color | Meaning |
|-------|-------|---------|
| 0-30% | Green `\033[32m` | Healthy |
| 31-60% | Bright Green `\033[1;32m` | Normal |
| 61-80% | Yellow `\033[33m` | Getting warm |
| 81-95% | Bright Red `\033[1;31m` | Danger |
| 96-100% | Blinking Red `\033[5;1;31m` | Critical |
| >100% | Bold Red + COMPRESSED | Context compressed |

### Item colors

| Item | Color | Rationale |
|------|-------|-----------|
| Project name | Bold `\033[1m` | Primary identity |
| CWD | Dim `\033[2m` | Low priority |
| Model | Cyan `\033[36m` | Identity, neutral |
| Agent | Magenta in model | Distinguish from model |
| Cost | Magenta `\033[35m` | Money = attention |
| Git staged | Green `\033[32m` | Convention: ready |
| Git modified | Yellow `\033[33m` | Convention: uncommitted |
| Velocity +lines | Green | Convention |
| Velocity -lines | Red | Convention |
| Duration | Dim | Low priority |
| Separator `│` | Dim `\033[2m` | Structure, not content |
| Rate limits | Color-coded by % | Same gradient logic |

---

## Item Inventory (18 items)

| # | Var | Chunk | C/D/M | Auto-hide |
|---|-----|-------|-------|-----------|
| 1 | `CLAUDE_SL_CWD` | Identity | 0/1/1 | if empty |
| 2 | `CLAUDE_SL_PROJECT` | Identity | 1/1/1 | if empty |
| 3 | `CLAUDE_SL_BRANCH` | Identity | 1/1/1 | if not git repo |
| 4 | `CLAUDE_SL_GIT_STATUS` | Identity | 1/1/1 | if no staged/modified |
| 5 | `CLAUDE_SL_SESSION` | Identity | 0/1/1 | if no session name |
| 6 | `CLAUDE_SL_WORKTREE` | Identity | 0/1/1 | if not in worktree |
| 7 | `CLAUDE_SL_MODEL` | Capability | 1/1/1 | never |
| 8 | `CLAUDE_SL_AGENT` | Capability | 0/1/1 | if no agent |
| 9 | `CLAUDE_SL_BAR` | Health | 1/1/1 | never |
| 10 | `CLAUDE_SL_PERCENT` | Health | 1/1/1 | never |
| 11 | `CLAUDE_SL_TOKENS` | Health | 0/1/1 | never |
| 12 | `CLAUDE_SL_COST` | Health | 1/1/1 | if zero |
| 13 | `CLAUDE_SL_VELOCITY` | Activity | 0/1/1 | if both zero |
| 14 | `CLAUDE_SL_RATE_5H` | Activity | 0/1/1 | smart (≥70% in compact) |
| 15 | `CLAUDE_SL_RATE_7D` | Activity | 0/1/1 | smart (≥70% in compact) |
| 16 | `CLAUDE_SL_DURATION` | Activity | 0/1/1 | never |
| 17 | `CLAUDE_SL_CACHE` | Activity | 0/0/0 | if empty |
| 18 | `CLAUDE_SL_LAYOUT` | — | compact | — |

New vs v8: `CLAUDE_SL_GIT_STATUS` (#4) added.

---

## Special States

| State | Example |
|-------|---------|
| Compressed (>100%) | `my-app main │ Opus 4.5 │ ████████████████ COMPRESSED (180K/200K) │ $5.20` |
| Agent mode | `my-app main │ Opus 4.5/reviewer │ ██████░░░░░░░░ 45% │ $1.25` |
| Worktree | `my-app main wt:feat-x │ Opus 4.5 │ ██████░░░░░░░░ 45% │ $1.25` |
| Clean git | `my-app main │ Opus 4.5 │ ██████████░░░░░ 62% │ $3.47` |
| Not a git repo | `my-app │ Opus 4.5 │ ██████████░░░░░ 62% │ $3.47` |
| Rate limit absent | `my-app main +2~5 │ Opus 4.5 │ ██████████░░░░░ 62% │ $3.47` |
| NO_COLOR | `my-app main +2~5 | Opus 4.5 | ██████████░░░░░ 62% | $3.47` |

---

## Config Tool Changes

- Add `CLAUDE_SL_GIT_STATUS` item in Identity section (after Branch)
- Section headers renamed: Identity / Capability / Health / Activity (matching chunk names)
- Preview uses `│` separators between chunks
- Line 2 of multiline preview uses `·` separators
- Smart auto-hide indicator: show which items auto-hide in compact mode

---

## Backwards Compatibility

- v8 config files work seamlessly — missing `CLAUDE_SL_GIT_STATUS` defaults to ON in all modes
- Existing toggle values preserved
- Rate limit countdown is additive — `CLAUDE_SL_RATE_5H`/`CLAUDE_SL_RATE_7D` still control visibility
- Git file counts are gated by `CLAUDE_SL_GIT_STATUS` (requires branch to be visible too)

---

## Implementation Steps

### Step 1: Update git caching in `statusline.sh`

Extend `get_git_info()` to also capture staged and modified file counts:
- `git diff --cached --numstat | wc -l` for staged
- `git diff --numstat | wc -l` for modified
- Cache format: `BRANCH|STAGED|MODIFIED`
- Parse with `IFS='|'` read

### Step 2: Add rate limit countdown formatting

New function `format_countdown()`:
- Takes `resets_at` (Unix epoch) and current time
- Returns formatted string like `↓4h32m`, `↓2h`, `↓45m`, `↓12m`
- Handle edge cases: already reset, >7 days, null

### Step 3: Implement smart auto-hide logic in compact mode

For compact layout only:
- Rate limits: show when `used_percentage >= 70` **unless** the user has explicitly set `CLAUDE_SL_RATE_5H=0` or `CLAUDE_SL_RATE_7D=0` in their config
- Git status: show when staged > 0 or modified > 0 (gated by `CLAUDE_SL_GIT_STATUS`)
- Smart auto-hide overrides layout defaults but **never** overrides explicit user config

### Step 4: Restructure output assembly with chunk separators

Replace space-only assembly with 4 chunks:
- Build each chunk's content string
- Join with ` ${DIM}│${RESET} ` separator
- Skip empty chunks (don't show consecutive separators)
- Multiline: line 1 gets chunks 1-3, line 2 gets chunk 4 with `·` separators

### Step 5: Add `CLAUDE_SL_GIT_STATUS` to config tool

- Add to `LAYOUT_DEFAULTS` and `ITEMS` arrays
- Place after Branch in Identity section
- Default label: "Git Status" / "Git 상태"
- Example text: `+2~5`

### Step 6: Update README

- New layout examples with `│` separators
- Updated item inventory (18 items)
- Git status rendering section
- Rate limit countdown section
- Updated version history

---

## Verification

1. Test git file counts with mock dirty/clean repos
2. Test rate limit countdown with various `resets_at` values
3. Test smart auto-hide: rate limits appear at ≥70%, disappear below
4. Test pipe separators in all 3 layout modes
5. Test special states: compressed, agent, worktree, clean git, non-git
6. Test NO_COLOR: all ANSI suppressed, `│` shows as plain `|`
7. Test backwards compatibility: load v8 config, verify defaults
8. Test performance: git caching keeps execution under 50ms on cache hit
9. Test config tool: toggle new item, preview with separators, save
