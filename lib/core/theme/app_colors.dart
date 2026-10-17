import 'package:flutter/material.dart';

/// 색상 토큰. 화면 코드에서는 이 값을 직접 쓰지 말고 `context.colors` 로 접근한다.
class AppColors {
  AppColors._();

  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF7F7F8);

  static const textPrimary = Color(0xFF111111);
  static const textSecondary = Color(0xFF6B6B6B);
  static const textDisabled = Color(0xFFB5B5B5);

  static const divider = Color(0xFFEDEDED);

  /// 포인트. 보조 버튼·활성 링크에만 절제해서.
  static const primary = Color(0xFF2563EB);

  /// 선택된 카드, 정보 박스 배경.
  static const primarySoft = Color(0xFFEFF4FF);

  /// 주요 버튼(검정)과 그 위 글자.
  static const ink = Color(0xFF111111);
  static const onInk = Color(0xFFFFFFFF);

  // 카테고리 뱃지 (배경은 10% 투명도, 글자는 원색)
  static const recycle = Color(0xFF2563EB);
  static const general = Color(0xFF6B6B6B);
  static const food = Color(0xFFD97706);
  static const special = Color(0xFFDC2626);

  static const error = Color(0xFFDC2626);
  static const errorSoft = Color(0xFFFDECEC);
  static const warningSoft = Color(0xFFFFF4CC);
  static const warningText = Color(0xFF8A6500);
}
