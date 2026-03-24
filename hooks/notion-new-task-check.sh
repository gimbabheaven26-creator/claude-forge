#!/bin/bash
# notion-new-task-check.sh - UserPromptSubmit Hook
# 카이란이 메세지 보낼 때 노션 새 태스크 확인 (10분 쿨다운)
# 지니가 Discord에서 생성한 태스크를 실시간에 가깝게 감지
# exit 0 필수

INPUT=$(cat)

export NOTION_KEY="$(cat ~/.config/notion/api_key 2>/dev/null)"
export TASK_DB="323d10348f3f8121b20ef0396dbe1c66"
export CURRENT_DIR="$(pwd)"

if [ -z "$NOTION_KEY" ]; then
    exit 0
fi

echo "$INPUT" | python3 -c "
import sys, json, os, time, urllib.request

try:
    d = json.load(sys.stdin)
except:
    sys.exit(0)

sid = d.get('session_id', '')
if not sid:
    sys.exit(0)

# 쿨다운 체크 (10분 = 600초)
cooldown_file = f'/tmp/notion-check-{sid}'
now = time.time()
if os.path.exists(cooldown_file):
    try:
        last_check = float(open(cooldown_file).read().strip())
        if now - last_check < 600:
            sys.exit(0)
    except:
        pass

# 쿨다운 갱신
with open(cooldown_file, 'w') as f:
    f.write(str(now))

api_key = os.environ.get('NOTION_KEY', '')
task_db = os.environ.get('TASK_DB', '')
cwd = os.environ.get('CURRENT_DIR', '')
if not api_key or not task_db:
    sys.exit(0)

# CWD → 에이전트 매핑 (1:1)
cwd_agent_map = {
    'special-education-web': ['강선생'],
    'edumind': ['안선생'],
    'untitled': ['안선생'],
    'gosari-namu-path': ['스미스'],
}
my_agents = []
for project_dir, agents in cwd_agent_map.items():
    if project_dir in cwd:
        my_agents = agents
        break
if not my_agents:
    home = os.path.expanduser('~')
    if cwd == home or cwd == home + '/':
        my_agents = ['클루디', '스미스 프라임']

# 마지막 확인 이후 생성된 태스크만 조회
# SessionStart 때 이미 본 태스크 제외하기 위해 세션 시작 시각 기록 확인
session_start_file = f'/tmp/notion-session-start-{sid}'
if not os.path.exists(session_start_file):
    # 첫 체크 — 세션 시작 시각 기록
    with open(session_start_file, 'w') as f:
        from datetime import datetime, timezone, timedelta
        kst = timezone(timedelta(hours=9))
        f.write(datetime.now(kst).isoformat())
    sys.exit(0)

session_start_iso = open(session_start_file).read().strip()

# 노션 쿼리: TODO/진행중 + 세션 시작 이후 생성된 것만
try:
    url = f'https://api.notion.com/v1/databases/{task_db}/query'
    payload = json.dumps({
        'filter': {
            'and': [
                {'or': [
                    {'property': '상태', 'select': {'equals': 'TODO'}},
                    {'property': '상태', 'select': {'equals': '진행중'}}
                ]},
                {'timestamp': 'created_time', 'created_time': {'after': session_start_iso}}
            ]
        }
    }).encode()

    req = urllib.request.Request(url, data=payload, method='POST')
    req.add_header('Authorization', f'Bearer {api_key}')
    req.add_header('Notion-Version', '2022-06-28')
    req.add_header('Content-Type', 'application/json')

    with urllib.request.urlopen(req, timeout=5) as resp:
        data = json.loads(resp.read())
except:
    sys.exit(0)

results = data.get('results', [])
if not results:
    sys.exit(0)

# 이미 알린 태스크 건너뛰기
notified_file = f'/tmp/notion-notified-{sid}'
notified_ids = set()
if os.path.exists(notified_file):
    notified_ids = set(open(notified_file).read().strip().split('\\n'))

new_tasks = []
for r in results:
    if r['id'] in notified_ids:
        continue

    props = r.get('properties', {})
    title = ''
    for p in props.values():
        if p.get('type') == 'title':
            title = ''.join([t.get('plain_text', '') for t in p.get('title', [])])
            break

    assignee = ''
    assignee_prop = props.get('담당', {})
    if assignee_prop.get('type') == 'select':
        sel = assignee_prop.get('select')
        if sel:
            assignee = sel.get('name', '')

    if title:
        # 내 담당이거나 에이전트 미식별이면 표시
        if not my_agents or assignee in my_agents:
            new_tasks.append((r['id'], title, assignee))

if new_tasks:
    # 알림 ID 기록
    with open(notified_file, 'a') as f:
        for tid, _, _ in new_tasks:
            f.write(tid + '\\n')

    # 출력
    lines = []
    for _, title, assignee in new_tasks:
        assign_str = f' ({assignee})' if assignee else ''
        lines.append(f'  🆕 {title}{assign_str}')

    msg = f'[새 태스크 감지] {len(new_tasks)}건 — 지니 또는 다른 세션에서 생성됨:\\n' + '\\n'.join(lines)
    print(msg, file=sys.stderr)
" 2>&1

exit 0
