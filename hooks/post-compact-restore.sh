#!/bin/bash
# post-compact-restore.sh - PostCompact Hook
# 컴팩 완료 후 핵심 컨텍스트 자동 재주입
# 에이전트가 컴팩 후 빠르게 현재 상황 파악하도록 도움
# exit 0 필수

INPUT=$(cat)

MSG=$(python3 -c "
import sys, json, os

try:
    d = json.loads('$INPUT'.replace(\"'\", '\"')) if '$INPUT' else {}
except:
    d = {}

home = os.path.expanduser('~')
lines = []

# 1. 현재 작업 디렉토리 감지
cwd = os.getcwd()
project = os.path.basename(cwd)

# 2. MEMORY.md 존재 확인 (CWD 기반 프로젝트 메모리 + HOME 메모리)
cwd_slug = cwd.replace('/', '-')
project_memory = os.path.join(home, f'.claude/projects/{cwd_slug}/memory/MEMORY.md')
home_memory = os.path.join(home, '.claude/projects/-Users-gihoonkim/memory/MEMORY.md')

memory_paths = [project_memory, home_memory, os.path.join(cwd, 'CLAUDE.md')]
found_memory = [p for p in memory_paths if os.path.exists(p)]

# 3. 핸드오프 파일 존재 확인 (최신 핸드오프 자동 탐지)
import glob
handoff_dir = os.path.join(home, f'.claude/projects/{cwd_slug}/memory')
handoff_files = sorted(glob.glob(os.path.join(handoff_dir, 'handoff_*.md')), reverse=True)
if not handoff_files:
    handoff_dir_home = os.path.join(home, '.claude/projects/-Users-gihoonkim/memory')
    handoff_files = sorted(glob.glob(os.path.join(handoff_dir_home, 'handoff*.md')), reverse=True)

lines.append(f'[PostCompact] 컴팩 완료 — 프로젝트: {project}')
if found_memory:
    for mp in found_memory:
        lines.append(f'  컨텍스트 복구: {os.path.basename(mp)} 읽기 권장 ({mp})')
if handoff_files:
    hf = handoff_files[0]
    lines.append(f'  최신 핸드오프: {os.path.basename(hf)} 읽기 권장')
lines.append('  /sync 로 전체 컨텍스트 동기화 가능')

print('\n'.join(lines))
" 2>/dev/null)

if [[ -n "$MSG" ]]; then
    echo "$MSG" >&2
fi

exit 0
