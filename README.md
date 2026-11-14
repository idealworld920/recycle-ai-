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

## Play Store 배포 (릴리스 빌드)

**앱 식별자**: `com.idealworld.recycle_ai` (Firebase·SHA 지문이 이미 이 값으로 등록돼 있어 유지). 앱 이름 ReSAI, 버전 `1.0.1+8` (pubspec.yaml 의 `version:` 한 곳에서 관리, `+` 뒤가 versionCode).

**1. 업로드 키스토어 만들기** (한 번만, 노트북에서. 잃어버리면 앱 업데이트를 못 하니 백업 필수)
```powershell
# Windows PowerShell — android\app 폴더 안에 생성
cd recycle-ai-\android\app
keytool -genkey -v -keystore upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
```bash
# Mac/Linux
cd recycle-ai-/android/app
keytool -genkey -v -keystore upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
비밀번호 2개(keystore, key)와 이름/조직 정보를 물어봐요. 비밀번호는 안전한 곳에 적어두세요.

**2. key.properties 만들기**
`android/key.properties.example` 을 복사해 `android/key.properties` 로 저장하고 비밀번호를 채워요. 두 파일(`key.properties`, `*.jks`)은 .gitignore 라 커밋되지 않아요. `key.properties` 가 있으면 릴리스 빌드가 자동으로 이 키로 서명되고, 없으면(CI) 디버그 키로 서명돼요.

**3. 릴리스 키 SHA 지문을 Firebase 에 추가** (구글 로그인용)
```bash
keytool -list -v -alias upload -keystore android/app/upload-keystore.jks
```
SHA-1·SHA-256 을 Firebase 콘솔 → 프로젝트 설정 → Android 앱 → 디지털 지문 추가. **Play 앱 서명**을 쓰면 Play Console → 테스트 및 출시 → 설정 → 앱 서명 의 "앱 서명 키 인증서" SHA 도 추가하고 google-services.json 재다운로드.

**4. 앱 번들 빌드**
```bash
flutter build appbundle --release --dart-define-from-file=dart_defines.json
```
(`dart_defines.json` 은 "구독 설정" 절 참고. 구독 없이 빌드하려면 옵션을 빼면 돼요.)
산출물: `build/app/outputs/bundle/release/app-release.aab` → Play Console 에 업로드.
APK 로 직접 설치해 보려면 `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`.

**5. 다음 버전 올릴 때**: pubspec.yaml 의 `version: 1.0.1+2` 처럼 둘 다 올리기 (versionCode 는 항상 증가).

**권한 (AndroidManifest)**: INTERNET, POST_NOTIFICATIONS(알림, 사용 시점에 요청), RECEIVE_BOOT_COMPLETED(재부팅 후 알림 복구). 카메라는 시스템 카메라 앱을 호출해서 CAMERA 권한이 없고, 갤러리는 Android 13+ 포토 피커라 저장소 권한이 없어요. `android.hardware.camera` 는 `required=false`. 플러그인이 합치는 권한은 빌드 후 `build/app/intermediates/merged_manifests/release/AndroidManifest.xml` 에서 확인할 수 있어요.

**targetSdk 36 / compileSdk 36 / minSdk 24** (firebase_auth 요구 23 이상).

### 릴리스 빌드가 스플래시에서 멈출 때

디버그는 되는데 릴리스(내부 테스트)만 흰 화면에 멈추면 거의 R8(코드 축소) 아니면 시작 단계가 막힌 거예요. 지금 구조는:

- `main()` 은 기기 안 저장소만 열고 **바로 그린다**. Firebase 초기화·App Check·익명 로그인·Firestore 첫 읽기는 백그라운드.
- 앱 안 스플래시(`SplashGate`)는 Firebase 가 정리되거나 **최대 3초**까지만 기다리고 무조건 홈으로.
- 단계마다 타임아웃(초기화 10초, 로그인 15초, Firestore 8초)이 있고, 실패 이유는 홈 상단 **작은 배너**에 뜬다 ("다시 연결" 버튼 포함).
- 알림·홈 위젯 플러그인 초기화는 첫 프레임 뒤에, 실패해도 배너에만 남긴다.
- R8 규칙은 `android/app/proguard-rules.pro` (Firebase·Play services·flutter_local_notifications+GSON·home_widget·workmanager keep, missing class 는 `-dontwarn`).

