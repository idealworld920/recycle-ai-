# 분리수거 AI (recycle-ai)

사진 한 장으로 "이거 어디에 버리지?"를 해결해 주는 Flutter 앱이에요.
Gemini 멀티모달 모델이 사진 속 물건을 보고 **한국 분리배출 기준**(환경부 가이드라인)에 맞춰
분류와 버리는 순서, 주의할 점을 알려줘요.

## 주요 기능

- **AI 판별** – 카메라로 찍거나 갤러리에서 고르면 분류(투명 페트병 / 플라스틱 / 종이 / 종이팩 / 캔·고철 / 유리병 / 비닐 / 스티로폼 / 음식물 / 유해 폐기물 / 폐가전 / 의류 / 대형 폐기물 / 일반 쓰레기)와 단계별 배출 방법을 보여줘요.
- **분리배출 가이드** – 분류별 "버리는 방법 / 되는 것 / 안 되는 것"을 오프라인으로 볼 수 있어요.
- **판별 기록** – 최근 50건을 사진과 함께 기기에 저장해요. 스와이프로 삭제.
- **설정** – Gemini API 키 입력 (기기에만 저장).

## 시작하기

```bash
flutter pub get
flutter run
```

AI 판별에는 Google Gemini API 키가 필요해요. 두 가지 방법 중 하나를 쓰면 돼요.

1. 앱 실행 후 **설정 → Gemini API 키**에 입력 (추천, 빌드 없이 바로 사용)
2. 빌드할 때 내장: `flutter run --dart-define=GEMINI_API_KEY=AIza...`

키는 [Google AI Studio](https://aistudio.google.com/apikey)에서 무료로 만들 수 있어요.

> 주의: 2번 방식으로 내장한 키는 APK에서 추출될 수 있어요. 공개 배포 시에는
> Firebase AI Logic(`firebase_ai`) 같은 서버 경유 방식으로 바꾸는 걸 권장해요.

## APK 받기

GitHub Actions가 `main`에 푸시될 때마다 `flutter analyze` → `flutter test` → `flutter build apk`를 돌려요.
**Actions 탭 → 최근 실행 → Artifacts → recycle-ai-apk**에서 내려받아 안드로이드 폰에 설치하면 돼요.

## 구조

```
lib/
  main.dart                   앱 진입점, 테마
  app_services.dart           설정/기록 저장소를 위젯 트리에 제공
  models/
    recycle_category.dart     분류 enum (키, 라벨, 아이콘, 색)
    recycle_result.dart       AI 판별 결과 모델 + JSON 파싱
  data/recycling_guide.dart   분류별 분리배출 안내 데이터
  services/
    gemini_classifier.dart    Gemini generateContent 호출 (JSON 스키마 응답)
    history_store.dart        판별 기록 로컬 저장
    settings_store.dart       API 키 저장
  screens/                    판별 / 결과 / 가이드 / 기록 / 설정 화면
  widgets/category_badge.dart
test/                         모델·가이드·화면 테스트
```

## 테스트

```bash
flutter analyze
flutter test
```

## 앞으로 할 것

- [ ] 결과 공유하기 (share_plus)
- [ ] 지역(지자체)별 배출 요일·기준 안내
- [ ] Firebase AI Logic으로 전환해 API 키를 앱에서 제거
- [ ] 분류 피드백("틀렸어요") 수집으로 프롬프트 개선
