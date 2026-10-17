import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_services.dart';
import '../../core/theme/app_sheet.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import 'auth_errors.dart';
import 'auth_service.dart';

/// 구글 연결 공통 흐름. 성공하면 true.
///
/// - 성공: 토스트 "기록이 모두 열렸어요"
/// - 이미 다른 기록에 묶인 계정: 불러오기 / 취소 시트
/// - 취소: 조용히 false
/// - 실패: 사용자 문구 스낵바
Future<bool> connectGoogle(BuildContext context) async {
  final services = AppServices.of(context);
  final auth = services.auth;
  final outcome = await auth.linkGoogle();
  if (!context.mounted) return false;
  switch (outcome) {
    case LinkSuccess():
      _toast(context, '기록이 모두 열렸어요');
      return true;
    case LinkCancelled():
      return false;
    case LinkFailed(:final error):
      _toast(context, AuthErrors.message(error));
      return false;
    case LinkAlreadyInUse(:final credential, :final email):
      final load = await _askLoadExisting(context, email);
      if (load != true || !context.mounted) return false;
      // 현재 익명 데이터는 버리고 기존 계정으로 전환.
      await services.resetLocalData();
      final r = await auth.switchToExisting(credential);
      if (!context.mounted) return false;
      if (r is LinkSuccess) {
        _toast(context, '기존 기록을 불러왔어요');
        return true;
      }
      if (r is LinkFailed) _toast(context, AuthErrors.message(r.error));
      return false;
  }
}

Future<bool?> _askLoadExisting(BuildContext context, String? email) {
  return showAppSheet<bool>(
    context,
    initialSize: 0.42,
    builder: (ctx, controller) => ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
      children: [
        Text('이 구글 계정에 기존 ReSAI 기록이 있어요. 불러올까요?', style: ctx.text.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${email ?? '이 계정'}으로 쓰던 기록으로 바꿔요. 지금 기기에 익명으로 쌓인 기록은 사라져요.',
          style: ctx.text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('불러오기')),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소 (익명으로 계속)')),
      ],
    ),
  );
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// 연결을 권하는 시트. [required] 면 "필수" 문구.
Future<bool> showLinkSheet(
  BuildContext context, {
  required String title,
  required String body,
  bool required = false,
}) async {
  final linked = await showAppSheet<bool>(
    context,
    initialSize: 0.42,
    builder: (ctx, controller) => ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
      children: [
        Icon(Symbols.cloud_done_rounded, size: 32, color: ctx.colors.primary),
        const SizedBox(height: AppSpacing.md),
        Text(title, style: ctx.text.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(body, style: ctx.text.bodySmall),
        const SizedBox(height: AppSpacing.xl),
        FilledButton.icon(
          onPressed: () async {
            final ok = await connectGoogle(ctx);
            if (ctx.mounted) Navigator.pop(ctx, ok);
          },
          icon: const Icon(Symbols.login_rounded, size: 20),
          label: const Text('구글로 연결'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(required ? '다음에 할게요' : '괜찮아요, 익명으로 계속')),
      ],
    ),
  );
  return linked == true;
}

/// 가족 공유 집 만들기·참여 전: 연결 필수.
Future<bool> requireLinkForFamily(BuildContext context) => showLinkSheet(
      context,
      title: '가족 공유는 구글 연결이 필요해요',
      body: '가족이 같은 집을 보려면 계정이 기기에 묶이지 않아야 해요. 연결해 두면 기기를 바꿔도 그대로예요.',
      required: true,
    );

/// 구독 결제 직전: 권장이지만 필수는 아님.
Future<bool> recommendLinkBeforePurchase(BuildContext context) => showLinkSheet(
      context,
      title: '복원을 위해 연결을 권장해요',
      body: '구글로 연결해 두면 기기를 바꾸거나 앱을 다시 설치해도 구독과 기록을 복원할 수 있어요. 지금 건너뛰어도 결제는 돼요.',
    );

/// 잠긴 영역을 눌렀을 때.
Future<bool> showLockedSheet(BuildContext context, {required String what}) => showLinkSheet(
      context,
      title: '$what은 구글 연결 후 볼 수 있어요',
      body: '데이터는 전부 저장되고 있어요. 연결하면 바로 열리고, 기기를 바꿔도 기록이 지켜져요.',
    );