그래도 멈추면 에뮬레이터나 폰에 릴리스로 깔고 로그를 봐요.
```bash
flutter devices                                  # 에뮬레이터 id 확인 (예: emulator-5554)
flutter run --release -d emulator-5554
# 다른 창에서
adb logcat -c && adb logcat *:E flutter:V AndroidRuntime:E | grep -iE "flutter|recycle_ai|FATAL|boot"
```
- `[boot] ... 실패` 로 시작하는 줄이 어느 단계가 실패했는지 알려줘요.
- `Missing type parameter` / `ClassNotFoundException` / `NoSuchMethodError` 가 보이면 R8 이 뭔가를 지운 것 → 그 패키지를 `proguard-rules.pro` 에 `-keep class 패키지.** { *; }` 로 추가.
- R8 이 뭘 지웠는지는 `build/app/outputs/mapping/release/` 의 `missing_rules.txt`, `usage.txt` 에서 볼 수 있어요.
- Play Integrity(App Check) 는 에뮬레이터에서 토큰을 못 받아요. 앱은 그래도 뜨고, 홈 배너와 AI 오류 문구에 이유가 나와요. 아래 **App Check** 절 참고.

### App Check (AI 호출 인증)

AI 호출마다 App Check 토큰이 붙어요. 토큰을 못 받으면 `[firebase_app_check/unknown] 403 App attestation failed` 로 채팅·분류가 실패해요.

| 상황 | 쓰는 provider | 할 일 |
|---|---|---|
| 디버그 빌드 (`flutter run`) | Debug | 처음 실행 때 logcat 에 찍히는 `Enter this debug secret into the allow list ...` 의 토큰을 Firebase 콘솔 → App Check → 앱 → ⋮ → **디버그 토큰 관리** 에 추가 (기기마다 한 번) |
| 릴리스를 에뮬레이터·사이드로드로 테스트 | Debug (강제) | **제일 쉬운 방법**: UUID 를 하나 만들고(PowerShell `[guid]::NewGuid()`) Firebase 콘솔 → App Check → 앱 → ⋮ → 디버그 토큰 관리에 등록한 뒤 `flutter run --release --dart-define=APP_CHECK_DEBUG_TOKEN=<그 UUID>`. logcat 을 볼 필요가 없다. (`--dart-define=APP_CHECK=debug` 만 주면 토큰이 자동 생성되어 logcat 태그 `DebugAppCheckProvider` 에 찍힌다) |
| 콘솔에서 적용(enforce)이 꺼져 있을 때 빠른 확인 | 없음 | `--dart-define=APP_CHECK=off` (토큰 없이 호출. 적용을 켜면 거부됨) |
| Play 내부 테스트·정식 (기본) | Play Integrity | Firebase 콘솔 → App Check → Android 앱 → **Play Integrity** 등록. 프로젝트 설정 → 디지털 지문에 업로드 키 **SHA-256** 과 Play Console → 앱 서명 → "앱 서명 키 인증서" **SHA-256** 둘 다 등록. Google Cloud 콘솔에서 **Play Integrity API** 사용 설정 |

Play Integrity 는 실제 기기에서만 성공해요(에뮬레이터·루팅 기기는 실패). 스토어 밖에서 설치한 APK 도 서명 SHA-256 만 등록돼 있으면 돼요.

### 광고 ID (Play Console "광고 ID 선언")

앱은 광고 ID 를 쓰지 않는다. firebase_analytics 가 병합해 넣는 `com.google.android.gms.permission.AD_ID` 와 Privacy Sandbox 권한
(`ACCESS_ADSERVICES_AD_ID`, `ACCESS_ADSERVICES_ATTRIBUTION`)을 `AndroidManifest.xml` 에서 `tools:node="remove"` 로 빼고,
`google_analytics_adid_collection_enabled=false` 메타데이터로 수집도 끈다. 빌드 뒤
`build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml` 에 AD_ID 가 없어야 한다.
Play Console 앱 콘텐츠 → 광고 ID 에서는 "아니요(광고 ID 사용 안 함)" 로 선언한다.
같은 방식으로 `BIND_GET_INSTALL_REFERRER_SERVICE`(Analytics 설치 리퍼러), `USE_BIOMETRIC` · `USE_FINGERPRINT`(firebase_auth 가 끌어오는
androidx.biometric)도 빼 두었다. 1.1.0 의 병합 매니페스트 권한은 INTERNET · POST_NOTIFICATIONS · RECEIVE_BOOT_COMPLETED · ACCESS_NETWORK_STATE ·
WAKE_LOCK · VIBRATE · FOREGROUND_SERVICE(_SHORT_SERVICE, 알림/워크매니저) · READ_GSERVICES(reCAPTCHA, firebase_auth) 뿐이다.

