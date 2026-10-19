import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_ai/core/theme/app_theme.dart';
import 'package:recycle_ai/features/auth/locked_overlay.dart';
import 'package:recycle_ai/features/history/history_record.dart';
import 'package:recycle_ai/features/tips/tips_repository.dart';
import 'package:recycle_ai/models/recycle_category.dart';
import 'package:recycle_ai/screens/home_screen.dart';

void main() {
  final tips = TipsRepository.fromJsonString(File('assets/data/tips.json').readAsStringSync());
  final now = DateTime(2026, 10, 19);

  HistoryRecord rec(String name, {int daysAgo = 1, String id = ''}) => HistoryRecord(
        id: id.isEmpty ? '$name-$daysAgo' : id,
        date: now.subtract(Duration(days: daysAgo)),
        itemName: name,
        category: RecycleCategory.general,
      );

  test('기록이 없으면 기본 목록', () {
    final out = HomeScreen.frequentTips(tips, const [], now: now);
    expect(out.map((t) => t.id).toList(), HomeScreen.frequentTipIds);
  });

  test('많이 분류한 품목이 앞에 오고, 나머지는 기본 목록으로 채운다', () {
    final out = HomeScreen.frequentTips(
      tips,
      [rec('우유팩', daysAgo: 1), rec('우유팩', daysAgo: 2), rec('생수 페트병', daysAgo: 3)],
      now: now,
    );
    expect(out.first.name, contains('팩'));
    expect(out[1].id, 'pet_bottle');
    expect(out.length, 9);
    expect(out.map((t) => t.id).toSet().length, 9, reason: '중복 없음');
  });

  test('90일보다 오래된 기록은 세지 않는다', () {
    final out = HomeScreen.frequentTips(tips, [rec('우유팩', daysAgo: 120)], now: now);
    expect(out.map((t) => t.id).toList(), HomeScreen.frequentTipIds);
  });

  testWidgets('잠금 오버레이는 가려지는 내용이 한 줄이어도 안내가 잘리지 않는다', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: LockedOverlay(
          message: '지난달 대비는 연결 후 볼 수 있어요',
          onConnect: () {},
          child: const Text('지난달보다 3%p 올랐어요'),
        ),
      ),
    ));
    final size = tester.getSize(find.byType(LockedOverlay));
    expect(size.height, greaterThanOrEqualTo(56));
    expect(find.text('지난달 대비는 연결 후 볼 수 있어요'), findsOneWidget);
    expect(find.text('연결'), findsOneWidget);
  });
}
