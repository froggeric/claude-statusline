# Claude Code Statusline v7

Custom statusline for the Claude Code CLI, applying human perception principles (preattentive color, visual hierarchy, chunking) to surface the most actionable information at a glance.

Based on [the original gist by inchan](https://gist.github.com/inchan/b7e63d8c1cb29c83960944d833422d04). See the [official Claude Code statusline documentation](https://code.claude.com/docs/en/statusline) for setup instructions and the JSON schema reference.

## Preview

### Compact (default)

```
my-app main +2~5 │ [Opus 4.5] │ ██████░░░░ 62% $3.47 │ 5h:24%
```

### Detailed

```
my-app ~/github/app main +2~5 feature-auth wt:feat-x │ [Opus 4.5/reviewer] │ ██████░░░░ 62% (124K/200K) $3.47 │ +156/-23 5h:24%↓2h15m 7d:41% 12m
```

### Multi-line

```
my-app main +2~5 feature-auth [Opus 4.5] │ ██████░░░░ 62% (124K/200K) $3.47 │ +156/-23 · 5h:24%↓2h15m 7d:41% · 12m
```

### Special states

| State | Example |
|-------|---------|
| Context compressed (>100%) | `my-app main │ [Opus 4.5] │ ████████████████ COMPRESSED (180K/200K) $5.20` |
| Agent mode | `my-app main │ [Opus 4.5/reviewer] │ ██████░░░░ 45% $1.25` |
| Worktree | `my-app main wt:feature-x │ [Opus 4.5] │ ██████░░░░ 45% $1.25` |

## Chunk Layout

The statusline uses `│` pipe separators to divide information into 4 visual chunks:

| Chunk | Contents | Purpose |
|-------|----------|---------|
| **Identity** | project, directory, branch, git status, session, worktree | Where am I? |
| **Capability** | model, agent | Who am I? |
| **Health** | progress bar, usage %, tokens, cost | How much capacity left? |
| **Activity** | velocity, rate limits, duration, cache | What's happening? |

## Item Inventory (17 configurable items)

### Identity

| # | Env Var | Default (C/D/M) | Auto-hide |
|---|---------|---------|-----------|
| 1 | `CLAUDE_SL_CWD` | 0/1/1 | if empty |
| 2 | `CLAUDE_SL_PROJECT` | 1/1/1 | if empty |
| 3 | `CLAUDE_SL_BRANCH` | 1/1/1 | if not git repo |
| 4 | `CLAUDE_SL_GIT_STATUS` | 1/1/1 | if no staged/modified files |
| 5 | `CLAUDE_SL_SESSION` | 0/1/1 | if no session name |
| 6 | `CLAUDE_SL_WORKTREE` | 0/1/1 | if not in worktree |

### Capability

| # | Env Var | Default (C/D/M) | Auto-hide |
|---|---------|---------|-----------|
| 7 | `CLAUDE_SL_MODEL` | 1/1/1 | never |
| 8 | `CLAUDE_SL_AGENT` | 0/1/1 | if no agent |

### Health

| # | Env Var | Default (C/D/M) | Auto-hide |
|---|---------|---------|-----------|
| 9 | `CLAUDE_SL_BAR` | 1/1/1 | never |
| 10 | `CLAUDE_SL_PERCENT` | 1/1/1 | never |
| 11 | `CLAUDE_SL_TOKENS` | 0/1/1 | never |
| 12 | `CLAUDE_SL_COST` | 1/1/1 | if zero |

### Activity

| # | Env Var | Default (C/D/M) | Auto-hide |
|---|---------|---------|-----------|
| 13 | `CLAUDE_SL_VELOCITY` | 0/1/1 | if both zero |
| 14 | `CLAUDE_SL_RATE_5H` | 0/1/1 | if absent (Pro/Max only); smart auto-show ≥70% in compact |
| 15 | `CLAUDE_SL_RATE_7D` | 0/1/1 | if absent (Pro/Max only); smart auto-show ≥70% in compact |
| 16 | `CLAUDE_SL_DURATION` | 0/1/1 | never |
| 17 | `CLAUDE_SL_CACHE` | 0/0/0 | if empty |

Defaults: **C**ompact / **D**etailed / **M**ultiline

## Smart Auto-Hide

In compact mode, rate limits auto-show when usage reaches ≥70%, even if toggled off. This prevents surprises when approaching limits. Explicit user settings always take precedence over auto-hide rules.

### Git File Status

Shows staged (`+N`, green) and modified (`~N`, yellow) file counts inline with the branch name. Cached per session with a 5-second TTL.

### Rate Limit Countdown

When `resets_at` is available from the API, rate limits show a countdown: `5h:87%↓2h15m`. The `↓` prefix indicates time until reset.

## Color System

### Context usage (5-band gradient)

| Range | Color | Meaning |
|-------|-------|---------|
| 0-30% | Green | Healthy |
| 31-60% | Bright Green | Normal |
| 61-80% | Yellow | Getting warm |
| 81-95% | Bright Red | Danger |
| 96-100% | Blinking Red | Critical |
| >100% | Bold Red + "COMPRESSED" | Context compressed |

### Item colors

| Item | Color | Rationale |
|------|-------|-----------|
| Project name | Bold | Primary identity |
| CWD | Dim | Low priority |
| Model | Cyan | Identity, neutral |
| Agent | Magenta (in model) | Distinguish from model |
| Cost | Magenta | Money = attention |
| Git staged (+N) | Green | Clean convention |
| Git modified (~N) | Yellow | Attention needed |
| Velocity +lines | Green | Convention |
| Velocity -lines | Red | Convention |
| Duration | Dim | Low priority |
| Rate limits | Color-coded by % | Same gradient logic |

## Installation

### Quick install

```bash
# Clone or download
git clone https://github.com/user/claude-statusline ~/.claude/statusline

# Make executable
chmod +x ~/.claude/statusline/statusline.sh ~/.claude/statusline/statusline-config.sh
```

### Claude Code settings

Add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline/statusline.sh",
    "refreshInterval": 1000
  }
}
```

Or use `/statusline` inside Claude Code. See the [official statusline documentation](https://code.claude.com/docs/en/statusline) for full details.

## File structure

```
~/.claude/statusline/
├── statusline.sh          # Main statusline script
├── statusline-config.sh   # Interactive TUI config tool
└── statusline.env         # Config file (auto-generated)
```

## Configuration

### Interactive (recommended)

```bash
~/.claude/statusline/statusline-config.sh
```

| Key | Action |
|-----|--------|
| `↑` / `↓` | Move between items |
| `Space` / `Enter` | Toggle on/off |
| `L` | Cycle layout (compact → detailed → multiline) |
| `s` | Save |
| `q` | Quit (no save) |

Supports English and Korean (toggle with language option). Korean keyboard layout: `ㄴ` = save, `ㅂ` = quit, `ㅣ` = layout cycle.

### Manual

Edit `~/.claude/statusline/statusline.env`:

```bash
# Layout mode: compact / detailed / multiline
export CLAUDE_SL_LAYOUT=compact