## 법적 문서와 Play Console 데이터 안전

- 개인정보처리방침: https://idealworld920.github.io/recycle-ai-/privacy.html (`web/privacy.html`)
- 이용약관: https://idealworld920.github.io/recycle-ai-/terms.html (`web/terms.html`)
- 앱 내: 최초 실행 온보딩 마지막 동의 화면(필수 2 + 선택 1, 동의 시각은 `users/{uid}.consent`), 설정 → 약관/개인정보 링크, 설정 → 내 데이터 삭제
- 운영자 표기: 라라스튜디오(이유정), idealworld13@gmail.com. 문서를 고치면 `LegalLinks.version` 을 올려 재동의를 받아요.

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

> **1.1.0 에는 구독이 없다.** Play Console 권한 목록을 줄이려고 `purchases_flutter` 를 pubspec 에서 뺐고,
> `lib/features/premium/` 는 "다음 업데이트에서 열려요" 안내 + 검토자 코드(`REVIEW_CODE`)·`PREMIUM_DEBUG` 만 남긴 가벼운 구현이다.
> 페이월·설정의 프리미엄 카드는 그대로 있고, 결제 버튼과 구매 복원만 없다.
> **1.4.0 에서 되돌리기**: `purchases_flutter: ^10.16.0` 을 pubspec 에 다시 넣고, git 기록에서 "Strip purchases_flutter" 커밋 **직전** 버전의
> `purchases_service.dart` · `premium_store.dart` · `purchase_errors.dart` · `paywall_screen.dart` · `test/premium_test.dart` 를 복원한다.
> 아래 RevenueCat 설정(상품·웹훅·키)은 그때 그대로 쓴다. 매니페스트의 `tools:node="remove"` 중 BILLING 은 건드린 적이 없으니 그대로 둬도 된다.


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
4. **API 키**: RevenueCat → API keys → Google Play 공개 키(`goog_…`) 복사. `dart_defines.example.json` 을
   `dart_defines.json` 으로 복사해 키를 넣고(커밋되지 않음) 빌드할 때 파일로 넘겨요:
   ```bash
   flutter build appbundle --release --dart-define-from-file=dart_defines.json
   flutter run --release --dart-define-from-file=dart_defines.json
   ```
   CI 는 GitHub Secrets `REVENUECAT_ANDROID_KEY` 를 같은 이름으로 넘겨요. 키가 없으면 결제 화면 대신 "곧 출시" 안내만 떠요.
   결제 없이 프리미엄 화면을 확인하려면 `--dart-define=PREMIUM_DEBUG=true`.
   Play 검토자용으로는 `REVIEW_CODE`(dart_defines.json) 를 넣어 두면 설정 → 앱 정보 7번 탭 → 코드 입력으로 30일 프리미엄이 열려요
   (코드가 비어 있으면 기능이 꺼져요. `docs/RELEASE_CHECKLIST.md` 의 앱 액세스 권한 항목 참고).
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

## 성장 기능 (feature/growth-1)

- **결과 화면**: 품목명 → 분류 뱃지 → "왜?" 한 줄(AI `reason`) → 배출 단계 → 지자체별 차이 노란 박스(팁의 `localNote`) 순서.
  사진 선택→결과 3초를 넘기면 대기 화면이 리뿅이 thinking + "조금만 기다려뿅" 으로 바뀌고, 소요 시간은 `[classify] …ms` 로 로그.
- **공유**: 결과 화면 공유 아이콘·[공유하기] → 1080x1350 카드(`lib/features/share/share_card.dart`, dart:ui Canvas 로 그림) 를
  share_plus 로 시스템 공유 시트에. 공유 횟수는 `users/{uid}.shareCount` 에 누적.
- **"결과가 틀렸나요?"**: 4분류 정답 + 메모 → Firestore `feedback/{id}` (쓰기 전용, 규칙 포함). 같은 품목을 다시 분류하면
  사용자 정답을 "내가 고친 답" 뱃지로 먼저 보여준다 (기기 캐시). 제출 후 리뿅이 "고마워뿅!".
  → 규칙이 바뀌었으니 **`firebase deploy --only firestore:rules`** 를 다시 해야 서버 저장이 된다.
