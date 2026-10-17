import 'package:flutter/material.dart';

import '../core/theme/app_sheet.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';
import '../data/recycling_guide.dart';
import '../widgets/app_card.dart';
import '../widgets/category_badge.dart';
import 'result_screen.dart' show StepNumber;

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
          children: [
            Text('분리배출 가이드', style: t.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text('분류별로 버리는 방법을 정리했어요. 인터넷 없이도 볼 수 있어요.', style: t.bodySmall),
            const SizedBox(height: AppSpacing.lg),
            for (var i = 0; i < recyclingGuide.length; i++) ...[
              _GuideRow(entry: recyclingGuide[i]),
              if (i != recyclingGuide.length - 1) const Divider(),
            ],
          ],
        ),
      ),
    );
  }
}

class _GuideRow extends StatelessWidget {
  const _GuideRow({required this.entry});

  final GuideEntry entry;

  @override
  Widget build(BuildContext context) {
    final cat = entry.category;
    final t = context.text;
    return InkWell(
      onTap: () => showGuideDetailSheet(context, entry),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            CategoryIcon(category: cat),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat.label, style: t.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(entry.summary, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.colors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// 분류 상세를 바텀시트로 연다.
Future<void> showGuideDetailSheet(BuildContext context, GuideEntry entry) {
  final cat = entry.category;
  return showAppSheet(
    context,
    builder: (ctx, controller) {
      final t = ctx.text;
      final c = ctx.colors;
      return ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
        children: [
          Row(children: [CategoryBadge.of(cat, large: true)]),
          const SizedBox(height: AppSpacing.md),
          Text(entry.summary, style: t.headlineSmall),
          const SizedBox(height: AppSpacing.xl),
          Text('버리는 방법', style: t.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          for (var i = 0; i < entry.howTo.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StepNumber(index: i + 1),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Padding(padding: const EdgeInsets.only(top: 2), child: Text(entry.howTo[i], style: t.bodyMedium))),
                ],
              ),
            ),
            if (i != entry.howTo.length - 1) const Divider(),
          ],
          const SizedBox(height: AppSpacing.xl),
          _ListSection(title: '이런 건 돼요', icon: Icons.check_rounded, iconColor: c.primary, items: entry.allowed),
          const SizedBox(height: AppSpacing.xl),
          _ListSection(title: '이런 건 안 돼요', icon: Icons.close_rounded, iconColor: c.error, items: entry.notAllowed),
        ],
      );
    },
  );
}

class _ListSection extends StatelessWidget {
  const _ListSection({required this.title, required this.icon, required this.iconColor, required this.items});

  final String title;
  final IconData icon;
  final Color iconColor;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final t = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: t.titleMedium),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.xs),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, size: 18, color: iconColor),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(items[i], style: t.bodyMedium)),
                    ],
                  ),
                ),
                if (i != items.length - 1) const Divider(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
