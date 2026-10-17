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

## 법적 문서와 Play Console 데이터 안전

- 개인정보처리방침: https://idealworld920.github.io/recycle-ai-/privacy.html (`web/privacy.html`)
- 이용약관: https://idealworld920.github.io/recycle-ai-/terms.html (`web/terms.html`)
- 앱 내: 최초 실행 온보딩 마지막 동의 화면(필수 2 + 선택 1, 동의 시각은 `users/{uid}.consent`), 설정 → 약관/개인정보 링크, 설정 → 내 데이터 삭제
- 문서의 `[사업자/개인 명칭]`, `[이름]`, `[privacy@example.com]` 은 채워야 해요. 문서를 고치면 `LegalLinks.version` 을 올려 재동의를 받아요.

**Play Console → 앱 콘텐츠 → 데이터 보안** 에 아래 기준으로 답하면 돼요 (현재 코드 기준).

| 질문 | 답 |
|---|---|
| 앱에서 필수 사용자 데이터 유형을 수집하거나 공유하나요? | **예** |
| 전송 중인 모든 사용자 데이터가 암호화되나요? | **예** (TLS) |
| 사용자가 데이터 삭제를 요청할 방법을 제공하나요? | **예** — 앱 내 "설정 → 내 데이터 삭제", 계정 삭제. 삭제 요청 URL 칸에는 privacy.html 주소 |
| 독립적인 보안 검토를 받았나요? | 아니요 |

| 데이터 유형 | 수집 | 공유 | 임시 처리 | 필수/선택 | 목적 |
|---|---|---|---|---|---|
| 사진 및 동영상 → 사진 | 예 | 아니요 (처리 위탁) | **예** (임시 처리, 저장 안 함) | 선택 (분류할 때만) | 앱 기능 |
| 앱 활동 → 기타 사용자 생성 콘텐츠 (분류 기록, 수거일, 도감, 퀴즈, 질문 텍스트) | 예 | 아니요 | 아니요 | 선택 | 앱 기능 |
| 앱 활동 → 앱 상호작용 | 예 | 아니요 | 아니요 | 필수 | 분석, 앱 기능 |
| 개인 정보 → 이메일 주소, 사용자 ID | 예 | 아니요 | 아니요 | 선택 (구글 연결 시) | 계정 관리, 앱 기능 |
| 개인 정보 → 이름 (가족 공유 닉네임) | 예 | 아니요 | 아니요 | 선택 | 앱 기능 |
| 금융 정보 → 구매 내역 | 예 | 아니요 | 아니요 | 선택 (구독 시) | 앱 기능 |
| 앱 정보 및 성능 → 비정상 종료 로그, 진단 | 예 | 아니요 | 아니요 | 필수 | 분석, 앱 기능 |
| 기기 또는 기타 ID (익명 UID, App Check 토큰) | 예 | 아니요 | 아니요 | 필수 | 앱 기능, 사기 방지 |
| 위치, 연락처, 광고 ID, 메시지, 오디오, 파일 | **수집 안 함** | | | | |

- "공유"는 제3자에게 넘기는 경우만 해당해요. Google(Firebase·Gemini)·RevenueCat 은 **서비스 제공업체(처리 위탁)** 라서 Play 기준으로 "공유"가 아니에요. 가족 공유 닉네임·체크는 같은 집 사용자에게 보이지만 "사용자가 직접 시작한 공유"라 공유 항목에 체크하지 않아도 돼요.
- 사진은 "임시로 처리됨" 체크 (서버 미저장).
- 데이터 처리 방식 질문의 "사용자가 선택적으로 제공" 은 분류·구글 연결·구독·가족 공유 항목에 해당해요.
- 광고 ID 를 쓰지 않으므로 광고 ID 선언은 "아니요". 앱 콘텐츠의 "광고" 도 "광고 없음".

## 구글 로그인 설정 (SHA 지문 등록)

앱은 익명으로 시작하고, 설정에서 "구글로 연결하기"를 누르면 익명 계정에 구글을 묶어요. Android 에서 구글 로그인이 되려면 Firebase 에 앱의 서명 지문이 등록돼 있어야 해요.

1. Firebase 콘솔 → Authentication → Sign-in method → **Google** 사용 설정 (지원 이메일 선택)
2. 지문 뽑기
   - 디버그 키 (개발용, `flutter run`):
     ```bash
     cd android && ./gradlew signingReport        # Variant: debug 아래 SHA1 / SHA-256
     # 또는
     keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android
     ```
   - 릴리스 키 (스토어 배포용 keystore):
     ```bash
     keytool -list -v -alias <alias> -keystore <release.jks>
     ```
   - Play 앱 서명을 쓰면 Play Console → 설정 → 앱 무결성 → **앱 서명 키 인증서**의 SHA-1/SHA-256 도 등록
