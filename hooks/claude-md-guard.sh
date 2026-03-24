#!/bin/bash
# claude-md-guard.sh — SessionStart Hook
# 현재 git repo에 CLAUDE.md가 없으면 경고 출력
# exit 0 필수 (세션 차단 금지)

CWD=$(pwd)

# git repo 루트 찾기
REPO_ROOT=$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null)

# git repo가 아니면 스킵
if [[ -z "$REPO_ROOT" ]]; then
    exit 0
fi

# CLAUDE.md 존재 확인
if [[ ! -f "$REPO_ROOT/CLAUDE.md" ]]; then
    cat >&2 << 'MSG'
⚠️  [claude-md-guard] CLAUDE.md 없음

이 레포에 CLAUDE.md가 없습니다. Claude Code는 세션 시작 시 이 파일을 자동으로
로드하여 프로젝트 컨텍스트를 파악합니다.

권장 내용:
  - 프로젝트 설명 + 스택
  - 핵심 명령어 (dev / build / test)
  - 에이전트 역할 분리 (있으면)
  - 주요 파일 경로
  - 코딩 규칙

생성: cat docs/CLAUDE.md 참고 또는 /init-project 실행
MSG
fi

exit 0
