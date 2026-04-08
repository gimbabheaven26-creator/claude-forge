#!/bin/bash
# genie-session-stop.sh — X 세션 종료 시 지니 daily log에 기록
# Stop 훅: 마지막 커밋 + 세션 종료 기록

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

LAST_COMMIT=$(cd ~/Projects/special-education-web && git log --oneline -1 2>/dev/null || echo "no commits")
ENTRY="- [$TIMESTAMP] 🔴 X 세션 종료 (마지막: $LAST_COMMIT)"

# 중복 방지: 마지막 행과 동일하면 skip (시각 제외, 커밋 해시로 비교)
LAST_LINE=$(tail -1 "$LOG_FILE" 2>/dev/null || echo "")
LAST_HASH=$(echo "$LAST_LINE" | grep -oE '[0-9a-f]{7}' | head -1)
NEW_HASH=$(echo "$ENTRY" | grep -oE '[0-9a-f]{7}' | head -1)
if echo "$LAST_LINE" | grep -q '🔴' && [ "$LAST_HASH" = "$NEW_HASH" ] && [ -n "$NEW_HASH" ]; then
  exit 0
fi

printf '%s\n' "$ENTRY" >> "$LOG_FILE"
