---
allowed-tools: Bash(git:*), Read, Grep, Glob
description: 지시서 내 파일 경로를 실제 코드베이스 대비 일괄 검증
argument-hint: [지시서 파일 경로]
---

# /validate-directive — 지시서 파일 경로 검증

지시서(md 파일)에서 파일 경로 참조를 추출하고 실제 존재 여부를 일괄 검증한다.
경로가 이동/삭제된 경우 현재 위치를 제안한다.

---

## 0단계: 입력 확인

지시서 파일 경로가 인자로 제공됐는지 확인.
없으면 현재 디렉토리의 `docs/*.md` 파일 목록을 출력하고 선택 요청.

---

## 1단계: 경로 참조 추출

지시서 파일을 읽어 파일 경로 패턴을 추출한다:

```bash
# src/, docs/, scripts/, data/ 시작 경로 추출
grep -oE '`src/[^`]+`|`docs/[^`]+`|`scripts/[^`]+`' [지시서파일] | tr -d '`' | sort -u
# 또는 텍스트 내 경로 패턴
grep -oE 'src/[a-zA-Z0-9_/\[\].-]+\.(tsx?|ts|md|json)' [지시서파일] | sort -u
```

---

## 2단계: 존재 여부 확인

추출된 각 경로에 대해:

```bash
# 직접 존재 확인
test -f [경로] && echo "OK: [경로]" || echo "MISSING: [경로]"
```

---

## 3단계: MISSING 항목 현재 위치 탐색

MISSING 항목에 대해 파일명 기반으로 현재 위치 탐색:

```bash
# 파일명으로 검색
find src/ -name "[파일명]" 2>/dev/null

# git 이동 이력 확인
git log --diff-filter=R --name-status --oneline | grep "[파일명]"
```

---

## 4단계: 결과 출력

```
## 검증 결과: [지시서 파일명]

| 경로 | 상태 | 현재 위치 |
|------|------|---------|
| src/app/subjects/[slug]/page.tsx | ❌ MISSING | → src/app/concepts/[subject]/page.tsx (ad4e00b에서 이동) |
| src/lib/kice.ts | ✅ OK | — |
| docs/contract.md | ✅ OK | — |

주의: MISSING 경로가 있습니다. 지시서 실행 전 현재 위치로 변경하세요.
```

MISSING이 없으면:
```
✅ 모든 경로 확인됨. 지시서 실행 가능.
```

---

## 사용 예시

```bash
/validate-directive docs/kangteacher2-0322-practice-auto-cmds.md
/validate-directive docs/kangteacher1-0324-analytics-beta-feedback-auto-cmds.md
```
