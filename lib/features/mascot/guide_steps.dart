/// 7일 가이드: 설치 경과일과 미설정 항목으로 홈 말풍선에 하나씩. 각 1회, 닫으면 기록, 설정된 항목은 건너뜀.
enum GuideStep {
  schedule('schedule', '수거일 알려주면 전날에 챙겨주겠뿅!', 2, 3),
  region('region', '우리 동네 어디뿅? 동네 기준으로 알려주겠뿅!', 4, 5),
  premium('premium', '프리미엄 써보면 더 편하뿅!', 6, 7);

  const GuideStep(this.key, this.line, this.fromDay, this.toDay);

  final String key;
  final String line;
  final int fromDay;
  final int toDay;

  /// 버튼 라벨: 수거일·지역은 [설정하기], 프리미엄은 [자세히](→ 페이월).
  String get actionLabel => this == premium ? '자세히' : '설정하기';

  /// 지금 보여줄 가이드. 없으면 null.
  static GuideStep? current({
    required int daysSinceInstall,
    required bool hasSchedule,
    required bool hasRegion,
    required bool isPremium,
    required Set<String> dismissed,
  }) {
    for (final s in GuideStep.values) {
      if (daysSinceInstall < s.fromDay || daysSinceInstall > s.toDay) continue;
      if (dismissed.contains(s.key)) continue;
      final alreadySet = switch (s) {
        GuideStep.schedule => hasSchedule,
        GuideStep.region => hasRegion,
        GuideStep.premium => isPremium,
      };
      if (alreadySet) continue;
      return s;
    }
    return null;
  }
}
