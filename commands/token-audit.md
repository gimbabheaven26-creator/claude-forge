---
description: 세션 자동 로드 문서(rules/memory/CLAUDE.md) 토큰 비용 측정 + 최적화 대상 식별.
---
# /token-audit — 자동 로드 문서 토큰 비용 분석

## 목적
매 세션 자동 로딩되는 문서의 토큰 비용을 측정하고 최적화 대상을 식별한다.

## 실행 단계

### 1. 크기 측정
```bash
echo "=== rules/ ===" && wc -c ~/.claude/rules/*.md 2>/dev/null
echo "=== CLAUDE.md ===" && wc -c CLAUDE.md 2>/dev/null
echo "=== .claude/rules/ (project) ===" && wc -c .claude/rules/*.md 2>/dev/null
echo "=== MEMORY.md ===" && wc -c ~/.claude/projects/*/memory/MEMORY.md 2>/dev/null
```

### 2. 토큰 추정
한국어+코드 혼합 기준: 1 토큰 ≈ 1.5 bytes (보수적).
총 bytes / 1.5 = 추정 토큰.

### 3. 분류 — 파일별 행동 영향 테스트
각 파일에 대해: **"이 파일이 없으면 오늘 내 작업 방식이 달라지는가?"**

| 답 | 분류 | 조치 |
|----|------|------|
| YES, 매 세션 | rules/ 유지 | - |
| YES, 소환 시만 | agents/ 이동 | rules에서 제거 |
| NO | memory/ 이동 또는 삭제 | rules에서 제거 |

### 4. 과대 파일 식별
- 150줄 초과 → 분리 검토
- 완료 체크리스트 → 요약 축약 검토
- 중복 내용 → 한 곳으로 통합

### 5. 리포트 출력

```
## Token Audit Report

| 파일 | Bytes | ~Tokens | 행동영향 | 권고 |
|------|-------|---------|---------|------|
| ... | ... | ... | YES/NO | 유지/이동/축약 |

총 토큰: ~N (병렬 3세션 = ~N×3)
권고 절감: ~M tokens/session
```

### 6. 사용자 승인 후 실행
권고 조치를 AskUserQuestion으로 확인 → 승인된 것만 편집.

## 주의
- rules/ 파일 삭제는 되돌릴 수 있지만, 다음 세션부터 즉시 영향
- 삭제 전 memory/나 agents/에 백업 이동 권장
- x-identity.md 핵심 정체성 제거 시 X 행동이 달라짐 — 산문 분리만 권장
