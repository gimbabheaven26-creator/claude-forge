#!/bin/bash
# genie-commit-sync.sh — X 커밋 시 지니 daily log에 자동 append
# PostToolUse Bash 훅: git commit 감지 → 지니 워크스페이스에 기록

set -euo pipefail

GENIE_MEMORY="$HOME/.openclaw/workspace/memory"
TODAY=$(date '+%Y-%m-%d')
LOG_FILE="$GENIE_MEMORY/$TODAY.md"
TIMESTAMP=$(date '+%H:%M')

# stdin에서 tool_input 읽기
INPUT=$(cat)

# git commit 명령인지 확인
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)
echo "$COMMAND" | grep -q 'git commit' || exit 0

# 커밋 메시지 추출 (가장 최근 커밋)
COMMIT_MSG=$(cd ~/Projects/special-education-web && git log --oneline -1 2>/dev/null || echo "unknown")

# 메모리 디렉토리 확인
mkdir -p "$GENIE_MEMORY"

# daily log 파일이 없으면 헤더 생성
if [ ! -f "$LOG_FILE" ]; then
  echo "# $TODAY Daily Log" > "$LOG_FILE"
  echo "" >> "$LOG_FILE"
  echo "## X 커밋 로그 (자동)" >> "$LOG_FILE"
fi

# 커밋 기록 append (printf로 특수문자 안전 처리)
printf '%s\n' "- [$TIMESTAMP] $COMMIT_MSG" >> "$LOG_FILE"

# channel.md 변경 감지 (가벼운 1줄 체크)
CHANNEL_FILE="$HOME/.openclaw/workspace/channel.md"
if [ -f "$CHANNEL_FILE" ]; then
  LAST_GENIE=$(grep '지니 → X' "$CHANNEL_FILE" 2>/dev/null | tail -1)
  if [ -n "$LAST_GENIE" ]; then
    # 마지막 지니 메시지의 시각 추출
    GENIE_TIME=$(echo "$LAST_GENIE" | grep -oE '\[([0-9]{2}:[0-9]{2})\]' | tr -d '[]')
    if [ -n "$GENIE_TIME" ]; then
      echo "📬 지니 메시지 있음 ($GENIE_TIME) — channel.md 확인" >&2
    fi
  fi
fi

exit 0
