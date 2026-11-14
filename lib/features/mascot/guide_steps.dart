/// 7일 가이드: 설치 경과일과 미설정 항목으로 홈 말풍선에 하나씩. 각 1회, 닫으면 기록, 설정된 항목은 건너뜀.
enum GuideStep {
  schedule('schedule', '수거일을 설정해두면 전날 저녁에 알려줄 수 있뿅!', 2, 3),
  region('region', '거주 지역을 고르면 우리 동네 기준으로 알려주겠뿅~', 4, 5),
  familyPlan('familyPlan', '가족이랑 같이 쓰면 누가 버렸는지도 보이뿅! 가족 플랜 구경해볼래뿅?', 6, 7);

  const GuideStep(this.key, this.line, this.fromDay, this.toDay);

  final String key;
  final String line;
  final int fromDay;
  final int toDay;

  /// 가족 플랜 가이드만 [자세히] 버튼이 있다.
  bool get hasDetail => this == familyPlan;

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
        GuideStep.familyPlan => isPremium,
      };
      if (alreadySet) continue;
      return s;
    }
    return null;
  }
}
