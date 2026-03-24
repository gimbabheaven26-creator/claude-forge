#!/bin/bash
# contract-version-check.sh — PreToolUse Hook (Bash)
# contract.md 미수정 상태에서 DB 관련 파일을 커밋하려 하면 경고
# exit 0 = 허용 (경고만)

INPUT=$(cat)

COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('command', ''))
" 2>/dev/null)

if ! echo "$COMMAND" | grep -q 'git commit'; then
    exit 0
fi

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [[ -z "$REPO_ROOT" ]]; then
    exit 0
fi

# 스테이지된 파일 목록
STAGED=$(git -C "$REPO_ROOT" diff --cached --name-only 2>/dev/null)

# DB/스키마 관련 파일이 스테이지됐는지 확인
DB_FILES=$(echo "$STAGED" | grep -E '(migration|schema|supabase|db\.ts|contract)' | head -5)

if [[ -z "$DB_FILES" ]]; then
    exit 0
fi

# contract.md가 스테이지됐거나 최근 수정됐는지 확인
CONTRACT_STAGED=$(echo "$STAGED" | grep 'contract\.md')

if [[ -z "$CONTRACT_STAGED" ]]; then
    # contract.md가 이번 커밋에 포함되지 않음
    CONTRACT_MODIFIED=$(git -C "$REPO_ROOT" status --short docs/contract.md 2>/dev/null | head -1)
    
    cat >&2 << MSG
⚠️  [contract-version-check] DB 관련 파일 커밋 감지

스테이지된 DB/스키마 파일:
$(echo "$DB_FILES" | sed 's/^/  /')

규칙 (CLAUDE.md):
  스키마/API 변경 → contract.md 먼저 수정 → 카이란 승인 → 구현

contract.md 상태: ${CONTRACT_MODIFIED:-"변경 없음"}

의도적 변경이면 계속 진행해도 됩니다.
MSG
fi

exit 0
