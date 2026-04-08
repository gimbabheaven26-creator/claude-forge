#!/bin/bash
# genie-session-start.sh — X 세션 시작 시 지니 daily log에 기록
# SessionStart 훅: 가볍게 한 줄만 append

GENIE_MEMORY="$HOME/.openclaw/workspace/memory"
TODAY=$(date '+%Y-%m-%d')
LOG_FILE="$GENIE_MEMORY/$TODAY.md"
TIMESTAMP=$(date '+%H:%M')

mkdir -p "$GENIE_MEMORY"

if [ ! -f "$LOG_FILE" ]; then
  echo "# $TODAY Daily Log" > "$LOG_FILE"
  echo "" >> "$LOG_FILE"
  echo "## X 세션 로그 (자동)" >> "$LOG_FILE"
fi

BRANCH=$(cd ~/Projects/special-education-web && git branch --show-current 2>/dev/null || echo "unknown")
ENTRY="- [$TIMESTAMP] 🟢 X 세션 시작 (branch: $BRANCH)"

# 중복 방지: 마지막 행과 동일하면 skip (시각 제외하고 비교)
LAST_LINE=$(tail -1 "$LOG_FILE" 2>/dev/null || echo "")
LAST_CONTENT=$(echo "$LAST_LINE" | sed 's/\[[0-9][0-9]:[0-9][0-9]\]/[__]/g')
NEW_CONTENT=$(echo "$ENTRY" | sed 's/\[[0-9][0-9]:[0-9][0-9]\]/[__]/g')
if [ "$LAST_CONTENT" = "$NEW_CONTENT" ]; then
  exit 0
fi

printf '%s\n' "$ENTRY" >> "$LOG_FILE"

# channel.md 변경 감지 — 지니가 남긴 메시지가 있으면 표시
CHANNEL_FILE="$HOME/.openclaw/workspace/channel.md"
if [ -f "$CHANNEL_FILE" ]; then
  GENIE_MSG=$(grep -c '지니 → X' "$CHANNEL_FILE" 2>/dev/null || echo "0")
  if [ "$GENIE_MSG" -gt 0 ]; then
    echo ""
    echo "📬 지니가 channel.md에 메시지 ${GENIE_MSG}건 남김 — ~/.openclaw/workspace/channel.md 확인"
    echo ""
  fi
fi
