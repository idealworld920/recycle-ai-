"""ReSAI 앱 아이콘 파생 파일 생성기.

원본: assets/branding/app_icon_source.png (둥근 사각 파란 배경 + 흰 쓰레기통·R·뚜껑).
python3 tool/make_icons.py
→ android mipmap(레거시+적응형 foreground), web/icons, web/favicon.png, assets/store/icon_512.png,
  assets/store/feature_graphic_1024x500.png, assets/branding/logo_192.png(스플래시), assets/branding/app_icon_128.png(공유 카드)

모든 파생본은 원본 해상도에서 바로 LANCZOS 축소한다 (작은 파일 재확대 금지).
배경색은 브랜드 #2563EB 로 통일한다 (원본 PNG 자체는 손대지 않는다).
"""
from PIL import Image, ImageDraw, ImageFont
import math
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'assets/branding/app_icon_source.png')
BRAND = (37, 99, 235)  # #2563EB (primary)
BRAND_HEX = '#2563EB'
WHITE = (255, 255, 255)
INK = (17, 17, 17)
MUTED = (107, 107, 107)
BOLD = os.path.join(ROOT, 'assets/fonts/Pretendard-Bold.otf')
SEMI = os.path.join(ROOT, 'assets/fonts/Pretendard-SemiBold.otf')
REG = os.path.join(ROOT, 'assets/fonts/Pretendard-Regular.otf')


