# 알림 시스템 (1.3.0)

리뿅이가 수거·분류 타이밍에만 알려준다. 종류별로 설정 → 알림에서 켜고 끌 수 있고, 가족 공유 알림만 FCM(서버 푸시), 나머지는 로컬 알림. **프로모션성 알림은 없다.**

코드: `lib/features/notifications/` (설정값 `notification_prefs.dart`, 문구 `notification_lines.dart`, 시각 계산 `notification_planner.dart`, 백그라운드 액션 `notification_background.dart`, FCM `push_service.dart`, 설정 화면 `notification_settings_screen.dart`) · `lib/features/schedule/notification_service.dart`(예약) · `functions/index.js`(onCheckin, householdEveningReminder, setMemberName) · `assets/data/notification_lines.json`(문구).

## 알림 종류

| 종류 (`NotificationType.key`) | 트리거 | 기본값 | 채널 | 문구 키 | 탭 → | 비고 |
|---|---|---|---|---|---|---|
| `pickup_eve` 수거일 전날 저녁 | 수거 요일 전날, 수거일 설정의 알림 시각(기본 20:00), 요일 반복 | ON | `pickup_reminders` 수거일 알림 | `pickupEve` | 홈 | 액션 **[버렸뿅!]** (내일 날짜로 체크인) |
| `pickup_morning` 수거일 당일 아침 | 수거 요일 당일, 알림 설정의 아침 시각(기본 07:30), 요일 반복 | ON | `pickup_reminders` | `pickupMorning` | 홈 | 액션 **[버렸뿅!]** → 앱 안 열고 체크인 + 알림 제거 |
| `weekly_report` 주간 리포트 | 일요일 20:00 1회. 앱을 켤 때마다 다시 계산, **그 주 분류 0개면 예약 안 함** | ON | `reports` 리포트·소식 | `weeklyReport` {N}{M} | 리포트 | 월간 리포트(매월 1일 09:00, id 200)는 기존 유지 |
| `family_checkin` 가족 체크인 | FCM: `households/{id}/checkins/{date}` 에 새 품목이 들어오면 체크한 사람 제외 가구원 | ON | `family` 가족 공유 | `familyCheckin` {이름}{품목} | 홈 | 가구 있을 때만 설정에 표시. 이름 = `members[].displayName` → nickname → "가족" |
| `family_reminder` 가족 미체크 리마인드 | FCM: 매일 21:00 KST 스케줄, 오늘 수거일인 집 중 체크인 0건 → 전원. 집당 하루 1회(`households.reminderSentDate`) | ON | `family` | `familyReminder` {품목} | 홈 | 가구 있을 때만 표시 |
| `special_day` 특별 수거일 | `special_days.json` 중 sourceUrl 있는 항목, 해당일 전날 20:00. 거주 지역 설정 + 항목 `region` 이 전국이거나 내 지역일 때만 (최대 30개, id 400~) | ON | `pickup_reminders` | `specialDay` {날짜}{사유}{품목} | 홈 | 현재 파일은 비어 있음 |
| `trial_end` 체험 종료 | 체험 시작 +5일·+6일 20:00 (id 300·301) | ON | `account` 계정·구독 | `trialEndD2`/`trialEndD1` (존댓말) | 프리미엄 관리 | 체험 중일 때만 설정에 표시, 끄면 경고. 취소·만료 감지 시 취소 |
| `comeback` 오랜만 인사 | 마지막 실행 +72h 1회. 앱을 켤 때마다 다시 잡히므로 72h 안 켜면 안 울림. **평생 1회**(`users/{uid}.comebackNudgeSentAt`) | ON | `reports` | `comeback` | 홈 | 울린 시각이 지난 뒤 앱을 켜면 소진 처리 |

공통: 방해 금지(기본 ON, 22:00~07:00, 설정에서 on/off·시각 변경)에 걸리면 **끝나는 시각으로 미룸** (`QuietHours.nextAllowed`), 끄면 미루지 않음 · 아이콘 `r_wink_static.png` · 비정확 알람(`inexactAllowWhileIdle`, SCHEDULE_EXACT_ALARM 미사용) · 재예약 = 앱 실행 + 설정 변경 + 수거일 변경 + 로그인, 재부팅은 `ScheduledNotificationBootReceiver` 가 복구 · 알림 권한은 수거일 첫 저장 때 1회만 요청, 거부 시 설정 화면 배너로만 안내.

알림 id 대역: 100~139 전날 / 150~189 아침 / 200 월간 / 201 주간 / 210 오랜만 / 300·301 체험 / 400~429 특별일 / 1000~ 캘린더 일정.

## 설정 저장
`users/{uid}/settings/notifications` = `{enabled:{<key>:false…}, morningHour, morningMinute, quiet:{start,end(분),enabled}, updatedAt}` + 기기 `notification_prefs_v1`. 꺼진 것만 `enabled` 에 들어간다. Functions 도 같은 문서를 읽어 끈 사람·방해 금지 시간을 제외한다.

