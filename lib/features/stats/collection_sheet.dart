import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_services.dart';
import '../../core/theme/app_sheet.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../models/waste_group.dart';
import '../../widgets/app_card.dart';
import '../tips/tip_model.dart';
import 'collection_store.dart';

IconData iconForGroup(WasteGroup g) => switch (g) {
      WasteGroup.recycle => Symbols.recycling_rounded,
      WasteGroup.general => Symbols.delete_rounded,
      WasteGroup.food => Symbols.restaurant_rounded,
      WasteGroup.special => Symbols.warning_rounded,
    };

/// 기록 탭 하단 "도감 23/55" 카드.
class CollectionCard extends StatelessWidget {
  const CollectionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppServices.of(context).collection;
    final t = context.text;
    final c = context.colors;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => AppCard(
        onTap: () => showCollectionSheet(context),
        child: Row(
          children: [
            Icon(Symbols.grid_view_rounded, size: 24, color: c.textPrimary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('도감 ${store.collected}/${store.total}', style: t.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text('처음 분류한 품목이 여기에 모여요', style: t.bodySmall),
                ],
              ),
            ),
            Icon(Symbols.chevron_right_rounded, color: c.textSecondary),
          ],
        ),
      ),
    );
  }
}

Future<void> showCollectionSheet(BuildContext context) {
  final services = AppServices.of(context);
  final CollectionStore store = services.collection;
  final List<Tip> tips = services.tips.all;
  return showAppSheet(
    context,
    title: '도감 ${store.collected}/${store.total}',
    initialSize: 0.9,
    builder: (ctx, controller) => GridView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.82,
      ),
      itemCount: tips.length,
      itemBuilder: (ctx, i) => _Tile(tip: tips[i], collected: store.has(tips[i])),
    ),
  );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.tip, required this.collected});

  final Tip tip;
  final bool collected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            iconForGroup(tip.category.group),
            size: 28,
            color: collected ? c.groupColor(tip.category.group) : c.textDisabled,
            fill: collected ? 1 : 0,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            collected ? tip.name : '???',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: t.bodySmall?.copyWith(fontSize: 12, color: collected ? c.textPrimary : c.textDisabled),
          ),
        ],
      ),
    );
  }
}
