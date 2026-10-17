import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 타이포 토큰. Pretendard, 자간 -0.3, 줄간격 1.4.
class AppTypography {
  AppTypography._();

  static const fontFamily = 'Pretendard';
  static const _spacing = -0.3;
  static const _height = 1.4;

  static const TextStyle _base = TextStyle(
    fontFamily: fontFamily,
    letterSpacing: _spacing,
    height: _height,
    color: AppColors.textPrimary,
  );

  /// 제목 24 / Bold
  static final TextStyle title = _base.copyWith(fontSize: 24, fontWeight: FontWeight.w700);

  /// 섹션 18 / SemiBold
  static final TextStyle section = _base.copyWith(fontSize: 18, fontWeight: FontWeight.w600);

  /// 본문 15 / Regular
  static final TextStyle body = _base.copyWith(fontSize: 15, fontWeight: FontWeight.w400);

  /// 본문 15 / SemiBold (리스트 제목, 버튼)
  static final TextStyle bodyStrong = _base.copyWith(fontSize: 15, fontWeight: FontWeight.w600);

  /// 캡션 13 / Regular
  static final TextStyle caption = _base.copyWith(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary);

  static TextTheme textTheme() => TextTheme(
        headlineSmall: title,
        titleLarge: section,
        titleMedium: section,
        titleSmall: bodyStrong,
        bodyLarge: body,
        bodyMedium: body,
        bodySmall: caption,
        labelLarge: bodyStrong,
        labelMedium: caption,
        labelSmall: caption,
      );
}