class Source:
    """원본에서 (1) 타일 영역·모서리 반지름 (2) 흰 요소 알파 스프라이트를 뽑는다."""

    def __init__(self, path):
        im = Image.open(path).convert('RGB')
        r, g, b = im.split()
        # 파랑 배경은 R 채널이 거의 0, 흰색은 255 → R 채널이 곧 '흰 정도'
        white = r.point(lambda v: max(0, min(255, int((v - 8) * 255 / (246 - 8)))))
        blue = Image.eval(white, lambda v: 255 - v)
        bbox = blue.getbbox()  # 타일(파란 영역) 경계
        self.tile_box = bbox
        l, t, rgt, btm = bbox
        self.tile_w, self.tile_h = rgt - l, btm - t
        # 모서리 반지름: 좌상단 코너의 흰 픽셀 넓이 = r^2 (1 - pi/4)
        q = min(self.tile_w, self.tile_h) // 4
        corner = white.crop((l, t, l + q, t + q))
        area = sum(corner.get_flattened_data() if hasattr(corner, 'get_flattened_data') else corner.getdata()) / 255
        self.radius = math.sqrt(area / (1 - math.pi / 4))
        # 타일 안쪽의 흰 요소만 (코너 바깥 흰색 제거)
        # 타일 경계의 안티앨리어싱 픽셀(연파랑)이 요소로 잡히지 않게 경계를 안쪽으로 조금 줄인다
        inset = max(6, self.tile_w // 100)
        mask = Image.new('L', im.size, 0)
        ImageDraw.Draw(mask).rounded_rectangle([l + inset, t + inset, rgt - 1 - inset, btm - 1 - inset], radius=int(self.radius - inset), fill=255)
        alpha = Image.composite(white, Image.new('L', im.size, 0), mask)
        alpha = alpha.point(lambda v: 0 if v < 12 else v)
        self.elem_box = alpha.point(lambda v: 255 if v > 24 else 0).getbbox()
        sprite = Image.new('RGBA', im.size, WHITE + (0,))
        sprite.putalpha(alpha)
        self.sprite = sprite.crop(self.elem_box)  # 흰 요소만, 투명 배경
        # 타일 기준 요소 위치 (비율)
        self.elem_rel = ((self.elem_box[0] - l) / self.tile_w, (self.elem_box[1] - t) / self.tile_h,
                         (self.elem_box[2] - l) / self.tile_w, (self.elem_box[3] - t) / self.tile_h)
        # 최소 외접원 (적응형 아이콘에서 원형 마스크에 안 잘리게 배치하려고)
        self.mec_center, self.mec_radius = self._enclosing_circle()

    def _enclosing_circle(self):
        """스프라이트의 불투명 픽셀을 모두 담는 최소 원 (Badoiu-Clarkson 근사). 좌표는 스프라이트 기준."""
        small = self.sprite.split()[3].resize((self.sprite.width // 4, self.sprite.height // 4), Image.BOX)
        pts = [(x * 4 + 2, y * 4 + 2) for y in range(small.height) for x in range(small.width) if small.getpixel((x, y)) > 96]
        cx = sum(p[0] for p in pts) / len(pts)
        cy = sum(p[1] for p in pts) / len(pts)
        for i in range(1, 400):
            fx, fy = max(pts, key=lambda p: (p[0] - cx) ** 2 + (p[1] - cy) ** 2)
            cx += (fx - cx) / (i + 1)
            cy += (fy - cy) / (i + 1)
        rad = max(math.hypot(p[0] - cx, p[1] - cy) for p in pts) + 3
        return (cx, cy), rad


SRCI = Source(SRC)


def tile(size, radius_ratio=None):
    """원본과 같은 배치의 아이콘 타일. radius_ratio=None 이면 원본 모서리, 0 이면 꽉 찬 정사각."""
    W = SRCI.tile_w
    rr = (SRCI.radius / W) if radius_ratio is None else radius_ratio
    img = Image.new('RGBA', (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if rr > 0:
        d.rounded_rectangle([0, 0, W - 1, W - 1], radius=int(W * rr), fill=BRAND + (255,))
    else:
        d.rectangle([0, 0, W, W], fill=BRAND + (255,))
    ex, ey = int(SRCI.elem_rel[0] * W), int(SRCI.elem_rel[1] * W)
    img.alpha_composite(SRCI.sprite, (ex, ey))
    return img.resize((size, size), Image.LANCZOS)


def adaptive_foreground(size, safe=0.66):
    """108dp 캔버스용 전경. 흰 요소의 최소 외접원이 캔버스 중앙 [safe] 지름 원 안에 들어가게 축소 배치."""
    scale = (size * safe / 2) / SRCI.mec_radius
    sw, sh = int(SRCI.sprite.width * scale), int(SRCI.sprite.height * scale)
    sp = SRCI.sprite.resize((sw, sh), Image.LANCZOS)
    cx, cy = SRCI.mec_center
    ox, oy = round(size / 2 - cx * scale), round(size / 2 - cy * scale)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    img.alpha_composite(sp, (ox, oy))
    return img


def maskable(size, safe=0.66):
    """PWA maskable: 꽉 찬 브랜드 배경 + 중앙 안전 영역 안의 요소."""
    img = Image.new('RGBA', (size, size), BRAND + (255,))
    img.alpha_composite(adaptive_foreground(size, safe))
    return img


def save(img, rel, mode='RGBA'):
    path = os.path.join(ROOT, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.convert(mode).save(path, optimize=True)
    print('wrote', rel, img.size)


def feature_graphic():
    fg = Image.new('RGB', (1024, 500), WHITE)
    d = ImageDraw.Draw(fg)
    t = tile(220)
    fg.paste(t, (96, 140), t)
    x = 372
    d.text((x, 150), 'ReSAI', font=ImageFont.truetype(BOLD, 84), fill=INK)
    d.text((x, 258), '찍으면 알려주는 AI 분리수거', font=ImageFont.truetype(SEMI, 40), fill=INK)
    d.text((x, 318), '사진 한 장이면 어디에 버릴지, 뭘 떼야 하는지 바로.', font=ImageFont.truetype(REG, 26), fill=MUTED)
    fchip = ImageFont.truetype(SEMI, 22)
    cx, cy = x, 380
    for c in ['사진 분류', '수거일 알림', '분리배출 팁']:
        b = d.textbbox((0, 0), c, font=fchip, anchor='lt')
        w = b[2] - b[0]
        d.rounded_rectangle([cx, cy, cx + w + 36, cy + 44], radius=22, fill=(247, 247, 248))
        d.text((cx + 18, cy + 10), c, font=fchip, fill=INK, anchor='lt')
        cx += w + 36 + 12
    return fg


def main():
    print(f'source tile {SRCI.tile_w}px, corner radius {SRCI.radius:.0f}px ({SRCI.radius / SRCI.tile_w:.2f}), '
          f'elements box {SRCI.elem_box}, enclosing circle r={SRCI.mec_radius:.0f}px')
    # 스토어 (Play 가 모서리를 깎으므로 꽉 찬 정사각, 알파 없음)
    save(tile(512, 0), 'assets/store/icon_512.png', 'RGB')
    save(feature_graphic(), 'assets/store/feature_graphic_1024x500.png', 'RGB')
    # 앱 안: 스플래시 로고, 공유 카드 브랜딩 아이콘
    save(tile(192), 'assets/branding/logo_192.png')
    save(tile(128), 'assets/branding/app_icon_128.png')
    # 웹
    save(tile(192), 'web/icons/Icon-192.png')
    save(tile(512), 'web/icons/Icon-512.png')
    save(maskable(192), 'web/icons/Icon-maskable-192.png')
    save(maskable(512), 'web/icons/Icon-maskable-512.png')
    save(tile(32), 'web/favicon.png')
    # 안드로이드 런처 (레거시 정사각 + 적응형)
    legacy = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
    for dpi, px in legacy.items():
        save(tile(px), f'android/app/src/main/res/mipmap-{dpi}/ic_launcher.png')
    fgsize = {'mdpi': 108, 'hdpi': 162, 'xhdpi': 216, 'xxhdpi': 324, 'xxxhdpi': 432}
    for dpi, px in fgsize.items():
        save(adaptive_foreground(px), f'android/app/src/main/res/mipmap-{dpi}/ic_launcher_foreground.png')
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
    if 'ic_launcher_background' in s:
        s = re.sub(r'<color name="ic_launcher_background">#[0-9A-Fa-f]{6}</color>',
                   f'<color name="ic_launcher_background">{BRAND_HEX}</color>', s)
    else:
        s = s.replace('</resources>', f'    <color name="ic_launcher_background">{BRAND_HEX}</color>\n</resources>')
    open(colors, 'w').write(s)
    print('ok')


if __name__ == '__main__':
    main()
