import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/recycle_result.dart';

/// 판별 기록을 기기에 저장한다. 사진은 앱 문서 폴더에 복사하고,
/// 결과 JSON은 SharedPreferences에 목록으로 보관한다.
class HistoryStore extends ChangeNotifier {
  HistoryStore(this._prefs) {
    _items = _readAll();
  }

  static const _pref = 'history_v1';
  static const maxItems = 50;

  final SharedPreferences _prefs;
  late List<RecycleResult> _items;

  List<RecycleResult> get items => List.unmodifiable(_items);

  static Future<HistoryStore> load() async {
    return HistoryStore(await SharedPreferences.getInstance());
  }

  List<RecycleResult> _readAll() {
    final raw = _prefs.getStringList(_pref) ?? const [];
    final parsed = <RecycleResult>[];
    for (final s in raw) {
      try {
        parsed.add(RecycleResult.fromMap(jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {
        // 손상된 항목은 건너뛴다.
      }
    }
    return parsed;
  }

  Future<void> _writeAll() async {
    await _prefs.setStringList(
      _pref,
      _items.map((r) => r.toJson()).toList(growable: false),
    );
  }

  /// 결과를 저장하고, 사진을 앱 폴더로 복사한 뒤 저장된 결과를 돌려준다.
  Future<RecycleResult> add(RecycleResult result, File? image) async {
    String? savedPath;
    if (image != null) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final folder = Directory('${dir.path}/captures');
        if (!await folder.exists()) await folder.create(recursive: true);
        final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        savedPath = (await image.copy('${folder.path}/$name')).path;
      } catch (_) {
        savedPath = null;
      }
    }
    final saved = result.copyWith(imagePath: savedPath);
    _items.insert(0, saved);
    while (_items.length > maxItems) {
      final removed = _items.removeLast();
      _deleteImage(removed.imagePath);
    }
    await _writeAll();
    notifyListeners();
    return saved;
  }

  Future<void> remove(RecycleResult result) async {
    _items.remove(result);
    _deleteImage(result.imagePath);
    await _writeAll();
    notifyListeners();
  }

  Future<void> clear() async {
    for (final r in _items) {
      _deleteImage(r.imagePath);
    }
    _items = [];
    await _writeAll();
    notifyListeners();
  }

  void _deleteImage(String? path) {
    if (path == null) return;
    try {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
  }
}
