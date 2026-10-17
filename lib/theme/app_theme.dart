import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 타다(TADA) 앱을 참고한 흑백 미니멀 팔레트.
/// 색은 거의 쓰지 않고, 여백과 타이포그래피로 위계를 만든다.
class AppColors {
  AppColors._();

  static const black = Color(0xFF111111);
  static const white = Color(0xFFFFFFFF);

  // Light
  static const bgLight = Color(0xFFFFFFFF);
  static const surfaceLight = Color(0xFFF4F4F5);
  static const surface2Light = Color(0xFFEBEBED);
  static const inkLight = Color(0xFF111111);
  static const mutedLight = Color(0xFF8A8A8E);
  static const dividerLight = Color(0xFFEDEDEF);

  // Dark
  static const bgDark = Color(0xFF000000);
  static const surfaceDark = Color(0xFF1A1A1C);
  static const surface2Dark = Color(0xFF2A2A2D);
  static const inkDark = Color(0xFFF5F5F7);
  static const mutedDark = Color(0xFF8E8E93);
  static const dividerDark = Color(0xFF2A2A2D);

  static const danger = Color(0xFFE5484D);
  static const success = Color(0xFF1DB954);
}

class AppShape {
  AppShape._();
  static const card = 16.0;
  static const button = 14.0;
  static const pill = 999.0;
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
    final surface2 = isDark ? AppColors.surface2Dark : AppColors.surface2Light;
    final ink = isDark ? AppColors.inkDark : AppColors.inkLight;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final divider = isDark ? AppColors.dividerDark : AppColors.dividerLight;
    final primary = isDark ? AppColors.white : AppColors.black;
    final onPrimary = isDark ? AppColors.black : AppColors.white;

    final scheme = ColorScheme(
      brightness: b,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: surface,
      onPrimaryContainer: ink,
      secondary: muted,
      onSecondary: bg,
      secondaryContainer: surface,
      onSecondaryContainer: ink,
      tertiary: AppColors.success,
      onTertiary: AppColors.white,
      error: AppColors.danger,
      onError: AppColors.white,
      errorContainer: isDark ? const Color(0xFF3A1D1F) : const Color(0xFFFDECEC),
      onErrorContainer: isDark ? const Color(0xFFFFB4B4) : const Color(0xFF8C1D21),
      surface: bg,
      onSurface: ink,
      onSurfaceVariant: muted,
      surfaceContainerLowest: bg,
      surfaceContainerLow: surface,
      surfaceContainer: surface,
      surfaceContainerHigh: surface2,
      surfaceContainerHighest: surface2,
      outline: divider,
      outlineVariant: divider,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: ink,
      onInverseSurface: bg,
      inversePrimary: onPrimary,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      fontFamily: _font,
      scaffoldBackgroundColor: bg,
      splashFactory: InkSparkle.splashFactory,
    );

    final text = base.textTheme.apply(bodyColor: ink, displayColor: ink).copyWith(
          displaySmall: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: -1.0, color: ink),
          headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, height: 1.25, letterSpacing: -0.8, color: ink),
          headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.3, letterSpacing: -0.6, color: ink),
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: ink),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.3, color: ink),
          titleSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: ink),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.55, letterSpacing: -0.2, color: ink),
          bodyMedium: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w400, height: 1.5, letterSpacing: -0.2, color: ink),
          bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, height: 1.45, color: muted),
          labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: ink),
          labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: muted),
          labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: muted),
        );

    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleMedium,
        iconTheme: IconThemeData(color: ink, size: 24),
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppShape.card)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: surface2,
          disabledForegroundColor: muted,
          minimumSize: const Size.fromHeight(56),
          elevation: 0,
          textStyle: const TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppShape.button)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          backgroundColor: surface,
          minimumSize: const Size.fromHeight(56),
          side: BorderSide.none,
          textStyle: const TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.2),
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
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        height: 64,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: _font,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected) ? ink : muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(size: 26, color: states.contains(WidgetState.selected) ? ink : muted),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        hintStyle: TextStyle(color: muted, fontFamily: _font),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppShape.button), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppShape.button), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppShape.button),
          borderSide: BorderSide(color: ink, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: TextStyle(fontFamily: _font, color: bg, fontSize: 14.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
      ),
      dividerTheme: DividerThemeData(color: divider, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(iconColor: muted, contentPadding: EdgeInsets.zero),
      iconTheme: IconThemeData(color: ink),
    );
  }
}