- **수거일 알림**: 제목 "리뿅이: 내일 재활용 날이뿅!", 본문은 안내 한 줄 + tips.json 의 같은 종류 팁 한 줄.
  같은 팁은 2주 안에 반복하지 않고(`reminder_tips_used`), 앱을 켤 때마다 다시 등록해 문구가 바뀐다. 리뿅이 PNG 가 큰 아이콘.
- **리뿅이 에셋**: `assets/branding/mascot/r_*.gif` + 첫 프레임 `r_*_static.png` (`python3 tool/mascot_frames.py` 로 추출).
  시스템 "애니메이션 줄이기" 가 켜져 있으면 PNG 를 쓴다. 설정 화면엔 등장하지 않는다. 현재 happy / cheer / thinking 3종.

## 지역 정확도 + 월간 리포트 (feature/growth-2)

원칙: **확실하지 않은 정보는 넣지 않는다.** 지역 정보와 탄소 계수는 "없음"이 "틀림"보다 낫다.

### 거주 지역 설정
- `assets/data/regions.json`: 행정안전부 법정동코드(code.go.kr) 원본(`docs/regions_raw_codegokr_2026-11-12.json`)에서
  `python3 tool/build_regions.py` 로 생성. 시/도 16개 · 시/군/구 256개 (일반구가 있는 시는 "수원시 장안구"처럼 구 단위).
  공식 코드표 기준으로 광주·전남은 **전남광주통합특별시(12)** 로 합쳐져 있다.
- 설정 → 거주 지역: 검색 + 시/도 → 시/군/구 2단계 선택. 위치 권한은 쓰지 않는다. `users/{uid}.region` 에 저장하고
  기기에는 `region_code_v2` 로 둔다 (예전 `region_v1` 이름 저장값은 자동 이관).
- 홈 하단에 "거주 지역을 설정하면 우리 동네 기준으로 안내해요" 한 줄 (미설정일 때만).

### 전국 시군구 분리배출 안내 URL (wasteGuideUrl)

`regions.json` 의 256칸(시군구 230곳, 일반구는 시 홈페이지 공용) 전부 채움. 현황 표와 칸별 비고는 `docs/waste_guide_urls.md`, 조사 원본은 `docs/research_waste_guide_urls_2026-11-12.json`, 병합은 `python3 tool/merge_guide_urls.py <결과.json> --report docs/waste_guide_urls.md`.

| 상태 | 시군구 수 | 설명 |
|---|---|---|
| 안내 페이지 | 183 | 구청 분리배출(생활폐기물) 안내 페이지를 직접 열어 본문에 분리배출/배출방법 내용이 있는지 확인 |
| 메인 폴백 | 9 | 사이트는 열리지만 분리배출 안내 메뉴 자체가 없음 |
| 메인 폴백(봇 차단) | 1 | JS 봇체크 페이지만 내려줘 안내 페이지 확인 불가 (우회하지 않음) |
| 메인(접속 불가, 미검증) | 37 | 해외 IP 차단(WAF)·연결 끊김으로 이 환경에서 열지 못함. 정부24 기관 누리집 목록의 공식 메인 URL 을 그대로 넣음 |

홈페이지 주소는 정부24 「기관 누리집」 목록(공식)을 1순위, 위키백과 정보상자를 2순위로 삼고 전부 직접 접속해 확인했다.
**메인으로 폴백한 지역**: 강원특별자치도 영월군, 강원특별자치도 인제군, 경기도 성남시, 경상북도 상주시, 전남광주통합특별시 담양군, 전북특별자치도 무주군, 전북특별자치도 부안군, 전북특별자치도 임실군, 전북특별자치도 정읍시 / 봇 차단: 서울특별시 강북구.
**접속하지 못한 지역(메인 URL만, 미검증)**: 강원특별자치도 삼척시, 강원특별자치도 철원군, 경기도 고양시, 경기도 여주시, 경기도 의정부시, 경상남도 거제시, 경상남도 거창군, 경상남도 고성군, 경상남도 남해군, 경상남도 산청군, 경상남도 의령군, 경상남도 진주시, 경상남도 창녕군, 경상남도 하동군, 경상남도 함안군, 경상남도 함양군, 경상남도 합천군, 경상북도 경산시, 경상북도 고령군, 경상북도 김천시, 경상북도 영덕군, 경상북도 영양군, 경상북도 영천시, 경상북도 울릉군, 경상북도 청도군, 경상북도 청송군, 경상북도 칠곡군, 대구광역시 중구, 부산광역시 수영구, 서울특별시 용산구, 인천광역시 계양구, 전남광주통합특별시 강진군, 전남광주통합특별시 구례군, 전남광주통합특별시 순천시, 전북특별자치도 남원시, 제주특별자치도 서귀포시, 제주특별자치도 제주시.
도메인 변경 확인: 예천군 ycg.go.kr→ycg.kr, 미추홀구 michuhol.go.kr, 광양시 www 없이 gwangyang.go.kr, 인천 제물포구·영종구·검단구·서해구 신설 도메인.

