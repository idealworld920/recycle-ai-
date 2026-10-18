# 정식 출시 체크리스트

내부 테스트까지 통과한 상태에서 **프로덕션**까지 가는 순서. 위에서부터 차례로.

## 0. 구독 (1.0 에 포함)

앱 코드는 준비돼 있어요. 아래는 전부 콘솔 작업이고, **순서대로** 해야 해요 (뒤 단계가 앞 단계를 참조).

- [ ] **판매자 계정**: Play Console → 수익 창출 설정 → "결제 프로필 만들기" → 사업자(라라스튜디오) 정보·사업자등록번호·정산 계좌. 승인까지 며칠 걸릴 수 있어요. 이게 없으면 구독 상품 메뉴가 안 열려요.
- [ ] **통신판매업 신고**: 정부24 → "통신판매업 신고" (수원시 팔달구, 소상공인은 면제·감면 있음). 신고번호가 나오면 `web/terms.html` 의 "신고 후 기재 예정" 자리에 적고 푸시 (gh-pages 자동 배포). 유료 구독을 파는 앱은 약관·스토어에 사업자 정보가 있어야 해요.
- [ ] **구독 상품 2개**: Play Console → 수익 창출 → 상품 → 구독 → 만들기
      - 상품 ID `resai_premium_monthly` · 이름 "ReSAI 프리미엄 월간" · 기본 요금제 `monthly` 월 2,900원 · 오퍼 "7일 무료 체험" (신규 구독자, 무료 체험 7일)
      - 상품 ID `resai_premium_yearly` · 이름 "ReSAI 프리미엄 연간" · 기본 요금제 `yearly` 연 19,900원 · 오퍼 "7일 무료 체험"
      - 둘 다 **활성화**. 혜택 설명: "사진 분류·AI 질문 무제한, 가족 공유". (앱에 적힌 가격과 같아야 해요. 바꾸면 `paywall_screen.dart` 의 기본 표시 가격도 같이.)
- [ ] **라이선스 테스터**: Play Console 홈(앱 선택 전) → 설정 → 라이선스 테스트 → 본인 Gmail 추가 → "라이선스 응답: RESPOND_NORMALLY". 이 계정은 결제가 실제로 청구되지 않고, 구독 갱신이 5분 단위로 빨라져요.
- [ ] **RevenueCat**: app.revenuecat.com 가입 → 프로젝트 "ReSAI" → Platforms → Google Play 앱 추가 (패키지 `com.idealworld.recycle_ai`)
      - **서비스 계정 JSON**: RevenueCat 화면의 안내대로 Google Cloud 콘솔(`recycle-ai-de1e1`) → IAM → 서비스 계정 만들기 → 키(JSON) 다운로드 → Play Console → 사용자 및 권한 → 그 서비스 계정 이메일 초대 (재무 데이터 보기 + 앱 관리 권한) → JSON 을 RevenueCat 에 업로드
      - Products → Import 로 위 두 상품 가져오기
      - Entitlements → **`premium`** 만들고 두 상품 연결 (이 이름 그대로, 앱 코드가 참조해요)
      - Offerings → `default` → 패키지 `$rc_monthly` = monthly, `$rc_annual` = yearly → "Current" 로 지정
      - API keys → Google Play **Public** key (`goog_…`) 복사
- [ ] **빌드에 키 넣기**: `dart_defines.example.json` → `dart_defines.json` 으로 복사, 키 붙여넣기. 이후 빌드는 전부
      `flutter build appbundle --release --dart-define-from-file=dart_defines.json`
      GitHub → 저장소 Settings → Secrets → `REVENUECAT_ANDROID_KEY` 에도 같은 값 (CI APK 용).
- [ ] **웹훅 함수 배포** (구독 상태를 Firestore 에 반영, 가족 공유 권한에 쓰여요):
      ```
      cd functions && npm install && cd ..
      firebase functions:secrets:set REVENUECAT_WEBHOOK_SECRET      # 아무 긴 랜덤 문자열 ([guid]::NewGuid() 두 개 이어 붙여도 됨)
      firebase deploy --only functions
      ```
      배포 끝에 나오는 URL(`https://asia-northeast3-recycle-ai-de1e1.cloudfunctions.net/revenuecatWebhook`)을
      RevenueCat → Integrations → Webhooks → URL 에, Authorization header 에 `Bearer <그 문자열>` 등록.
      (`firebase` 명령이 없으면 `npm install -g firebase-tools` → `firebase login`)