## FCM
- 토큰: `users/{uid}/fcmTokens/{deviceId}` `{token, platform, updatedAt}` — deviceId 는 설치 단위 랜덤(기기 prefs). 갱신 시 같은 문서 덮어씀, 로그아웃·데이터 삭제·계정 전환 시 삭제(`PushService.detach`). 규칙: 본인만 write, read 는 false(Functions 는 관리자 권한).
- 발송: `sendEachForMulticast`, 채널 `family`, 무효 토큰(`registration-token-not-registered`/`invalid-registration-token`) 자동 삭제.
- 앱: 포그라운드 수신 → 상단 인앱 배너(리뿅이 아이콘 + 본문, 5초, 탭 → 홈) · 백그라운드/종료 상태 탭 → 홈. 매니페스트 기본 채널 `family`.

## 분석 이벤트
`notification_scheduled{type}` · `notification_tap{type}` · `notification_action_checkin{type}` (+ `checkin_done{source:notification}`) · `fcm_token_saved` · `push_received{type, foreground}` · `notification_toggle{type, on}` · `quiet_hours_changed{start,end,on}` · `notification_permission{granted}`.

## 배포
```bash
# Functions (Node 22 — Node 20 은 2026-10-30 지원 종료라 22 로 올려 둠)
cd functions && npm install && cd ..
firebase deploy --only functions
#  → householdEveningReminder 가 처음 만들어질 때 Cloud Scheduler API(cloudscheduler.googleapis.com) 활성화를 CLI 가 묻는다. 예.
#     리전 asia-northeast3(서울). Cloud Scheduler 는 App Engine 리전이 필요할 수 있다(프로젝트에 App Engine 앱이 없으면 콘솔에서 asia-northeast3 로 생성).
firebase deploy --only firestore:rules      # fcmTokens 규칙
```
Firebase 콘솔: Cloud Messaging API(V1) 가 켜져 있는지(프로젝트 설정 → 클라우드 메시징). `google-services.json` 은 그대로.

## 테스트 순서
1. **로컬 알림(기기 시계 조작)**: 수거일을 "내일" 요일로 저장 → 알림 설정에서 전날 시각을 2분 뒤로 → 기다리거나 기기 시계를 그 시각으로 → 제목 "내일이뿅!" + [버렸뿅!]. 당일 아침은 시계를 수거 요일 07:29 로 → 07:30 "오늘이다뿅!!".
2. **[버렸뿅!] 액션**: 아침 알림에서 버튼 탭 → 알림 사라짐, 앱 안 열림 → 앱 열면 홈 카드에 체크 반영 + DebugView `notification_action_checkin`, `checkin_done{source:notification}`.
3. **방해 금지**: 전날 시각을 23:00 으로 → 알림이 다음 날 07:00 에 옴(시계 조작). 설정에서 방해 금지를 09:00~10:00 으로 바꾸고 테스트 알림(설정 → 테스트 알림 보내기)은 즉시 오는지(테스트 알림은 방해 금지 미적용).
4. **주간 리포트**: 분류 1개 이상 한 주, 일요일 20:00 으로 시계 → "이번 주 결산이뿅". 분류 0개인 새 설치에선 안 옴.
5. **오랜만 인사**: 앱 종료 후 시계를 +73h → 알림. 다시 켜면 설정 토글은 유지되고 두 번 다시 안 옴.
6. **체험 종료**: 라이선스 테스터로 체험 시작 → 알림 설정에 "프리미엄 체험 종료 안내" 토글이 보임 → 끄면 경고 문구. `adb shell dumpsys alarm | findstr recycle` 로 300/301 확인.
7. **FCM 체크인(두 계정)**: 폰 A·B 같은 집, 둘 다 Google 연결 → A 에서 "버렸어요" → B 에 "{A 이름}님이 버렸뿅" (B 가 포그라운드면 상단 배너, 백그라운드면 시스템 알림). B 가 가족 체크인 토글을 끄면 안 옴.
8. **저녁 리마인드**: 오늘이 수거일인 집에서 아무도 체크 안 함 → 21:00 KST 에 전원 수신. Functions 로그 `evening reminder: N households`. 바로 보려면 Firebase 콘솔 → Functions → householdEveningReminder → "지금 실행"(Cloud Scheduler 작업에서).
9. **이름 바꾸기**: 집 시트 → (나) 옆 연필 → 이름 변경 → 상대 폰 푸시에 새 이름.
10. **토큰 정리**: 로그아웃 → Firestore `users/{uid}/fcmTokens` 에서 이 기기 문서 사라짐 → 더 이상 그 계정 푸시 안 옴.

## Play Console 데이터 보안 양식에 추가할 항목
- **기기 또는 기타 ID** (Device or other IDs): 수집 ✔ — 용도 "앱 기능"(푸시 알림 전달). 공유 ✘. 이유: FCM 등록 토큰과 설치 단위 랜덤 ID(`fcmTokens/{deviceId}`)를 서버에 저장.
- 암호화 전송 ✔ (HTTPS), 삭제 요청 가능 ✔ (설정 → 내 데이터 삭제가 토큰 문서까지 지움).
- 기존 항목 유지: 앱 활동(분석 이벤트), 앱 정보 및 성능, 이메일(Google 연결 시).
