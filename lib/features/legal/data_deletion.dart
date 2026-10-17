import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_services.dart';
import '../../core/theme/app_sheet.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_errors.dart';

/// 설정 → 내 데이터 삭제. 서버 users/{uid} 하위 전부 + 기기 초기화 + 익명 계정 삭제 → 온보딩으로.
Future<void> showDeleteDataSheet(BuildContext context) {
  return showAppSheet(
    context,
    title: '내 데이터 삭제',
    initialSize: 0.5,
    builder: (ctx, controller) {
      final t = ctx.text;
      final c = ctx.colors;
      return ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
        children: [
          Icon(Symbols.delete_forever_rounded, size: 32, color: c.error),
          const SizedBox(height: AppSpacing.md),
          Text('정말 모두 지울까요?', style: t.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text('서버와 이 기기에서 다음이 즉시, 영구히 삭제돼요.', style: t.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final line in const ['분류 기록과 썸네일', '수거일 설정과 체크 기록', '도감, 질문 사용량', '계정(구글 연결 포함)과 동의 기록'])
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text('•  $line', style: t.bodySmall),
            ),
          const SizedBox(height: AppSpacing.md),
          Text('구독은 Google Play 에서 따로 해지해야 해요. 가족 공유 집은 자동으로 나가져요.', style: t.bodySmall),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: c.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await runDataDeletion(context);
            },
            child: const Text('전부 삭제'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
        ],
      );
    },
  );
}

Future<void> runDataDeletion(BuildContext context) async {
  final services = AppServices.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    if (services.household.active) await services.household.leave();
    await services.auth.deleteAccount(); // 서버 데이터 삭제 + 계정 삭제 + 새 익명 계정
    await services.resetLocalData();
    await services.settings.resetAll(); // 온보딩·동의·안내 플래그 초기화
    if (!context.mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    messenger.showSnackBar(const SnackBar(content: Text('데이터를 모두 삭제했어요.')));
    services.settings.notifyReset();
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(AuthErrors.message(e))));
  }
}
