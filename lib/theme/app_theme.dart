import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 브랜드 컬러. "지구를 위한 네온 라임" 컨셉.
class AppColors {
  AppColors._();

  static const lime = Color(0xFFD8FF4A);
  static const onLime = Color(0xFF14161A);
  static const green = Color(0xFF12B76A);
  static const ink = Color(0xFF14161A);

  // Light
  static const bgLight = Color(0xFFF5F7F0);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceTintLight = Color(0xFFEEF2E6);
  static const mutedLight = Color(0xFF6B7280);
  static const outlineLight = Color(0xFFE3E7DB);

  // Dark
  static const bgDark = Color(0xFF0F1114);
  static const surfaceDark = Color(0xFF1A1D21);
  static const surfaceTintDark = Color(0xFF24282E);
  static const mutedDark = Color(0xFF9CA3AF);
  static const outlineDark = Color(0xFF2E333A);
}

/// 자주 쓰는 모양 값.
class AppShape {
  AppShape._();
  static const card = 24.0;
  static const chip = 999.0;
  static const button = 20.0;
}

class AppTheme {
  AppTheme._();

  static const _font = 'Pretendard';

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final isDark = b == Brightness.dark;
    final bg = isDark ? AppColors.bgDark : AppColors.bgLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final surfaceTint = isDark ? AppColors.surfaceTintDark : AppColors.surfaceTintLight;
    final ink = isDark ? const Color(0xFFF3F4F6) : AppColors.ink;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final outline = isDark ? AppColors.outlineDark : AppColors.outlineLight;

    final scheme = ColorScheme(
      brightness: b,
      primary: AppColors.green,
      onPrimary: Colors.white,
      primaryContainer: AppColors.lime,
      onPrimaryContainer: AppColors.onLime,
      secondary: AppColors.lime,
      onSecondary: AppColors.onLime,
      secondaryContainer: surfaceTint,
      onSecondaryContainer: ink,
      tertiary: AppColors.ink,
      onTertiary: AppColors.lime,
      error: const Color(0xFFEF4444),
      onError: Colors.white,
      errorContainer: const Color(0xFFFFE4E6),
      onErrorContainer: const Color(0xFF7F1D1D),
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: muted,
      surfaceContainerHighest: surfaceTint,
      surfaceContainerLow: bg,
      outline: outline,
      outlineVariant: outline,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isDark ? AppColors.surfaceLight : AppColors.ink,
      onInverseSurface: isDark ? AppColors.ink : Colors.white,
      inversePrimary: AppColors.lime,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      fontFamily: _font,
      scaffoldBackgroundColor: bg,
    );

    final text = base.textTheme.apply(bodyColor: ink, displayColor: ink).copyWith(
          displaySmall: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, height: 1.15, letterSpacing: -1, color: ink),
          headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: -0.8, color: ink),
          headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.25, letterSpacing: -0.6, color: ink),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: ink),
          titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.3, color: ink),
          titleSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ink),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, color: ink),
          bodyMedium: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w400, height: 1.5, color: ink),
          bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, height: 1.4, color: muted),
          labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ink),
          labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: muted),
        );

    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShape.card),
          side: BorderSide(color: outline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.lime,
          foregroundColor: AppColors.onLime,
          minimumSize: const Size.fromHeight(60),
          textStyle: const TextStyle(fontFamily: _font, fontSize: 17, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppShape.button)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size.fromHeight(56),
          side: BorderSide(color: outline, width: 1.5),
          textStyle: const TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppShape.button)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ink,
          textStyle: const TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.lime,
        height: 72,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w600, color: ink),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? AppColors.onLime : muted,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.green, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(fontFamily: _font, color: Colors.white, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppShape.card)),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyLarge,
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(iconColor: muted),
    );
  }
}
