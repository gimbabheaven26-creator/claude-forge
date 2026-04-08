#!/bin/bash
# skill-audit.sh — 스킬 품질 자동 감사
# 트리거: SessionStart 훅 또는 수동 실행
# 출력: 문제 있을 때만 요약 리포트 (없으면 무출력)

# === 감사 대상 디렉토리 ===
GLOBAL_DIR="$HOME/.claude/commands"
PROJECT_DIR=""

# CWD 기반 프로젝트 디렉토리 탐지
if [ -f ".claude/commands" ] || [ -d ".claude/commands" ]; then
  PROJECT_DIR="$(pwd)/.claude/commands"
fi

# === 카운터 ===
TOTAL=0
NO_DESC=0
SHORT_DESC=0
STALE_REF=0
COMPLETED_MISSION=0
ISSUES=""

# === 폐기된 에이전트명 (R4 기준) ===
RETIRED_AGENTS="강선생|클루디|프라임|kangsaeng|cloodi|prime"

# === 완료 미션 키워드 ===
COMPLETED_KEYWORDS="migrator|generator-loading|one-time"

audit_dir() {
  local dir="$1"
  local label="$2"

  [ -d "$dir" ] || return

  for f in "$dir"/*.md; do
    [ -f "$f" ] || continue
    TOTAL=$((TOTAL + 1))
    local name
    name=$(basename "$f" .md)

    # 1. Description 유무 체크
    local desc=""
    if head -1 "$f" | grep -q '^---'; then
      desc=$(head -5 "$f" | grep "^description:" | sed 's/^description: //')
    fi

    if [ -z "$desc" ]; then
      NO_DESC=$((NO_DESC + 1))
      ISSUES="${ISSUES}  ❌ [${label}] ${name} — description 없음\n"
      continue
    fi

    # 2. Description 길이 체크 (< 20자 = 너무 짧음)
    local len=${#desc}
    if [ "$len" -lt 20 ]; then
      SHORT_DESC=$((SHORT_DESC + 1))
      ISSUES="${ISSUES}  ⚠️  [${label}] ${name} — description 너무 짧음 (${len}자)\n"
    fi

    # 3. 폐기 에이전트명 참조 체크
    if grep -qiE "$RETIRED_AGENTS" "$f" 2>/dev/null; then
      STALE_REF=$((STALE_REF + 1))
      local matched
      matched=$(grep -oiE "$RETIRED_AGENTS" "$f" | head -1)
      ISSUES="${ISSUES}  🗑️  [${label}] ${name} — 폐기 에이전트명 '${matched}' 참조\n"
    fi

    # 4. 완료 미션 이름 패턴 체크
    if echo "$name" | grep -qiE "$COMPLETED_KEYWORDS"; then
      COMPLETED_MISSION=$((COMPLETED_MISSION + 1))
      ISSUES="${ISSUES}  🏁 [${label}] ${name} — 일회성 미션 스킬? 은퇴 검토\n"
    fi

  done
}

# === SKILL.md (폴더형 스킬) 감사 ===
audit_folder_skills() {
  local dir="$1"
  local label="$2"

  [ -d "$dir" ] || return

  for d in "$dir"/*/; do
    [ -d "$d" ] || continue
    local skill_file="$d/SKILL.md"
    [ -f "$skill_file" ] || continue
    TOTAL=$((TOTAL + 1))
    local name
    name=$(basename "$d")

    local desc=""
    if head -1 "$skill_file" | grep -q '^---'; then
      desc=$(head -5 "$skill_file" | grep "^description:" | sed 's/^description: //')
    fi

    if [ -z "$desc" ]; then
      NO_DESC=$((NO_DESC + 1))
      ISSUES="${ISSUES}  ❌ [${label}] ${name}/SKILL.md — description 없음\n"
    fi
  done
}

# === 실행 ===
audit_dir "$GLOBAL_DIR" "global"
audit_folder_skills "$GLOBAL_DIR" "global"

if [ -n "$PROJECT_DIR" ]; then
  audit_dir "$PROJECT_DIR" "project"
  audit_folder_skills "$PROJECT_DIR" "project"
fi

# === 결과 출력 (문제 있을 때만) ===
ISSUE_TOTAL=$((NO_DESC + SHORT_DESC + STALE_REF + COMPLETED_MISSION))

if [ "$ISSUE_TOTAL" -gt 0 ]; then
  echo "🔧 스킬 감사 (${TOTAL}개 스캔, ${ISSUE_TOTAL}건 발견)"
  echo ""

  [ "$NO_DESC" -gt 0 ] && echo "  description 없음: ${NO_DESC}개"
  [ "$SHORT_DESC" -gt 0 ] && echo "  description 짧음: ${SHORT_DESC}개"
  [ "$STALE_REF" -gt 0 ] && echo "  폐기 참조: ${STALE_REF}개"
  [ "$COMPLETED_MISSION" -gt 0 ] && echo "  은퇴 후보: ${COMPLETED_MISSION}개"

  echo ""
  echo -e "$ISSUES"
  echo "기준: Anthropic 공식 — description이 발동 정확도를 결정"
  echo "조치: description 추가/개선, 폐기 참조 제거, 은퇴 스킬 삭제"
fi

exit 0
