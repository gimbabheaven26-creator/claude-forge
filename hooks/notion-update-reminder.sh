#!/bin/bash
# notion-update-reminder.sh - Stop Hook
# 세션이 진행되었는데 노션 업데이트가 없으면 리마인더
# 클루디 하이브리드 제안: sh는 관문(gate), 에이전트는 실행(executor)
# session-stats.json 의존 제거 → /tmp 마커 기반 단순화 (안선생 검증 반영)
# exit 0 필수

INPUT=$(cat)

echo "$INPUT" | python3 -c "
import sys, json, os, glob

try:
    d = json.load(sys.stdin)
except:
    sys.exit(0)

sid = d.get('session_id', '')
if not sid:
    sys.exit(0)

# 세션당 1회만
reminder_marker = f'/tmp/notion-reminder-{sid}'
if os.path.exists(reminder_marker):
    sys.exit(0)

# 세션 시작 마커 확인 — work-tracker가 생성하는 세션 파일로 판단
# 세션 시작 마커가 없으면 (매우 짧은 세션) 건너뛰기
sessions_dir = os.path.expanduser('~/.claude/work-log/.sessions')
session_marker = os.path.join(sessions_dir, sid)
if not os.path.exists(session_marker):
    # work-log가 없어도, 세션이 존재한다면 buffer.jsonl에서 확인
    buffer = os.path.expanduser('~/.claude/work-log/buffer.jsonl')
    tool_count = 0
    try:
        with open(buffer) as f:
            for line in f:
                try:
                    ev = json.loads(line.strip())
                    if ev.get('session_id') == sid and ev.get('event') == 'tool_use':
                        tool_count += 1
                except:
                    continue
    except:
        pass
    # 최소 10회 도구 호출이 있어야 의미 있는 세션
    if tool_count < 10:
        sys.exit(0)

# 노션 MCP 호출 여부 확인
notion_marker = f'/tmp/notion-updated-{sid}'
if os.path.exists(notion_marker):
    sys.exit(0)

# 마커 생성
open(reminder_marker, 'w').close()

print(json.dumps({
    'continue': True,
    'systemMessage': '[Notion 리마인더] 이 세션에서 노션 작업 상태를 업데이트하지 않았습니다. '
        '완료/진행 중인 태스크가 있다면 노션 상태를 업데이트해 주세요. '
        '(mcp__notion__API-patch-page 또는 /session-wrap에서 처리)'
}))
" 2>/dev/null

exit 0
