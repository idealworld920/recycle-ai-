import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../app_services.dart';
import '../core/theme/app_sheet.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';
import '../widgets/app_card.dart';

/// 설정 바텀시트. AI 연결 상태와 앱 정보.
Future<void> showSettingsSheet(BuildContext context) {
  final session = AppServices.of(context).firebase;
  return showAppSheet(
    context,
    title: '설정',
    initialSize: 0.55,
    builder: (ctx, controller) => ListenableBuilder(
      listenable: session,
      builder: (ctx, _) {
        final c = ctx.colors;
        final t = ctx.text;
        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
          children: [
            Text('AI 연결', style: t.titleSmall),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Row(
                children: [
                  Icon(
                    session.ready ? Symbols.check_circle_rounded : Symbols.cloud_off_rounded,
                    color: session.ready ? c.primary : c.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(session.ready ? '연결됨' : (session.busy ? '연결하는 중' : '연결 안 됨'), style: t.titleSmall),
                        if (session.ready && session.uid != null)
                          Text('익명 ID ${session.uid!.substring(0, 6)}…', style: t.bodySmall)
                        else if (session.error != null)
                          Text(session.error!, style: t.bodySmall),
                      ],
                    ),
                  ),
                  if (!session.ready && !session.busy) TextButton(onPressed: session.init, child: const Text('다시 연결')),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('API 키는 앱에 저장되지 않아요. Firebase 가 대신 AI 를 호출해요.', style: t.bodySmall),
            const SizedBox(height: AppSpacing.xxl),
            Text('앱 정보', style: t.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'ReSAI(리사이) 0.1.0\n'
              '사진 한 장으로 올바른 분리배출 방법을 알려주는 앱이에요.\n'
              '판별 결과는 참고용이며, 최종 기준은 거주 지역 지자체 안내를 따라 주세요.',
              style: t.bodyMedium?.copyWith(color: c.textSecondary),
            ),
          ],
        );
      },
    ),
  );
}
