# 사용 분석 (Firebase Analytics) — 1.2.1

목표: 설치 후 사용자가 어디까지 가고 어디서 빠지는지, 무엇을 쓰는지. **사진·채팅 본문·이메일·정확한 위치는 어떤 이벤트에도 넣지 않는다.**

- 래퍼: `lib/core/analytics.dart` (`Analytics.log / screen / setUserProperty`). 파라미터는 String/num/bool/enum 만, null 은 뺀다. debug 빌드에선 전부 `[A] 이벤트 {파라미터}` 로 `debugPrint`.
- 화면 추적: `AnalyticsNavigatorObserver` (MaterialApp.navigatorObservers) 가 라우트 전환마다 `screen_view`. 이름은 `pushPage` 가 위젯 타입으로 넣는다(`ResultScreen` → `result_screen`). 바텀시트·오버레이는 `Analytics.screen()` 수동 호출.
- 수집 끄기: `--dart-define=ANALYTICS_DISABLED=true` → Firebase 준비 뒤 `setAnalyticsCollectionEnabled(false)`.
- 테스터: `is_tester` 사용자 속성(수집은 유지). 이메일 목록은 `UserProps.testerEmails`, debug 빌드도 true.

## 주요 이벤트 (Firebase 콘솔 → 이벤트 → "주요 이벤트로 표시" 직접 체크)
`first_classify_done`, `classify_done`, `schedule_set`, `purchase_success`, `household_create`

## 사용자 속성 (`lib/core/analytics_user_props.dart`, 앱 시작 + 값 바뀔 때)

| 속성 | 값 | 출처 |
|---|---|---|
| `is_tester` | `true`/`false` | 계정 이메일이 테스터 목록 or debug 빌드 (이메일은 보내지 않음) |
| `premium_status` | `none`/`trial`/`active`/`cancelled`/`expired` | `PremiumStore.analyticsStatus` (RevenueCat entitlement, 이전에 있었고 지금 없으면 expired) |
| `region_set` / `region_sido` | `true`/`false` · 시도 짧은 이름(`서울`, `경기`…)/`none` | `RegionStore.admin.sidoShort` — 구 단위 금지 |
| `in_household` / `household_role` | `true`/`false` · `owner`/`member`/`none` | `HouseholdStore` |
| `auth_type` | `anonymous`/`google` | `AuthStore.isAnonymous` |
| `collection_bucket` | `0`/`1-9`/`10-29`/`30-55`/`56` | 도감 개수 |
| `install_age_bucket` | `0`/`1-3`/`4-7`/`8-30`/`30+` | `installedAt` 기준 일수 |

## 이벤트 전체 (코드에서 자동 추출, `Analytics.log` / `Analytics.screen` 호출 지점)

