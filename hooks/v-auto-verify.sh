#!/bin/bash
# v-auto-verify.sh — PostToolUse Hook (Bash matcher)
# feat: 커밋 감지 시:
#   1. npm run lint + tsc --noEmit 경량 검증 (자동)
#   2. V 심층 검증 추천 메시지 (systemMessage)
# 다른 커밋(fix:, refactor:, docs: 등)에는 반응하지 않음.
# exit 0 필수 (세션 방해 금지)

# stdin에서 tool input 읽기
INPUT=$(cat)

# git commit 명령인지 확인
COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null)

if ! echo "$COMMAND" | grep -q "git commit"; then
    exit 0
fi

# feat: 커밋인지 확인 (커밋 메시지에 feat: 포함)
if ! echo "$COMMAND" | grep -qi "feat[:(]"; then
    exit 0
fi

# 프로젝트 디렉토리 확인
PROJECT_DIR="$HOME/Projects/special-education-web"
if [[ ! -d "$PROJECT_DIR" ]]; then
    exit 0
fi

# 경량 검증 실행 (lint + typecheck)
ERRORS=""

cd "$PROJECT_DIR" || exit 0

# lint 검사
LINT_OUTPUT=$(npm run lint 2>&1)
LINT_EXIT=$?
if [[ $LINT_EXIT -ne 0 ]]; then
    ERRORS="$ERRORS\n⚠️ lint 실패: $(echo "$LINT_OUTPUT" | tail -5)"
fi

# typecheck 검사
TSC_OUTPUT=$(npx tsc --noEmit 2>&1)
TSC_EXIT=$?
if [[ $TSC_EXIT -ne 0 ]]; then
    ERRORS="$ERRORS\n⚠️ typecheck 실패: $(echo "$TSC_OUTPUT" | tail -5)"
fi

# 결과 메시지 구성
if [[ -n "$ERRORS" ]]; then
    MSG="🔴 [V 경량 검증] feat: 커밋 감지 — 문제 발견:${ERRORS}\n\n👉 V 심층 검증을 실행하세요. Completion Contract가 있다면 기준 대비 검증이 필요합니다."
else
    MSG="🟢 [V 경량 검증] feat: 커밋 감지 — lint ✅ typecheck ✅ 통과.\n\n👉 V 심층 검증 추천: 기능 완료 확인을 위해 V를 소환하여 Completion Contract 기준 검증을 실행하세요."
fi

echo "{\"continue\": true, \"systemMessage\": \"$MSG\"}"
exit 0
