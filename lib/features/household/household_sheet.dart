import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:share_plus/share_plus.dart';

import '../../app_services.dart';
import '../../core/theme/app_sheet.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../auth/link_flows.dart';
import '../premium/premium_gate.dart';
import 'household_repository.dart';

/// 설정 → 가족 공유.
Future<void> showHouseholdSheet(BuildContext context) {
  return showAppSheet(
    context,
    title: '가족 공유',
    initialSize: 0.7,
    builder: (ctx, controller) => _HouseholdBody(controller: controller),
  );
}

class _HouseholdBody extends StatelessWidget {
  const _HouseholdBody({required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final services = AppServices.of(context);
    final store = services.household;
    final t = context.text;
    final c = context.colors;
    return ListenableBuilder(
      listenable: Listenable.merge([store, services.auth, services.premium]),
      builder: (context, _) {
        final h = store.household;
        if (h == null) {
          return ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
            children: [
              Text('가족·룸메와 수거일을 같이 봐요. 한 명이 바꾸면 모두에게 반영되고, 누가 버렸는지도 보여요.', style: t.bodyMedium),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: store.busy ? null : () => _create(context),
                icon: const Icon(Symbols.add_home_rounded, size: 20),
                label: const Text('집 만들기'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: store.busy ? null : () => _join(context),
                icon: const Icon(Symbols.pin_rounded, size: 20),
                label: const Text('초대 코드로 참여'),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('집 만들기는 프리미엄, 참여는 구글 연결만 있으면 돼요.', style: t.bodySmall),
            ],
          );
        }
        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
          children: [
            AppCard(
              soft: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('초대 코드', style: t.bodySmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(h.code, style: t.headlineSmall?.copyWith(fontSize: 32, letterSpacing: 4)),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    onPressed: () => SharePlus.instance.share(
                      ShareParams(text: 'ReSAI 우리 집 초대 코드: ${h.code}\n앱 설정 → 가족 공유 → 초대 코드로 참여에 입력하면 수거일을 같이 볼 수 있어요.'),
                    ),
                    icon: const Icon(Symbols.share_rounded, size: 20),
                    label: const Text('카카오톡·문자로 공유'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('멤버 ${store.members.length}명', style: t.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            for (final m in store.members)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Icon(Symbols.account_circle_rounded, size: 22, color: m.uid == h.ownerUid ? c.primary : c.textSecondary, fill: 1),
                    const SizedBox(width: AppSpacing.sm),
                    Text(m.nickname.isEmpty ? '이름 없음' : m.nickname, style: t.bodyMedium),
                    if (m.uid == store.me?.uid) ...[const SizedBox(width: AppSpacing.xs), Text('(나)', style: t.bodySmall)],
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: c.textSecondary),
              onPressed: store.busy ? null : () => _leave(context),
              child: const Text('집 나가기'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _create(BuildContext context) async {
    final services = AppServices.of(context);
    if (services.auth.isAnonymous) {
      if (!await requireLinkForFamily(context)) return;
    }
    if (!context.mounted) return;
    if (!await ensurePremium(context, reason: '가족 공유는 프리미엄 기능이에요')) return;
    if (!context.mounted) return;
    final nickname = await _askNickname(context);
    if (nickname == null || !context.mounted) return;
    try {
      await services.household.create(nickname);
    } on HouseholdException catch (e) {
      if (context.mounted) _toast(context, e.message);
    } catch (e) {
      if (context.mounted) _toast(context, '집을 만들지 못했어요. 잠시 후 다시 시도해 주세요.');
    }
  }

  Future<void> _join(BuildContext context) async {
    final services = AppServices.of(context);
    if (services.auth.isAnonymous) {
      if (!await requireLinkForFamily(context)) return;
    }
    if (!context.mounted) return;
    final input = await _askJoin(context);
    if (input == null || !context.mounted) return;
    try {
      await services.household.join(input.$1, input.$2);
      if (context.mounted) _toast(context, '참여했어요. 수거일이 집 설정으로 바뀌어요.');
    } on HouseholdException catch (e) {
      if (context.mounted) _toast(context, e.message);
    } catch (e) {
      if (context.mounted) _toast(context, '참여하지 못했어요. 인터넷 연결을 확인해 주세요.');
    }
  }

  Future<void> _leave(BuildContext context) async {
    final c = context.colors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('집을 나갈까요?'),
        content: const Text('내 수거일 설정은 나가기 전 집 설정을 그대로 가져가요. 다시 참여하려면 초대 코드가 필요해요.'),
        actions: [
          TextButton(style: TextButton.styleFrom(foregroundColor: c.textSecondary), onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(style: TextButton.styleFrom(foregroundColor: c.error), onPressed: () => Navigator.pop(ctx, true), child: const Text('나가기')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await AppServices.of(context).household.leave();
  }

  void _toast(BuildContext context, String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<String?> _askNickname(BuildContext context) async {
    final ctrl = TextEditingController();
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('집에서 부를 이름'),
        content: TextField(controller: ctrl, autofocus: true, maxLength: 10, decoration: const InputDecoration(hintText: '예: 엄마, 민수')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('확인')),
        ],
      ),
    );
    return (v == null || v.isEmpty) ? null : v;
  }

  Future<(String, String)?> _askJoin(BuildContext context) async {
    final code = TextEditingController();
    final nick = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('초대 코드로 참여'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: code, autofocus: true, keyboardType: TextInputType.number, maxLength: 6, decoration: const InputDecoration(hintText: '6자리 코드')),
            const SizedBox(height: AppSpacing.sm),
            TextField(controller: nick, maxLength: 10, decoration: const InputDecoration(hintText: '집에서 부를 이름')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('참여')),
        ],
      ),
    );
    if (ok != true || code.text.trim().length != 6 || nick.text.trim().isEmpty) return null;
    return (code.text.trim(), nick.text.trim());
  }
}
