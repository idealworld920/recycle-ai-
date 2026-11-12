"""조사 결과(JSON) → tips.json regionNotes / regions.json wasteGuideUrl / docs/region_notes_evidence.md

python3 tool/merge_region_notes.py <research.json> [--exclude 11680:cup_noodle,11680:ice_pack ...]

- 조사 JSON 의 각 칸은 {note, sourceUrl, quote, verifiedAt, caveat?}. 출처 URL 없는 칸은 절대 넣지 않는다.
- --exclude 로 "안내 페이지가 아닌 출처" 등 사람이 검토해서 뺀 칸을 지정한다 (근거는 evidence 문서에 남긴다).
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TIPS = ROOT / 'assets' / 'data' / 'tips.json'
REGIONS = ROOT / 'assets' / 'data' / 'regions.json'
EVIDENCE = ROOT / 'docs' / 'region_notes_evidence.md'
ITEM_TO_TIP = {'cup_noodle': 'cup_noodle', 'ice_pack': 'ice_pack', 'aseptic_pack': 'aseptic_pack', 'paper_cup': 'paper_cup', 'styrofoam': 'styrofoam'}


def main(argv):
    src = Path(argv[1])
    excludes = set()
    if '--exclude' in argv:
        excludes = set(argv[argv.index('--exclude') + 1].split(','))
    research = json.loads(src.read_text(encoding='utf-8'))
    tips = json.loads(TIPS.read_text(encoding='utf-8'))
    regions = json.loads(REGIONS.read_text(encoding='utf-8'))
    by_tip = {t['id']: t for t in tips['items']}
    code_to_name = {g['code']: g['name'] for s in regions['sido'] for g in s['sigungu']}

    added, guides = 0, 0
    lines = [f'\n## {src.name} 병합 ({research and list(research.values())[0].get("items", {}) and "2026-11-12"})\n']
    for code, g in research.items():
        name = g.get('name') or code_to_name.get(code, code)
        url = g.get('wasteGuideUrl')
        if url and url.startswith('https://'):
            for s in regions['sido']:
                for gg in s['sigungu']:
                    if gg['code'] == code:
                        gg['wasteGuideUrl'] = url
                        guides += 1
        lines.append(f'\n### {name} ({code})\n- 안내 페이지: {url or "없음"} {("— " + g.get("wasteGuideUrlReason", "")) if not url else ""}\n')
        for item, cell in (g.get('items') or {}).items():
            tip_id = ITEM_TO_TIP[item]
            key = f'{code}:{item}'
            reason = (g.get('itemReasons') or {}).get(item, '')
            if not cell:
                lines.append(f'- {tip_id}: 비움 — {reason or "언급 없음"}')
                continue
            if key in excludes:
                lines.append(f'- {tip_id}: **제외(검토)** — 출처가 분리배출 안내 페이지가 아님 ({cell.get("caveat", "")}). 원문: "{cell.get("quote", "")}" <{cell.get("sourceUrl", "")}>')
                continue
            if not cell.get('sourceUrl', '').startswith('https://') or not cell.get('note'):
                lines.append(f'- {tip_id}: 비움 — sourceUrl 또는 note 없음')
                continue
            by_tip[tip_id].setdefault('regionNotes', {})[code] = {
                'note': cell['note'].strip(),
                'sourceUrl': cell['sourceUrl'].strip(),
                'verifiedAt': cell.get('verifiedAt', '2026-11-12'),
            }
            added += 1
            cav = f' (주의: {cell["caveat"]})' if cell.get('caveat') else ''
            lines.append(f'- {tip_id}: ✓ "{cell["note"]}"{cav}\n  - 원문: "{cell.get("quote", "")}"\n  - 출처: {cell["sourceUrl"]} (확인 {cell.get("verifiedAt", "")})')

    TIPS.write_text(json.dumps(tips, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    REGIONS.write_text(json.dumps(regions, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    if not EVIDENCE.exists():
        EVIDENCE.write_text('# 지역 노트 근거 기록\n\n각 칸의 원문 인용과 출처. tips.json 의 regionNotes 는 이 문서의 ✓ 항목만 반영한다.\n', encoding='utf-8')
    with EVIDENCE.open('a', encoding='utf-8') as f:
        f.write('\n'.join(lines) + '\n')
    print(f'notes added: {added}, guide urls: {guides}; evidence → {EVIDENCE.relative_to(ROOT)}')


if __name__ == '__main__':
    main(sys.argv)
