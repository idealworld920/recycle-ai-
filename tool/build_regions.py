"""행정표준코드 원본(regions_raw.json, code.go.kr 법정동코드 전체자료에서 추출) → assets/data/regions.json

python3 tool/build_regions.py <regions_raw.json>
- 일반구가 있는 시(수원시 등)는 상위 행만 빼고 "수원시 장안구" 같은 구 단위만 남긴다 (선택 단위 = 실제 배출 기준 단위).
- 시/도 표시용 짧은 이름(short)을 붙인다.
- wasteGuideUrl 은 기존 regions.json 값이 있으면 보존한다 (구청 공식 안내 페이지, 확인된 곳만).
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'assets' / 'data' / 'regions.json'
SHORT = {
    '서울특별시': '서울', '부산광역시': '부산', '대구광역시': '대구', '인천광역시': '인천', '광주광역시': '광주',
    '대전광역시': '대전', '울산광역시': '울산', '세종특별자치시': '세종', '경기도': '경기', '강원특별자치도': '강원',
    '충청북도': '충북', '충청남도': '충남', '전북특별자치도': '전북', '전라남도': '전남', '경상북도': '경북',
    '경상남도': '경남', '제주특별자치도': '제주', '전남광주통합특별시': '전남광주',
}


def main(raw_path: str) -> None:
    raw = json.loads(Path(raw_path).read_text(encoding='utf-8'))
    existing = {}
    if OUT.exists():
        for s in json.loads(OUT.read_text(encoding='utf-8')).get('sido', []):
            for g in s.get('sigungu', []):
                if g.get('wasteGuideUrl'):
                    existing[g['code']] = g['wasteGuideUrl']
    sidos = []
    total = 0
    for s in raw['sido']:
        items = []
        for g in s['sigungu']:
            if g.get('hasGu'):
                continue  # 상위 시는 구 단위로 대체
            item = {'code': g['code'], 'name': g['name']}
            if g['code'] in existing:
                item['wasteGuideUrl'] = existing[g['code']]
            items.append(item)
        items.sort(key=lambda x: x['code'])
        total += len(items)
        sidos.append({'code': s['code'], 'name': s['name'], 'short': SHORT.get(s['name'], s['name']), 'sigungu': items})
    sidos.sort(key=lambda x: x['code'])
    out = {
        'version': 1,
        'source': {
            'name': '행정안전부 행정표준코드관리시스템 법정동코드 (시군구 5자리, 존재 행만)',
            'url': raw['source'].get('url', 'https://www.code.go.kr/stdcode/regCodeL.do'),
            'fetchedAt': raw['source'].get('fetchedAt'),
            'note': raw['source'].get('note', ''),
        },
        'sido': sidos,
    }
    OUT.write_text(json.dumps(out, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    print('wrote', OUT.relative_to(ROOT), f'{len(sidos)} sido / {total} sigungu')


if __name__ == '__main__':
    main(sys.argv[1])
