import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/recycle_category.dart';
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

  /// 스크린샷·데모용 샘플 데이터.
  Future<void> seedDemo() async {
    final now = DateTime.now();
    RecycleResult make(String name, RecycleCategory c, double conf, List<String> steps, List<String> warns, String tip, int minutesAgo) {
      return RecycleResult(
        itemName: name,
        category: c,
        confidence: conf,
        steps: steps,
        warnings: warns,
        tip: tip,
        createdAt: now.subtract(Duration(minutes: minutesAgo)),
      );
    }

    _items = [
      make('생수 페트병', RecycleCategory.pet, 0.96,
          ['내용물을 비우고 물로 헹궈요.', '라벨을 떼어 비닐로 버려요.', '발로 밟아 찌그러뜨리고 뚜껑을 닫아요.', '투명 페트병 전용 수거함에 넣어요.'],
          ['색이 있는 페트병은 일반 플라스틱이에요.'],
          '찌그러뜨리면 수거함 공간을 3배 아낄 수 있어요.', 12),
      make('컵라면 용기', RecycleCategory.general, 0.91,
          ['남은 국물을 버려요.', '종량제 봉투에 넣어요.'],
          ['음식물이 묻은 스티로폼은 재활용이 안 돼요.'],
          '깨끗이 씻어도 흡수된 기름 때문에 재활용이 어려워요.', 180),
      make('택배 상자', RecycleCategory.paper, 0.98,
          ['송장과 테이프를 모두 떼어요.', '상자를 펼쳐 납작하게 만들어요.', '종이류끼리 묶어서 내놓아요.'],
          const [],
          '송장에 개인정보가 있으니 꼭 떼서 버려요.', 1500),
      make('보조배터리', RecycleCategory.hazardous, 0.94,
          ['일반 쓰레기에 절대 버리지 않아요.', '주민센터나 아파트 폐건전지 수거함에 넣어요.'],
          ['부풀어 있으면 만지지 말고 수거함에 바로 넣어요.'],
          '리튬 배터리는 종량제 봉투 안에서 화재를 일으킬 수 있어요.', 2900),
    ];
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