### 지역별 안내 (regionNotes)
- `tips.json` 의 `regionNotes: { "<시군구코드>": { note, sourceUrl, verifiedAt } }`. 대상 품목 5개: 컵라면 용기 · 아이스팩 · 멸균팩 · 종이컵 · 스티로폼.
- **구청 공식 분리배출 안내 페이지**에서 직접 확인한 것만 넣는다. 소식지·카드뉴스·수거보상제 공지는 넣지 않는다.
  근거(원문 인용·URL·확인일)는 `docs/region_notes_evidence.md`, 병합은 `python3 tool/merge_region_notes.py <조사.json> --exclude …`.
- 결과/팁 화면: 노트가 있으면 파란 박스 "📍 {시군구} 기준" + 출처 보기 + 확인일, 없으면 노란 박스 + 구청 안내 페이지 링크(`wasteGuideUrl`)
  또는 "거주 지역 설정" 버튼. "이 정보가 다른가요?" → `feedback`(type `region`) + `regionNoteReports/{code}_{tipId}` 카운터, 3건 이상이면 자동 숨김.
- AI 프롬프트에 거주 지역을 넘기되 "지자체 기준을 모르면 모른다고, 지어내지 말 것"을 명시.

#### regionNotes 채움 현황 (2026-11-12)

서울 25개 구 × 5개 품목 = 125칸 중 **58칸 채움** (안내 페이지 URL 확보 23/25개 구)

| 구 | 컵라면 용기 | 아이스팩 | 멸균팩 | 종이컵 | 스티로폼 | 안내 URL | 비고 |
|---|---|---|---|---|---|---|---|
| 종로구 | ✓ | – | – | ✓ | ✓ | ✓ |  |
| 중구 | – | – | – | ✓ | ✓ | ✓ |  |
| 용산구 | ⊘ | ⊘ | ⊘ | ⊘ | ⊘ | – | www.yongsan.go.kr 서버가 TLS 연결 후 빈 응답(Empty reply from server) |
| 성동구 | – | – | – | ✓ | ✓ | ✓ |  |
| 광진구 | ✓ | – | ✓ | – | ✓ | ✓ |  |
| 동대문구 | – | – | – | ✓ | ✓ | ✓ |  |
| 중랑구 | – | – | – | – | ✓ | ✓ |  |
| 성북구 | ✗ | – | – | – | ✓ | ✓ |  |
| 강북구 | ⊘ | ⊘ | ⊘ | ⊘ | ⊘ | – | www.gangbuk.go.kr의 모든 경로가 JS 쿠키(sabFingerPrint/sabSignature) |
| 도봉구 | – | – | – | ✓ | ✓ | ✓ |  |
| 노원구 | ✓ | ✓ | – | ✓ | ✓ | ✓ | '우유팩 등'만 언급, '멸균팩' 명시 없음 |
| 은평구 | ✓ | – | – | – | ✓ | ✓ |  |
| 서대문구 | ✓ | ✓ | – | – | ✓ | ✓ |  |
| 마포구 | ✓ | – | ✓ | ✓ | ✓ | ✓ | 페이지에 해당 품목 언급 없음 |
| 양천구 | – | ✓ | – | ✓ | ✓ | ✓ |  |
| 강서구 | – | – | ✓ | ✓ | ✓ | ✓ |  |
| 구로구 | – | – | – | ✓ | ✓ | ✓ |  |
| 금천구 | – | – | ✓ | ✓ | ✓ | ✓ |  |
| 영등포구 | – | ✓ | ✓ | ✓ | ✓ | ✓ | 페이지에 해당 품목 언급 없음 |
| 동작구 | – | ✗ | – | ✓ | ✓ | ✓ |  |
| 관악구 | – | – | – | ✓ | ✓ | ✓ |  |
| 서초구 | ✓ | ✓ | – | ✗ | ✓ | ✓ | 종이팩(우유팩,두유팩 등)만 언급, '멸균팩' 명시 없음 |
| 강남구 | ✗ | ✗ | – | – | ✓ | ✓ |  |
| 송파구 | – | – | ✓ | ✓ | ✓ | ✓ | 페이지에 해당 품목 언급 없음 |
| 강동구 | – | – | ✓ | ✓ | ✓ | ✓ |  |

