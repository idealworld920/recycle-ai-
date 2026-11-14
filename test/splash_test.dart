import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_ai/core/mascot.dart';
import 'package:recycle_ai/core/theme/app_theme.dart';
import 'package:recycle_ai/features/splash/splash_plan.dart';
import 'package:recycle_ai/features/splash/splash_screen.dart';
import 'package:recycle_ai/services/settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final now = DateTime(2026, 11, 14, 9);
  final msg = SplashMessage(id: 'nov', text: '11월 이벤트뿅!', startAt: now.subtract(const Duration(days: 1)), endAt: now.add(const Duration(days: 1)));

  group('SplashPlan.decide', () {
    test('최초 실행: 긴 인트로 2.6초 → 온보딩', () {
      final p = SplashPlan.decide(onboarded: false, lastOpenedAt: null, now: now);
      expect(p.kind, SplashKind.firstRun);
      expect(p.length, const Duration(milliseconds: 2600));
      expect(p.goesToOnboarding, isTrue);
      expect(p.text, isNull);
    });

    test('평소: 짧은 인트로 0.8초 → 홈', () {
      final p = SplashPlan.decide(onboarded: true, lastOpenedAt: now.subtract(const Duration(hours: 5)), now: now);
      expect(p.kind, SplashKind.short);
      expect(p.length, const Duration(milliseconds: 800));
      expect(p.goesToOnboarding, isFalse);
    });

    test('3일 이상 복귀: 긴 인트로 + "오랜만이뿅!"', () {
      final p = SplashPlan.decide(onboarded: true, lastOpenedAt: now.subtract(const Duration(days: 3)), now: now);
      expect(p.kind, SplashKind.returning);
      expect(p.text, '오랜만이뿅!');
      expect(p.length, const Duration(milliseconds: 2600));
      // 2일 23시간은 평소
      expect(SplashPlan.decide(onboarded: true, lastOpenedAt: now.subtract(const Duration(hours: 71)), now: now).kind, SplashKind.short);
    });

    test('Remote Config 공지: 기간 안 + 안 본 id 일 때 1회, 본 뒤엔 평소', () {
      final p = SplashPlan.decide(onboarded: true, lastOpenedAt: now, now: now, message: msg);
      expect(p.kind, SplashKind.message);
      expect(p.text, '11월 이벤트뿅!');
      expect(p.messageId, 'nov');
      expect(SplashPlan.decide(onboarded: true, lastOpenedAt: now, now: now, message: msg, seen: {'nov'}).kind, SplashKind.short);
      // 기간 밖
      final later = now.add(const Duration(days: 3));
      expect(SplashPlan.decide(onboarded: true, lastOpenedAt: later, now: later, message: msg).kind, SplashKind.short);
      // 복귀 인사가 공지보다 우선, 공지 id 는 소비하지 않는다
      final r = SplashPlan.decide(onboarded: true, lastOpenedAt: now.subtract(const Duration(days: 10)), now: now, message: msg);
      expect(r.kind, SplashKind.returning);
      expect(r.messageId, isNull);
    });

    test('Remote Config JSON 파싱', () {
      final m = SplashMessage.fromJson({'id': 'x', 'text': '안녕뿅', 'startAt': '2026-11-01T00:00:00Z', 'endAt': '2026-11-30T00:00:00Z'});
      expect(m, isNotNull);
      expect(m!.activeAt(DateTime.utc(2026, 11, 14)), isTrue);
      expect(m.activeAt(DateTime.utc(2026, 12, 1)), isFalse);
      expect(SplashMessage.fromJson({'text': '없음'}), isNull);
      expect(SplashMessage.fromJson(null), isNull);
    });

    test('애니메이션 줄이기: 정지 이미지 0.3초, 문구는 유지', () {
      final p = SplashPlan.decide(onboarded: true, lastOpenedAt: now.subtract(const Duration(days: 4)), now: now, reduceMotion: true);
      expect(p.kind, SplashKind.reduced);
      expect(p.length, const Duration(milliseconds: 300));
      expect(p.text, '오랜만이뿅!');
      final m = SplashPlan.decide(onboarded: true, lastOpenedAt: now, now: now, message: msg, reduceMotion: true);
      expect(m.kind, SplashKind.reduced);
      expect(m.messageId, 'nov');
    });
  });

  group('SplashScreen', () {
    Future<void> pump(WidgetTester tester, SplashPlan plan, Future<void> ready, List<SplashPlan> done, {Duration? maxTotal}) {
      return tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        home: SplashScreen(plan: plan, ready: ready, onDone: done.add, maxTotal: maxTotal ?? SplashPlan.maxTotal),
      ));
    }

    testWidgets('평소: 초기화가 끝나 있으면 0.8초 뒤 넘어간다', (tester) async {
      final done = <SplashPlan>[];
      await pump(tester, const SplashPlan(SplashKind.short), Future.value(), done);
      await tester.pump(const Duration(milliseconds: 700));
      expect(done, isEmpty);
      await tester.pump(const Duration(milliseconds: 150));
      expect(done.single.kind, SplashKind.short);
    });

    testWidgets('탭하면 즉시 넘어간다 (한 번만)', (tester) async {
      final done = <SplashPlan>[];
      await pump(tester, const SplashPlan(SplashKind.firstRun), Future.value(), done);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byType(SplashScreen));
      await tester.pump();
      expect(done, hasLength(1));
      await tester.pump(const Duration(seconds: 3));
      expect(done, hasLength(1));
    });

    testWidgets('애니메이션 끝났는데 초기화가 안 끝났으면 thinking + "잠깐만뿅…", 끝나면 바로 진행', (tester) async {
      final done = <SplashPlan>[];
      final ready = Completer<void>();
      await pump(tester, const SplashPlan(SplashKind.short), ready.future, done);
      expect(find.text(SplashScreen.waitingText), findsNothing);
      await tester.pump(const Duration(milliseconds: 850));
      expect(done, isEmpty);
      expect(find.text(SplashScreen.waitingText), findsOneWidget);
      final img = tester.widget<MascotImage>(find.byType(MascotImage));
      expect(img.mascot, Mascot.thinking);
      ready.complete();
      await tester.pump();
      expect(done, hasLength(1));
    });

    testWidgets('초기화가 끝나지 않아도 3초 상한에 넘어간다', (tester) async {
      final done = <SplashPlan>[];
      await pump(tester, const SplashPlan(SplashKind.returning, text: '오랜만이뿅!'), Completer<void>().future, done);
      expect(find.text('오랜만이뿅!'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 2900));
      expect(done, isEmpty);
      await tester.pump(const Duration(milliseconds: 200));
      expect(done, hasLength(1));
    });

    testWidgets('애니메이션 줄이기: 정지 PNG, 0.3초', (tester) async {
      final done = <SplashPlan>[];
      await pump(tester, const SplashPlan(SplashKind.reduced), Future.value(), done);
      final img = tester.widget<Image>(find.byType(Image));
      expect((img.image as AssetImage).assetName, endsWith('r_intro_static.png'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(done, hasLength(1));
    });
  });

  test('설정 저장소: 본 공지 id 저장, 72시간 무제한', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await SettingsStore.load();
    expect(s.seenSplashIds, isEmpty);
    Map<String, dynamic>? sent;
    await s.markSplashSeen('nov', remote: (m) async => sent = m);
    expect(s.seenSplashIds, {'nov'});
    expect((sent!['seenSplash'] as Map)['nov'], isNotNull);
    expect(s.inFreeGrace, isTrue); // 방금 설치
  });
}