| 이벤트 | 파라미터 | 위치 |
|---|---|---|
| `badge_earned` | `{'level': level}` | `features/classify/classify_flow.dart:120` classifyOne() |
| `badge_earned` | `{'level': 'crown'}` | `features/paywall/paywall_screen.dart:81` _buy() |
| `calendar_event_add` | `{'kind': kind.name, 'remind': remind}` | `features/calendar/calendar_screen.dart:400` showAddEventSheet() |
| `calendar_view` | `{'month_offset': 0}` | `features/calendar/calendar_screen.dart:37` initState() |
| `calendar_view` | `{'month_offset': _monthOffset(_month)}` | `features/calendar/calendar_screen.dart:83` CalendarView.build() (월 스와이프) |
| `chat_answer` | `{'elapsed_ms': sw.elapsedMilliseconds}` | `features/chat/chat_screen.dart:116` _send() |
| `chat_limit_hit` | `{'daily_count': count}` | `features/chat/chat_screen.dart:101` _send() |
| `chat_send` | `{'length_bucket': Analytics.lengthBucket(text.length)}` | `features/chat/chat_screen.dart:113` _send() |
| `checkin_done` | `{'source': source}` | `features/schedule/schedule_store.dart:167` checkIn() |
| `classify_done` | `{ 'category': result.category.key, 'recyclable': result.category.isRecyclable, 'confidence_bucket': Analytics.confidenceBucket(result.confidence), 'elapsed_ms': sw.elapsedMilliseconds, 'is_first': isFirst, }` | `features/classify/classify_flow.dart:107` classifyOne() |
| `classify_fail` | `{'reason': 'limit'}` | `features/classify/classify_flow.dart:42` run() |
| `classify_fail` | `{'reason': failReason(e)}` | `features/classify/classify_flow.dart:74` run() |
| `classify_fail` | `{'reason': failReason(e)}` | `features/classify/classify_flow.dart:77` run() |
| `classify_fail` | `{'reason': 'limit'}` | `features/classify/multi/multi_classify_screen.dart:73` _runOne() |
| `classify_fail` | `{'reason': ClassifyFlow.failReason(e)}` | `features/classify/multi/multi_classify_screen.dart:86` _runOne() |
| `classify_fail` | `{'reason': ClassifyFlow.failReason(e)}` | `features/classify/multi/multi_classify_screen.dart:89` _runOne() |
| `classify_limit_hit` | `{'daily_count': services.freeLimits.classifyCountToday()}` | `features/classify/classify_flow.dart:41` run() |
| `classify_limit_hit` | `{'daily_count': services.freeLimits.classifyCountToday()}` | `features/classify/multi/multi_classify_screen.dart:72` _runOne() |
| `classify_start` | `{'source': source == ImageSource.camera ? 'camera' : 'gallery', 'photo_count': 1}` | `features/classify/classify_flow.dart:59` run() |
| `classify_start` | `{'source': 'multi', 'photo_count': _items.where((i) => i.done == null).length}` | `features/classify/multi/multi_classify_screen.dart:57` _runAll() |
| `collection_unlock` | `{'item_id': tip!.id, 'total_count': total}` | `features/classify/classify_flow.dart:118` classifyOne() |
| `collection_view` | `{'filled_count': store.collected}` | `features/stats/collection_sheet.dart:61` showCollectionSheet() |
| `data_delete_done` | `{'elapsed_ms': sw.elapsedMilliseconds}` | `features/legal/data_deletion.dart:104` run() |
| `data_delete_start` | `—` | `features/legal/data_deletion.dart:87` run() |
| `feedback_send` | `—` | `features/feedback/feedback_sheet.dart:56` _submit() |
| `first_classify_done` | `{'seconds_since_install': DateTime.now().difference(services.settings.installedAt).inSeconds}` | `screens/result_screen.dart:100` initState() |
| `google_link_fail` | `{'code': AuthErrors.shortCode(error)}` | `features/auth/link_flows.dart:40` connectGoogle() |
| `google_link_start` | `—` | `features/auth/link_flows.dart:23` connectGoogle() |
| `google_link_success` | `—` | `features/auth/link_flows.dart:29` connectGoogle() |
| `history_delete` | `{'count': n, 'from': from}` | `features/history/delete_records.dart:99` confirmAndDelete() |
| `history_delete` | `{'count': n, 'from': 'select'}` | `features/history/history_screen.dart:233` build() (스와이프 삭제) |
| `history_detail_view` | `—` | `screens/result_screen.dart:92` initState() |
| `history_view` | `{'from': 'notification'}` | `screens/home_shell.dart:46` _onAction() |
| `history_view` | `{'from': 'tab'}` | `screens/home_shell.dart:84` build() |
| `household_code_share` | `{'channel': ShareService.shareChannel(r.raw)}` | `features/household/household_sheet.dart:110` _HouseholdBody.build() (초대 공유 버튼) |
| `household_create` | `—` | `features/household/household_store.dart:109` create() |
| `household_join_fail` | `{'reason': joinFailReason(e.code)}` | `features/household/household_store.dart:125` join() |
| `household_join_fail` | `{'reason': 'network'}` | `features/household/household_store.dart:128` join() |
| `household_join_start` | `—` | `features/household/household_store.dart:116` join() |
| `household_join_success` | `—` | `features/household/household_store.dart:123` join() |
| `household_leave` | `—` | `features/household/household_store.dart:139` leave() |
| `logout` | `—` | `features/auth/link_flows.dart:150` signOutFlow() |
| `manage_subscription_tap` | `{'from': 'premium_sheet'}` | `features/paywall/premium_sheet.dart:64` showPremiumSheet() |
| `manage_subscription_tap` | `{'from': 'settings_card'}` | `screens/settings_sheet.dart:82` showSettingsSheet() |
| `notification_permission` | `{'granted': granted}` | `features/schedule/notification_service.dart:75` requestPermission() |
| `onboarding_complete` | `{'auth_choice': 'google'}` | `features/onboarding/account_page.dart:48` _google() |
| `onboarding_complete` | `{'auth_choice': 'skip'}` | `features/onboarding/account_page.dart:87` build() (나중에 할게요) |
| `onboarding_page_view` | `{'page': i == _lastIndex ? 'account' : '${i + 1}'}` | `features/onboarding/onboarding_screen.dart:49` _logPage() |
| `onboarding_skip` | `{'page': _page + 1}` | `features/onboarding/onboarding_screen.dart:106` _skip() |
| `onboarding_start` | `—` | `features/onboarding/onboarding_screen.dart:41` initState() |
| `paywall_select_plan` | `{'plan': 'yearly'}` | `features/paywall/paywall_screen.dart:167` build() (연간 타일) |
| `paywall_select_plan` | `{'plan': 'monthly'}` | `features/paywall/paywall_screen.dart:179` build() (월간 타일) |
| `paywall_view` | `{'source': widget.source.analyticsName}` | `features/paywall/paywall_screen.dart:49` initState() |
| `purchase_fail` | `{'plan': _plan, 'reason': 'cancelled'}` | `features/paywall/paywall_screen.dart:86` _buy() |
| `purchase_fail` | `{'plan': _plan, 'reason': 'error'}` | `features/paywall/paywall_screen.dart:90` _buy() |
| `purchase_start` | `{'plan': _plan}` | `features/paywall/paywall_screen.dart:75` _buy() |
| `purchase_success` | `{'plan': _plan, 'is_trial': trial}` | `features/paywall/paywall_screen.dart:80` _buy() |
| `reduce_motion_toggle` | `{'on': on}` | `main.dart:313` didChangeAccessibilityFeatures() |
| `region_guide_tap` | `{'type': 'bulk_report'}` | `features/places/places_section.dart:85` _openBulky() |
| `region_guide_tap` | `{'type': 'collection_box'}` | `features/places/places_section.dart:152` _openBattery() |
| `region_guide_tap` | `{'type': 'waste_guide'}` | `features/places/region_guidance.dart:164` _Fallback.build() |
| `region_set` | `{'sido': region.sidoShort}` | `features/places/region_store.dart:49` selectAdmin() |
| `report_shared` | `{'month': r.key, 'format': story ? 'story' : 'feed'}` | `features/report/report_screen.dart:113` _share() |
| `report_viewed` | `{'month': _report!.key, 'total': _report!.total}` | `features/report/report_screen.dart:57` didChangeDependencies() |
| `restore_success` | `—` | `features/paywall/paywall_screen.dart:101` _restore() |
| `restore_success` | `—` | `features/paywall/premium_sheet.dart:79` showPremiumSheet() |
| `restore_tap` | `{'from': 'paywall'}` | `features/paywall/paywall_screen.dart:96` _restore() |
| `restore_tap` | `{'from': 'premium_sheet'}` | `features/paywall/premium_sheet.dart:76` showPremiumSheet() |
| `result_feedback` | `{'correct': answer == widget.result.category.group}` | `features/feedback/feedback_sheet.dart:55` _submit() |
| `result_section_view` | `{'section': e.key}` | `screens/result_screen.dart:71` _checkSections() |
| `result_share` | `{'channel': shareChannel(r.raw)}` | `features/share/share_service.dart:56` shareResult() |
| `review_prompt_dismissed` | `—` | `features/review/review_prompter.dart:86` maybePrompt() |
| `review_prompt_shown` | `—` | `features/review/review_prompter.dart:89` maybePrompt() |
| `ribbong_bubble_shown` | `{'condition': when.name}` | `features/mascot/home_ribbong.dart:122` build() (대사 선택 시, 하루 1회) |
| `ribbong_tap` | `{'location': 'home', 'tap_count': _taps.length}` | `features/mascot/home_ribbong.dart:57` _onTap() |
| `ribbong_tickle` | `—` | `features/mascot/home_ribbong.dart:60` _onTap() |
| `schedule_reminder_tap` | `—` | `features/schedule/notification_service.dart:46` init() (알림 탭 콜백) |
| `schedule_set` | `{ 'weekday_count': WasteType.values.fold<int>(0, (a, t) => a + s.daysOf(t).length), 'has_time': s.isConfigured, }` | `features/schedule/schedule_store.dart:122` save() |
| `splash_tap_skip` | `{'kind': widget.plan.kind.name}` | `features/splash/splash_screen.dart:103` build() (onTap) |
| `screen_view` screen_name=account_sheet | — | `features/auth/link_flows.dart:67` askSwitchToExisting() |
| `screen_view` screen_name=account_sheet | — | `features/auth/link_flows.dart:108` signOutFlow() |
| `screen_view` screen_name=delete_confirm | — | `features/history/delete_records.dart:18` confirm() |
| `screen_view` screen_name=delete_confirm | — | `features/legal/data_deletion.dart:15` showDeleteDataSheet() |
| `screen_view` screen_name=first_classify_celebration | — | `screens/result_screen.dart:103` initState() |
| `screen_view` screen_name=household_sheet | — | `features/household/household_sheet.dart:26` showHouseholdSheet() |
| `screen_view` screen_name=paywall | — | `features/paywall/paywall_screen.dart:48` initState() |
| `screen_view` screen_name=region_picker | — | `features/places/region_picker_sheet.dart:15` showRegionPickerSheet() |
| `screen_view` screen_name=settings | — | `screens/settings_sheet.dart:29` showSettingsSheet() |

