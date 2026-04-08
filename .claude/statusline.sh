#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
FIVE_H=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
FIVE_H_RESET=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
WEEK=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
WEEK_RESET=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

CYAN='\033[36m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; RESET='\033[0m'

# Context color
if [ "$PCT" -ge 90 ]; then CTX_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then CTX_COLOR="$YELLOW"
else CTX_COLOR="$GREEN"; fi

# Format time until reset
format_remaining() {
  local reset_at=$1
  local now=$(date +%s)
  local diff=$((reset_at - now))
  [ "$diff" -le 0 ] && echo "now" && return
  local hours=$((diff / 3600))
  local mins=$(((diff % 3600) / 60))
  if [ "$hours" -gt 0 ]; then
    echo "${hours}h${mins}m"
  else
    echo "${mins}m"
  fi
}

# Git branch
BRANCH=""
git rev-parse --git-dir > /dev/null 2>&1 && BRANCH=" | 🌿 $(git branch --show-current 2>/dev/null)"

# Rate limits with reset countdown
LIMITS=""
if [ -n "$FIVE_H" ]; then
  FIVE_H_FMT=$(printf '%.0f' "$FIVE_H")
  FIVE_H_REMAINING=""
  [ -n "$FIVE_H_RESET" ] && FIVE_H_REMAINING=" $(format_remaining "$FIVE_H_RESET")"
  LIMITS=" | 5h: ${FIVE_H_FMT}%${FIVE_H_REMAINING}"
fi
if [ -n "$WEEK" ]; then
  WEEK_FMT=$(printf '%.0f' "$WEEK")
  WEEK_REMAINING=""
  [ -n "$WEEK_RESET" ] && WEEK_REMAINING=" $(format_remaining "$WEEK_RESET")"
  LIMITS="${LIMITS} 7d: ${WEEK_FMT}%${WEEK_REMAINING}"
fi

# Line 1: model, dir, git
echo -e "${CYAN}[$MODEL]${RESET} 📁 ${DIR##*/}$BRANCH"
# Line 2: context %, rate limits with reset time
echo -e "${CTX_COLOR}ctx: ${PCT}%${RESET}${LIMITS}"
