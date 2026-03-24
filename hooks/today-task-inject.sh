#!/bin/bash
# today-task-inject.sh - SessionStart Hook
# 프라임이 작성한 today-*.md 파일을 세션 시작 시 자동 주입
# CLAUDE_ROLE 환경변수로 Opus/Sonnet 구분 (기본값: opus)
# exit 0 필수

CWD=$(pwd)
HOME_DIR="$HOME"
ROLE="${CLAUDE_ROLE:-opus}"
SEW_DIR="$HOME_DIR/Projects/special-education-web"

# CWD 기반 파일 경로 결정
if [[ "$CWD" == *"special-education-web"* ]]; then
    TODAY_FILE="$SEW_DIR/docs/today-kangteacher.md"
    AGENT="강선생"
elif [[ "$CWD" == "$HOME_DIR" || "$CWD" == "$HOME_DIR/" ]]; then
    TODAY_FILE="$SEW_DIR/docs/today-cloudy.md"
    AGENT="클루디"
else
    exit 0
fi

# 파일 없으면 조용히 종료
if [ ! -f "$TODAY_FILE" ]; then
    exit 0
fi

{
    echo ""
    echo "━━━ 오늘의 지시서 [$AGENT / $(echo $ROLE | tr '[:lower:]' '[:upper:]') 세션] ━━━"
    cat "$TODAY_FILE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
} >&2

exit 0