스펙 대비 메모
- `checkin_done.source` 는 지금 `home` 만 발생한다 (알림·캘린더에서 바로 체크인하는 UI 가 없음). `ribbong_tap.location` 도 탭 가능한 리뿅이가 홈뿐이라 `home` 만.
- `report_viewed` 는 기존 파라미터(`month`, `total`) 그대로 유지.
- `review_prompt_dismissed` = 리뿅이 말풍선(3초)을 X 로 닫아 리뷰 요청까지 안 간 경우. Play 인앱 리뷰 다이얼로그 자체의 닫힘은 OS 가 알려주지 않는다.
- `household_code_share.channel`, `result_share.channel` 은 share_plus 의 대상 패키지명을 kakao/sns/sms/copy/other 로만 접는다 (패키지명은 안 보냄).

## 인앱 리뷰 (`lib/features/review/review_prompter.dart`)
- 조건: 설치 24시간 경과 AND (분류 성공 3회째 결과 화면에서 2초 뒤 OR 수거일 체크인 2회째) 중 먼저 오는 쪽. 구독을 시작한 세션에선 안 묻고, 요청 뒤 90일 재요청 금지 (`users/{uid}.reviewPromptAt` + 기기).
- 리뿅이 말풍선 "리뿅이 어때뿅? 별점 주면 힘나뿅!" 3초 → `InAppReview.requestReview()`. 미지원·실패는 조용히.

