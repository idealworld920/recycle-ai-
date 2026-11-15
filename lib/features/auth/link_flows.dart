import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_services.dart';
import '../../core/theme/app_sheet.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import 'auth_errors.dart';
import 'auth_service.dart';

/// Google 연결 공통 흐름. 성공하면 true. 모든 결과를 사용자에게 보이게 처리한다.
///
/// - 성공: 스낵바 "Google 계정이 연결됐어요"
/// - 이미 다른 기록에 묶인 계정: "그 계정으로 로그인할까요?" 시트 → 로그인하면 익명 계정 삭제 후 전환
/// - 이미 연결됨: 스낵바 "이미 연결돼 있어요"
/// - 계정 선택 취소: 조용히 false
/// - 실패: 코드별 스낵바 (네트워크 / 설정 오류 / 기타)
Future<bool> connectGoogle(BuildContext context) async {
  final services = AppServices.of(context);
  final auth = services.auth;
  debugPrint('[auth] 연결 시도 (현재 uid=${auth.uid}, 익명=${auth.isAnonymous})');
  final outcome = await auth.linkGoogle();
  if (!context.mounted) return false;
  switch (outcome) {
    case LinkSuccess():
      debugPrint('[auth] 연결 성공');
      showAuthToast(context, '구글 계정이 연결됐어요');
      return true;
    case LinkAlreadyLinked():
      showAuthToast(context, AuthErrors.alreadyLinked);
      return false;
    case LinkCancelled():
      debugPrint('[auth] 연결 취소');
      return false;
    case LinkFailed(:final error):
      debugPrint('[auth] 연결 실패 ${AuthErrors.code(error)}');
      showAuthToast(context, AuthErrors.message(error));
      return false;
    case LinkAlreadyInUse(:final credential, :final email):
      debugPrint('[auth] 이미 가입된 Google 계정 ($email) → 전환 여부 확인');
      final login = await askSwitchToExisting(context, count: services.history.items.length);
      if (!login || !context.mounted) return false;
      // 지금 기기의 익명 데이터는 버리고 기존 계정으로. RevenueCat 은 새 uid 로 attachAll 에서 다시 logIn 된다.
      await services.leaveAccountLocally();
      final r = await auth.switchToExisting(credential);
      if (!context.mounted) return false;
      if (r is LinkSuccess) {
        debugPrint('[auth] 기존 계정 전환 성공');
        showAuthToast(context, '기존 계정으로 로그인했어요');
        Navigator.of(context).popUntil((route) => route.isFirst); // 홈 새로고침
        return true;
      }
      if (r is LinkFailed) {
        debugPrint('[auth] 기존 계정 전환 실패 ${AuthErrors.code(r.error)}');
        showAuthToast(context, AuthErrors.message(r.error));
      }
      return false;
  }
}

/// "이 Google 계정으로 가입된 기록이 이미 있어요" 시트. 로그인을 고르면 true.
Future<bool> askSwitchToExisting(BuildContext context, {required int count}) async {
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
            Text('이 Google 계정으로 가입된 기록이 이미 있어요. 그 계정으로 로그인할까요?', style: t.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text('지금 기기의 기록 $count개는 사라져요.', style: t.bodyMedium?.copyWith(color: c.textSecondary)),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소'))),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: c.ink, foregroundColor: c.onInk),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('로그인'),
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

/// 로그아웃 흐름: 확인 시트 → Firebase signOut → RevenueCat logOut → 기기 캐시 초기화 → 새 익명 → 홈.
Future<bool> signOutFlow(BuildContext context) async {
  final services = AppServices.of(context);
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
            Text('로그아웃할까요?', style: t.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text('기록은 계정에 안전하게 보관돼요. 다시 로그인하면 그대로 볼 수 있어요.', style: t.bodyMedium?.copyWith(color: c.textSecondary)),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소'))),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: c.ink, foregroundColor: c.onInk),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('로그아웃'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
  if (ok != true || !context.mounted) return false;
  final rootMessenger = ScaffoldMessenger.of(context);
  final nav = Navigator.of(context);
  try {
    debugPrint('[auth] 로그아웃 흐름 시작');
    await services.leaveAccountLocally(); // RevenueCat logOut + 기기 캐시
    await services.auth.signOutToAnonymous(); // signOut → 새 익명 (attachAll 이 새 uid 로 RevenueCat logIn)
    debugPrint('[auth] 로그아웃 완료');
    nav.popUntil((r) => r.isFirst);
    rootMessenger.showSnackBar(const SnackBar(content: Text('로그아웃했어요')));
    return true;
  } catch (e) {
    debugPrint('[auth] 로그아웃 실패 ${AuthErrors.code(e)}');
    if (context.mounted) showAuthToast(context, AuthErrors.message(e));
    return false;
  }
}

void showAuthToast(BuildContext context, String message) {
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
          label: const Text('Google 계정으로 연결하기'),
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
      title: '가족 공유는 Google 연결이 필요해요',
      body: '가족이 같은 집을 보려면 계정이 기기에 묶이지 않아야 해요. 연결해 두면 기기를 바꿔도 그대로예요.',
      required: true,
    );

/// 구독 결제 직전: 권장이지만 필수는 아님.
Future<bool> recommendLinkBeforePurchase(BuildContext context) => showLinkSheet(
      context,
      title: '복원을 위해 연결을 권장해요',
      body: 'Google 계정으로 연결해 두면 기기를 바꾸거나 앱을 다시 설치해도 구독과 기록을 복원할 수 있어요. 지금 건너뛰어도 결제는 돼요.',
    );

/// 잠긴 영역을 눌렀을 때.
Future<bool> showLockedSheet(BuildContext context, {required String what}) => showLinkSheet(
      context,
      title: '$what은 Google 연결 후 볼 수 있어요',
      body: '데이터는 전부 저장되고 있어요. 연결하면 바로 열리고, 기기를 바꿔도 기록이 지켜져요.',
    );