- [ ] **테스트 결제**: 키 넣은 번들을 내부 테스트에 올리고, 라이선스 테스터 계정의 폰에서 설정 → 프리미엄 → "7일 무료로 시작" → Google 결제 시트 → 완료 → 홈에 프리미엄 반영. RevenueCat → Customers 에 해당 uid 가 보이면 끝. 5분 뒤 갱신 이벤트가 웹훅으로 들어오는지 Firestore `users/{uid}.premium` 확인.
- [ ] 결제 안 되면: 상품이 "활성" 인지, 앱이 테스트 트랙에 **같은 패키지·같은 서명**으로 올라가 있는지, 테스터 계정이 라이선스 테스터인지 순서로 확인.

## 1. 코드·빌드

- [ ] `pubspec.yaml` `version:` 올리기 (`1.0.0+N`, N 은 Play 에 올린 적 없는 숫자)
- [ ] `flutter analyze` / `flutter test` 통과 (CI 초록)
- [ ] `flutter build appbundle --release --dart-define-from-file=dart_defines.json` (APP_CHECK 관련 define 은 넣지 않기 → Play Integrity)
- [ ] 내부 테스트에 올려서 Play 설치본으로 확인: 스플래시 → 홈 3초 이내, 배너 없음, 사진 분류 1회, 물어보기 1회, 수거일 저장 → 알림 권한 → 위젯

## 2. Firebase / Google Cloud

- [ ] **Firestore 보안 규칙 배포**: `firebase deploy --only firestore:rules` (한 번도 안 했으면 지금. 콘솔 → Firestore → 규칙 탭에서 `users/{uid}` 규칙이 보이면 된 것)
- [ ] **App Check 적용(enforce)**: Firebase 콘솔 → App Check → API 탭 → **Firebase AI Logic** → "적용" 켜기.
      Play 설치본에서 AI 가 되는 걸 확인한 **뒤에** 켤 것. 켜면 토큰 없는 요청(API 키 도용)이 거부돼요. Firestore·Auth 도 같은 방식으로 켤 수 있어요(선택).
- [ ] **OAuth 동의 화면 게시**: Google Cloud 콘솔 → API 및 서비스 → OAuth 동의 화면 → 게시 상태가 "테스트"면 **앱 게시** (프로덕션).
      테스트 상태면 구글 연결이 100명까지만 되고 토큰이 7일마다 만료돼요. 기본 스코프(email·profile)만 쓰므로 검증 절차는 없어요.
- [ ] Firebase 디지털 지문: 업로드 키 SHA-256 + Play 앱 서명 키 SHA-256 둘 다 있는지
- [ ] 요금제: Vertex AI 는 Blaze. **예산 알림** 걸어두기 (Google Cloud → 결제 → 예산 및 알림, 예: 월 10,000원)

## 3. Play Console → 앱 콘텐츠 (정책 → 앱 콘텐츠)

전부 채워야 프로덕션 버튼이 열려요.

- [ ] **개인정보처리방침**: https://idealworld920.github.io/recycle-ai-/privacy.html
- [ ] **앱 액세스 권한(로그인 세부정보)**: **"예, 제한된 부분이 있음"** (프리미엄 결제 뒤에 잠긴 기능이 있어서). Google 검토자는 결제·무료 체험을 못 하므로 **검토자 코드**를 줘요.
      - 코드 만들기: PowerShell `[guid]::NewGuid().ToString("N")` → `dart_defines.json` 의 `REVIEW_CODE` 에 넣고 빌드 (번들마다 같은 코드 유지)
      - Play Console 에 "안내 추가" → 이름 `Reviewer code`, 사용자 이름 `reviewer`, 비밀번호 칸에 그 코드, 안내문:
        ```
        회원가입·로그인 없이 바로 사용 가능합니다 (익명 계정 자동 생성).
        유료 기능(프리미엄: 무제한 분류·질문, 가족 공유)은 결제 없이 아래 방법으로 열 수 있습니다:
        홈 → 오른쪽 위 설정(⚙️) → 맨 아래 "앱 정보" 글자를 7번 탭 → 검토자 코드 입력창에 위 비밀번호 입력 → 30일간 프리미엄 활성화.
        Google 계정 연결(설정 → 구글로 연결)은 선택 기능이며, 검토에 필요하지 않습니다.
        ---
        No sign-up or login is required (an anonymous account is created automatically).
        Paid features (Premium: unlimited classification/questions, family sharing) can be unlocked without payment:
        Home → Settings (gear, top right) → tap the "앱 정보" (App info) text at the bottom 7 times → enter the password above as the reviewer code → Premium is enabled for 30 days.
        Google account linking is optional and not needed for review.
        ```