## DebugView 로 확인하는 순서 (테스트 폰)
1. `adb shell setprop debug.firebase.analytics.app com.idealworld.recycle_ai` (끌 땐 `.none.`) → Firebase 콘솔 → Analytics → DebugView.
2. 앱 삭제 후 설치 → 실행: `screen_view`(splash 없음, 온보딩은 home 라우트라 수동 없음) → `onboarding_start` → `onboarding_page_view{page:1}` → 스와이프 `page:2` → 건너뛰기 `onboarding_skip{page:2}` → `page:3` → 동의 → `page:account` → 나중에 `onboarding_complete{skip}`. 사용자 속성 탭에서 `is_tester`, `install_age_bucket=0`, `auth_type=anonymous` 확인.
3. 카메라로 분류: `classify_start{camera,1}` → `classify_done{category,recyclable,confidence_bucket,elapsed_ms,is_first:true}` → `first_classify_done{seconds_since_install}` → `screen_view{first_classify_celebration}` → `screen_view{result_screen}` → 스크롤하며 `result_section_view{howto→region→caution→tip→item_tip}` (각 1회). 도감 새 품목이면 `collection_unlock`.
4. 결과 화면 공유 → `result_share{channel}`. "결과가 틀렸나요?" → `result_feedback{correct}` + `feedback_send`.
5. 설정 → `screen_view{settings}` → 프리미엄 카드 → `screen_view{paywall}` + `paywall_view{source:settings}` → 월간 탭 `paywall_select_plan{monthly}` → 구독 시작 `purchase_start` → 취소 `purchase_fail{cancelled}` (라이선스 테스터로 완료하면 `purchase_success{plan,is_trial}` + `badge_earned{crown}`, 속성 `premium_status=trial`).
6. 설정 → 거주 지역 → `screen_view{region_picker}` → 선택 `region_set{sido}`, 속성 `region_set=true`, `region_sido`.
7. 설정 → 수거일 저장 → `notification_permission{granted}` → `schedule_set{weekday_count,has_time}`. 홈 카드 "버렸어요" → `checkin_done{home}` (2회째면 리뷰 말풍선 → `review_prompt_shown`).
8. 물어보기 탭 → 질문 → `chat_send{length_bucket}` → `chat_answer{elapsed_ms}`. 6번째 질문 → `chat_limit_hit{daily_count:5}` → 페이월 `paywall_view{limit}`.
9. 기록 탭 → `history_view{tab}` → 캘린더 세그먼트 → `calendar_view{0}` → 월 스와이프 `calendar_view{-1}` → 항목 길게 눌러 삭제 → `screen_view{delete_confirm}` → `history_delete{count,from:select}`.
10. 홈 리뿅이 탭 ×5 → `ribbong_tap{home,1..5}` + `ribbong_tickle`. 그날 첫 홈 진입에 `ribbong_bubble_shown{condition}` 1회.
11. 설정 → 집 → `screen_view{household_sheet}` → 만들기 → `paywall_view{household}`(비구독) / `household_create`. 초대 공유 → `household_code_share{channel}`. 다른 폰에서 참여 → `household_join_start` → `household_join_success` (잘못된 코드 → `household_join_fail{invalid}`).
12. 설정 → 계정 → Google 연결 → `google_link_start` → `google_link_success` (실패 시 `google_link_fail{code}`), 속성 `auth_type=google`. 로그아웃 → `screen_view{account_sheet}` → `logout`.
13. 설정 → 내 데이터 삭제 → `screen_view{delete_confirm}` → `data_delete_start` → `data_delete_done{elapsed_ms}` → 온보딩 처음으로.
14. 시스템 설정에서 "애니메이션 제거" 토글 → 앱 복귀 → `reduce_motion_toggle{on}`.
15. `--dart-define=ANALYTICS_DISABLED=true` 로 빌드한 기기에선 DebugView 에 아무것도 안 올라오고 로그에 `[A] 수집 꺼짐` 이 찍힌다.

## 개인정보 미포함 체크리스트
- [x] 사진 바이트·경로: 어떤 이벤트에도 없음 (`classify_*` 는 category/confidence_bucket/elapsed 만)
- [x] 채팅 본문: `chat_send` 는 `length_bucket` 만
- [x] 이메일·이름·uid: 사용자 속성은 `is_tester` 불리언만 (테스터 판별은 기기 안에서), `google_link_fail.code` 는 `AuthErrors.shortCode` 로 메시지 없이 코드만
- [x] 위치: `region_set.sido` / `region_sido` 는 시도명만, 구·동 없음
- [x] 품목명: `collection_unlock.item_id` 는 tips.json 의 팁 ID (사용자 입력 아님), `classify_done.category` 는 분류 키
- [x] 공유 대상: 패키지명 → 채널 5종으로 접음
- [x] 가격·결제 식별자: `plan` 은 monthly/yearly 뿐, 주문 ID 없음
- [x] 테스트: `test/analytics_test.dart` 가 사용자 속성에 `@` 가 없음을 확인