✓ 채움 · ✗ 구청 사이트에 있으나 분리배출 안내가 아니라 제외(소식지·카드뉴스·사업 공지·재질 예시만) · – 안내 페이지에 해당 품목 언급 없음 · ⊘ 구청 사이트 접속 불가 · ? 미조사. 칸별 원문·사유는 docs/region_notes_evidence.md

미조사·접속 불가 구와 서울 외 지역은 다음 라운드에서. 조사 원본은 `docs/research_region_notes_batch*_2026-11-12.json`, 표 재생성: `python3 tool/region_notes_table.py <조사.json…> --exclude …`

### 월간 리포트
- 매월 1일 09:00 로컬 알림(id 200) → 지난달 리포트. 기록 탭 상단 카드(지난달 기록 1건 이상)에서도 연다.
- 섹션: 헤더(리뿅이 — 재활용률이 지난달 이상이면 happy, 하락하면 idle + "다음 달엔 같이 올려보자뿅!") · 총 분류 · 재활용률 · 분류 비율 막대 · TOP3 ·
  탄소 절감 환산 · 수거일 체크 · 공유 · 면책 한 줄. 지난달 비교·연속 주는 비로그인 시 LockedOverlay.
- **탄소 계수는 `assets/data/carbon_factors.json` 에 출처(기관·문서·URL·연도)가 있는 것만.** 계수가 있는 품목이 그 달 기록의 50% 미만이면 ⑥ 섹션을 숨긴다.
  현재 `factors` 는 **비어 있어 ⑥은 "데이터가 더 쌓이면 보여드릴게요"** 로 나온다. 조사 기록과 비워 둔 이유: `docs/carbon_factors_research.md`.

| 계수 | 값 | 출처 |
|---|---|---|
| 소나무 환산 | 6.6 kgCO2/그루/년 (30년생) | 서울특별시 기후환경본부 보도자료(2013, 국립산림과학원 인용) https://news.seoul.go.kr/env/archives/31374 |
| 품목별 계수 | 없음 | 환경부·공단 공식 페이지에서 품목 1개당(또는 kg당 + 평균 무게) 수치를 확인하지 못함 |

- 공유 카드 1080x1350(피드) / 1080x1920(스토리), `lib/features/report/report_share_card.dart`. 애널리틱스 `report_viewed` / `report_shared`.
- 리포트는 기록 50건 이상일 때만 `users/{uid}/reports/{yyyy-MM}` 에 캐시.
- 홈 하단 "이번 달 n개 분류 · 재활용 m%" → 기록 탭.

### 데이터 검증
- `dart run tool/validate_data.dart`: regions 코드 형식·중복, regionNotes 의 코드 존재·https 출처·확인일·80자, carbon_factors 의 출처 필수 항목을 검사하고 하나라도 빠지면 종료 코드 1.
  CI(`.github/workflows/build.yml`)에서 analyze 전에 돈다.
- Firestore 규칙이 바뀌었다 (`feedback` type `region`, `regionNoteReports`). **`firebase deploy --only firestore:rules`** 필요.
- 새 패키지: `firebase_analytics` 하나.

## 온보딩 (최초 실행 1회)

`lib/features/onboarding/` — `onboarding_screen.dart`(흐름) · `intro_animation.dart`(인트로·말풍선) · `pages.dart`(1·2페이지 목업) · `consent_sheet.dart`(동의).
완료 여부는 shared_preferences `onboardingDone`. Firebase 익명 로그인은 백그라운드에서 따로 돌고 온보딩을 막지 않는다 (온보딩일 때는 SplashGate 를 거치지 않는다).