- [ ] **광고**: 광고 없음
- [ ] **콘텐츠 등급**: 설문 시작 → 카테고리 "유틸리티·생산성·커뮤니케이션 등" → 폭력·성적·약물 등 전부 "아니요" → 사용자 생성 콘텐츠 "아니요"(채팅은 AI 와 1:1, 다른 사용자에게 공개되지 않음) → 전체이용가
- [ ] **타겟층 및 콘텐츠**: 연령대 **18세 이상**만 선택 (18세 미만을 포함하면 가족 정책 심사가 붙어요. 앱이 아동 대상이 아니므로 18+ 로 두는 게 간단)
- [ ] **뉴스 앱**: 아니요
- [ ] **코로나19 접촉 추적·상태 앱**: 아니요
- [ ] **데이터 보안**: README "법적 문서와 Play Console 데이터 안전" 의 표 그대로. 요약:
      수집 = 이메일(선택, 구글 연결 시)·사진(임시 처리, 저장 안 함)·앱 활동(분류 기록·채팅)·기기 ID(익명 UID, App Check)·비정상 종료 로그.
      전송 중 암호화 예, 삭제 요청 가능 예(설정 → 내 데이터 삭제), 제3자 공유 없음.
- [ ] **정부 앱**: 아니요
- [ ] **금융 기능**: 없음 (인앱 구독은 여기 해당 안 됨. Play 가 번들에서 결제 라이브러리를 보고 "인앱 구매" 표시를 자동으로 붙여요)
- [ ] **건강**: 해당 없음

## 4. Play Console → 스토어 등록정보

- [ ] `docs/STORE_LISTING.md` 의 이름·간단한 설명·자세한 설명 붙여넣기
- [ ] 아이콘 512, 그래픽 1024x500, 휴대전화 스크린샷 4장 (`assets/store/`)
- [ ] 카테고리 라이프스타일, 연락처 이메일, 개인정보처리방침 URL
- [ ] 스토어 설정 → 앱 카테고리·태그

## 5. 테스트 트랙 요건 (개인 개발자 계정이면 필수)

- [ ] 2023년 11월 이후 만든 **개인** 개발자 계정은 **비공개 테스트에서 테스터 20명 이상이 14일 연속** 참여해야 "프로덕션 액세스 신청" 버튼이 열려요.
      Play Console 대시보드에 "프로덕션 액세스 신청" 카드가 있으면 이 경우예요.
      → 테스트 및 출시 → 비공개 테스트 → 버전 만들기 → 테스터 목록(이메일 20개 이상 또는 Google 그룹) → 링크 공유 → 14일 뒤 신청서 작성.
- [ ] 조직(사업자) 계정이면 이 요건이 없어요. 대시보드에 "프로덕션 액세스 신청"이 없으면 바로 6번.

## 6. 프로덕션 출시

- [ ] 테스트 및 출시 → **프로덕션** → 새 버전 만들기 → 내부 테스트에서 확인한 것과 같은 번들 (버전 코드 동일해도 됨, "라이브러리에서 추가")
- [ ] 국가: 대한민국 (필요하면 전체)
- [ ] 출시 노트 → 검토 → **프로덕션으로 출시 시작**
- [ ] 심사 보통 1~7일. 첫 앱은 길어질 수 있어요. 반려되면 사유 메일에 적힌 정책 항목을 보고 수정 후 재제출.

## 7. 출시 직후

- [ ] 실제 스토어 페이지에서 설치 → 전체 흐름 한 번 더
- [ ] Firebase 콘솔 → App Check → 지표에서 "확인되지 않은 요청"이 없는지
- [ ] Google Cloud 결제 → 일일 비용 확인 (AI 호출량)
- [ ] 리뷰·문의 메일(idealworld13@gmail.com) 확인 루틴
- [ ] RevenueCat → Charts 로 체험 → 유료 전환율 보기
- [ ] 1.1 계획: Crashlytics(선택), 리뷰 반영