3. Firebase 콘솔 → 프로젝트 설정 → 내 앱 → Android 앱 → **디지털 지문 추가** 에 위 SHA-1 과 SHA-256 을 디버그·릴리스 **둘 다** 추가
4. `google-services.json` 을 **다시 다운로드**해서 `android/app/` 에 덮어쓰기 (지문을 추가하면 파일 안에 OAuth 클라이언트가 생겨요). `flutterfire configure` 를 다시 돌려도 돼요
5. 앱 재설치 후 설정 → 구글로 연결하기

문제가 생기면: `clientConfigurationError` / `DEVELOPER_ERROR` 는 거의 항상 지문 누락이거나 google-services.json 이 옛날 파일인 경우예요.

## 구독 (RevenueCat) 설정

앱은 `purchases_flutter`(RevenueCat)로 결제·영수증 검증·복원을 처리해요. 구독 상태의 진실은 RevenueCat SDK 이고,
Firestore `users/{uid}.premium` 은 `functions/index.js` 의 RevenueCat 웹훅만 갱신해요 (클라이언트는 규칙상 못 씀).

1. **Play Console 상품 등록**: 수익 창출 → 구독 → 구독 만들기
   - `resai_premium_monthly` : 기본 요금제 월 2,900원, 무료 체험 7일 오퍼 추가
   - `resai_premium_yearly` : 기본 요금제 연 19,900원, 무료 체험 7일 오퍼 추가
   - 두 상품 모두 "활성화". 앱은 내부 테스트 트랙에 한 번 올라가 있어야 상품이 보여요
2. **라이선스 테스터**: Play Console → 설정 → 라이선스 테스트 → 테스트할 Google 계정 추가 (결제 없이 테스트, 체험·갱신이 분 단위로 빨라져요)
3. **RevenueCat 프로젝트**: app.revenuecat.com → 프로젝트 만들기 → Android 앱 추가 (패키지 `com.idealworld.recycle_ai`)
   - Play 서비스 계정 JSON 업로드 (RevenueCat 안내대로 Google Cloud 에서 서비스 계정 만들고 Play Console 에 초대)
   - Products 에 위 두 상품 import → Entitlement **`premium`** 하나 만들고 두 상품 연결
   - Offering `default` 에 패키지 `$rc_monthly` = monthly, `$rc_annual` = yearly
4. **API 키**: RevenueCat → API keys → Google Play 공개 키(`goog_…`) 복사. 빌드할 때 넣어요:
   ```bash
   flutter run --dart-define=REVENUECAT_ANDROID_KEY=goog_xxx
   ```
   CI 는 GitHub Secrets `REVENUECAT_ANDROID_KEY` 를 같은 이름으로 넘겨요. 키가 없으면 페이월은 미리보기만 떠요.
   결제 없이 프리미엄 화면을 확인하려면 `--dart-define=PREMIUM_DEBUG=true`
5. **웹훅 (Cloud Function)**:
   ```bash
   cd functions && npm install && cd ..
   firebase functions:secrets:set REVENUECAT_WEBHOOK_SECRET   # 아무 긴 문자열
   firebase deploy --only functions,firestore:rules
   ```
   RevenueCat → Integrations → Webhooks 에 함수 URL 과 `Authorization: Bearer <그 문자열>` 등록
6. 앱에서 설정 → 프리미엄 → 7일 무료로 시작 → 라이선스 테스터 계정으로 결제 → 홈 카드에 반영되면 끝

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
    stats/                    월간 요약·주간 스트릭·도감
    places/                   버리는 곳: 지역 선택, 대형폐기물 신고·수거함 링크
    quiz/                     주 1회 헷갈리는 쓰레기 퀴즈 (토요일 11:00 알림)
    auth/                     익명 → 구글 연결, 잠금 UI, 로그아웃·계정 삭제
    premium/                  RevenueCat 구독, 페이월, 무료 한도
    household/                가족 공유 집: 초대 코드, 공유 수거일, 멤버 체크인
    onboarding/               최초 실행 소개 + 동의 화면
    legal/                    약관·개인정보 링크, 인앱 웹뷰, 권한 사전 안내, 내 데이터 삭제
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
