# Claude Code Statusline v8

Custom statusline for the Claude Code CLI, applying human perception principles (preattentive color, visual hierarchy, chunking) to surface the most actionable information at a glance.

## Preview

### Compact (default)

```
my-app main [Opus 4.5] ██████████░░░░░ 62% $3.47
```

### Detailed

```
my-app main feature-auth wt:feat-x [Opus 4.5/reviewer] ██████████░░░░░ 62% (124K/200K) $3.47 +156/-23 5h:24% 7d:41% 12m
```

### Multi-line

```
my-app main feature-auth [Opus 4.5] ██████████░░░░░ 62% (124K/200K) $3.47
+156/-23 · 5h:24% 7d:41% · 12m
```

### Special states

| State | Example |
|-------|---------|
| Context compressed (>100%) | `my-app main [Opus 4.5] ████████████████ COMPRESSED (180K/200K) $5.20` |
| Agent mode | `my-app main [Opus 4.5/reviewer] ██████░░░░░░░░ 45% $1.25` |
| Worktree | `my-app main wt:feature-x [Opus 4.5] ██████░░░░░░░░ 45% $1.25` |

## Item Inventory (16 configurable items)

### Identity

| # | Env Var | Default (C/D/M) | Auto-hide |
|---|---------|---------|-----------|
| 1 | `CLAUDE_SL_CWD` | 0/1/1 | if empty |
| 2 | `CLAUDE_SL_PROJECT` | 1/1/1 | if empty |
| 3 | `CLAUDE_SL_BRANCH` | 1/1/1 | if not git repo |
| 4 | `CLAUDE_SL_SESSION` | 0/1/1 | if no session name |
| 5 | `CLAUDE_SL_WORKTREE` | 0/1/1 | if not in worktree |

### Capability

| # | Env Var | Default (C/D/M) | Auto-hide |
|---|---------|---------|-----------|
| 6 | `CLAUDE_SL_MODEL` | 1/1/1 | never |
| 7 | `CLAUDE_SL_AGENT` | 0/1/1 | if no agent |

### Health

| # | Env Var | Default (C/D/M) | Auto-hide |
|---|---------|---------|-----------|
| 8 | `CLAUDE_SL_BAR` | 1/1/1 | never |
| 9 | `CLAUDE_SL_PERCENT` | 1/1/1 | never |
| 10 | `CLAUDE_SL_TOKENS` | 0/1/1 | never |
| 11 | `CLAUDE_SL_COST` | 1/1/1 | if zero |
| 12 | `CLAUDE_SL_VELOCITY` | 0/1/1 | if both zero |
| 13 | `CLAUDE_SL_RATE_5H` | 0/1/1 | if absent (Pro/Max only) |
| 14 | `CLAUDE_SL_RATE_7D` | 0/1/1 | if absent (Pro/Max only) |
| 15 | `CLAUDE_SL_DURATION` | 0/1/1 | never |
| 16 | `CLAUDE_SL_CACHE` | 0/0/0 | if empty |

Defaults: **C**ompact / **D**etailed / **M**ultiline

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

Or use `/statusline` inside Claude Code.

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

## Migration from v7

Old config files work seamlessly — existing toggle values are preserved. New v8 items (branch, session, worktree, agent, velocity, rate limits, duration) adopt layout-mode defaults automatically. The unreliable "time remaining estimate" has been removed.

## Other options

| Variable | Description |
|----------|-------------|
| `NO_COLOR=1` | Disable all colors |
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
| v7 | Project name, working directory |
| v8 | Layout modes, git branch, rate limits, code velocity, session duration, agent/worktree support, 5-band color gradient, auto-hiding, Korean i18n |

## License

MIT
