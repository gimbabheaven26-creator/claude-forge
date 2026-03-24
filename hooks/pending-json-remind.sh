#!/bin/bash
# pending-json-remind.sh — PreToolUse Hook (Bash)
# git commit 시 ~/.claude/notion-pending.json이 비어있거나 없으면 알림
# exit 0 = 허용 (차단하지 않음)

INPUT=$(cat)

COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('command', ''))
" 2>/dev/null)

if ! echo "$COMMAND" | grep -q 'git commit'; then
    exit 0
fi

PENDING="$HOME/.claude/notion-pending.json"

# pending.json 없으면 알림
if [[ ! -f "$PENDING" ]]; then
    cat >&2 << 'MSG'
💡 [pending-json-remind] notion-pending.json 없음

커밋과 동시에 노션 스프린트 로그에 올리려면 커밋 전에 작성하세요:

  ~/.claude/notion-pending.json

스프린트 로그 포맷:
  {
    "destination": "sprint",
    "title": "에이전트명: 작업내용 (날짜)",
    "agent": "에이전트명",
    "status": "완료",
    "tags": ["태그"],
    "content": "## 완료 사항\n\n- ..."
  }

건너뛰려면 무시해도 됩니다.
MSG
    exit 0
fi

# pending.json이 직전 커밋 이후 변경되지 않았으면 알림 (오래된 파일)
PENDING_MTIME=$(stat -f %m "$PENDING" 2>/dev/null || stat -c %Y "$PENDING" 2>/dev/null)
LAST_COMMIT_TIME=$(git log -1 --format="%ct" 2>/dev/null)

if [[ -n "$LAST_COMMIT_TIME" && -n "$PENDING_MTIME" ]]; then
    if (( PENDING_MTIME < LAST_COMMIT_TIME )); then
        echo "💡 [pending-json-remind] notion-pending.json이 마지막 커밋보다 오래됨 — 업데이트 권장" >&2
    fi
fi

exit 0
