---
description: 3+파일 변경 또는 아키텍처 변경 전 구현 계획 수립. 체크리스트+단계별 접근법 생성. 단순 1-2파일 수정이면 바로 구현.
---

# Plan Command

This command invokes the **planner** agent to create a comprehensive implementation plan before writing any code.

## What This Command Does

1. **Restate Requirements** - Clarify what needs to be built
2. **Identify Risks** - Surface potential issues and blockers
3. **Create Step Plan** - Break down implementation into phases
4. **Wait for Confirmation** - MUST receive user approval before proceeding

## When to Use

Use `/plan` when:
- Starting a new feature
- Making significant architectural changes
- Working on complex refactoring
- Multiple files/components will be affected
- Requirements are unclear or ambiguous

## How It Works

The planner agent will:

1. **Analyze the request** and restate requirements in clear terms
2. **Break down into phases** with specific, actionable steps
3. **Identify dependencies** between components
4. **Assess risks** and potential blockers
5. **Estimate complexity** (High/Medium/Low)
6. **Present the plan** and WAIT for your explicit confirmation

## Example Usage

```
User: /plan I need to add real-time notifications when markets resolve

Agent (planner):
# Implementation Plan: Real-Time Market Resolution Notifications

## Requirements Restatement
- Send notifications to users when markets they're watching resolve
- Support multiple notification channels (in-app, email, webhook)
- Ensure notifications are delivered reliably
- Include market outcome and user's position result

## Implementation Phases

### Phase 1: Database Schema
- Add notifications table with columns: id, user_id, market_id, type, status, created_at
- Add user_notification_preferences table for channel preferences
- Create indexes on user_id and market_id for performance

### Phase 2: Notification Service
- Create notification service in lib/notifications.ts
- Implement notification queue using BullMQ/Redis
- Add retry logic for failed deliveries
- Create notification templates

### Phase 3: Integration Points
- Hook into market resolution logic (when status changes to "resolved")
- Query all users with positions in market
- Enqueue notifications for each user

### Phase 4: Frontend Components
- Create NotificationBell component in header
- Add NotificationList modal
- Implement real-time updates via Supabase subscriptions
- Add notification preferences page

## Dependencies
- Redis (for queue)
- Email service (SendGrid/Resend)
- Supabase real-time subscriptions

## Risks
- HIGH: Email deliverability (SPF/DKIM required)
- MEDIUM: Performance with 1000+ users per market
- MEDIUM: Notification spam if markets resolve frequently
- LOW: Real-time subscription overhead

## Estimated Complexity: MEDIUM
- Backend: 4-6 hours
- Frontend: 3-4 hours
- Testing: 2-3 hours
- Total: 9-13 hours

**WAITING FOR CONFIRMATION**: Proceed with this plan? (yes/no/modify)
```

## Completion Contract (필수)

**모든 /plan 출력에는 Completion Contract가 포함되어야 한다.** 이것은 V(평가자)가 검증에 사용하는 객관적 기준이다.

### 작성 규칙

1. **"무엇을 만들지"와 "어떻게 만들지"를 분리한다**
   - `## Requirements` = "무엇" — 사용자 스토리, 기능 요구사항, UX 기대
   - `## Implementation Phases` = "어떻게" — 기술 세부는 X(구현자)가 결정
   - Planner(카이란)는 "무엇"에 집중. 테이블명, API 라우트 같은 기술 세부는 X에게 위임

2. **Completion Contract 섹션을 반드시 포함한다**

```
## Completion Contract

V(평가자)가 이 기준으로 PASS/FAIL을 판정한다. 80% 이상 통과해야 PASS.

### 기능 기준
- [ ] 북마크 버튼 클릭 시 저장된다
- [ ] 재클릭 시 해제된다
- [ ] 북마크 목록 페이지가 존재한다

### UX 기준
- [ ] 로딩 중 스켈레톤이 표시된다
- [ ] 빈 상태 안내 메시지가 있다
- [ ] 0건→1건 전환 시 자연스럽다

### 접근성 기준
- [ ] 모든 버튼에 aria-label이 있다
- [ ] 키보드만으로 조작 가능하다
- [ ] 스크린리더로 상태 변화를 인지할 수 있다

### 보안 기준
- [ ] 인증 없이 타인의 북마크 접근 불가
- [ ] XSS 벡터 없음
```

3. **기준은 V가 검증 가능한 형태로 작성한다**
   - "감성 설계가 좋아야 한다" (X) → "0% 점수 시 격려 메시지 표시, 100% 시 축하 메시지 표시" (O)
   - "성능이 좋아야 한다" (X) → "목록 100건 로딩 시 2초 이내" (O)

## Important Notes

**CRITICAL**: The planner agent will **NOT** write any code until you explicitly confirm the plan with "yes" or "proceed" or similar affirmative response.

If you want changes, respond with:
- "modify: [your changes]"
- "different approach: [alternative]"
- "skip phase 2 and do phase 3 first"

## Integration with Other Commands

After planning:
- Use `/tdd` to implement with test-driven development
- Use `/build-and-fix` if build errors occur
- Use `/code-review` to review completed implementation

## Related Agents

This command invokes the `planner` agent located at:
`~/.claude/agents/planner.md`

---

## 후처리: 계획 저장

사용자가 계획을 확인하면, 확정된 계획을 `prompt_plan.md`에 저장한다:
1. 프로젝트 루트의 `prompt_plan.md`에 계획 내용을 기록
2. 기존 `prompt_plan.md`가 있으면 이전 내용을 "## 이전 계획" 섹션으로 아카이브 후 덮어쓰기
3. 저장 후 안내: "계획이 prompt_plan.md에 저장되었습니다."

이렇게 하면 다음 세션에서 `/sync`로 계획을 불러올 수 있다.

## 다음 단계

| 계획이 확정되면 | 커맨드 |
|:---------------|:-------|
| 테스트하면서 구현 | `/tdd` |
| 한 번에 자동 실행 | `/auto` |
| 문서 동기화 | `/sync` (다른 세션에서 이어서 작업 시) |
