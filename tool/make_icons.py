"""ReSAI 로고(쓰레기통 안의 R) 생성기.

python3 tool/make_icons.py
→ assets/store/, web/icons/, web/favicon.png, android mipmap/적응형 아이콘을 모두 다시 만든다.
"""
from PIL import Image, ImageDraw, ImageFont
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GREEN = (22, 163, 74)
WHITE = (255, 255, 255)
INK = (17, 17, 17)
MUTED = (107, 107, 107)
BOLD = os.path.join(ROOT, 'assets/fonts/Pretendard-Bold.otf')
SEMI = os.path.join(ROOT, 'assets/fonts/Pretendard-SemiBold.otf')
REG = os.path.join(ROOT, 'assets/fonts/Pretendard-Regular.otf')
SS = 4  # 슈퍼샘플링 배율


def bin_mark(size, fg=WHITE, bg=GREEN, scale=1.0):
    """투명 배경 위에 쓰레기통 + 안쪽에 R(배경색으로 뚫림). [scale] 로 마크 크기 조절."""
    S = size * SS
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    u = S * scale  # 마크가 차지하는 한 변
    ox = (S - u) / 2
    oy = (S - u) / 2
    r = u * 0.04
    # 손잡이
    hw, hh = u * 0.22, u * 0.07
    d.rounded_rectangle([ox + (u - hw) / 2, oy + u * 0.09, ox + (u + hw) / 2, oy + u * 0.09 + hh], radius=r, fill=fg)
    # 뚜껑
    lw, lh = u * 0.74, u * 0.11
    d.rounded_rectangle([ox + (u - lw) / 2, oy + u * 0.15, ox + (u + lw) / 2, oy + u * 0.15 + lh], radius=r, fill=fg)
    # 몸통 (아래로 살짝 좁아지는 사다리꼴 + 둥근 아래 모서리)
    top, bottom = oy + u * 0.30, oy + u * 0.90
    tw, bw = u * 0.62, u * 0.52
    body = [
        (ox + (u - tw) / 2, top), (ox + (u + tw) / 2, top),
        (ox + (u + bw) / 2, bottom), (ox + (u - bw) / 2, bottom),
    ]
    d.polygon(body, fill=fg)
    # 아래 모서리 둥글게: 바닥 캡슐
    d.rounded_rectangle([ox + (u - bw) / 2, bottom - u * 0.08, ox + (u + bw) / 2, bottom], radius=u * 0.05, fill=fg)
    # 안쪽 R (배경색으로)
    f = ImageFont.truetype(BOLD, int(u * 0.40))
    b = d.textbbox((0, 0), 'R', font=f, anchor='lt')
    w, h = b[2] - b[0], b[3] - b[1]
    cx = ox + u / 2
    cy = (top + bottom) / 2 + u * 0.005
    d.text((cx - w / 2 - b[0], cy - h / 2 - b[1]), 'R', font=f, fill=bg, anchor='lt')
    return img.resize((size, size), Image.LANCZOS)


def tile(size, radius_ratio, mark_scale=0.78):
    """초록 타일 + 마크."""
    S = size * SS
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if radius_ratio > 0:
        d.rounded_rectangle([0, 0, S - 1, S - 1], radius=int(S * radius_ratio), fill=GREEN)
    else:
        d.rectangle([0, 0, S, S], fill=GREEN)
    img = img.resize((size, size), Image.LANCZOS)
    m = bin_mark(size, scale=mark_scale)
    img.alpha_composite(m)
    return img


def save(img, rel, mode='RGBA'):
    path = os.path.join(ROOT, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    (img.convert(mode)).save(path, optimize=True)
    print('wrote', rel, img.size)


def main():
    # 스토어
    save(tile(512, 0), 'assets/store/icon_512.png', 'RGB')
    # 피처 그래픽
    fg = Image.new('RGB', (1024, 500), WHITE)
    d = ImageDraw.Draw(fg)
    t = tile(220, 0.22)
    fg.paste(t, (96, 140), t)
    x = 372
    d.text((x, 150), 'ReSAI', font=ImageFont.truetype(BOLD, 84), fill=INK)
    d.text((x, 258), '찍으면 알려주는 AI 분리수거', font=ImageFont.truetype(SEMI, 40), fill=INK)
    d.text((x, 318), '사진 한 장이면 어디에 버릴지, 뭘 떼야 하는지 바로.', font=ImageFont.truetype(REG, 26), fill=MUTED)
    fchip = ImageFont.truetype(SEMI, 22)
    cx, cy = x, 380
    for c in ['사진 분류', '수거일 알림', '가족 공유']:
        b = d.textbbox((0, 0), c, font=fchip, anchor='lt')
        w = b[2] - b[0]
        d.rounded_rectangle([cx, cy, cx + w + 36, cy + 44], radius=22, fill=(247, 247, 248))
        d.text((cx + 18, cy + 10), c, font=fchip, fill=INK, anchor='lt')
        cx += w + 36 + 12
    save(fg, 'assets/store/feature_graphic_1024x500.png', 'RGB')

    # 웹
    save(tile(192, 0.22), 'web/icons/Icon-192.png')
    save(tile(512, 0.22), 'web/icons/Icon-512.png')
    save(tile(192, 0, 0.6), 'web/icons/Icon-maskable-192.png')
    save(tile(512, 0, 0.6), 'web/icons/Icon-maskable-512.png')
    save(tile(64, 0.22).resize((32, 32), Image.LANCZOS), 'web/favicon.png')

    # 안드로이드 런처 (레거시 정사각 + 적응형)
    legacy = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
    for dpi, px in legacy.items():
        save(tile(px, 0.18), f'android/app/src/main/res/mipmap-{dpi}/ic_launcher.png')
    # 적응형: 108dp 중 안전 영역 66dp → 마크는 캔버스의 약 0.56
    fgsize = {'mdpi': 108, 'hdpi': 162, 'xhdpi': 216, 'xxhdpi': 324, 'xxxhdpi': 432}
    for dpi, px in fgsize.items():
        save(bin_mark(px, scale=0.50), f'android/app/src/main/res/mipmap-{dpi}/ic_launcher_foreground.png')
    xml_dir = os.path.join(ROOT, 'android/app/src/main/res/mipmap-anydpi-v26')
    os.makedirs(xml_dir, exist_ok=True)
    for name in ['ic_launcher', 'ic_launcher_round']:
        with open(os.path.join(xml_dir, f'{name}.xml'), 'w') as f:
            f.write('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
    <monochrome android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
''')
    colors = os.path.join(ROOT, 'android/app/src/main/res/values/colors.xml')
    s = open(colors).read()
    if 'ic_launcher_background' not in s:
        s = s.replace('</resources>', '    <color name="ic_launcher_background">#16A34A</color>\n</resources>')
        open(colors, 'w').write(s)
    print('ok')


if __name__ == '__main__':
    main()
