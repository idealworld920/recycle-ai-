import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_ai/app_services.dart';
import 'package:recycle_ai/screens/guide_screen.dart';
import 'package:recycle_ai/services/history_store.dart';
import 'package:recycle_ai/services/settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('가이드 화면에 모든 분류가 표시된다', (tester) async {
    final settings = await SettingsStore.load();
    final history = await HistoryStore.load();
    await tester.pumpWidget(
      AppServices(
        settings: settings,
        history: history,
        child: const MaterialApp(home: GuideScreen()),
      ),
    );
    expect(find.text('분리배출 가이드'), findsOneWidget);
    expect(find.text('투명 페트병'), findsOneWidget);
    // 목록은 lazy하게 그려지므로 마지막 항목까지 스크롤한다.
    await tester.scrollUntilVisible(
      find.text('일반 쓰레기'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('일반 쓰레기'), findsOneWidget);
  });
}
