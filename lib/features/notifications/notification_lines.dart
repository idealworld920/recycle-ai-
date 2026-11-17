import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

/// assets/data/notification_lines.json. 종류별 제목 1 + 본문 3, 랜덤 선택, {치환자} 치환.
/// 파일을 못 읽으면 내장 문구([builtIn])로.
class NotificationLines {
  NotificationLines(this._data, {Random? random}) : _rnd = random ?? Random();

  static const assetPath = 'assets/data/notification_lines.json';

  /// 체크인 액션 버튼 라벨.
  static const checkinAction = '버렸뿅!';

  static NotificationLines current = NotificationLines(builtIn);

  final Map<String, dynamic> _data;
  final Random _rnd;

  static const Map<String, dynamic> builtIn = {
    'pickupEve': {'title': '내일이뿅!', 'bodies': ['내일 {품목} 수거일이뿅! 미리 모아두면 아침이 편하뿅', '{품목} 내일 나가는 날이뿅~ 잊지 말라뿅!', '내일 아침 바쁠 테니 오늘 저녁에 정리해두자뿅']},
    'pickupMorning': {'title': '오늘이다뿅!!', 'bodies': ['{품목} 버리는 날이뿅! 버렸으면 아래 눌러주라뿅', '일어났뿅? 오늘 {품목} 수거일이뿅!', '나가기 전에 {품목} 챙겼뿅?']},
    'weeklyReport': {'title': '이번 주 결산이뿅', 'bodies': ['이번 주 {N}개 분류했뿅! 재활용 {M}%뿅. 대단하뿅', '{N}개나 찍었뿅! 다음 주도 같이 하자뿅', '이번 주 수고했뿅! 재활용 {M}%면 훌륭하뿅']},
    'familyCheckin': {'title': '{이름}님이 버렸뿅', 'bodies': ['{이름}님이 오늘 {품목} 버리고 왔뿅! 든든하뿅', '{이름}님 덕분에 오늘 수거 끝났뿅!', '{이름}님이 다녀왔뿅~ 고맙다고 해주라뿅']},
    'familyReminder': {'title': '아직이뿅…?', 'bodies': ['오늘 수거일인데 아직 아무도 안 버렸뿅! 누가 갈 거뿅?', '{품목} 아직 집에 있뿅… 누가 나갈 차례뿅?', '저녁 9시뿅! 오늘 안 버리면 다음 주까지 기다려야 하뿅']},
    'specialDay': {'title': '내일은 쉬는 날이뿅', 'bodies': ['내일({날짜})은 {사유}로 수거 안 하뿅! 헷갈리지 말라뿅', '{사유} 때문에 내일은 수거 없뿅~ 다음 수거일에 내놓자뿅', '내일 {품목} 내놓으면 안 되뿅! {사유}라 쉬는 날이뿅']},
    'comeback': {'title': '오랜만이뿅', 'bodies': ['냉장고 정리하다 애매한 거 나오면 찍어보라뿅! 내가 알려주겠뿅', '요즘 분리수거 잘하고 있뿅? 궁금한 거 있으면 불러달라뿅', '리뿅이 심심하뿅… 아무거나 하나 찍어주라뿅']},
    'trialEndD2': {'title': 'ReSAI 프리미엄', 'bodies': ['프리미엄 체험이 이틀 뒤 끝나요. 계속 쓰려면 그대로 두시면 돼요.']},
    'trialEndD1': {'title': 'ReSAI 프리미엄', 'bodies': ['내일 체험이 끝나요. 해지는 Google Play 구독 관리에서 할 수 있어요.']},
  };

  static Future<NotificationLines> load() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      return NotificationLines.fromJsonString(raw);
    } catch (_) {
      return NotificationLines(builtIn);
    }
  }

  static NotificationLines fromJsonString(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return NotificationLines(builtIn);
    return NotificationLines({...builtIn, ...decoded.cast<String, dynamic>()});
  }

  Map<String, dynamic> _entry(String key) => (_data[key] is Map ? (_data[key] as Map).cast<String, dynamic>() : null) ?? (builtIn[key] as Map).cast<String, dynamic>();

  List<String> bodies(String key) {
    final b = _entry(key)['bodies'];
    final list = b is List ? b.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList() : const <String>[];
    return list.isEmpty ? ((builtIn[key] as Map)['bodies'] as List).cast<String>() : list;
  }

  String title(String key, {Map<String, String> vars = const {}}) => fill(_entry(key)['title']?.toString() ?? '', vars);

  /// 본문 하나를 랜덤으로. [index] 를 주면 고정 (테스트·서버와 맞출 때).
  String body(String key, {Map<String, String> vars = const {}, int? index}) {
    final list = bodies(key);
    final i = index == null ? _rnd.nextInt(list.length) : index % list.length;
    return fill(list[i], vars);
  }

  /// 모든 종류가 문구를 갖는지 (검증용).
  Iterable<String> get keys => builtIn.keys;

  static String fill(String s, Map<String, String> vars) {
    var out = s;
    vars.forEach((k, v) => out = out.replaceAll('{$k}', v));
    return out;
  }
}
