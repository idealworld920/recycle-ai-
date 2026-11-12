"""리뿅이 GIF 에서 첫 프레임(인트로는 마지막 프레임)을 PNG 로 뽑는다.

python3 tool/mascot_frames.py
→ assets/branding/mascot/r_*.gif 마다 r_*_static.png 생성 (투명 배경 유지).
공유 카드·알림·"애니메이션 줄이기" 모드에서 이 PNG 를 쓴다.
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
DIR = ROOT / 'assets' / 'branding' / 'mascot'

# 마지막 프레임을 써야 하는 것 (인트로: 끝난 모습에서 멈춘다)
LAST_FRAME = {'r_intro'}

for gif in sorted(DIR.glob('r_*.gif')):
    im = Image.open(gif)
    im.seek(im.n_frames - 1 if gif.stem in LAST_FRAME else 0)
    frame = im.convert('RGBA')
    # 투명 인덱스가 배경으로 깔린 경우 모서리 색을 투명 처리
    bg = frame.getpixel((0, 0))
    if bg[3] == 255:
        px = frame.load()
        w, h = frame.size
        for y in range(h):
            for x in range(w):
                if px[x, y][:3] == bg[:3]:
                    px[x, y] = (0, 0, 0, 0)
    out = gif.with_name(gif.stem + '_static.png')
    frame.save(out, optimize=True)
    print('wrote', out.relative_to(ROOT), frame.size)
