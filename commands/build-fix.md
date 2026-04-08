---
description: 빌드 또는 타입 에러 단계적 수정. npm run build 실패 시 사용. 아키텍처 문제면 /plan 먼저.
---
# Build and Fix

> **참고**: 빌드 에러가 아키텍처 문제에서 기인하는 경우, `/plan`으로 구조적 해결 방안을 먼저 수립하세요.

Incrementally fix TypeScript and build errors:

1. Run build: npm run build or pnpm build

2. Parse error output:
   - Group by file
   - Sort by severity

3. For each error:
   - Show error context (5 lines before/after)
   - Explain the issue
   - Propose fix
   - Apply fix
   - Re-run build
   - Verify error resolved

4. Stop if:
   - Fix introduces new errors
   - Same error persists after 3 attempts
   - User requests pause

5. Show summary:
   - Errors fixed
   - Errors remaining
   - New errors introduced

Fix one error at a time for safety!

---

## SSG Prerender 실패 디버깅

Next.js SSG prerender TypeError가 발생하면:

### 원인 분류
1. **readFileSync in Server Component** — Node fs API가 webpack 모듈 그래프 오염 → 무관한 SSG 페이지 `call` TypeError
   - 해결: `import data from '@/../data/path.json'` (static JSON import)
   - 대상 탐지: `grep -r "readFileSync" src/ --include="*.tsx" --include="*.ts" | grep -v "test" | grep -v "__tests__"`
2. **optimizePackageImports 충돌** — `lucide-react` 등 barrel export가 webpack 분할과 충돌
   - 해결: `next.config.mjs`에서 해당 패키지 제거 (6067d27)
3. **SSG 불가 페이지** — 동적 API/쿠키 의존으로 SSG 불가
   - 해결: `export const dynamic = 'force-dynamic'` 추가

### 원인 격리: 바이너리 서치
커밋 내 여러 파일 중 원인 파일이 불명확할 때:
1. `next build --no-cache` 실행
2. 의심 파일을 절반씩 임시 revert (git stash -p 또는 주석 처리)
3. 빌드 성공/실패 분기점에서 원인 파일 특정
4. import 트리 추적 — Node API (fs, path, process) 사용 여부 확인
5. 시도 횟수: log₂(N) (8파일이면 3회)

---

## CI Failure Triage

로컬 pass / CI fail 상황에서의 원격 디버깅 절차:

### 1단계: 로그 수집
```bash
gh run list --limit 5                    # 최근 5개 실행
gh run view [run-id] --log-failed        # 실패 로그만 추출
```

### 2단계: 원인 분류

| 패턴 | 원인 | 처치 |
|------|------|------|
| `Secret not found` / `env undefined` | GitHub Secrets 미등록 | `gh secret set KEY < .env.local` |
| `Timeout waiting for` | CI 환경 느림 / locator 불안정 | timeout 증가 + `getByRole` 전환 |
| `Cannot read properties of undefined (reading 'call')` | SSG prerender webpack 모듈 깨짐 | `export const dynamic = 'force-dynamic'` |
| `ECONNREFUSED` / `fetch failed` | dev server 미기동 / baseURL 불일치 | `webServer` 설정 확인 |

### 3단계: 수정 → 재실행
```bash
# 수정 후 push
git push

# 특정 실행 재시도
gh run rerun [run-id] --failed
```

---

## 다음 단계

| 빌드 수정이 끝나면 | 커맨드 |
|:-----------------|:-------|
| 전체 검증 | `/handoff-verify` |
| 빠른 커밋 | `/quick-commit` |
| 문서 동기화 | `/sync` |
