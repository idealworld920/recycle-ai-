"""전국 시군구 wasteGuideUrl 병합.

python3 tool/merge_guide_urls.py <results.json> [--report docs/waste_guide_urls.md]

results.json: {"<시도>|<시군구>": {"codes": [...], "status": "found|fallback|botcheck|unreachable",
                                   "url": "...", "title": "...", "note": "..."}}
- found: 구청 분리배출 안내 페이지(직접 열어 확인) / fallback: 안내 페이지 못 찾아 홈 메인(열림 확인)
- botcheck: 봇 차단 페이지라 안내 페이지 확인 불가 → 홈 메인 / unreachable: 홈도 못 열어 메인 URL 만(미검증)
- 이미 들어 있는 값(서울 25구처럼 앞서 검증한 것)은 덮어쓰지 않는다.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REGIONS = ROOT / 'assets' / 'data' / 'regions.json'
LABEL = {'kept': '안내 페이지(이전 확인)', 'found': '안내 페이지', 'fallback': '메인 폴백', 'botcheck': '메인 폴백(봇 차단)', 'unreachable': '메인(접속 불가, 미검증)', 'empty': '비움'}


def main(argv):
    results = json.loads(Path(argv[1]).read_text(encoding='utf-8'))
    report = Path(argv[argv.index('--report') + 1]) if '--report' in argv else None
    regions = json.loads(REGIONS.read_text(encoding='utf-8'))
    by_code = {c: r for r in results.values() for c in r['codes']}
    rows, counts = [], {}
    for s in regions['sido']:
        for g in s['sigungu']:
            code, existing, r = g['code'], g.get('wasteGuideUrl'), by_code.get(g['code'])
            if existing:
                st, url, note = 'kept', existing, ''
            elif r and r.get('url') and r.get('status') in LABEL:
                st, url, note = r['status'], r['url'], (r.get('note') or r.get('title') or '')[:80]
                g['wasteGuideUrl'] = url
            else:
                st, url, note = 'empty', '', (r or {}).get('note', '조사 결과 없음')
            counts[st] = counts.get(st, 0) + 1
            rows.append((s['name'], g['name'], code, st, url, note))
    REGIONS.write_text(json.dumps(regions, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    print(counts)
    if report:
        L = ['# 시군구 분리배출 안내 URL 현황 (2026-11-12)', '',
             '칸 수는 regions.json 기준(일반구는 시 홈페이지를 공용으로 쓴다). ' + ' · '.join(f'{LABEL[k]} {v}' for k, v in counts.items()), '',
             '## 메인으로 폴백한 지역 (안내 페이지를 못 찾음)', '']
        L += [f'- {a} {b} ({c}): {u} — {n}' for a, b, c, st, u, n in rows if st == 'fallback'] or ['- 없음']
        L += ['', '## 메인으로 폴백한 지역 (봇 차단으로 안내 페이지 확인 불가)', '']
        L += [f'- {a} {b} ({c}): {u}' for a, b, c, st, u, n in rows if st == 'botcheck'] or ['- 없음']
        L += ['', '## 접속하지 못해 메인 URL만 넣은 지역 (미검증)', '']
        L += [f'- {a} {b} ({c}): {u} — {n}' for a, b, c, st, u, n in rows if st == 'unreachable'] or ['- 없음']
        L += ['', '## 비워 둔 지역', '']
        L += [f'- {a} {b} ({c}): {n}' for a, b, c, st, u, n in rows if st == 'empty'] or ['- 없음']
        L += ['', '## 전체 목록', '', '| 시/도 | 시/군/구 | 코드 | 상태 | URL | 비고 |', '|---|---|---|---|---|---|']
        L += [f'| {a} | {b} | {c} | {LABEL[st]} | {u} | {n} |' for a, b, c, st, u, n in rows]
        report.write_text('\n'.join(L) + '\n', encoding='utf-8')
        print('report →', report)


if __name__ == '__main__':
    main(sys.argv)
