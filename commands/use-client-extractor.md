---
description: 'use client' page.tsx → SC wrapper + Client 분리 변환. Next.js force-dynamic 필요 페이지에 사용.
---
# use-client-extractor

> 'use client' page.tsx에서 클라이언트 코드를 분리하여 SC wrapper 패턴으로 변환한다.
> Next.js App Router에서 force-dynamic이 필요한 'use client' 페이지에 사용.

## 사용법

```
/use-client-extractor src/app/target/page.tsx
```

## 절차

### 1. 대상 확인
```bash
# 'use client' + force-dynamic이 필요한 페이지 탐지
grep -l "'use client'" src/app/**/page.tsx
```

### 2. 클라이언트 코드 추출
- `page.tsx`의 컴포넌트 본문 전체를 `*Client.tsx`로 이동
- props 인터페이스가 있으면 함께 이동
- `'use client'` 지시어는 `*Client.tsx`에만

### 3. SC wrapper 생성
```tsx
// page.tsx (Server Component)
export const dynamic = 'force-dynamic'

import TargetClient from './TargetClient'

export default function TargetPage() {
  return <TargetClient />
}
```

### 4. 검증
```bash
npm run build  # SSG prerender 에러 없는지 확인
npm run lint   # import 경로 정상 확인
```

## 주의사항

- `export const dynamic = 'force-dynamic'`은 Server Component에서만 유효
- `'use client'` 파일에서 선언하면 Next.js가 무시함 (이것이 이 패턴이 필요한 이유)
- 기존 import를 모두 `*Client.tsx`로 이동해야 함
- `generateStaticParams`나 `generateMetadata`는 `page.tsx`(SC)에 남김

## 관련

- `/build-fix` — SSG prerender 에러 디버깅
- CLAUDE.md "force-dynamic 필수 페이지" 목록 참조
