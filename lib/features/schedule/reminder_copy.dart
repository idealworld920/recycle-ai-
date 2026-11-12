import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../tips/tip_model.dart';
import '../tips/tips_repository.dart';
import 'pickup_schedule.dart';

/// 수거일 알림 문구. 리뿅이가 말하고, 종류별 팁 풀에서 하나를 붙인다.
///
/// 같은 팁은 2주 안에 다시 쓰지 않도록 쓴 날짜를 기기에 남긴다.
class ReminderCopy {
  ReminderCopy(this._tips, this._prefs, {Random? random, DateTime Function()? now})
      : _random = random ?? Random(),
        _now = now ?? DateTime.now;

  static const prefKey = 'reminder_tips_used';
  static const noRepeat = Duration(days: 14);

  final TipsRepository _tips;
  final SharedPreferences _prefs;
  final Random _random;
  final DateTime Function() _now;

  static String title(WasteType type) => '리뿅이: 내일 ${type.label} 날이뿅!';

  static String lead(WasteType type) => switch (type) {
        WasteType.recycle => '내일 재활용 날이에요. 모아둔 거 꺼내둬요!',
        WasteType.general => '내일 일반쓰레기 날이에요. 종량제 봉투 묶어둬요!',
        WasteType.food => '내일 음식물 날이에요. 물기 빼서 준비해요!',
      };

  static TipCategory categoryOf(WasteType type) => switch (type) {
        WasteType.recycle => TipCategory.recycle,
        WasteType.general => TipCategory.general,
        WasteType.food => TipCategory.food,
      };

  /// 종류에 맞는 팁 풀에서 최근 2주간 안 쓴 것 중 하나. 다 썼으면 전체에서 고른다.
  Tip? pickTip(WasteType type) {
    final pool = _tips.all.where((t) => t.category == categoryOf(type) && t.steps.isNotEmpty).toList();
    if (pool.isEmpty) return null;
    final used = _usedMap();
    final cutoff = _now().subtract(noRepeat).millisecondsSinceEpoch;
    final fresh = pool.where((t) => (used[t.id] ?? 0) < cutoff).toList();
    final from = fresh.isEmpty ? pool : fresh;
    return from[_random.nextInt(from.length)];
  }

  /// 본문: 안내 한 줄 + 팁 한 줄. 예) "내일 재활용 날이에요. 모아둔 거 꺼내둬요! 💡 투명 페트병: 라벨 떼고 찌그러뜨리기"
  String body(WasteType type, {Tip? tip}) {
    final t = tip ?? pickTip(type);
    if (t == null) return lead(type);
    return '${lead(type)} 💡 ${t.name}: ${_short(t.steps.first)}';
  }

  /// 알림을 등록할 때 쓴 팁을 기록한다.
  Future<void> markUsed(Iterable<Tip> tips) async {
    final used = _usedMap();
    final nowMs = _now().millisecondsSinceEpoch;
    final cutoff = _now().subtract(noRepeat * 2).millisecondsSinceEpoch;
    for (final t in tips) {
      used[t.id] = nowMs;
    }
    used.removeWhere((_, v) => v < cutoff);
    await _prefs.setString(prefKey, jsonEncode(used));
  }

  Map<String, int> _usedMap() {
    final raw = _prefs.getString(prefKey);
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  static String _short(String s) {
    final t = s.trim().replaceAll(RegExp(r'[.。!]+$'), '');
    return t.length > 28 ? '${t.substring(0, 28)}…' : t;
  }
}
