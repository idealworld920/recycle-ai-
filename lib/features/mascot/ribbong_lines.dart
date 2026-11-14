import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../schedule/pickup_schedule.dart';

/// 홈 말풍선 조건. 위가 우선.
enum LineWhen { pickupToday, pickupTomorrow, returnAfter3Days, classified10, morning, day, evening, night, random }

/// 홈 리뿅이 대사. assets/data/ribbong_lines.json 을 읽고, 없거나 조건 키가 없으면 내장 문장을 쓴다.
///
/// 파일 형식(둘 다 허용):
///  - ["문장", ...]                               → 전부 random
///  - {"lines":[{"text":"…","when":"morning"}, …]} → when 은 LineWhen 이름(없으면 random)
///  - {"morning":[…], "random":[…], …}
/// 문장은 "~뿅" 으로 끝나야 한다 (리뿅이 말풍선).
class RibbongLines {
  RibbongLines(this._byWhen);

  final Map<LineWhen, List<String>> _byWhen;

  static const assetPath = 'assets/data/ribbong_lines.json';

  /// main() 에서 로드해 둔 현재 대사집. 로드 전엔 내장 문장만.
  static RibbongLines current = RibbongLines(const {});

  static const builtIn = <LineWhen, List<String>>{
    LineWhen.pickupToday: ['오늘 {type} 버리는 날이뿅! 모아둔 거 꺼내뿅!', '{type} 내놓는 날이뿅~ 버렸으면 눌러주뿅!'],
    LineWhen.pickupTomorrow: ['내일 {type} 날이뿅. 미리 묶어두면 편하뿅~', '내일은 {type}! 오늘 저녁에 정리해두뿅.'],
    LineWhen.returnAfter3Days: ['오랜만이뿅! 보고 싶었뿅!', '어디 갔다 왔뿅? 다시 와서 기쁘뿅!'],
    LineWhen.classified10: ['오늘 벌써 10개나 분류했뿅! 대단하뿅!!', '분류 10개 돌파뿅! 손이 빠르뿅~'],
    LineWhen.morning: ['좋은 아침이뿅! 오늘도 깔끔하게 가보자뿅~', '아침이뿅! 버릴 거 있으면 찍어보뿅.'],
    LineWhen.day: ['뭐 버릴 거 있으면 찍어보뿅!', '헷갈리는 쓰레기? 나한테 보여주뿅~'],
    LineWhen.evening: ['저녁엔 쓰레기 정리하기 좋은 시간이뿅~', '오늘 하루도 수고했뿅! 분리수거도 잊지 말뿅.'],
    LineWhen.night: ['늦은 밤이뿅… 내일 버릴 거 미리 모아둘까뿅?', '밤이 깊었뿅. 쓰레기는 아침에 내놓뿅~'],
    LineWhen.random: ['페트병은 라벨 떼고 찌그러뜨리뿅!', '종이팩은 종이랑 따로 모으뿅~', '기록 탭에서 이번 달 재활용률 확인해보뿅!'],
  };

  static Future<RibbongLines> load() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      return RibbongLines.fromJsonString(raw);
    } catch (_) {
      return RibbongLines(const {});
    }
  }

  static RibbongLines fromJsonString(String raw) {
    final decoded = jsonDecode(raw);
    final out = <LineWhen, List<String>>{};
    void add(LineWhen w, Object? text) {
      final s = text?.toString().trim() ?? '';
      if (s.isEmpty) return;
      out.putIfAbsent(w, () => []).add(s);
    }

    LineWhen whenOf(Object? v) => LineWhen.values.where((w) => w.name == v?.toString()).firstOrNull ?? LineWhen.random;
    if (decoded is List) {
      for (final e in decoded) {
        if (e is Map) {
          add(whenOf(e['when'] ?? e['condition']), e['text'] ?? e['line']);
        } else {
          add(LineWhen.random, e);
        }
      }
    } else if (decoded is Map) {
      final lines = decoded['lines'];
      if (lines is List) {
        for (final e in lines) {
          if (e is Map) {
            add(whenOf(e['when'] ?? e['condition']), e['text'] ?? e['line']);
          } else {
            add(LineWhen.random, e);
          }
        }
      }
      for (final w in LineWhen.values) {
        final v = decoded[w.name];
        if (v is List) {
          for (final e in v) {
            add(w, e);
          }
        }
      }
    }
    return RibbongLines(out);
  }

  int get count => _byWhen.values.fold(0, (a, b) => a + b.length);

  List<String> linesFor(LineWhen w) => _byWhen[w]?.isNotEmpty == true ? _byWhen[w]! : (builtIn[w] ?? const []);

  /// 조건 우선순위: 수거일 당일 > 전날 > 3일 미접속 복귀 > 당일 분류 10개↑ > 시간대 > 랜덤.
  static LineWhen decide({
    required DateTime now,
    required List<WasteType> todayPickups,
    required List<WasteType> tomorrowPickups,
    required DateTime? lastOpenedAt,
    required int classifiedToday,
  }) {
    if (todayPickups.isNotEmpty) return LineWhen.pickupToday;
    if (tomorrowPickups.isNotEmpty) return LineWhen.pickupTomorrow;
    if (lastOpenedAt != null && now.difference(lastOpenedAt) >= const Duration(days: 3)) return LineWhen.returnAfter3Days;
    if (classifiedToday >= 10) return LineWhen.classified10;
    final h = now.hour;
    if (h >= 5 && h < 11) return LineWhen.morning;
    if (h >= 11 && h < 17) return LineWhen.day;
    if (h >= 17 && h < 22) return LineWhen.evening;
    return LineWhen.night;
  }

  /// 조건에 맞는 문장 하나. 시간대 문장이 없으면 random 으로.
  String pick(LineWhen when, {List<WasteType> types = const [], Random? rnd}) {
    var pool = linesFor(when);
    if (pool.isEmpty) pool = linesFor(LineWhen.random);
    // 시간대·랜덤은 랜덤 풀과 섞어서 지루하지 않게.
    if (when.index >= LineWhen.morning.index) pool = [...pool, ...linesFor(LineWhen.random)];
    final r = rnd ?? Random();
    final line = pool[r.nextInt(pool.length)];
    final typeLabel = types.isEmpty ? '쓰레기' : types.map((t) => t.label).join('·');
    return line.replaceAll('{type}', typeLabel);
  }
}
