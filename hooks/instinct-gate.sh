#!/bin/bash
# instinct-gate.sh — instinct 파일 작성 시 중복 체크 (PostToolUse Write 훅)
# 트리거: ~/.claude/homunculus/instincts/personal/ 에 .md 파일 Write 시
#
# 차단하지 않음 — 경고만 출력. 판단은 에이전트에게.

INSTINCT_DIR="$HOME/.claude/homunculus/instincts/personal"
CLAUDE_MD="$HOME/Projects/special-education-web/CLAUDE.md"
RULES_DIR="$HOME/.claude/rules"
MEMORY_DIR="$HOME/.claude/projects/-Users-gihoonkim-Projects-special-education-web/memory"

# stdin에서 JSON 읽기
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)

# instinct 디렉토리가 아니면 무시
if [[ "$FILE_PATH" != "$INSTINCT_DIR"* ]] || [[ "$FILE_PATH" != *.md ]]; then
  exit 0
fi

FILENAME=$(basename "$FILE_PATH")
WARNINGS=""

# --- Stopword 목록 (일반 프로그래밍/웹 용어) ---
STOPWORDS="server client check limit build error type file page route next data use get set fetch post delete update create read write config test debug deploy start stop run call load save send handle event state store action render style layout component module import export default return value index entry point status code base path name list item count query param option flag mode level scope context token session cache proxy hook util helper format parse valid match filter sort merge split"

is_stopword() {
  local word="$1"
  for sw in $STOPWORDS; do
    [ "$word" = "$sw" ] && return 0
  done
  return 1
}

