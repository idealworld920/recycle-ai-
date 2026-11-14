import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../tips/tips_repository.dart';
import 'history_record.dart';
import '../stats/collection_store.dart';

/// 기록 삭제 한 곳: 확인 시트 → 기록 삭제 → 도감 재계산 → 스낵바.
/// 설정·삭제류 화면 규칙: 리뿅이 없음, 표준 존댓말.
class RecordDeleter {
  RecordDeleter._();

  /// "기록 N개를 삭제할까요?" 바텀시트. 삭제를 고르면 true.
  static Future<bool> confirm(BuildContext context, int count) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      builder: (ctx) {
        final c = ctx.colors;
        final t = ctx.text;
        return Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('기록 $count개를 삭제할까요?', style: t.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text('삭제한 기록은 복구할 수 없어요. 이 기록으로만 등록된 도감 친구도 함께 사라져요.', style: t.bodyMedium?.copyWith(color: c.textSecondary)),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: c.error, foregroundColor: c.onInk),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('삭제'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    return ok == true;
  }

  /// 기록을 지우고 도감을 맞춘다. 지운 개수를 돌려준다.
  static Future<int> delete(AppServices services, Iterable<String> ids) async {
    final removed = await services.history.removeMany(ids);
    if (removed.isEmpty) return 0;
    await reconcileCollection(services.collection, services.tips, removed: removed, remaining: services.history.items);
    return removed.length;
  }

  /// 지운 기록이 가리키던 도감 품목 중, 남은 기록 어디에도 없는 것만 도감에서 뺀다 (기록 수 기준 재계산).
  static Future<Set<String>> reconcileCollection(
    CollectionStore collection,
    TipsRepository tips, {
    required List<HistoryRecord> removed,
    required List<HistoryRecord> remaining,
  }) async {
    final candidates = <String>{};
    for (final r in removed) {
      final tip = tips.findForItem(r.itemName);
      if (tip != null) candidates.add(tip.id);
    }
    if (candidates.isEmpty) return const {};
    final still = <String>{};
    for (final r in remaining) {
      final tip = tips.findForItem(r.itemName);
      if (tip != null && candidates.contains(tip.id)) {
        still.add(tip.id);
        if (still.length == candidates.length) break;
      }
    }
    return collection.prune(candidates, stillCollected: still);
  }

  /// 확인 → 삭제 → 스낵바까지. 지웠으면 true.
  static Future<bool> confirmAndDelete(BuildContext context, Iterable<String> ids) async {
    final list = ids.toList();
    if (list.isEmpty) return false;
    final ok = await confirm(context, list.length);
    if (!ok || !context.mounted) return false;
    final services = AppServices.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final n = await delete(services, list);
    messenger.showSnackBar(SnackBar(content: Text('기록 $n개를 삭제했어요')));
    return n > 0;
  }
}
