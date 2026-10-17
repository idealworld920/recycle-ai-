import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'quiz_model.dart';

/// 이번 주 퀴즈 결과. 기기에 저장하고, 로그인돼 있으면 users/{uid}/quiz/{weekId} 에도 쓴다.
class QuizResult {
  const QuizResult({required this.weekId, required this.score, required this.total, required this.answers, required this.completedAt});

  final String weekId;
  final int score;
  final int total;

  /// 문제 id → 고른 보기 index.
  final Map<String, int> answers;
  final DateTime completedAt;

  Map<String, dynamic> toJson() => {
        'weekId': weekId,
        'score': score,
        'total': total,
        'answers': answers,
        'completedAt': completedAt.toIso8601String(),
      };

  factory QuizResult.fromJson(Map<String, dynamic> j) => QuizResult(
        weekId: j['weekId'] as String,
        score: (j['score'] as num).toInt(),
        total: (j['total'] as num).toInt(),
        answers: {for (final e in ((j['answers'] as Map?) ?? const {}).entries) e.key.toString(): (e.value as num).toInt()},
        completedAt: DateTime.tryParse(j['completedAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

class QuizStore extends ChangeNotifier {
  QuizStore(this._prefs, this.repository);

  static const prefPrefix = 'quiz_result_';

  final SharedPreferences _prefs;
  final QuizRepository repository;
  String? uid;

  static Future<QuizStore> load(QuizRepository repo) async => QuizStore(await SharedPreferences.getInstance(), repo);

  String get currentWeekId => QuizRepository.weekId(DateTime.now());

  QuizResult? resultFor(String weekId) {
    final raw = _prefs.getString('$prefPrefix$weekId');
    if (raw == null) return null;
    try {
      return QuizResult.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  QuizResult? get thisWeek => resultFor(currentWeekId);
  bool get doneThisWeek => thisWeek != null;

  Future<void> save(QuizResult r) async {
    await _prefs.setString('$prefPrefix${r.weekId}', jsonEncode(r.toJson()));
    notifyListeners();
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).collection('quiz').doc(r.weekId).set({
        ...r.toJson(),
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('퀴즈 결과 동기화 실패: $e');
    }
  }
}
