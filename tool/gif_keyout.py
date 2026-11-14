"""리뿅이 GIF 의 배경(흰색·연회색·검정)을 투명하게 만든다.

python3 tool/gif_keyout.py r_intro r_wink
네 모서리에서 이어진 밝은 영역만 투명 처리하므로 얼굴(흰 눈·입)은 남는다.
"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
DIR = ROOT / 'assets' / 'branding' / 'mascot'
KEY = (255, 0, 255)


def keyout(frame: Image.Image) -> Image.Image:
    rgb = frame.convert('RGB')
    w, h = rgb.size
    for xy in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]:
        px0 = rgb.getpixel(xy)
        # 밝은(흰·연회색) 배경이나 검정 배경 둘 다. 얼굴의 흰 눈·검은 눈매는 파란 몸통 안에 갇혀 있어 안 닿는다.
        if min(px0) > 200 or max(px0) < 40:
            ImageDraw.floodfill(rgb, xy, KEY, thresh=48)
    out = rgb.convert('RGBA')
    px = out.load()
    for y in range(h):
        for x in range(w):
            if px[x, y][:3] == KEY:
                px[x, y] = (0, 0, 0, 0)
    return out


def main(names):
    for name in names:
        path = DIR / f'{name}.gif'
        im = Image.open(path)
        frames, durations = [], []
        for i in range(im.n_frames):
            im.seek(i)
            durations.append(im.info.get('duration', 100))
            rgba = keyout(im.convert('RGBA'))
            # 팔레트 255색 + 투명 인덱스
            alpha = rgba.split()[3]
            p = rgba.convert('RGB').quantize(colors=255, method=Image.Quantize.MEDIANCUT)
            p = p.point(lambda v: v)  # copy
            mask = alpha.point(lambda a: 255 if a < 128 else 0)
            p.paste(255, mask=mask)
            frames.append(p)
        frames[0].save(path, save_all=True, append_images=frames[1:], duration=durations, loop=0, transparency=255, disposal=2, optimize=False)
        print('rewrote', path.relative_to(ROOT), f'{len(frames)} frames')


if __name__ == '__main__':
    main(sys.argv[1:] or ['r_intro', 'r_wink'])
