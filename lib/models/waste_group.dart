/// 뱃지·요약에 쓰는 4분류. 색은 테마 토큰에서 가져온다.
enum WasteGroup {
  recycle('재활용'),
  general('일반'),
  food('음식물'),
  special('특수');

  const WasteGroup(this.label);
  final String label;
}
