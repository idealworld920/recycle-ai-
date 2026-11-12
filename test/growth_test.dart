import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_ai/features/feedback/feedback_store.dart';
import 'package:recycle_ai/features/schedule/pickup_schedule.dart';
import 'package:recycle_ai/features/schedule/reminder_copy.dart';
import 'package:recycle_ai/features/share/share_card.dart';
import 'package:recycle_ai/features/tips/tip_model.dart';
import 'package:recycle_ai/features/tips/tips_repository.dart';
import 'package:recycle_ai/models/recycle_category.dart';
import 'package:recycle_ai/models/recycle_result.dart';
import 'package:recycle_ai/models/waste_group.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final tips = TipsRepository.fromJsonString(File('assets/data/tips.json').readAsStringSync());

  group('결과 모델', () {
    test('reason 을 읽고, 없으면 빈 문자열', () {
      final r = RecycleResult.fromMap({'itemName': '생수 페트병', 'category': 'pet', 'confidence': 0.9, 'reason': '투명 PET 재질이에요.'});
      expect(r.reason, '투명 PET 재질이에요.');
      expect(RecycleResult.fromMap({'itemName': 'x', 'category': 'pet'}).reason, '');
    });
  });

  group('피드백', () {
    test('정답을 기억하고 같은 품목(공백·대소문자 무시)에 돌려준다', () async {
      SharedPreferences.setMockInitialValues({});
      final store = FeedbackStore(await SharedPreferences.getInstance());
      final r = RecycleResult.fromMap({'itemName': '컵라면 용기', 'category': 'plastic', 'confidence': 0.8});
      expect(store.overrideFor('컵라면 용기'), isNull);
      await store.submit(result: r, userAnswer: WasteGroup.general); // uid 없음 → 기기 기록만
      expect(store.overrideFor('컵라면용기'), WasteGroup.general);

      final reloaded = FeedbackStore(await SharedPreferences.getInstance());
      expect(reloaded.overrideFor('컵라면 용기'), WasteGroup.general);
      await reloaded.resetLocal();
      expect(reloaded.overrideFor('컵라면 용기'), isNull);
    });

    test('이미지 해시는 결정적이고 16자리', () {
      final a = FeedbackStore.fnv1a64(Uint8List.fromList([1, 2, 3]));
      expect(a, FeedbackStore.fnv1a64(Uint8List.fromList([1, 2, 3])));
      expect(a.length, 16);
      expect(a, isNot(FeedbackStore.fnv1a64(Uint8List.fromList([1, 2, 4]))));
    });
  });

  group('알림 문구', () {
    test('제목은 리뿅이 화자, 본문은 안내 + 같은 종류 팁', () async {
      SharedPreferences.setMockInitialValues({});
      final copy = ReminderCopy(tips, await SharedPreferences.getInstance(), random: Random(1));
      expect(ReminderCopy.title(WasteType.recycle), '리뿅이: 내일 재활용 날이뿅!');
      final tip = copy.pickTip(WasteType.food)!;
      expect(tip.category, TipCategory.food);
      final body = copy.body(WasteType.food, tip: tip);
      expect(body, startsWith('내일 음식물 날이에요.'));
      expect(body, contains('💡 ${tip.name}:'));
    });

    test('2주 안에 쓴 팁은 다시 고르지 않는다', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var now = DateTime(2026, 11, 12);
      final copy = ReminderCopy(tips, prefs, random: Random(7), now: () => now);
      final pool = tips.all.where((t) => t.category == TipCategory.food && t.steps.isNotEmpty).toList();
      final seen = <String>{};
      for (var i = 0; i < pool.length; i++) {
        final t = copy.pickTip(WasteType.food)!;
        expect(seen.add(t.id), isTrue, reason: '${t.id} 가 2주 안에 반복됨');
        await copy.markUsed([t]);
      }
      // 풀을 다 쓰면 전체에서 다시 고른다 (null 아님)
      expect(copy.pickTip(WasteType.food), isNotNull);
      // 15일 뒤엔 다시 신선해진다
      now = now.add(const Duration(days: 15));
      final again = copy.pickTip(WasteType.food)!;
      expect(seen.contains(again.id), isTrue);
    });
  });

  group('공유 카드', () {
    testWidgets('1080x1350 PNG 를 만든다 (사진 없이)', (tester) async {
      final r = RecycleResult.fromMap({
        'itemName': '생수 페트병',
        'category': 'pet',
        'confidence': 0.96,
        'reason': '투명하고 색이 없는 PET 재질이라 투명 페트병이에요.',
        'steps': ['내용물 비우기'],
      });
      final png = await tester.runAsync(() => ShareCard.render(
            result: r,
            groupColor: ShareCard.fallbackGroupColor(WasteGroup.recycle),
            groupSoft: ShareCard.fallbackGroupColor(WasteGroup.recycle).withValues(alpha: 0.1),
            primary: const Color(0xFF2563EB),
            ink: const Color(0xFF111111),
            surface: const Color(0xFFF7F7F8),
            textSecondary: const Color(0xFF6B6B6B),
            divider: const Color(0xFFEDEDED),
          ));
      expect(png, isNotNull);
      // PNG 시그니처 + IHDR 의 width/height
      expect(png!.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
      final w = png.buffer.asByteData().getUint32(16);
      final h = png.buffer.asByteData().getUint32(20);
      expect(w, 1080);
      expect(h, 1350);
      expect(RecycleCategory.pet.group, WasteGroup.recycle);
    });
  });
}
