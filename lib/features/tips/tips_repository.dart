import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'tip_model.dart';

/// assets/data/tips.json 을 읽어 검색·매칭을 제공한다.
class TipsRepository {
  TipsRepository._(this._tips);

  static const assetPath = 'assets/data/tips.json';

  final List<Tip> _tips;

  List<Tip> get all => List.unmodifiable(_tips);

  static Future<TipsRepository> load() async {
    final raw = await rootBundle.loadString(assetPath);
    return TipsRepository.fromJsonString(raw);
  }

  /// 테스트나 다른 소스에서 바로 만들 때.
  factory TipsRepository.fromJsonString(String raw) {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final items = (decoded['items'] as List).cast<Map<String, dynamic>>().map(Tip.fromJson).toList(growable: false);
    return TipsRepository._(items);
  }

  static String _norm(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');

  /// 이름·별칭에 검색어가 포함된 팁. 분류 필터는 선택.
  List<Tip> search(String query, {TipCategory? category}) {
    final q = _norm(query);
    return _tips.where((t) {
      if (category != null && t.category != category) return false;
      if (q.isEmpty) return true;
      return t.allNames.any((n) => _norm(n).contains(q));
    }).toList(growable: false);
  }

  /// AI가 판별한 품목명과 가장 잘 맞는 팁 하나. 없으면 null.
  ///
  /// 우선순위: 이름/별칭 완전 일치 → 품목명 안에 팁 이름이 포함 → 팁 이름 안에 품목명이 포함.
  /// 여러 개면 더 긴 이름이 맞은 쪽을 고른다.
  Tip? findForItem(String itemName) {
    final q = _norm(itemName);
    if (q.isEmpty) return null;

    Tip? best;
    var bestScore = 0;
    for (final tip in _tips) {
      for (final name in tip.allNames) {
        final n = _norm(name);
        if (n.isEmpty) continue;
        int score;
        if (n == q) {
          score = 1000 + n.length;
        } else if (q.contains(n) && n.length >= 2) {
          score = 500 + n.length;
        } else if (n.contains(q) && q.length >= 2) {
          score = 100 + q.length;
        } else {
          continue;
        }
        if (score > bestScore) {
          bestScore = score;
          best = tip;
        }
      }
    }
    return best;
  }
}
