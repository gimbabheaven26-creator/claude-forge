#!/bin/bash
# build-required-check.sh — PreToolUse Hook (Bash)
# git commit 시 npm run build 미실행 경고
# 수정된 .ts/.tsx 파일이 있으면 빌드 확인 촉구
# exit 0 = 허용(경고만), exit 2 = 차단

INPUT=$(cat)

# git commit 명령인지 확인
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('command', ''))
" 2>/dev/null)

# git commit이 아니면 스킵
if ! echo "$COMMAND" | grep -q 'git commit'; then
    exit 0
fi

# --no-build 플래그로 우회 허용 (문서 커밋 등)
if echo "$COMMAND" | grep -q '\-\-no-build'; then
    exit 0
fi

# 현재 repo 루트 찾기
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [[ -z "$REPO_ROOT" ]]; then
    exit 0
fi

# package.json + build script 있는 프로젝트인지 확인
if [[ ! -f "$REPO_ROOT/package.json" ]]; then
    exit 0
fi
if ! python3 -c "
import json
p = json.load(open('$REPO_ROOT/package.json'))
exit(0 if 'build' in p.get('scripts', {}) else 1)
" 2>/dev/null; then
    exit 0
fi

# 스테이지된 .ts/.tsx/.js 파일 있는지 확인
STAGED=$(git -C "$REPO_ROOT" diff --cached --name-only 2>/dev/null | grep -E '\.(ts|tsx|js|jsx)$' | head -5)

if [[ -n "$STAGED" ]]; then
    echo "" >&2
    echo "⚠️  [build-required-check] TypeScript 파일이 스테이지됨" >&2
    echo "" >&2
    echo "  수정된 파일:" >&2
    echo "$STAGED" | sed 's/^/    /' >&2
    echo "" >&2
    echo "  빌드 확인 후 커밋 권장: npm run build" >&2
    echo "  문서 전용 커밋은 무시해도 됨." >&2
    echo "" >&2
fi

# 경고만, 차단하지 않음
exit 0
