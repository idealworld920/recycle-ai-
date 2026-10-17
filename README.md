# 분리수거 AI (recycle-ai)

사진 한 장으로 "이거 어디에 버리지?"를 해결해 주는 Flutter 앱이에요.
Gemini 멀티모달 모델이 사진 속 물건을 보고 **한국 분리배출 기준**(환경부 가이드라인)에 맞춰
분류와 버리는 순서, 주의할 점을 알려줘요.

## 주요 기능

- **AI 판별** – 카메라로 찍거나 갤러리에서 고르면 분류(투명 페트병 / 플라스틱 / 종이 / 종이팩 / 캔·고철 / 유리병 / 비닐 / 스티로폼 / 음식물 / 유해 폐기물 / 폐가전 / 의류 / 대형 폐기물 / 일반 쓰레기)와 단계별 배출 방법을 보여줘요.
- **분리배출 가이드** – 분류별 "버리는 방법 / 되는 것 / 안 되는 것"을 오프라인으로 볼 수 있어요.
- **판별 기록** – 최근 50건을 사진과 함께 기기에 저장해요. 스와이프로 삭제.
- **물어보기** – 분리배출 질문 채팅. 하루 5회, Firestore 에 사용량 기록.
- **팁** – 55개 품목 검색과 분류별 배출 방법.

## 시작하기

```bash
flutter pub get
flutter run
```

AI 호출은 **Firebase AI Logic(firebase_ai)** 을 통해 이뤄져서 앱 안에 API 키가 없어요.
처음 한 번 Firebase 프로젝트를 연결해야 해요.

```bash
dart pub global activate flutterfire_cli
flutterfire configure --platforms=android
```

이 명령이 만드는 `lib/firebase_options.dart` 와 `android/app/google-services.json` 은 커밋하지 않아요(.gitignore).
Firebase 없이 빌드만 하려면 `bash tool/firebase_placeholders.sh` 로 자리표시자를 만들 수 있어요.

Firebase 콘솔에서 켜야 하는 것: Vertex AI(Firebase AI Logic), 익명 로그인, App Check, Firestore(+ `firestore.rules` 배포).

## APK 받기

GitHub Actions가 `main`에 푸시될 때마다 `flutter analyze` → `flutter test` → `flutter build apk`를 돌려요.
**Actions 탭 → 최근 실행 → Artifacts → recycle-ai-apk**에서 내려받아 안드로이드 폰에 설치하면 돼요.

## 수거일 알림·위젯 테스트 (에뮬레이터)

**알림**
1. 앱 실행 → 홈 "수거일 설정하기" → 요일 몇 개 켜고 저장 (이때 Android 13+ 알림 권한 팝업 → 허용)
2. 바로 확인하려면 설정(⚙️) → **테스트 알림 보내기** → 5초 뒤 알림이 와요. 알림을 누르면 카메라가 바로 열려요
3. 실제 예약 알림을 보려면 에뮬레이터 시계를 바꿔요:
   ```bash
   adb shell "date $(date -d 'next sunday 19:59' +%m%d%H%M%Y.%S)"   # 수거일 전날 알림 직전으로
   ```
   또는 설정에서 알림 시각을 지금+2분으로 바꾸고 전날에 해당하는 요일을 켜 두세요
4. 재부팅 유지 확인: `adb reboot` 후 같은 시각에 알림이 오면 성공 (BOOT_COMPLETED 리시버가 재등록)
5. 알림 목록 확인: `adb shell dumpsys notification --noredact | grep -A3 pickup_reminders`

**홈 위젯**
1. 에뮬레이터 홈 화면 빈 곳 길게 누르기 → 위젯 → **ReSAI** → "수거일 (작게)" 또는 "수거일" 을 끌어다 놓기
2. 앱에서 수거일을 저장하면 즉시 갱신돼요. 오늘이 수거일이면 D-Day 가 파란색
3. 자정 갱신(WorkManager)을 바로 돌려보려면:
   ```bash
   adb shell dumpsys jobscheduler | grep -A5 resai.pickup      # 등록 확인
   adb shell cmd jobscheduler run -f com.idealworld.recycle_ai <JOB_ID>
   ```
4. 위젯을 누르면 앱 홈이 열려요

## 구조

```
lib/
  main.dart                   앱 진입점, 테마
  app_services.dart           설정/기록 저장소를 위젯 트리에 제공
  models/
    recycle_category.dart     분류 enum (키, 라벨, 아이콘, 색)
    recycle_result.dart       AI 판별 결과 모델 + JSON 파싱
  data/recycling_guide.dart   분류별 분리배출 안내 데이터
  core/
    firebase_session.dart     Firebase 초기화, App Check, 익명 로그인
    ai_backend.dart           firebase_ai 백엔드 선택(Vertex / Google AI)
  features/
    chat/                     물어보기 채팅 (하루 5회 제한)
    schedule/                 수거일 설정·전날 알림·홈 위젯·버렸어요 체크인
    tips/                     품목별 팁 검색
    history/                  분류 기록 (로컬 저장)
  services/
    gemini_classifier.dart    firebase_ai 로 사진 판별 (JSON 스키마 응답)
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
- [ ] 분류 피드백("틀렸어요") 수집으로 프롬프트 개선
