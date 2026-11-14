import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_ai/core/theme/app_theme.dart';
import 'package:recycle_ai/features/mascot/first_classify_overlay.dart';
import 'package:recycle_ai/services/settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pump(WidgetTester tester, {bool reduceMotion = false}) {
    return tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion), child: child!),
      home: Scaffold(body: Builder(builder: (context) => TextButton(onPressed: () => showFirstClassifyOverlay(context), child: const Text('GO')))),
    ));
  }

  testWidgets('첫 분류 연출: 오버레이 + 문구, 2초 뒤 자동으로 닫힌다', (tester) async {
    await pump(tester);
    await tester.tap(find.text('GO'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(firstClassifyLine), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();
    expect(find.text(firstClassifyLine), findsNothing);
  });

  testWidgets('탭하면 바로 닫힌다', (tester) async {
    await pump(tester);
    await tester.tap(find.text('GO'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text(firstClassifyLine));
    await tester.pumpAndSettle();
    expect(find.text(firstClassifyLine), findsNothing);
  });

  testWidgets('애니메이션 줄이기: 색종이 없이 토스트만', (tester) async {
    await pump(tester, reduceMotion: true);
    await tester.tap(find.text('GO'));
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text(firstClassifyLine), findsOneWidget);
    expect(find.byType(CustomPaint).evaluate().where((e) => e.widget.toString().contains('Confetti')), isEmpty);
  });

  test('첫 분류 플래그는 1회만 (두 번째부터 연출 없음)', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await SettingsStore.load();
    expect(s.firstClassifyDone, isFalse);
    await s.markFirstClassifyDone();
    expect(s.firstClassifyDone, isTrue);
    final again = await SettingsStore.load();
    expect(again.firstClassifyDone, isTrue);
  });
}
