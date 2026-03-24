# Gosari Namu Path (고사리나무길) - 구현 계획서

**프로젝트 코드명**: Gosari Namu Path
**철학**: 신영복 선생의 "싱싱한 한 그루 나무가 되기를" + 나무와 나무의 연대로 숲이 되는 학습
**대상**: 예비 교사 + 현직 교사
**기술 스택**: Next.js 15 (App Router) + TypeScript + Tailwind CSS + shadcn/ui + Supabase + MDX

---

## 기술 스택

| 항목 | 선택 | 이유 |
|------|------|------|
| 프레임워크 | Next.js 15 (App Router) | SSG, 파일 기반 라우팅 |
| 언어 | TypeScript | 타입 안전성 |
| 스타일링 | Tailwind CSS + shadcn/ui | 빠르고 일관된 UI |
| DB/인증 | Supabase (PostgreSQL + Auth) | 무료 티어, RLS, 실시간 |
| 콘텐츠 | MDX | 저작 편의성, 인터랙티브 컴포넌트 삽입 |
| 시각화 | @xyflow/react, recharts, 커스텀 SVG | 마인드맵, 차트, 스킬트리 |
| 드래그앤드롭 | @dnd-kit | 접근성 우수 |
| 애니메이션 | framer-motion | 부드러운 전환 |
| 아이콘 | lucide-react | 깔끔한 아이콘 |

---

## UI/UX 방향

- 단정하고 깔끔한 성인 대상 UI
- 뮤트 톤 색상 팔레트 (채도 40% 이하, 원색/보색 금지)
- 귀여운 아이콘 OK, 지나치게 화려한 색 금지
- 게이미피케이션: XP/레벨/뱃지/스트릭 (과하지 않게)
- 고사리 잎이 펼쳐지는 이미지를 브랜딩에 활용

---

## 핵심 기능

1. **MDX 콘텐츠 뷰어** - 챕터/섹션별 학습, 코드 하이라이팅, 목차
2. **퀴즈 시스템** - 객관식 + 단답형, 즉시 피드백 + 해설
3. **진도 추적** - 섹션 완료율, 선행 조건 잠금/해제
4. **오답 복습** - Leitner 간격 반복 시스템
5. **게이미피케이션** - XP, 레벨, 뱃지, 학습 스트릭
6. **마인드맵/지식 그래프** - ReactFlow 기반, 섹션 간 관계 시각화
7. **스킬트리** - 커스텀 SVG, 학습 경로 시각화
8. **대시보드 차트** - 학습 시간, 퀴즈 점수 추이, 취약 영역
9. **인터랙티브 콘텐츠** - 드래그&드롭, 타임라인, 비교표, 플래시카드
10. **반응형 + 다크모드**

---

## Supabase 스키마

### profiles
- id (UUID, FK auth.users), display_name, avatar_url
- total_xp, current_level, current_streak, longest_streak, last_study_date

### courses
- id, slug (UNIQUE), title, description, thumbnail_url, color, sort_order, is_published

### sections
- id, course_id (FK), slug, title, description, mdx_path
- sort_order, xp_reward, estimated_minutes, is_published

### section_prerequisites
- section_id (FK), prerequisite_id (FK) — 스킬트리용

### section_relations
- id, source_id (FK), target_id (FK), relation_type, label — 마인드맵용

### quizzes
- id, section_id (FK), question, quiz_type (multiple_choice/short_answer)
- options (JSONB), correct_answer, explanation, xp_reward

### section_progress
- id, user_id (FK), section_id (FK), is_completed, completed_at, time_spent_seconds

### quiz_attempts
- id, user_id (FK), quiz_id (FK), user_answer, is_correct, xp_earned, attempted_at

### xp_log
- id, user_id (FK), amount, source, reference_id

### study_sessions
- id, user_id (FK), section_id (FK), started_at, ended_at, duration_seconds

### badges
- id, slug (UNIQUE), name, description, icon_url, condition_type, condition_value (JSONB), xp_reward

### user_badges
- id, user_id (FK), badge_id (FK), earned_at

### review_cards (Leitner)
- id, user_id (FK), quiz_id (FK), box_number (1~5), next_review_at, last_reviewed_at, review_count

모든 사용자 데이터 테이블에 RLS 적용 (본인 데이터만 접근).

---

## 구현 단계

### Phase 1: 프로젝트 초기 설정 (1일)
- Next.js 15 프로젝트 생성
- shadcn/ui 초기화 + 기본 컴포넌트 설치
- Tailwind 뮤트 톤 색상 팔레트 설정
- Supabase 프로젝트 연결 + 환경변수
- 기본 레이아웃 (루트, 다크모드)
- ESLint 설정

