#!/bin/bash
# notion-pending-poster.sh - Stop Hook (v2 — destination 라우팅)
# ~/.claude/notion-pending.json이 존재하면 자동으로 Notion에 POST
# destination 필드로 DB 라우팅: "sprint" → 스프린트 로그 DB, 기본값 → 지식 베이스 DB
# 에이전트는 이 파일에 기록 내용을 쓰기만 하면 됨 — MCP 호출 불필요
# exit 0 필수 (세션 방해 금지)

PENDING_FILE="$HOME/.claude/notion-pending.json"

if [[ ! -f "$PENDING_FILE" ]]; then
    exit 0
fi

python3 << 'PYEOF'
import json, os, subprocess, sys
from datetime import datetime, timezone, timedelta

pending_file = os.path.expanduser("~/.claude/notion-pending.json")
token = os.environ.get("NOTION_API_KEY", "")

# DB 라우팅 (destination 필드)
KB_DB_ID     = "323d1034-8f3f-815b-816d-fb88391f31da"  # 지식 베이스 DB
SPRINT_DB_ID = "32dd1034-8f3f-8103-ae65-d4fda63c4bae"  # 스프린트 로그 DB

try:
    with open(pending_file) as f:
        data = json.load(f)
except Exception as e:
    sys.exit(0)

destination = data.get("destination", "kb")  # "sprint" 또는 "kb"(기본값)
db_id = SPRINT_DB_ID if destination == "sprint" else KB_DB_ID

title = data.get("title", "무제")
content = data.get("content", "")
tags = data.get("tags", [])
notion_type = data.get("type", "세션기록")

kst = timezone(timedelta(hours=9))
today = datetime.now(kst).strftime("%Y-%m-%d")

# 속성 구성 (destination별 분기)
properties = {
    "제목": {"title": [{"text": {"content": title[:2000]}}]},
    "날짜": {"date": {"start": today}},
}

if destination == "sprint":
    # 스프린트 로그 전용 속성
    agent = data.get("agent", "")
    commit = data.get("commit", "")
    sprint_status = data.get("status", "완료")
    if agent:
        properties["에이전트"] = {"select": {"name": agent}}
    properties["상태"] = {"select": {"name": sprint_status}}
    if commit:
        properties["커밋"] = {"rich_text": [{"text": {"content": commit[:2000]}}]}
    if tags:
        properties["태그"] = {"multi_select": [{"name": t} for t in tags[:10]]}
else:
    # 지식 베이스 전용 속성
    properties["유형"] = {"select": {"name": notion_type}}
    if tags:
        properties["태그"] = {"multi_select": [{"name": t} for t in tags[:10]]}

# 본문 블록 변환 (마크다운 기본 지원)
children = []
for line in content.split("\n"):
    if len(children) >= 95:  # Notion API 한 번에 최대 100블록
        break
    stripped = line.rstrip()
    if not stripped:
        children.append({"object": "block", "type": "paragraph",
                         "paragraph": {"rich_text": []}})
    elif stripped.startswith("## "):
        children.append({"object": "block", "type": "heading_2",
                         "heading_2": {"rich_text": [{"text": {"content": stripped[3:2003]}}]}})
    elif stripped.startswith("### "):
        children.append({"object": "block", "type": "heading_3",
                         "heading_3": {"rich_text": [{"text": {"content": stripped[4:2004]}}]}})
    elif stripped.startswith("- ") or stripped.startswith("* "):
        children.append({"object": "block", "type": "bulleted_list_item",
                         "bulleted_list_item": {"rich_text": [{"text": {"content": stripped[2:2002]}}]}})
    elif stripped.startswith("✅") or stripped.startswith("⚠️") or stripped.startswith("❌"):
        children.append({"object": "block", "type": "bulleted_list_item",
                         "bulleted_list_item": {"rich_text": [{"text": {"content": stripped[:2000]}}]}})
    else:
        children.append({"object": "block", "type": "paragraph",
                         "paragraph": {"rich_text": [{"text": {"content": stripped[:2000]}}]}})

payload = {
    "parent": {"database_id": db_id},
    "properties": properties
}
if children:
    payload["children"] = children

result = subprocess.run(
    ["curl", "-s", "-X", "POST",
     "https://api.notion.com/v1/pages",
     "-H", f"Authorization: Bearer {token}",
     "-H", "Content-Type: application/json",
     "-H", "Notion-Version: 2022-06-28",
     "-d", json.dumps(payload, ensure_ascii=False)
    ],
    capture_output=True, text=True, timeout=20
)

discord_token = os.environ.get("DISCORD_BOT_TOKEN", "")
discord_channel = "1480223000799215697"  # dev-log

def send_discord(msg):
    try:
        subprocess.run(
            ["curl", "-s", "-X", "POST",
             f"https://discord.com/api/v10/channels/{discord_channel}/messages",
             "-H", f"Authorization: Bot {discord_token}",
             "-H", "Content-Type: application/json",
             "-d", json.dumps({"content": msg}, ensure_ascii=False)
            ],
            capture_output=True, text=True, timeout=10
        )
    except:
        pass

try:
    resp = json.loads(result.stdout)
    if resp.get("object") == "page":
        page_url = resp.get("url", "")
        os.remove(pending_file)
        # Discord 알림
        agent_name = data.get("agent", tags[0] if tags else "에이전트")
        dest_label = "스프린트 로그" if destination == "sprint" else "지식 베이스"
        send_discord(f"📋 **{agent_name}** 완료 보고\n> {title}\n> 노션 {dest_label}에 기록됨. 확인 후 다음 세션 열어주세요.")
        print(json.dumps({
            "continue": True,
            "systemMessage": f"✅ [노션 자동 기록 완료] '{title}' {dest_label} 등록 + Discord dev-log 알림 전송."
        }))
    else:
        err = resp.get("message", str(resp))[:200]
        print(json.dumps({
            "continue": True,
            "systemMessage": f"⚠️ [노션 기록 실패] {err} — ~/.claude/notion-pending.json 유지됨."
        }))
except Exception as e:
    print(json.dumps({
        "continue": True,
        "systemMessage": f"⚠️ [노션 기록 실패] 응답 파싱 오류: {str(e)[:100]} — pending 파일 유지됨."
    }))

PYEOF

exit 0
