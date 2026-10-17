import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/recycle_category.dart';
import '../../models/recycle_result.dart';
import 'history_record.dart';
import 'thumbnail.dart';

/// 분류 기록 저장소. shared_preferences 에 JSON 목록으로 보관한다.
class HistoryStore extends ChangeNotifier {
  HistoryStore(this._prefs) {
    _items = _readAll();
  }

  static const prefKey = 'history_v2';
  static const maxItems = 500;

  /// 같은 품목·분류가 이 시간 안에 또 들어오면 중복으로 보고 저장하지 않는다.
  static const dedupeWindow = Duration(minutes: 2);

  final SharedPreferences _prefs;
  late List<HistoryRecord> _items;

  /// 최신순.
  List<HistoryRecord> get items => List.unmodifiable(_items);

  static Future<HistoryStore> load() async => HistoryStore(await SharedPreferences.getInstance());

  List<HistoryRecord> _readAll() {
    final raw = _prefs.getStringList(prefKey) ?? const [];
    final parsed = <HistoryRecord>[];
    for (final s in raw) {
      try {
        parsed.add(HistoryRecord.fromJson(jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {
        // 손상된 항목은 건너뛴다.
      }
    }
    parsed.sort((a, b) => b.date.compareTo(a.date));
    return parsed;
  }

  Future<void> _writeAll() async {
    await _prefs.setStringList(prefKey, _items.map((r) => jsonEncode(r.toJson())).toList(growable: false));
  }

  /// AI 분류 결과를 저장한다. 중복이면 기존 기록을 돌려준다.
  Future<HistoryRecord> addResult(RecycleResult result, {Uint8List? imageBytes}) async {
    final dup = _findDuplicate(result);
    if (dup != null) return dup;

    String? thumb;
    if (imageBytes != null) {
      thumb = await makeThumbBase64(imageBytes);
    }
    final record = HistoryRecord.fromResult(result, id: _newId(result.createdAt), imageThumb: thumb);
    return _insert(record);
  }

  /// 이미 만들어진 기록을 넣는다 (테스트·데모용).
  Future<HistoryRecord> addRecord(HistoryRecord record) async {
    if (_items.any((r) => r.id == record.id)) return record;
    return _insert(record);
  }

  Future<HistoryRecord> _insert(HistoryRecord record) async {
    _items.insert(0, record);
    _items.sort((a, b) => b.date.compareTo(a.date));
    if (_items.length > maxItems) {
      _items = _items.sublist(0, maxItems);
    }
    await _writeAll();
    notifyListeners();
    return record;
  }

  HistoryRecord? _findDuplicate(RecycleResult result) {
    for (final r in _items) {
      if (r.itemName == result.itemName &&
          r.category == result.category &&
          result.createdAt.difference(r.date).abs() <= dedupeWindow) {
        return r;
      }
    }
    return null;
  }

  static String _newId(DateTime at) =>
      '${at.microsecondsSinceEpoch.toRadixString(36)}-${at.hashCode.toRadixString(36)}';

  Future<void> remove(String id) async {
    _items.removeWhere((r) => r.id == id);
    await _writeAll();
    notifyListeners();
  }

  Future<void> clear() async {
    _items = [];
    await _writeAll();
    notifyListeners();
  }

  // ---- 요약 ----

  /// 해당 월의 기록.
  List<HistoryRecord> inMonth(DateTime month) =>
      _items.where((r) => r.date.year == month.year && r.date.month == month.month).toList(growable: false);

  /// 그룹별 건수. 모든 그룹 키를 포함한다.
  static Map<HistoryGroup, int> countByGroup(Iterable<HistoryRecord> records) {
    final counts = {for (final g in HistoryGroup.values) g: 0};
    for (final r in records) {
      counts[r.group] = counts[r.group]! + 1;
    }
    return counts;
  }

  /// 날짜(연-월-일)별로 묶는다. 최신 날짜가 먼저.
  static List<(DateTime, List<HistoryRecord>)> groupByDay(Iterable<HistoryRecord> records) {
    final map = <DateTime, List<HistoryRecord>>{};
    for (final r in records) {
      final day = DateTime(r.date.year, r.date.month, r.date.day);
      map.putIfAbsent(day, () => []).add(r);
    }
    final keys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return [for (final k in keys) (k, map[k]!)];
  }

  /// 스크린샷·데모용 샘플.
  Future<void> seedDemo() async {
    final now = DateTime.now();
    HistoryRecord make(String name, RecycleCategory c, double conf, List<String> steps, List<String> warns, String tip, int minutesAgo) {
      final r = RecycleResult(
        itemName: name,
        category: c,
        confidence: conf,
        steps: steps,
        warnings: warns,
        tip: tip,
        createdAt: now.subtract(Duration(minutes: minutesAgo)),
      );
      return HistoryRecord.fromResult(r, id: _newId(r.createdAt));
    }

    _items = [
      make('생수 페트병', RecycleCategory.pet, 0.96,
          ['내용물을 비우고 물로 헹궈요.', '라벨을 떼어 비닐로 버려요.', '찌그러뜨리고 뚜껑을 닫아요.'],
          ['색이 있는 페트병은 일반 플라스틱이에요.'], '찌그러뜨리면 수거함 공간을 아낄 수 있어요.', 12),
      make('컵라면 용기', RecycleCategory.general, 0.91,
          ['남은 국물을 버려요.', '종량제 봉투에 넣어요.'], ['음식물이 묻은 스티로폼은 재활용이 안 돼요.'], '', 180),
      make('택배 상자', RecycleCategory.paper, 0.98,
          ['송장과 테이프를 떼요.', '펼쳐서 납작하게 만들어요.', '종이류끼리 묶어요.'], const [], '송장의 개인정보는 꼭 떼서 버려요.', 1500),
      make('보조배터리', RecycleCategory.hazardous, 0.94,
          ['일반 쓰레기에 버리지 않아요.', '폐건전지 수거함에 넣어요.'], ['부풀어 있으면 만지지 마세요.'], '', 2900),
      make('바나나 껍질', RecycleCategory.food, 0.97, ['물기를 빼요.', '음식물 봉투에 넣어요.'], const [], '', 4300),
    ];
    await _writeAll();
    notifyListeners();
  }
}
