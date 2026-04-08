#!/bin/bash
# instinct-audit.sh — 세션 시작 시 instinct stale/중복 감사
# 트리거: SessionStart 훅
# 출력: 문제 있을 때만 요약 리포트 (없으면 무출력)

INSTINCT_DIR="$HOME/.claude/homunculus/instincts/personal"
CLAUDE_MD="$HOME/Projects/special-education-web/CLAUDE.md"

# instinct 디렉토리 없으면 종료
[ -d "$INSTINCT_DIR" ] || exit 0

TOTAL=$(ls "$INSTINCT_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
[ "$TOTAL" -eq 0 ] && exit 0

STALE_FILES=""
DUPE_KEYWORDS=""
STALE_COUNT=0

# --- Stopword 목록 (일반 프로그래밍/웹 용어) ---
STOPWORDS="server client check limit build error type file page route next data use get set fetch post delete update create read write config test debug deploy start stop run call load save send handle event state store action render style layout component module import export default return value index entry point status code base path name list item count query param option flag mode level scope context token session cache proxy hook util helper format parse valid match filter sort merge split"

is_stopword() {
  local word="$1"
  for sw in $STOPWORDS; do
    [ "$word" = "$sw" ] && return 0
  done
  return 1
}

# --- 파일명에서 핵심 키워드 추출 ---
# prefix 제거: "X-20260402-rate-limit-check.md" → "rate-limit-check"
# 마지막 3단어만 사용, stopword 제거, 최소 길이 7
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
    [ ${#w} -ge 7 ] || continue
    result="${result} ${w}"
  done
  echo "$result"
}

# --- 복합 키워드 추출 (하이픈 연결 2어 조합) ---
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

# 1. Stale 체크 (30일 이상 미수정)
THIRTY_DAYS_AGO=$(date -v-30d +%s 2>/dev/null || date -d "30 days ago" +%s 2>/dev/null)
for f in "$INSTINCT_DIR"/*.md; do
  MTIME=$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null)
  if [ -n "$MTIME" ] && [ "$MTIME" -lt "$THIRTY_DAYS_AGO" ]; then
    FDATE=$(date -r "$MTIME" +%m/%d 2>/dev/null || date -d @"$MTIME" +%m/%d 2>/dev/null)
    STALE_FILES="${STALE_FILES}  - $(basename "$f") (${FDATE})\n"
    STALE_COUNT=$((STALE_COUNT + 1))
  fi
done

# 2. CLAUDE.md 키워드 중복 체크 (상위 5개만)
DUPE_COUNT=0
if [ -f "$CLAUDE_MD" ]; then
  for f in "$INSTINCT_DIR"/*.md; do
    FNAME=$(basename "$f")
    MATCHED=false

    # 2a. 복합 키워드 먼저 (정밀도 높음)
    COMPOUND=$(extract_compound_keywords "$FNAME")
    for pattern in $COMPOUND; do
      HITS=$(grep -icE "$pattern" "$CLAUDE_MD" 2>/dev/null) || true
      HITS=${HITS:-0}
      if [ "$HITS" -ge 2 ]; then
        DISPLAY=$(echo "$pattern" | sed 's/\[- _\]/ /g')
        DUPE_KEYWORDS="${DUPE_KEYWORDS}  - ${FNAME}: '${DISPLAY}' CLAUDE.md ${HITS}회\n"
        DUPE_COUNT=$((DUPE_COUNT + 1))
        MATCHED=true
        break
      fi
    done

    # 2b. 복합에서 못 찾으면 단일 키워드 (stopword 제거 + 7자 이상)
    if ! $MATCHED; then
      KEYWORDS=$(extract_keywords "$FNAME")
      for kw in $KEYWORDS; do
        HITS=$(grep -ic "$kw" "$CLAUDE_MD" 2>/dev/null) || true
        HITS=${HITS:-0}
        if [ "$HITS" -ge 2 ]; then
          DUPE_KEYWORDS="${DUPE_KEYWORDS}  - ${FNAME}: '$kw' CLAUDE.md ${HITS}회\n"
          DUPE_COUNT=$((DUPE_COUNT + 1))
          break
        fi
      done
    fi

    [ "$DUPE_COUNT" -ge 5 ] && break
  done
fi

# 3. 리포트 출력 (문제 있을 때만)
if [ "$STALE_COUNT" -gt 0 ] || [ "$DUPE_COUNT" -gt 0 ]; then
  echo "📋 instinct 감사 (${TOTAL}개)"

  if [ "$STALE_COUNT" -gt 0 ]; then
    echo -e "⏰ 30일+ stale ${STALE_COUNT}개:\n${STALE_FILES}"
  fi

  if [ "$DUPE_COUNT" -gt 0 ]; then
    echo -e "🔄 CLAUDE.md 중복 의심 ${DUPE_COUNT}개:\n${DUPE_KEYWORDS}"
  fi

  echo "기준: ~/.claude/rules/instinct-policy.md"
fi

exit 0
