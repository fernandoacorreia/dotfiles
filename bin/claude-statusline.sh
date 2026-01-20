#!/bin/bash
# Claude Code statusline with powerline style and git status
# Uses nerd fonts and ANSI colors for rainbow effect
# Based on https://github.com/pchalasani/claude-code-tools/blob/main/scripts/statusline.sh

input=$(cat)

# Validate JSON and extract fields safely
if ! echo "$input" | jq -e . >/dev/null 2>&1; then
    echo "⚠ invalid input"
    exit 0
fi

cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty' 2>/dev/null)
dir_name=$(basename "$cwd" 2>/dev/null || echo "?")

# Extract model - could be string or object with .id field
model=$(echo "$input" | jq -r '
  if .model | type == "object" then .model.id // .model.name // "claude"
  elif .model | type == "string" then .model
  else "claude"
  end
' 2>/dev/null)
[ -z "$model" ] || [ "$model" = "null" ] && model="claude"
# Clean up model name - remove claude- prefix and date suffix, truncate
model=$(echo "$model" | sed 's/claude-//' | sed 's/-[0-9]*$//' | cut -c1-10)

# Set model background color based on model name
shopt -s nocasematch
if [[ "$model" == *opus* ]]; then
    model_bg=$'\033[45m'      # BG_MAGENTA
    model_fg=$'\033[35m'      # FG_MAGENTA
else
    model_bg=$'\033[44m'      # BG_BLUE
    model_fg=$'\033[34m'      # FG_BLUE
fi
shopt -u nocasematch

# ANSI color codes (using $'...' for proper escape handling)
RESET=$'\033[0m'
BG_BLUE=$'\033[44m'
FG_BLUE=$'\033[34m'
BG_GREEN=$'\033[42m'
FG_GREEN=$'\033[32m'
BG_YELLOW=$'\033[43m'
FG_YELLOW=$'\033[33m'
BG_CYAN=$'\033[46m'
FG_CYAN=$'\033[36m'
BG_RED=$'\033[41m'
FG_RED=$'\033[31m'
BG_ORANGE=$'\033[48;5;208m'
FG_ORANGE=$'\033[38;5;208m'
BG_MAGENTA=$'\033[45m'
FG_MAGENTA=$'\033[35m'
BG_LTGREEN=$'\033[48;5;114m'
FG_LTGREEN=$'\033[38;5;114m'
BG_BLACK=$'\033[40m'
FG_BLACK=$'\033[30m'
FG_WHITE=$'\033[97m'
BOLD=$'\033[1m'
BLINK=$'\033[5m'

# Powerline separator
SEP=''
# Separator space with black background
SPACER="${RESET}${BG_BLACK} ${RESET}"

# Git info - check status to determine git branch background color
git_segment=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
    [ -z "$branch" ] && branch=$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null)

    # Get status counts
    status=$(git -C "$cwd" status --porcelain 2>/dev/null)
    staged=$(echo "$status" | grep -c '^[MADRC]')
    modified=$(echo "$status" | grep -c '^.[MD]')
    untracked=$(echo "$status" | grep -c '^??')

    # Ahead/behind
    ahead=$(git -C "$cwd" rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
    behind=$(git -C "$cwd" rev-list --count HEAD..@{u} 2>/dev/null || echo 0)

    # Build compact git status (starship style)
    git_status=""
    [ "$ahead" -gt 0 ] 2>/dev/null && git_status+="⇡$ahead"
    [ "$behind" -gt 0 ] 2>/dev/null && git_status+="⇣$behind"
    [ "$staged" -gt 0 ] && git_status+="+$staged"
    [ "$modified" -gt 0 ] && git_status+="!$modified"
    [ "$untracked" -gt 0 ] && git_status+="?$untracked"

    # Choose color - yellow for dirty branch, light blue for clean branch
    BG_LTBLUE=$'\033[48;5;75m'
    FG_LTBLUE=$'\033[38;5;75m'
    if [ -n "$git_status" ]; then
        git_bg=$BG_YELLOW
        git_fg=$FG_YELLOW
        git_content="  $branch $git_status "
    else
        git_bg=$BG_LTBLUE
        git_fg=$FG_LTBLUE
        git_content="  $branch "
    fi
    git_segment="${FG_BLACK}${git_bg}${SEP}${FG_BLACK}${git_content}"
    next_fg=$git_fg
    next_bg=$BG_CYAN
else
    next_fg=$FG_BLUE
    next_bg=$BG_CYAN
fi

# Context progress bar (uses built-in used_percentage from Claude Code 2.1.6+)
context_segment=""
pct_raw=$(echo "$input" | jq -r '.context_window.used_percentage // empty' 2>/dev/null)
pct=$(printf "%.0f" "$pct_raw" 2>/dev/null)
if [ -n "$pct" ] && [ "$pct" != "null" ] && [ "$pct" -ge 0 ] 2>/dev/null; then
    # Build progress bar (10 chars wide)
    bar_width=10
    filled=$((pct * bar_width / 100))
    [ "$filled" -gt "$bar_width" ] && filled=$bar_width
    empty=$((bar_width - filled))

    # Colors for filled portion based on level
    if [ "$pct" -gt 95 ]; then
        fill_color=$'\033[38;5;196m'  # bright red
        bar_blink=$BLINK
    elif [ "$pct" -gt 85 ]; then
        fill_color=$'\033[38;5;208m'  # orange
        bar_blink=""
    elif [ "$pct" -gt 70 ]; then
        fill_color=$'\033[38;5;220m'  # yellow
        bar_blink=""
    else
        fill_color=$'\033[38;5;29m'   # forest green
        bar_blink=""
    fi
    empty_color=$'\033[38;5;240m'     # dark gray

    # Build the bar string
    filled_bar=""
    empty_bar=""
    for ((i=0; i<filled; i++)); do filled_bar+="█"; done
    for ((i=0; i<empty; i++)); do empty_bar+="░"; done

    # Segment with dark background
    BG_DARK=$'\033[48;5;236m'
    FG_DARK=$'\033[38;5;236m'
    context_segment="${FG_BLACK}${BG_DARK}${SEP}${bar_blink}${fill_color}${filled_bar}${RESET}${BG_DARK}${empty_color}${empty_bar}${FG_WHITE} ${pct}%${RESET}"
    next_fg=$FG_DARK
fi

# Fallback if no context data
if [ -z "$context_segment" ]; then
    BG_DARK=$'\033[48;5;236m'
    FG_DARK=$'\033[38;5;236m'
    context_segment="${FG_BLACK}${BG_DARK}${SEP}${FG_WHITE} --%${RESET}"
    next_fg=$FG_DARK
fi

# Build output with powerline style
# Model: black on green (clean) or yellow (dirty)
echo -n "${model_bg}${FG_WHITE}${BOLD} $model ${RESET}"
echo -n "${model_fg}${SEP}${SPACER}"
echo -n "${FG_LTGREEN}${BG_LTGREEN}${SEP}${FG_BLACK}  $dir_name ${RESET}"
echo -n "${FG_LTGREEN}${SEP}${SPACER}"
echo -n "$git_segment"
[ -n "$git_segment" ] && echo -n "${git_fg}${SEP}${SPACER}"
echo -n "$context_segment"
echo -n "${next_fg}${SEP}${RESET}"
