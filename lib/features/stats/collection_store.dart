import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../tips/tip_model.dart';
import '../tips/tips_repository.dart';

/// 도감: 처음 분류한 tips.json 품목을 모은다. users/{uid}/collection/{tipId}
class CollectionStore extends ChangeNotifier {
  CollectionStore(this._prefs, this._tips, {this.firestore}) {
    _ids = (_prefs.getStringList(prefKey) ?? const []).toSet();
  }

  static const prefKey = 'collection_v1';

  final SharedPreferences _prefs;
  final TipsRepository _tips;
  /// 테스트에서 주입. null 이면 기본 인스턴스.
  final FirebaseFirestore? firestore;
  String? uid;
  late Set<String> _ids;

  Set<String> get collectedIds => Set.unmodifiable(_ids);
  int get collected => _ids.length;
  int get total => _tips.all.length;
  bool has(Tip tip) => _ids.contains(tip.id);

  static Future<CollectionStore> load(TipsRepository tips) async =>
      CollectionStore(await SharedPreferences.getInstance(), tips);

  CollectionReference<Map<String, dynamic>>? get _col =>
      uid == null ? null : (firestore ?? FirebaseFirestore.instance).collection('users').doc(uid).collection('collection');

  Future<void> attachUser(String? uid) async {
    this.uid = uid;
    final col = _col;
    if (col == null) return;
    try {
      final snap = await col.get();
      final remote = snap.docs.map((d) => d.id).toSet();
      final merged = {..._ids, ...remote};
      // 기기에만 있던 것은 올려 준다.
      for (final id in _ids.difference(remote)) {
        await col.doc(id).set({'firstAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      }
      _ids = merged;
      await _prefs.setStringList(prefKey, _ids.toList());
      notifyListeners();
    } catch (e) {
      debugPrint('도감 동기화 실패: $e');
    }
  }

  /// 기기 복사본만 비운다. 계정 전환용.
  Future<void> resetLocal() async {
    _ids = {};
    await _prefs.setStringList(prefKey, const []);
    notifyListeners();
  }

  /// 처음 보는 품목이면 추가하고 true. 이미 있으면 false.
  Future<bool> collect(Tip tip, {String? itemName}) async {
    if (_ids.contains(tip.id)) return false;
    _ids = {..._ids, tip.id};
    await _prefs.setStringList(prefKey, _ids.toList());
    notifyListeners();
    final col = _col;
    if (col != null) {
      try {
        await col.doc(tip.id).set({
          'name': tip.name,
          if (itemName != null) 'itemName': itemName, // ignore: use_null_aware_elements
          'firstAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('도감 저장 실패: $e');
      }
    }
    return true;
  }

  /// 기록 삭제 뒤 도감 정리. [candidates] 중 [stillCollected] 에 없는 것만 뺀다.
  /// 호출 쪽이 "남은 기록에 같은 품목이 하나라도 있는지" 를 계산해 넘긴다. 뱃지는 개수로 즉시 계산되므로 조용히 내려간다.
  Future<Set<String>> prune(Set<String> candidates, {required Set<String> stillCollected}) async {
    final drop = candidates.where((id) => _ids.contains(id) && !stillCollected.contains(id)).toSet();
    if (drop.isEmpty) return drop;
    _ids = _ids.difference(drop);
    await _prefs.setStringList(prefKey, _ids.toList());
    notifyListeners();
    final col = _col;
    if (col != null) {
      final db = firestore ?? FirebaseFirestore.instance;
      final batch = db.batch();
      for (final id in drop) {
        batch.delete(col.doc(id));
      }
      unawaited(batch.commit().catchError((Object e) => debugPrint('도감 정리 동기화 실패: $e')));
    }
    return drop;
  }
}
