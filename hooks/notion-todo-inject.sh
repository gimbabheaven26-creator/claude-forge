#!/bin/bash
# notion-todo-inject.sh - SessionStart Hook
# 노션 작업 관리 DB에서 TODO/진행중 태스크를 가져와 세션 시작 시 주입
# CWD 기반 에이전트 식별 → 담당별 필터링 (강선생 제안 반영)
# exit 0 필수

INPUT=$(cat)

export NOTION_KEY="$(cat ~/.config/notion/api_key 2>/dev/null)"
export TASK_DB="323d10348f3f8121b20ef0396dbe1c66"
export CURRENT_DIR="$(pwd)"

if [ -z "$NOTION_KEY" ]; then
    exit 0
fi

MSG=$(echo "$INPUT" | python3 -c "
import sys, json, os, urllib.request

try:
    d = json.load(sys.stdin)
except:
    sys.exit(0)

api_key = os.environ.get('NOTION_KEY', '')
task_db = os.environ.get('TASK_DB', '')
cwd = os.environ.get('CURRENT_DIR', '')
if not api_key or not task_db:
    sys.exit(0)

# CWD → 에이전트 매핑 (1:1)
# 프론트엔드 3명: 각자 프로젝트 전담
# 클루디: 크로스 프로젝트 데이터/인프라 (홈 디렉토리)
# 스미스 프라임: 전략 (홈 디렉토리)
cwd_agent_map = {
    'special-education-web': ['강선생'],
    'edumind': ['안선생'],
    'untitled': ['안선생'],
    'gosari-namu-path': ['스미스'],
}

# CWD에서 프로젝트 디렉토리 감지
my_agents = []
for project_dir, agents in cwd_agent_map.items():
    if project_dir in cwd:
        my_agents = agents
        break

# 홈 디렉토리 → 클루디 또는 스미스 프라임
if not my_agents:
    home = os.path.expanduser('~')
    if cwd == home or cwd == home + '/':
        my_agents = ['클루디', '스미스 프라임']

# 노션 작업 관리 DB 쿼리 — TODO 또는 진행중인 태스크만
try:
    url = f'https://api.notion.com/v1/databases/{task_db}/query'
    payload = json.dumps({
        'filter': {
            'or': [
                {'property': '상태', 'select': {'equals': 'TODO'}},
                {'property': '상태', 'select': {'equals': '진행중'}}
            ]
        },
        'sorts': [
            {'property': '상태', 'direction': 'ascending'}
        ]
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

my_lines = []
other_lines = []

for r in results:
    props = r.get('properties', {})

    # 제목 추출
    title = ''
    for p in props.values():
        if p.get('type') == 'title':
            title = ''.join([t.get('plain_text', '') for t in p.get('title', [])])
            break

    # 상태 추출
    status = ''
    status_prop = props.get('상태', {})
    if status_prop.get('type') == 'select':
        sel = status_prop.get('select')
        if sel:
            status = sel.get('name', '')

    # 담당 추출
    assignee = ''
    assignee_prop = props.get('담당', {})
    if assignee_prop.get('type') == 'select':
        sel = assignee_prop.get('select')
        if sel:
            assignee = sel.get('name', '')

    if not title:
        continue

    mark = '🔵' if status == '진행중' else '⚪'
    assign_str = f' ({assignee})' if assignee else ''
    line = f'  {mark} {title}{assign_str} [{status}]'

    # 에이전트 필터링
    if my_agents and assignee in my_agents:
        my_lines.append(line)
    else:
        other_lines.append(line)

# 출력: 내 태스크 우선, 나머지는 접어서
if my_agents:
    agent_name = '/'.join(my_agents)
    if my_lines:
        print(f'[Notion TODO] {agent_name} 담당 {len(my_lines)}건:')
        print('\\n'.join(my_lines))
    else:
        print(f'[Notion TODO] {agent_name} 담당 태스크 없음')
    if other_lines:
        print(f'  --- 다른 에이전트 {len(other_lines)}건 ---')
        for ol in other_lines[:3]:
            print(ol)
        if len(other_lines) > 3:
            print(f'  ... 외 {len(other_lines)-3}건')
else:
    # 에이전트 식별 불가 → 전체 표시
    all_lines = my_lines + other_lines
    if all_lines:
        print(f'[Notion TODO] 미완료 태스크 {len(all_lines)}건:')
        print('\\n'.join(all_lines))
" 2>/dev/null)

if [[ -n "$MSG" ]]; then
    echo "$MSG" >&2
fi

exit 0