# Only write overrides — items not listed here use layout defaults
export CLAUDE_SL_TOKENS=1
export CLAUDE_SL_COST=0

# Language (ko/en)
export CLAUDE_SL_LANG=en
```

### Per-session override

```bash
CLAUDE_SL_LAYOUT=detailed CLAUDE_SL_RATE_5H=1 claude
```

## Migration from v6

Old config files work seamlessly — existing toggle values are preserved. New v7 items (git status, rate limit countdown, chunk separators) adopt layout-mode defaults automatically. The unreliable "time remaining estimate" has been removed.

## Other options

| Variable | Description |
|----------|-------------|
| `NO_COLOR=1` | Disable all colors, `│` becomes `\|` |
| `CLAUDE_STATUSLINE_DEBUG=1` | Debug mode (saves JSON to `/tmp/claude_statusline_debug.json`) |

## Dependencies

- `jq` — JSON parsing
- `awk` — Cost formatting
- `git` — Branch detection (optional)

Standard on macOS and most Linux distributions.

## Version history

| Version | Changes |
|---------|---------|
| v3 | Cost, cache, burn rate |
| v4 | Token calculation fix (current_usage) |
| v5 | M suffix, NO_COLOR standard |
| v6 | Per-item toggles, interactive config tool |
| v7 | Chunked layout with `│` separators, git file status (staged/modified), rate limit countdown (`↓XhYm`), smart auto-hide for rate limits (≥70%), 4 visual groups (Identity/Capability/Health/Activity), layout modes, 5-band color gradient, Korean i18n |

## License

MIT
