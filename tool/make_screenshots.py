"""Play Store 스크린샷 프레임 합성.

사용법: python3 tool/make_screenshots.py <캡처 폴더>
  캡처 폴더에는 1080x1920 (360x640 @3x) 앱 캡처 PNG 가 있어야 한다.
  결과: assets/store/screenshots/01..04.png (1080x1920)
"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
FONTS = ROOT / 'assets' / 'fonts'
OUT = ROOT / 'assets' / 'store' / 'screenshots'
W, H = 1080, 1920
BG = (239, 244, 255)        # primarySoft
INK = (17, 24, 39)
MUTED = (107, 114, 128)
PRIMARY = (37, 99, 235)

FRAMES = [
    ('01-home.png',    '01_home.png',    '찍으면 바로 알려줘요',       '사진 한 장이면 분리수거 끝'),
    ('02-result.png',  '02_result.png',  '어디에, 어떻게 버리는지까지', '품목별 배출 방법을 단계로 안내'),
    ('03-tips.png',    '03_tips.png',    '헷갈리는 품목, 버리는 곳까지', '대형폐기물 신고부터 폐의약품 수거함까지'),
    ('04-history.png', '04_history.png', '쌓이는 기록, 한눈에',       '월간 요약과 수거일 연속 체크'),
]


def font(name, size):
    return ImageFont.truetype(str(FONTS / f'Pretendard-{name}.otf'), size)


def rounded(img, radius):
    mask = Image.new('L', img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, img.width - 1, img.height - 1], radius, fill=255)
    out = Image.new('RGBA', img.size, (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out


def compose(src, headline, sub):
    canvas = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(canvas)
    # 상단 문구
    f1, f2 = font('Bold', 66), font('Medium', 36)
    y = 120
    tw = d.textlength(headline, font=f1)
    d.text(((W - tw) / 2, y), headline, font=f1, fill=INK)
    tw = d.textlength(sub, font=f2)
    d.text(((W - tw) / 2, y + 96), sub, font=f2, fill=MUTED)
    # 폰 캡처
    shot = Image.open(src).convert('RGB')
    pw = 880
    ph = round(shot.height * pw / shot.width)
    shot = shot.resize((pw, ph), Image.LANCZOS)
    radius = 56
    x0, y0 = (W - pw) // 2, 330
    # 그림자
    shadow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle([x0, y0 + 18, x0 + pw, y0 + ph + 18], radius, fill=(37, 99, 235, 60))
    shadow = shadow.filter(ImageFilter.GaussianBlur(28))
    canvas.paste(shadow, (0, 0), shadow)
    # 테두리 + 캡처
    frame = Image.new('RGBA', (pw + 12, ph + 12), (0, 0, 0, 0))
    ImageDraw.Draw(frame).rounded_rectangle([0, 0, pw + 11, ph + 11], radius + 6, fill=(17, 24, 39, 255))
    canvas.paste(frame, (x0 - 6, y0 - 6), frame)
    r = rounded(shot, radius)
    canvas.paste(r, (x0, y0), r)
    return canvas


def main():
    src_dir = Path(sys.argv[1])
    OUT.mkdir(parents=True, exist_ok=True)
    for src, dst, h, s in FRAMES:
        img = compose(src_dir / src, h, s)
        img.save(OUT / dst, optimize=True)
        print('wrote', OUT / dst, img.size)


if __name__ == '__main__':
    main()
