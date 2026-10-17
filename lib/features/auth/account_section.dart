import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_services.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_card.dart';
import 'auth_errors.dart';
import 'link_flows.dart';

/// 설정 상단 프로필 영역. 미연결: 구글로 연결하기 / 연결됨: 이메일 + 로그아웃 + 계정 삭제.
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Symbols.account_circle_rounded, size: 28, color: c.textSecondary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: Text('익명으로 쓰는 중', style: t.titleSmall)),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('기록 백업 · 기기 간 동기화', style: t.bodySmall),
                const SizedBox(height: AppSpacing.base),
                FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  onPressed: auth.busy ? null : () => connectGoogle(context),
                  icon: const Icon(Symbols.login_rounded, size: 20),
                  label: Text(auth.busy ? '연결하는 중…' : '구글로 연결하기'),
                ),
              ],
            ),
          );
        }
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Symbols.account_circle_rounded, size: 28, color: c.primary, fill: 1),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(auth.email ?? '구글 계정', style: t.titleSmall),
                        Text('연결됨 · 기기를 바꿔도 기록이 유지돼요', style: t.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: c.textSecondary),
                    onPressed: auth.busy ? null : () => _signOut(context),
                    child: const Text('로그아웃'),
                  ),
                  const Spacer(),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: c.error),
                    onPressed: auth.busy ? null : () => _deleteAccount(context),
                    child: const Text('계정 삭제'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final services = AppServices.of(context);
    final ok = await _confirm(context, '로그아웃할까요?', '이 기기는 새 익명 계정으로 시작해요. 구글 기록은 다시 연결하면 돌아와요.', '로그아웃');
    if (ok != true || !context.mounted) return;
    try {
      await services.resetLocalData();
      await services.auth.signOutToAnonymous();
      if (!context.mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그아웃했어요. 익명으로 다시 시작해요.')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AuthErrors.message(e))));
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final services = AppServices.of(context);
    final ok = await _confirm(
      context,
      '계정을 삭제할까요?',
      '기록·도감·수거일 설정·퀴즈 결과가 서버와 기기에서 모두 지워지고 되돌릴 수 없어요. 보안을 위해 구글 재로그인을 요청할 수 있어요.',
      '삭제',
      destructive: true,
    );
    if (ok != true || !context.mounted) return;
    try {
      await services.auth.deleteAccount();
      await services.resetLocalData();
      if (!context.mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('계정을 삭제했어요. 익명으로 다시 시작해요.')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AuthErrors.message(e))));
    }
  }

  Future<bool?> _confirm(BuildContext context, String title, String body, String action, {bool destructive = false}) {
    final c = context.colors;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: c.textSecondary),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: destructive ? c.error : c.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );
  }
}
