import 'package:flutter/material.dart';

import '../../models/waste_group.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// 화면에서 쓰는 색 토큰. `Theme.of(context).extension<AppTokens>()` 로 꺼낸다.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.divider,
    required this.primary,
    required this.primarySoft,
    required this.ink,
    required this.onInk,
    required this.recycle,
    required this.general,
    required this.food,
    required this.special,
    required this.error,
    required this.errorSoft,
    required this.warningSoft,
    required this.warningText,
  });

  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color divider;
  final Color primary;
  final Color primarySoft;
  final Color ink;
  final Color onInk;
  final Color recycle;
  final Color general;
  final Color food;
  final Color special;
  final Color error;
  final Color errorSoft;
  final Color warningSoft;
  final Color warningText;

  Color groupColor(WasteGroup g) => switch (g) {
        WasteGroup.recycle => recycle,
        WasteGroup.general => general,
        WasteGroup.food => food,
        WasteGroup.special => special,
      };

  /// 뱃지 배경: 10% 투명도.
  Color groupSoft(WasteGroup g) => groupColor(g).withValues(alpha: 0.10);

  static const light = AppTokens(
    background: AppColors.background,
    surface: AppColors.surface,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textDisabled: AppColors.textDisabled,
    divider: AppColors.divider,
    primary: AppColors.primary,
    primarySoft: AppColors.primarySoft,
    ink: AppColors.ink,
    onInk: AppColors.onInk,
    recycle: AppColors.recycle,
    general: AppColors.general,
    food: AppColors.food,
    special: AppColors.special,
    error: AppColors.error,
    errorSoft: AppColors.errorSoft,
    warningSoft: AppColors.warningSoft,
    warningText: AppColors.warningText,
  );

  @override
  AppTokens copyWith() => this;

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) => this;
}

extension AppContext on BuildContext {
  AppTokens get colors => Theme.of(this).extension<AppTokens>()!;
  TextTheme get text => Theme.of(this).textTheme;
}

/// 200ms 페이드 + 살짝 올라오는 전환. 과한 효과 없음.
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}

/// MaterialPageRoute 는 300ms 고정이라 200ms 짜리를 따로 둔다.
class AppPageRoute<T> extends MaterialPageRoute<T> {
  AppPageRoute({required super.builder, super.settings});

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 200);
}

extension AppNavigation on BuildContext {
  Future<T?> pushPage<T>(Widget page) => Navigator.of(this).push<T>(AppPageRoute(builder: (_) => page));
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    const c = AppTokens.light;
    final text = AppTypography.textTheme();

    final scheme = const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primarySoft,
      onPrimaryContainer: AppColors.primary,
      secondary: AppColors.ink,
      onSecondary: AppColors.onInk,
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceContainerLow: AppColors.surface,
      surfaceContainer: AppColors.surface,
      surfaceContainerHigh: AppColors.surface,
      surfaceContainerHighest: AppColors.surface,
      outline: AppColors.divider,
      outlineVariant: AppColors.divider,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.errorSoft,
      onErrorContainer: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      fontFamily: AppTypography.fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: c.background,
      splashFactory: NoSplash.splashFactory,
      highlightColor: c.surface,
      extensions: const [AppTokens.light],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AppPageTransitionsBuilder(),
          TargetPlatform.iOS: AppPageTransitionsBuilder(),
          TargetPlatform.macOS: AppPageTransitionsBuilder(),
          TargetPlatform.windows: AppPageTransitionsBuilder(),
          TargetPlatform.linux: AppPageTransitionsBuilder(),
          TargetPlatform.fuchsia: AppPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        titleTextStyle: AppTypography.section,
        iconTheme: IconThemeData(color: c.textPrimary, size: 24, weight: 300, fill: 0),
      ),
      iconTheme: IconThemeData(color: c.textPrimary, size: 24, weight: 300, fill: 0),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.ink,
          foregroundColor: c.onInk,
          disabledBackgroundColor: c.surface,
          disabledForegroundColor: c.textDisabled,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          elevation: 0,
          textStyle: AppTypography.bodyStrong,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textPrimary,
          backgroundColor: c.surface,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          side: BorderSide.none,
          textStyle: AppTypography.bodyStrong,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          textStyle: AppTypography.bodyStrong,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: c.textPrimary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surface,
        selectedColor: c.ink,
        labelStyle: AppTypography.bodyStrong.copyWith(fontSize: 14),
        secondaryLabelStyle: AppTypography.bodyStrong.copyWith(fontSize: 14, color: c.onInk),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        showCheckmark: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        height: 64,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppTypography.caption.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected) ? c.textPrimary : c.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            weight: 300,
            color: states.contains(WidgetState.selected) ? c.textPrimary : c.textSecondary,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.base),
        hintStyle: AppTypography.body.copyWith(color: c.textDisabled),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.button), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.button), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.ink,
        contentTextStyle: AppTypography.body.copyWith(color: c.onInk),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.md)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet)),
        titleTextStyle: AppTypography.section,
        contentTextStyle: AppTypography.body,
      ),
      dividerTheme: DividerThemeData(color: c.divider, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(iconColor: c.textSecondary, contentPadding: EdgeInsets.zero),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.ink),
    );
  }
}
