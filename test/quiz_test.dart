import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_ai/features/quiz/quiz_model.dart';
import 'package:recycle_ai/features/tips/tips_repository.dart';

void main() {
  late QuizRepository quiz;
  late TipsRepository tips;

  setUpAll(() {
    quiz = QuizRepository.fromJsonString(File('assets/data/quiz.json').readAsStringSync());
    tips = TipsRepository.fromJsonString(File('assets/data/tips.json').readAsStringSync());
  });

  test('30문항, 4지선다, 정답 범위, tipId 가 tips.json 에 있다', () {
    expect(quiz.all.length, 30);
    final tipIds = tips.all.map((t) => t.id).toSet();
    for (final q in quiz.all) {
      expect(q.choices.length, 4, reason: q.id);
      expect(q.choices.toSet().length, 4, reason: '${q.id} 보기 중복');
      expect(q.answer, inInclusiveRange(0, 3), reason: q.id);
      expect(tipIds, contains(q.tipId), reason: q.id);
    }
    expect(quiz.all.map((q) => q.id).toSet().length, 30);
  });

  test('주차 id 는 월요일 시작, 같은 주면 같은 값', () {
    expect(QuizRepository.weekId(DateTime(2026, 10, 12)), QuizRepository.weekId(DateTime(2026, 10, 18)));
    expect(QuizRepository.weekId(DateTime(2026, 10, 18)) == QuizRepository.weekId(DateTime(2026, 10, 19)), isFalse);
    expect(QuizRepository.weekId(DateTime(2026, 1, 1)), startsWith('2026-W'));
  });

  test('같은 주차에는 항상 같은 3문제', () {
    final a = quiz.forWeek('2026-W42').map((q) => q.id).toList();
    final b = quiz.forWeek('2026-W42').map((q) => q.id).toList();
    expect(a, b);
    expect(a.length, 3);
    expect(a.toSet().length, 3);
    expect(quiz.forWeek('2026-W43').map((q) => q.id).toList() == a, isFalse);
  });
}
