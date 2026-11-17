import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_ai/core/analytics.dart';
import 'package:recycle_ai/core/analytics_user_props.dart';
import 'package:recycle_ai/features/auth/auth_errors.dart';
import 'package:recycle_ai/features/classify/classify_flow.dart';
import 'package:recycle_ai/features/household/household_store.dart';
import 'package:recycle_ai/features/premium/premium_gate.dart';
import 'package:recycle_ai/features/review/review_prompter.dart';
import 'package:recycle_ai/features/share/share_service.dart';
import 'package:recycle_ai/models/recycle_category.dart';
import 'package:recycle_ai/models/recycle_result.dart';
import 'package:recycle_ai/screens/result_screen.dart';
import 'package:recycle_ai/services/settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Analytics 래퍼', () {
    test('파라미터 정리: null 제거, bool/enum 은 문자열, 숫자·문자열 그대로', () {
      final p = Analytics.sanitize({'a': 1, 'b': 'x', 'c': true, 'd': null, 'e': PaywallSource.guide7, 'f': 1.5});
      expect(p, {'a': 1, 'b': 'x', 'c': 'true', 'e': 'guide7', 'f': 1.5});
      expect(Analytics.sanitize(null), isNull);
    });

    test('버킷', () {
      expect(Analytics.confidenceBucket(0.3), 'low');
      expect(Analytics.confidenceBucket(0.7), 'mid');
      expect(Analytics.confidenceBucket(0.95), 'high');
      expect(Analytics.lengthBucket(5), 'short');
      expect(Analytics.lengthBucket(50), 'mid');
      expect(Analytics.lengthBucket(200), 'long');
      expect([0, 1, 9, 10, 29, 30, 55, 56, 80].map(Analytics.collectionBucket), ['0', '1-9', '1-9', '10-29', '10-29', '30-55', '30-55', '56', '56']);
      expect([0, 1, 3, 4, 7, 8, 30, 31].map(Analytics.installAgeBucket), ['0', '1-3', '1-3', '4-7', '4-7', '8-30', '8-30', '30+']);
    });

    test('화면 이름: 위젯 타입 → snake_case', () {
      expect(Analytics.screenNameOf(ResultScreen(result: _dummyResult)), 'result_screen');
    });

    test('Firebase 없이도 log/screen 은 조용히 통과하고 sink 로 가로챌 수 있다', () async {
      final got = <String>[];
      Analytics.sink = (n, p) => got.add('$n ${p ?? ''}');
      await Analytics.log('x', {'k': 1});
      await Analytics.screen('paywall');
      Analytics.sink = null;
      expect(got, ['x {k: 1}', 'screen_view {screen_name: paywall}']);
    });
  });

  group('사용자 속성', () {
    test('테스터·구독·지역·집·인증·버킷', () {
      final p = UserProps.compute(
        email: 'IY093452@gmail.com',
        anonymous: false,
        premiumStatus: 'trial',
        regionSido: '서울',
        inHousehold: true,
        isOwner: true,
        collected: 12,
        installDays: 5,
      );
      expect(p['is_tester'], 'true');
      expect(p['premium_status'], 'trial');
      expect(p['region_set'], 'true');
      expect(p['region_sido'], '서울');
      expect(p['in_household'], 'true');
      expect(p['household_role'], 'owner');
      expect(p['auth_type'], 'google');
      expect(p['collection_bucket'], '10-29');
      expect(p['install_age_bucket'], '4-7');
      // 이메일 자체는 어디에도 없다
      expect(p.values.any((v) => v.contains('@')), isFalse);
      final q = UserProps.compute(email: null, anonymous: true, premiumStatus: 'none', regionSido: null, inHousehold: false, isOwner: false, collected: 0, installDays: 0);
      expect(q['household_role'], 'none');
      expect(q['auth_type'], 'anonymous');
      expect(q['region_set'], 'false');
      expect(q['region_sido'], 'none');
    });
  });

  group('값 매핑', () {
    test('공유 채널은 패키지명 대신 분류만', () {
      expect(ShareService.shareChannel('com.kakao.talk/...'), 'kakao');
      expect(ShareService.shareChannel('com.instagram.android'), 'sns');
      expect(ShareService.shareChannel('com.samsung.android.messaging'), 'sms');
      expect(ShareService.shareChannel('android/com.android.intent.clipboard'), 'copy');
      expect(ShareService.shareChannel('com.whatever'), 'other');
    });

    test('분류 실패 사유', () {
      expect(ClassifyFlow.failReason(Exception('인터넷 연결을 확인해 주세요')), 'network');
      expect(ClassifyFlow.failReason(Exception('응답 시간이 너무 길어요')), 'timeout');
      expect(ClassifyFlow.failReason(Exception('오늘 한도를 다 썼어요')), 'limit');
      expect(ClassifyFlow.failReason(Exception('???')), 'unknown');
    });

    test('집 참여 실패 사유', () {
      expect(HouseholdStore.joinFailReason('not-found'), 'invalid');
      expect(HouseholdStore.joinFailReason('deadline-exceeded'), 'expired');
      expect(HouseholdStore.joinFailReason('resource-exhausted'), 'full');
      expect(HouseholdStore.joinFailReason('unavailable'), 'network');
    });

    test('인증 실패 코드는 메시지(이메일 가능성) 없이 코드만', () {
      expect(AuthErrors.shortCode(PlatformException(code: '10', message: 'user a@b.com failed')), 'platform/10');
      expect(AuthErrors.shortCode(FirebaseAuthException(code: 'network-request-failed', message: 'x')), 'firebase/network-request-failed');
    });

    test('페이월 source 이름', () {
      expect(PaywallSource.limitHit.analyticsName, 'limit');
      expect(PaywallSource.featureTap.analyticsName, 'feature_tap');
      expect(PaywallSource.reportBottom.analyticsName, 'report');
      expect(PaywallSource.household.analyticsName, 'household');
      expect(PaywallSource.household.isFeatureTap, isTrue);
    });
  });

  group('인앱 리뷰 조건', () {
    final now = DateTime(2026, 11, 17, 12);
    test('설치 24시간 전엔 안 묻고, 90일 안엔 다시 안 묻고, 구독한 세션엔 안 묻는다', () {
      expect(ReviewPrompter.eligible(installedAt: now.subtract(const Duration(hours: 23)), lastPromptAt: null, now: now), isFalse);
      expect(ReviewPrompter.eligible(installedAt: now.subtract(const Duration(hours: 25)), lastPromptAt: null, now: now), isTrue);
      expect(ReviewPrompter.eligible(installedAt: now.subtract(const Duration(days: 10)), lastPromptAt: now.subtract(const Duration(days: 89)), now: now), isFalse);
      expect(ReviewPrompter.eligible(installedAt: now.subtract(const Duration(days: 100)), lastPromptAt: now.subtract(const Duration(days: 91)), now: now), isTrue);
      expect(ReviewPrompter.eligible(installedAt: now.subtract(const Duration(days: 10)), lastPromptAt: null, now: now, purchasedThisSession: true), isFalse);
    });

    test('카운터·리뷰 시각·하루 1회 말풍선 로그', () async {
      SharedPreferences.setMockInitialValues({});
      final s = await SettingsStore.load();
      expect(await s.bump(ReviewPrompter.classifyCounter), 1);
      expect(await s.bump(ReviewPrompter.classifyCounter), 2);
      expect(s.counter(ReviewPrompter.classifyCounter), 2);
      expect(s.reviewPromptAt, isNull);
      Map<String, dynamic>? sent;
      await s.markReviewPrompted(remote: (m) async => sent = m);
      expect(s.reviewPromptAt, isNotNull);
      expect(sent!['reviewPromptAt'], isA<String>());
      expect(await s.claimDailyBubbleLog(now), isTrue);
      expect(await s.claimDailyBubbleLog(now), isFalse);
      expect(await s.claimDailyBubbleLog(now.add(const Duration(days: 1))), isTrue);
    });
  });
}

final _dummyResult = RecycleResult(itemName: '캔', category: RecycleCategory.can, confidence: 0.9, steps: const [], warnings: const [], tip: '', createdAt: DateTime(2026));
