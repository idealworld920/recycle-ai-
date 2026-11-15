import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_services.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_card.dart';
import 'link_flows.dart';

/// 설정 → 계정. 익명: [Google 계정으로 연결하기] / 연결됨: 이메일 + [로그아웃]. 리뿅이 없음, 표준 존댓말.
class AccountSection extends StatelessWidget {
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AppServices.of(context).auth;
    final t = context.text;
    final c = context.colors;
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        if (auth.isAnonymous) {
          return AppCard(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  onPressed: auth.busy ? null : () => connectGoogle(context),
                  icon: const Icon(Symbols.login_rounded, size: 20),
                  label: Text(auth.busy ? '연결하는 중…' : 'Google 계정으로 연결하기'),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('기기를 바꿔도 기록을 이어서 볼 수 있어요', style: t.bodySmall, textAlign: TextAlign.center),
              ],
            ),
          );
        }
        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Row(
            children: [
              Icon(Symbols.account_circle_rounded, size: 28, color: c.primary, fill: 1),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(auth.email ?? 'Google 계정', style: t.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('Google 계정으로 연결됨', style: t.bodySmall),
                  ],
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: c.textSecondary),
                onPressed: auth.busy ? null : () => signOutFlow(context),
                child: const Text('로그아웃'),
              ),
            ],
          ),
        );
      },
    );
  }
}
