import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/recycle_result.dart';
import '../../models/waste_group.dart';

/// "결과가 틀렸나요?" 피드백.
///
/// - 서버: `feedback/{id}` 에 {uid, imageHash, aiResult, userAnswer, memo, createdAt} 를 쓴다 (쓰기 전용).
/// - 기기: 품목명 → 사용자 정답(4분류) 을 기억해 두고, 같은 품목을 다시 분류하면 그걸 먼저 보여준다.
class FeedbackStore extends ChangeNotifier {
  // ignore: prefer_initializing_formals
  FeedbackStore(this._prefs, {FirebaseFirestore? firestore}) : _firestore = firestore {
    final raw = _prefs.getString(prefKey);
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _overrides = map.map((k, v) => MapEntry(k, _groupFromKey(v as String)));
      } catch (_) {
        _overrides = {};
      }
    }
  }

  static const prefKey = 'feedback_overrides';

  final SharedPreferences _prefs;
  final FirebaseFirestore? _firestore;
  String? _uid;
  Map<String, WasteGroup?> _overrides = {};

  void attachUser(String? uid) => _uid = uid;

  /// 같은 품목에 대해 사용자가 고쳐 둔 분류. 없으면 null.
  WasteGroup? overrideFor(String itemName) => _overrides[normalize(itemName)];

  static String normalize(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');

  /// 제출. 서버 저장은 Firebase 가 준비돼 있을 때만, 실패해도 기기 기록은 남긴다.
  Future<void> submit({
    required RecycleResult result,
    required WasteGroup userAnswer,
    String memo = '',
    Uint8List? imageBytes,
  }) async {
    _overrides = {..._overrides, normalize(result.itemName): userAnswer};
    await _prefs.setString(
      prefKey,
      jsonEncode(_overrides.map((k, v) => MapEntry(k, v?.name ?? ''))),
    );
    notifyListeners();

    final uid = _uid;
    if (uid == null) return; // Firebase 준비 전엔 기기 기록만
    try {
      final db = _firestore ?? FirebaseFirestore.instance;
      await db.collection('feedback').add({
        'uid': uid,
        'imageHash': imageBytes == null ? null : fnv1a64(imageBytes),
        'itemName': result.itemName,
        'aiResult': {
          'category': result.category.key,
          'group': result.category.group.name,
          'confidence': result.confidence,
          'reason': result.reason,
        },
        'userAnswer': userAnswer.name,
        'memo': memo.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('피드백 서버 저장 실패: $e');
    }
  }

  Future<void> resetLocal() async {
    _overrides = {};
    await _prefs.remove(prefKey);
    notifyListeners();
  }

  static WasteGroup? _groupFromKey(String key) {
    for (final g in WasteGroup.values) {
      if (g.name == key) return g;
    }
    return null;
  }

  /// 사진 중복 판별용 가벼운 해시 (32비트 FNV-1a 두 번 → 16진수 16자리). 암호용 아님.
  /// 웹(JS)에서도 정확하도록 64비트 곱셈을 쓰지 않는다.
  static String fnv1a64(Uint8List bytes) {
    final a = _fnv1a32(bytes, 0x811c9dc5);
    final b = _fnv1a32(bytes, 0x811c9dc5 ^ 0x5bd1e995);
    return a.toRadixString(16).padLeft(8, '0') + b.toRadixString(16).padLeft(8, '0');
  }

  static int _fnv1a32(Uint8List bytes, int seed) {
    var h = seed & 0xFFFFFFFF;
    for (final byte in bytes) {
      h ^= byte;
      h = _mul32(h, 0x01000193);
    }
    return h;
  }

  /// 32비트 곱셈을 16비트 조각으로 나눠 JS 의 2^53 한계를 넘지 않게 한다.
  static int _mul32(int a, int b) {
    final lo = (a & 0xFFFF) * b;
    final hi = (((a >>> 16) * b) & 0xFFFF) << 16;
    return (lo + hi) & 0xFFFFFFFF;
  }
}