# --- 파일명에서 핵심 키워드 추출 (stopword 제거 + 최소 6자) ---
extract_keywords() {
  local fname="$1"
  local stem="${fname%.md}"
  stem=$(echo "$stem" | sed -E 's/^[A-Z]+-[0-9]+-//')
  stem=$(echo "$stem" | sed -E 's/^[0-9]+-//')

  local words
  words=$(echo "$stem" | tr '-' '\n' | tr '_' '\n' | grep -v '^$' | tail -3)

  local result=""
  for w in $words; do
    w=$(echo "$w" | tr '[:upper:]' '[:lower:]')
    is_stopword "$w" && continue
    [ ${#w} -ge 6 ] || continue
    result="${result} ${w}"
  done
  echo "$result"
}

# --- 복합 키워드 추출 (2어 조합) ---
extract_compound_keywords() {
  local fname="$1"
  local stem="${fname%.md}"
  stem=$(echo "$stem" | sed -E 's/^[A-Z]+-[0-9]+-//')
  stem=$(echo "$stem" | sed -E 's/^[0-9]+-//')

  local pairs=""
  local prev=""
  for w in $(echo "$stem" | tr '-' '\n' | tr '_' '\n' | grep -v '^$'); do
    w=$(echo "$w" | tr '[:upper:]' '[:lower:]')
    if [ -n "$prev" ]; then
      if [ ${#prev} -ge 3 ] && [ ${#w} -ge 3 ]; then
        pairs="${pairs} ${prev}[- _]${w}"
      fi
    fi
    prev="$w"
  done
  echo "$pairs"
}

# 1. 파일명에서 키워드 추출
KEYWORDS=$(extract_keywords "$FILENAME")
COMPOUND=$(extract_compound_keywords "$FILENAME")

# 2. CLAUDE.md 중복 체크 — 복합 키워드 우선, 단일 키워드 보조
CLAUDE_MATCHED=false
if [ -f "$CLAUDE_MD" ]; then
  # 2a. 복합 키워드 (정밀도 높음)
  for pattern in $COMPOUND; do
    HITS=$(grep -icE "$pattern" "$CLAUDE_MD" 2>/dev/null) || true
    HITS=${HITS:-0}
    if [ "$HITS" -ge 2 ]; then
      DISPLAY=$(echo "$pattern" | sed 's/\[- _\]/ /g')
      WARNINGS="${WARNINGS}⚠ R1: CLAUDE.md에 '${DISPLAY}' ${HITS}회 언급됨\n"
      CLAUDE_MATCHED=true
      break
    fi
  done

  # 2b. 단일 키워드 (stopword 제거 + 6자 이상)
  if ! $CLAUDE_MATCHED; then
    for kw in $KEYWORDS; do
      HITS=$(grep -ic "$kw" "$CLAUDE_MD" 2>/dev/null) || true
      HITS=${HITS:-0}
      if [ "$HITS" -ge 2 ]; then
        WARNINGS="${WARNINGS}⚠ R1: CLAUDE.md에 '$kw' ${HITS}회 언급됨\n"
        break
      fi
    done
  fi
fi

# 3. rules/ 중복 체크 — 같은 로직
RULES_MATCHED=false
# 3a. 복합
for pattern in $COMPOUND; do
  HITS=0
  for rf in "$RULES_DIR"/*.md; do
    [ -f "$rf" ] || continue
    H=$(grep -icE "$pattern" "$rf" 2>/dev/null) || true
    H=${H:-0}
    HITS=$((HITS + H))
  done
  if [ "$HITS" -ge 2 ]; then
    DISPLAY=$(echo "$pattern" | sed 's/\[- _\]/ /g')
    WARNINGS="${WARNINGS}⚠ R1: rules/에 '${DISPLAY}' ${HITS}회 언급됨\n"
    RULES_MATCHED=true
    break
  fi
done
# 3b. 단일
if ! $RULES_MATCHED; then
  for kw in $KEYWORDS; do
    HITS=0
    for rf in "$RULES_DIR"/*.md; do
      [ -f "$rf" ] || continue
      H=$(grep -ic "$kw" "$rf" 2>/dev/null) || true
      H=${H:-0}
      HITS=$((HITS + H))
    done
    if [ "$HITS" -ge 2 ]; then
      WARNINGS="${WARNINGS}⚠ R1: rules/에 '$kw' ${HITS}회 언급됨\n"
      break
    fi
  done
fi

# 4. 같은 주제 instinct 중복 체크 — 복합 키워드 기반
MAIN_COMPOUND=""
for pattern in $COMPOUND; do
  MAIN_COMPOUND="$pattern"
  break  # 첫 번째 복합 키워드만
done

if [ -n "$MAIN_COMPOUND" ]; then
  DUPES=$(ls "$INSTINCT_DIR"/*.md 2>/dev/null | xargs grep -liE "$MAIN_COMPOUND" 2>/dev/null | grep -v "$FILENAME" | wc -l | tr -d ' ')
  if [ "$DUPES" -gt 0 ]; then
    MATCHING=$(ls "$INSTINCT_DIR"/*.md 2>/dev/null | xargs grep -liE "$MAIN_COMPOUND" 2>/dev/null | grep -v "$FILENAME" | head -3 | xargs -I{} basename {})
    WARNINGS="${WARNINGS}⚠ R2: 유사 instinct ${DUPES}개 존재: ${MATCHING}\n"
  fi
else
  # 복합 키워드 없으면 단일 키워드 중 첫 번째 사용
  MAIN_KEYWORD=""
  for kw in $KEYWORDS; do
    MAIN_KEYWORD="$kw"
    break
  done
  if [ -n "$MAIN_KEYWORD" ] && [ ${#MAIN_KEYWORD} -ge 6 ]; then
    DUPES=$(ls "$INSTINCT_DIR"/*.md 2>/dev/null | xargs grep -li "$MAIN_KEYWORD" 2>/dev/null | grep -v "$FILENAME" | wc -l | tr -d ' ')
    if [ "$DUPES" -gt 0 ]; then
      MATCHING=$(ls "$INSTINCT_DIR"/*.md 2>/dev/null | xargs grep -li "$MAIN_KEYWORD" 2>/dev/null | grep -v "$FILENAME" | head -3 | xargs -I{} basename {})
      WARNINGS="${WARNINGS}⚠ R2: 유사 instinct ${DUPES}개 존재: ${MATCHING}\n"
    fi
  fi
fi

# 5. memory/feedback 중복 체크 — stopword 제거 + 7자 이상
for kw in $KEYWORDS; do
  if [ ${#kw} -ge 7 ]; then
    HITS=0
    for mf in "$MEMORY_DIR"/feedback_*.md; do
      [ -f "$mf" ] || continue
      H=$(grep -ic "$kw" "$mf" 2>/dev/null) || true
      H=${H:-0}
      HITS=$((HITS + H))
    done
    if [ "$HITS" -gt 0 ]; then
      WARNINGS="${WARNINGS}⚠ R1/P2: memory/feedback에 '$kw' ${HITS}회 — 승격 대상?\n"
      break
    fi
  fi
done

# 경고 출력
if [ -n "$WARNINGS" ]; then
  echo -e "🔍 instinct-gate: ${FILENAME} 중복 의심\n${WARNINGS}삭제 기준: ~/.claude/rules/instinct-policy.md 참조"
fi

exit 0
