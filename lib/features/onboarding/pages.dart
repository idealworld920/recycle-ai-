import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/mascot.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../models/recycle_category.dart';
import '../../models/recycle_result.dart';
import '../../widgets/app_card.dart';
import '../../widgets/result_card.dart';

/// 온보딩 1·2페이지 공통 틀: 위 60% 목업(+ 리뿅이 96px 겹침), 아래 제목 24/Bold + 부제 15/Regular.
class OnboardingValuePage extends StatelessWidget {
  const OnboardingValuePage({super.key, required this.mock, required this.mascot, required this.title, required this.subtitle});

  final Widget mock;
  final Mascot mascot;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0),
            child: LayoutBuilder(
              builder: (context, box) {
                final w = box.maxWidth.clamp(0.0, 340.0);
                return Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // 살짝 뒤로 기울여 깊이감. 터치는 막는다.
                    IgnorePointer(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0012)
                            ..rotateX(0.14),
                          child: SizedBox(width: w, child: mock),
                        ),
                      ),
                    ),
                    Positioned(
                      left: (box.maxWidth - w) / 2 - 36,
                      top: -4,
                      child: MascotImage(mascot, size: 96),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.headlineSmall),
                const SizedBox(height: AppSpacing.md),
                Text(subtitle, style: t.bodyMedium?.copyWith(color: c.textSecondary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 1페이지 목업: 실제 [ResultCard] 를 샘플 데이터로 그린다.
class ResultMock extends StatelessWidget {
  const ResultMock({super.key});

  static final sample = RecycleResult(
    itemName: '컵라면 용기',
    category: RecycleCategory.general,
    confidence: 0.91,
    reason: '기름이 밴 용기는 재활용이 어려워요.',
    steps: const ['남은 국물을 비워요.', '종량제 봉투에 넣어요.'],
    warnings: const [],
    tip: '',
    createdAt: DateTime(2026, 1, 1),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 88,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(AppRadius.card)),
            child: Icon(RecycleCategory.general.icon, size: 36, color: c.textPrimary),
          ),
          const SizedBox(height: AppSpacing.base),
          ResultCard(result: sample, showConfidence: false),
        ],
      ),
    );
  }
}

/// 2페이지 목업: 수거일 카드 두 상태("D-1" + "오늘 버리는 날") 겹침 + 홈 위젯 미리보기.
class RoutineMock extends StatelessWidget {
  const RoutineMock({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            // 뒤: 다음 수거일
            Padding(
              padding: const EdgeInsets.only(left: 56, bottom: 128),
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('다음 수거일', style: t.bodySmall),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(child: Text('재활용', style: t.bodyMedium)),
                        Text('(수요일)', style: t.bodySmall),
                        const SizedBox(width: AppSpacing.sm),
                        Text('D-1', style: t.titleSmall?.copyWith(fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(child: Text('일반쓰레기', style: t.bodyMedium)),
                        Text('(금요일)', style: t.bodySmall),
                        const SizedBox(width: AppSpacing.sm),
                        Text('D-3', style: t.titleSmall?.copyWith(fontSize: 18)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // 앞: 오늘 수거일
            Positioned(
              left: 0,
              right: AppSpacing.xl,
              bottom: 0,
              child: AppCard(
                soft: true,
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Symbols.delete_rounded, size: 22, color: c.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text('오늘 재활용 버리는 날!', style: t.headlineSmall?.copyWith(fontSize: 18))),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text('모아둔 거 한 번에 내놓고, 버렸으면 눌러주세요.', style: t.bodySmall),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(child: Text('재활용', style: t.titleSmall)),
                        Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: c.ink, borderRadius: BorderRadius.circular(AppRadius.button)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Symbols.check_rounded, size: 18, color: c.onInk),
                              const SizedBox(width: AppSpacing.xs),
                              Text('버렸어요', style: t.labelLarge?.copyWith(color: c.onInk)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // 홈 위젯 미리보기 (작게)
        Container(
          width: 168,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: c.background,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: c.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Symbols.widgets_rounded, size: 14, color: c.textSecondary),
                  const SizedBox(width: AppSpacing.xs),
                  Text('홈 위젯', style: t.bodySmall),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(child: Text('재활용', style: t.bodyMedium)),
                  Text('D-1', style: t.titleSmall?.copyWith(color: c.primary)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: Text('일반쓰레기', style: t.bodyMedium)),
                  Text('D-3', style: t.titleSmall),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
