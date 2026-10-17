import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

/// 4지선다 한 문제. tipId 로 틀렸을 때 보여줄 팁 카드를 찾는다.
class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.tipId,
    required this.question,
    required this.choices,
    required this.answer,
    required this.explanation,
  });

  final String id;
  final String tipId;
  final String question;
  final List<String> choices;
  final int answer;
  final String explanation;

  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
        id: j['id'] as String,
        tipId: j['tipId'] as String,
        question: j['question'] as String,
        choices: (j['choices'] as List).map((e) => e.toString()).toList(growable: false),
        answer: (j['answer'] as num).toInt(),
        explanation: (j['explanation'] as String?) ?? '',
      );
}

class QuizRepository {
  QuizRepository._(this._questions);

  static const assetPath = 'assets/data/quiz.json';
  static const perWeek = 3;

  final List<QuizQuestion> _questions;
  List<QuizQuestion> get all => List.unmodifiable(_questions);

  static Future<QuizRepository> load() async => QuizRepository.fromJsonString(await rootBundle.loadString(assetPath));

  factory QuizRepository.fromJsonString(String raw) {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return QuizRepository._((decoded['items'] as List).cast<Map<String, dynamic>>().map(QuizQuestion.fromJson).toList(growable: false));
  }

  /// 주차 id. 월요일 시작, "2026-W42" 형식.
  static String weekId(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    final thursday = day.add(Duration(days: 4 - day.weekday)); // ISO 주는 목요일이 속한 해
    final jan1 = DateTime(thursday.year, 1, 1);
    final week = ((thursday.difference(jan1).inDays) / 7).floor() + 1;
    return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
  }

  /// 같은 주면 항상 같은 3문제가 나오도록 주차 id 를 시드로 쓴다.
  List<QuizQuestion> forWeek(String weekId, {int count = perWeek}) {
    if (_questions.isEmpty) return const [];
    final rnd = Random(weekId.hashCode);
    final pool = [..._questions]..shuffle(rnd);
    return pool.take(count).toList(growable: false);
  }
}