0. **인트로**: 흰 배경, `r_intro.gif` 240px 를 2초 타이머로 1회만 재생(끝나면 마지막 프레임 PNG 로 고정), 1.6초에 "리뿅이 등장했뿅!" 말풍선 400ms 페이드인, 2.6초에 1페이지로 200ms 슬라이드. 아무 데나 탭하면 즉시. 다시 보기에서도 인트로부터.
1. **찍으면 알려줘요**: 실제 `ResultCard`(`lib/widgets/result_card.dart`, 결과 화면과 같은 위젯)를 "컵라면 용기 / 일반 쓰레기 / 기름이 밴 용기는 재활용이 어려워요" 샘플로 그린 목업 + `r_wink.gif` 96px. 우상단 [건너뛰기] → 동의 페이지.
2. **수거일도 챙겨드려요**: 수거일 카드 두 상태(D-1 · 오늘 버리는 날) + 홈 위젯 미리보기 목업 + `r_happy.gif`.
3. **시작하기 전에**: 모두 동의 / [필수] 이용약관 · 개인정보처리방침(인앱 웹뷰 [보기]) / [선택] 수거일·리포트 알림. 필수 2개 전엔 [시작하기] 비활성. 뒤로가기는 2페이지로.
   저장: 기기 `consent_*` + `users/{uid}.consent = {terms, privacy, marketing, version: "2026-11"}`. 익명 로그인이 아직이면 `consent_remote_pending` 으로 두고 `attachAll` 이 로그인 뒤 올린다. **알림 권한은 여기서 묻지 않는다** (수거일 저장 시점에).
4. **완료 → 카메라 화면** (`lib/screens/capture_screen.dart`): 홈 위에 떠서 바로 시스템 카메라를 열고, 상단에 "뭐든 가져와뿅! 리뿅이가 알려주겠뿅!" + `r_wink` 48px 를 첫 1회만(`firstCameraHintShown`) 5초 또는 사진 선택까지. 뒤로가기 → 홈.
   사진 선택→분류→결과는 `lib/features/classify/classify_flow.dart` 로 빼서 홈과 카메라 화면이 같이 쓴다.

- 설정 → 약관 카드의 **온보딩 다시 보기**: 동의는 다시 묻지 않고 0→1→2 보고 홈으로.
- 시스템 "애니메이션 줄이기": 인트로는 마지막 프레임 정지 이미지 1초 뒤 넘어가고, 페이지 리뿅이는 `_static.png`.
- GIF 배경: 올려주신 원본은 완전 흰색이 아니라(#FBFBFB) 흰 화면에서 네모가 비쳐, `python3 tool/gif_keyout.py r_intro r_wink` 로 모서리에서 이어진 배경만 투명 처리했다 (얼굴의 흰 눈·입은 유지).
- 테스트 `test/onboarding_test.dart`: 최초 실행 전체 / 모두 동의 / 건너뛰기 / 필수 미체크 비활성 / 뒤로가기 / 인트로 탭 / 다시 보기 / 애니메이션 줄이기.
- 캡처용 데모: `--dart-define=DEMO=true --dart-define=DEMO_ONBOARDING=true` 면 데모 시드가 온보딩을 건너뛰지 않는다.

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
    places/                   거주 지역(법정동코드) 선택, 지역별 안내 박스, 대형폐기물 신고·수거함 링크
    auth/                     익명 → 구글 연결, 잠금 UI, 로그아웃·계정 삭제
    premium/                  RevenueCat 구독, 페이월, 무료 한도
    household/                가족 공유 집: 초대 코드, 공유 수거일, 멤버 체크인
    onboarding/               최초 실행: 인트로(리뿅이 등장) → 가치 2장 → 동의 → 카메라
    classify/                 사진 선택 → AI 분류 → 결과 (홈·카메라 화면 공용)
    legal/                    약관·개인정보 링크, 인앱 웹뷰, 권한 사전 안내, 내 데이터 삭제
    tips/                     품목별 팁 검색 (지역별 regionNotes 박스 포함)
    report/                   월간 리포트: 계산·화면·공유 카드·탄소 계수 로더
    feedback/                 결과 피드백, 지역 노트 신고
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

- [ ] 서울 외 지역 regionNotes 채우기, 접속 못 한 시군구(용산구 등 37곳) 안내 페이지 재확인
- [ ] 탄소 품목 계수: 환경부 「탄소중립 생활 실천 안내서」 원문 확보 후 채우기
- [ ] 분류 피드백("틀렸어요") 수집으로 프롬프트 개선
