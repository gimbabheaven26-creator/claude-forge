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

# 2. MEMORY.md 존재 확인
memory_paths = [
    os.path.join(home, '.claude/projects/-Users-gihoonkim/memory/MEMORY.md'),
    os.path.join(cwd, 'CLAUDE.md'),
]

found_memory = [p for p in memory_paths if os.path.exists(p)]

# 3. 핸드오프 파일 존재 확인
handoff_paths = [
    os.path.join(home, '.claude/projects/-Users-gihoonkim/memory/handoff-smith-prime.md'),
    os.path.join(cwd, 'docs/sprint-beta-prep.md'),
]
found_handoff = [p for p in handoff_paths if os.path.exists(p)]

lines.append(f'[PostCompact] 컴팩 완료 — 프로젝트: {project}')
if found_memory:
    lines.append(f'  컨텍스트 복구: MEMORY.md 읽기 권장')
if found_handoff:
    hf = os.path.basename(found_handoff[0])
    lines.append(f'  핸드오프 확인: {hf} 읽기 권장')
lines.append('  /sync 로 전체 컨텍스트 동기화 가능')

print('\n'.join(lines))
" 2>/dev/null)

if [[ -n "$MSG" ]]; then
    echo "$MSG" >&2
fi

exit 0
