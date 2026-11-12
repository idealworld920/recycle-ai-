"""조사 JSON(들) + tips.json → regionNotes 채움 현황 표(markdown).

python3 tool/region_notes_table.py research1.json research2.json [--exclude 11680:cup_noodle,...] > docs/region_notes_status.md

칸 표기: ✓ 채움 / ✗ 출처가 안내 페이지가 아니라 제외 / – 안내 페이지에 언급 없음 / ⊘ 구청 사이트 접속 불가
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ITEMS = [('cup_noodle', '컵라면 용기'), ('ice_pack', '아이스팩'), ('aseptic_pack', '멸균팩'), ('paper_cup', '종이컵'), ('styrofoam', '스티로폼')]


def main(argv):
    files = [a for a in argv[1:] if not a.startswith('--') and a.endswith('.json')]
    excludes = set()
    if '--exclude' in argv:
        excludes = set(argv[argv.index('--exclude') + 1].split(','))
    research = {}
    for f in files:
        research.update(json.loads(Path(f).read_text(encoding='utf-8')))
    tips = json.loads((ROOT / 'assets/data/tips.json').read_text(encoding='utf-8'))
    regions = json.loads((ROOT / 'assets/data/regions.json').read_text(encoding='utf-8'))
    notes = {t['id']: t.get('regionNotes') or {} for t in tips['items']}
    seoul = next(s for s in regions['sido'] if s['code'] == '11')

    filled = 0
    rows = []
    for g in seoul['sigungu']:
        code, name = g['code'], g['name']
        r = research.get(code, {})
        has_url = bool(g.get('wasteGuideUrl'))
        cells = []
        for item, _ in ITEMS:
            if code in notes.get(item, {}):
                cells.append('✓')
                filled += 1
            elif f'{code}:{item}' in excludes:
                cells.append('✗')
            elif not r:
                cells.append('?')  # 조사 안 함
            elif not has_url and not r.get('wasteGuideUrl'):
                cells.append('⊘')
            else:
                cells.append('–')
        note = ''
        if not r:
            note = '미조사'
        elif not r.get('wasteGuideUrl'):
            note = (r.get('wasteGuideUrlReason') or '접속 불가').split(';')[0][:60]
        else:
            ids = [i for i, _ in ITEMS]
            reasons = {v for k, v in (r.get('itemReasons') or {}).items() if k in ids and cells[ids.index(k)] == '–'}
            if len(reasons) == 1:
                note = next(iter(reasons))[:60]

        rows.append(f'| {name} | ' + ' | '.join(cells) + f' | {"✓" if has_url else "–"} | {note} |')

    total = len(seoul['sigungu']) * len(ITEMS)
    print(f'서울 {len(seoul["sigungu"])}개 구 × {len(ITEMS)}개 품목 = {total}칸 중 **{filled}칸 채움** '
          f'(안내 페이지 URL 확보 {sum(1 for g in seoul["sigungu"] if g.get("wasteGuideUrl"))}/{len(seoul["sigungu"])}개 구)\n')
    print('| 구 | ' + ' | '.join(n for _, n in ITEMS) + ' | 안내 URL | 비고 |')
    print('|---|' + '---|' * (len(ITEMS) + 2))
    print('\n'.join(rows))
    print('\n✓ 채움 · ✗ 구청 사이트에 있으나 분리배출 안내가 아니라 제외(소식지·카드뉴스·사업 공지·재질 예시만) · – 안내 페이지에 해당 품목 언급 없음 · ⊘ 구청 사이트 접속 불가 · ? 미조사. 칸별 원문·사유는 docs/region_notes_evidence.md')


if __name__ == '__main__':
    main(sys.argv)
