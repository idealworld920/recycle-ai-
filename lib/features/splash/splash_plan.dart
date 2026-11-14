/// Remote Config `splash_message` = {"id":"…","text":"…뿅","startAt":"2026-12-01T00:00:00+09:00","endAt":"…"}.
class SplashMessage {
  const SplashMessage({required this.id, required this.text, this.startAt, this.endAt});

  final String id;
  final String text;
  final DateTime? startAt;
  final DateTime? endAt;

  bool activeAt(DateTime now) => (startAt == null || !now.isBefore(startAt!)) && (endAt == null || now.isBefore(endAt!));

  static SplashMessage? fromJson(Map<String, dynamic>? j) {
    if (j == null) return null;
    final id = j['id']?.toString() ?? '';
    final text = j['text']?.toString() ?? '';
    if (id.isEmpty || text.isEmpty) return null;
    return SplashMessage(id: id, text: text, startAt: DateTime.tryParse(j['startAt']?.toString() ?? ''), endAt: DateTime.tryParse(j['endAt']?.toString() ?? ''));
  }
}

enum SplashKind {
  /// 최초 실행: r_intro.gif 2.6초 → 온보딩.
  firstRun,

  /// 평소: r_intro_short.gif 0.8초 → 홈.
  short,

  /// 3일 이상 미접속 복귀: r_intro.gif + "오랜만이뿅!" → 홈.
  returning,

  /// Remote Config 공지: r_intro.gif + 문구 → 홈, id 저장.
  message,

  /// 애니메이션 줄이기: r_intro_static.png 0.3초.
  reduced,
}

/// 스플래시가 무엇을 얼마나 보여줄지. 순수 계산이라 테스트하기 쉽다.
class SplashPlan {
  const SplashPlan(this.kind, {this.text, this.messageId});

  final SplashKind kind;
  final String? text;
  final String? messageId;

  static const introLength = Duration(milliseconds: 2600);
  static const shortLength = Duration(milliseconds: 800);
  static const reducedLength = Duration(milliseconds: 300);
  static const maxTotal = Duration(seconds: 3);
  static const returnAfter = Duration(days: 3);
  static const returningText = '오랜만이뿅!';

  Duration get length => switch (kind) {
        SplashKind.short => shortLength,
        SplashKind.reduced => reducedLength,
        _ => introLength,
      };

  bool get goesToOnboarding => kind == SplashKind.firstRun;

  static SplashPlan decide({
    required bool onboarded,
    required DateTime? lastOpenedAt,
    required DateTime now,
    SplashMessage? message,
    Set<String> seen = const {},
    bool reduceMotion = false,
  }) {
    if (!onboarded) return const SplashPlan(SplashKind.firstRun);
    final returning = lastOpenedAt != null && now.difference(lastOpenedAt) >= returnAfter;
    final msg = message != null && message.activeAt(now) && !seen.contains(message.id) ? message : null;
    if (reduceMotion) {
      // 정지 이미지 0.3초. 문구는 유지(복귀·공지)하되 짧게.
      if (returning) return const SplashPlan(SplashKind.reduced, text: returningText);
      if (msg != null) return SplashPlan(SplashKind.reduced, text: msg.text, messageId: msg.id);
      return const SplashPlan(SplashKind.reduced);
    }
    if (returning) return const SplashPlan(SplashKind.returning, text: returningText);
    if (msg != null) return SplashPlan(SplashKind.message, text: msg.text, messageId: msg.id);
    return const SplashPlan(SplashKind.short);
  }
}
