#!/usr/bin/env python3
"""
KB "완료보고:" 패턴 페이지 전체 검색 → 삭제 (archive)
Notion post-search API 기반 (query-data-source 버그 우회)

사용법:
  python3 kb-cleanup-completionreports.py --dry-run   # 대상 목록 확인
  python3 kb-cleanup-completionreports.py --confirm   # 실제 삭제
"""
import subprocess, json, time, os, sys

TOKEN = os.environ.get('NOTION_API_KEY', '')
KB_DB_ID = '323d1034-8f3f-815b-816d-fb88391f31da'
DELAY_S = 0.35

if not TOKEN:
    print("❌ NOTION_API_KEY 환경변수 미설정")
    sys.exit(1)


def notion_request(method, path, payload=None):
    cmd = ['curl', '-s', f'-X{method.upper()}',
           f'https://api.notion.com/v1{path}',
           '-H', f'Authorization: Bearer {TOKEN}',
           '-H', 'Notion-Version: 2022-06-28',
           '-H', 'Content-Type: application/json']
    if payload:
        cmd += ['-d', json.dumps(payload, ensure_ascii=False)]
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=20)
    return json.loads(r.stdout)


def search_completion_reports(cursor=None):
    """post-search로 '완료보고:' 포함 페이지 조회 (페이지네이션)"""
    payload = {
        'query': '완료보고:',
        'filter': {'value': 'page', 'property': 'object'},
        'page_size': 100
    }
    if cursor:
        payload['start_cursor'] = cursor
    return notion_request('POST', '/search', payload)


def filter_kb_pages(results):
    """검색 결과 중 KB DB 소속이고 제목이 '완료보고:'로 시작하는 페이지만 필터"""
    matched = []
    for p in results:
        if p.get('object') != 'page':
            continue
        parent_db = p.get('parent', {}).get('database_id', '').replace('-', '')
        if parent_db != KB_DB_ID.replace('-', ''):
            continue
        title_arr = p.get('properties', {}).get('제목', {}).get('title', [])
        if not title_arr:
            continue
        plain = title_arr[0].get('plain_text', '')
        if plain.startswith('완료보고:'):
            matched.append({'id': p['id'], 'title': plain})
    return matched


def archive_page(page_id):
    """페이지 archive (소프트 삭제)"""
    return notion_request('PATCH', f'/pages/{page_id}', {'archived': True})


def main(dry_run=False):
    print(f"{'[DRY RUN] ' if dry_run else ''}KB 완료보고 삭제 시작")
    print(f"대상 DB: {KB_DB_ID}")
    print()

    cursor = None
    total_found = 0
    total_deleted = 0

    while True:
        resp = search_completion_reports(cursor)
        results = resp.get('results', [])
        has_more = resp.get('has_more', False)
        cursor = resp.get('next_cursor')

        kb_pages = filter_kb_pages(results)
        total_found += len(kb_pages)

        for page in kb_pages:
            pid = page['id']
            title = page['title']
            print(f"  {'[DRY]' if dry_run else 'DELETE'}: {title[:70]}")

            if not dry_run:
                result = archive_page(pid)
                if result.get('archived'):
                    total_deleted += 1
                else:
                    print(f"    ⚠️ 삭제 실패 — {result.get('message', '?')[:80]}")
                time.sleep(DELAY_S)

        if not has_more:
            break
        time.sleep(DELAY_S)

    print()
    if dry_run:
        print(f"✅ [DRY RUN 완료] 삭제 대상 {total_found}건 발견")
        print("실제 삭제하려면: python3 kb-cleanup-completionreports.py --confirm")
    else:
        print(f"✅ 완료: 발견={total_found} 삭제={total_deleted}")


if __name__ == '__main__':
    dry_run = '--dry-run' in sys.argv
    if not dry_run and '--confirm' not in sys.argv:
        print("사용법:")
        print("  python3 kb-cleanup-completionreports.py --dry-run   # 목록 확인")
        print("  python3 kb-cleanup-completionreports.py --confirm   # 실제 삭제")
        sys.exit(1)
    main(dry_run=dry_run)
