# 스토어 등록 이미지

- `icon_512.png` — Play Console 앱 아이콘 (512×512, PNG, 알파 없음, 1MB 이하). Play 가 모서리를 자동으로 둥글게 처리하므로 꽉 찬 정사각.
- `feature_graphic_1024x500.png` — 그래픽 이미지 (1024×500, PNG). 스토어 상단 배너.

이 폴더는 pubspec 의 assets 에 등록하지 않아서 앱 번들에 포함되지 않아요.

## 스크린샷 (`screenshots/`)

| 파일 | 화면 | 상단 문구 |
|---|---|---|
| `01_home.png` | 홈 (수거일 카드·사진 찍기) | 찍으면 바로 알려줘요 |
| `02_result.png` | 판별 결과 | 어디에, 어떻게 버리는지까지 |
| `03_tips.png` | 분리배출 팁 (버리는 곳) | 헷갈리는 품목, 버리는 곳까지 |
| `04_history.png` | 분류 기록 (월간 요약·스트릭) | 쌓이는 기록, 한눈에 |

모두 1080x1920 PNG. Play Console → 스토어 등록정보 → 휴대전화 스크린샷에 올리면 된다.

### 다시 만들기

1. 데모 모드 웹 빌드: `flutter build web --release --dart-define=DEMO=true --no-web-resources-cdn --base-href /`
2. `build/web` 을 로컬 서버로 띄우고, 뷰포트 360x640 · DPR 3 · 로케일 `ko-KR` 로 홈/결과/팁/기록 화면을 캡처한다
   (파일명 `01-home.png` `02-result.png` `03-tips.png` `04-history.png`).
3. `python3 tool/make_screenshots.py <캡처 폴더>` → `assets/store/screenshots/` 에 프레임이 합성된다.

문구는 `tool/make_screenshots.py` 의 `FRAMES` 에서 바꾼다.

## 브랜드 색 · 아이콘 원본

- 브랜드 색: 파랑 `#2563EB` (앱 primary 와 동일). `tool/make_icons.py` 의 `BRAND` 한 곳에서 바꾼다.
- 아이콘 원본: `assets/branding/app_icon_source.png` (1254px, 둥근 사각 파란 배경 위 흰 쓰레기통·R·뚜껑). 원본은 손대지 않는다.
  원본의 배경은 `#0254EF` 에 가깝지만 파생본은 모두 브랜드 색 `#2563EB` 로 통일한다.
- `python3 tool/make_icons.py` 가 원본에서 바로 축소해 아래를 전부 다시 만든다 (작은 파일을 재확대하지 않는다):
  - `assets/store/icon_512.png` (꽉 찬 정사각, 알파 없음) · `assets/store/feature_graphic_1024x500.png` (왼쪽 아이콘)
  - `web/icons/Icon-192.png` `Icon-512.png` (둥근 사각) · `Icon-maskable-192.png` `Icon-maskable-512.png` (꽉 찬 배경 + 중앙 66% 요소) · `web/favicon.png` (32)
  - `android/.../mipmap-*/ic_launcher.png` (레거시, 48~192) · `ic_launcher_foreground.png` (적응형 전경 108~432: 흰 요소의 최소 외접원이 캔버스 중앙 66% 원 안에 들어가 원형 마스크에서 뚜껑 손잡이가 안 잘린다) · 배경은 `@color/ic_launcher_background` = `#2563EB`
  - `assets/branding/logo_192.png` (스플래시) · `assets/branding/app_icon_128.png` (공유 카드 브랜딩 영역에 64px 로 그림)
