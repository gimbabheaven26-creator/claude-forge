#!/bin/bash
# notion-usage-marker.sh - PostToolUse Hook (matcher: mcp__notion__*)
# 노션 MCP를 사용했으면 마커 파일 생성 → Stop 훅에서 리마인더 억제
# exit 0 필수

INPUT=$(cat)

echo "$INPUT" | python3 -c "
import sys, json, os

try:
    d = json.load(sys.stdin)
except:
    sys.exit(0)

sid = d.get('session_id', '')
tool = d.get('tool_name', '')

if not sid:
    sys.exit(0)

# patch-page 호출 시에만 마커 (실제 상태 업데이트)
if 'patch-page' in tool or 'post-page' in tool:
    marker = f'/tmp/notion-updated-{sid}'
    open(marker, 'w').close()
" 2>/dev/null

exit 0