### Phase 2: 인증 & 프로필 (1일)
- DB 마이그레이션: profiles
- Supabase Auth 트리거 (회원가입 시 profiles 자동 생성)
- 로그인/회원가입 페이지
- 대시보드 레이아웃 + 사이드바

### Phase 3: 코스 & 콘텐츠 시스템 (2일)
- DB 마이그레이션: courses, sections, prerequisites, relations
- MDX 로더 + 커스텀 컴포넌트 매핑
- 코스 목록 → 코스 상세 → 섹션 학습 플로우
- 샘플 MDX 콘텐츠 작성

### Phase 4: 진도 추적 (1.5일)
- DB 마이그레이션: section_progress, study_sessions
- 섹션 완료 표시 + 학습 시간 기록
- 선행 조건 잠금 로직
- 사이드바 완료 상태 표시

### Phase 5: 퀴즈 & 피드백 (2일)
- DB 마이그레이션: quizzes, quiz_attempts
- 객관식/단답형 UI + 즉시 피드백
- 채점 로직 (순수 함수)
- 퀴즈 결과 요약

### Phase 6: 게이미피케이션 (1.5일)
- DB 마이그레이션: badges, user_badges, xp_log
- XP 부여 규칙 + 레벨 계산
- 뱃지 획득 조건 체크
- XP 토스트, 레벨 프로그레스, 뱃지 모달
- 스트릭 캘린더

### Phase 7: 간격 반복 복습 (1일)
- DB 마이그레이션: review_cards
- Leitner system (Box 1~5, 1/2/4/8/16일 간격)
- 오답 자동 등록 + 복습 UI
- 대시보드 "오늘 복습할 문제 N개"

### Phase 8: 대시보드 차트 (1.5일)
- 통계 요약 카드 (총 XP, 레벨, 완료 수, 스트릭)
- 학습 시간 추이 (BarChart)
- 퀴즈 점수 추이 (LineChart)
- 취약 영역 레이더 (RadarChart)

### Phase 9: 스킬트리 (2일)
- 커스텀 SVG + framer-motion
- 노드 상태: locked/available/completed
- 잠금 해제 애니메이션
- 코스 개요 페이지에 통합

### Phase 10: 마인드맵/지식 그래프 (2일)
- @xyflow/react (ReactFlow) 통합
- 커스텀 노드/엣지 + 자동 레이아웃 (dagre/elk)
- 줌/패닝, 미니맵, 코스별 필터

### Phase 11: 인터랙티브 콘텐츠 (2일)
- 드래그앤드롭 정렬 (@dnd-kit)
- 인터랙티브 비교표
- 빈칸 채우기
- 플래시카드, 타임라인
- MDX 컴포넌트 매핑에 등록

### Phase 12: 프로필 & 마무리 (1일)
- 프로필 페이지 (레벨, 뱃지, 통계)
- 반응형 확인 (모바일 네비게이션)
- 로딩 skeleton, 에러 바운더리
- 메타데이터/SEO

---

## 일정 요약

| Phase | 내용 | 일수 |
|-------|------|------|
| 1 | 초기 설정 | 1 |
| 2 | 인증 & 프로필 | 1 |
| 3 | 코스 & 콘텐츠 | 2 |
| 4 | 진도 추적 | 1.5 |
| 5 | 퀴즈 & 피드백 | 2 |
| 6 | 게이미피케이션 | 1.5 |
| 7 | 간격 반복 | 1 |
| 8 | 대시보드 차트 | 1.5 |
| 9 | 스킬트리 | 2 |
| 10 | 마인드맵 | 2 |
| 11 | 인터랙티브 콘텐츠 | 2 |
| 12 | 마무리 | 1 |
| **합계** | | **~18.5일** |

---

## 리스크

| 리스크 | 대응 |
|--------|------|
| ReactFlow 성능 (노드 많을 때) | 뷰포트 밖 렌더링 생략, 코스별 필터로 노드 수 제한 |
| 스킬트리 자동 레이아웃 노드 겹침 | dagre/elk 레이아웃 엔진, 수동 보정 옵션 |
| Supabase RLS 디버깅 | 정책 단순화, 통합 테스트 |
| XP 레이스 컨디션 | Supabase RPC 트랜잭션 처리 |
| 뮤트 톤 가독성 | WCAG AA 명도비 보장 |

---

## 설계 결정

1. MDX는 파일시스템 기반, DB에는 메타데이터만
2. 스킬트리는 커스텀 SVG (ReactFlow와 분리)
3. XP 부여는 서버 사이드 (치팅 방지)
4. 레벨은 계산값 (total_xp에서 순수 함수로)
5. 지식 그래프 != 스킬트리 (데이터 소스 분리)

---

## 상태: 계획 확정 ✓
## 다음: Phase 1 시작
