import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_services.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_errors.dart';
import '../auth/link_flows.dart';

/// 온보딩 4페이지: 계정 선택. [Google로 시작하기] 또는 "나중에 할게요"(익명으로 진행). 리뿅이 없음, 표준 존댓말.
class AccountPage extends StatefulWidget {
  const AccountPage({super.key, required this.onDone});

  /// 연결 성공 또는 "나중에" 를 고르면 호출.
  final VoidCallback onDone;

  static const googleLabel = 'Google로 시작하기';
  static const laterLabel = '나중에 할게요';

  /// 익명 로그인이 아직이면 이만큼만 기다린다.
  static const firebaseWait = Duration(seconds: 6);

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _busy = false;

  Future<void> _google() async {
    if (_busy) return;
    setState(() => _busy = true);
    final services = AppServices.of(context);
    try {
      // 익명 로그인이 끝나야 연결(link)할 수 있다. 백그라운드 초기화를 잠깐 기다린다.
      if (!services.firebase.ready) {
        debugPrint('[auth] 온보딩: Firebase 대기');
        await services.firebase.settled.timeout(AccountPage.firebaseWait, onTimeout: () {});
      }
      if (!mounted) return;
      if (!services.firebase.ready) {
        showAuthToast(context, AuthErrors.network);
        return;
      }
      final ok = await connectGoogle(context);
      if (ok && mounted) widget.onDone();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 1),
          Icon(Symbols.cloud_done_rounded, size: 48, color: c.primary),
          const SizedBox(height: AppSpacing.lg),
          Text('기록을 계정에 보관할까요?', style: t.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Google 계정으로 시작하면 기기를 바꾸거나 앱을 다시 설치해도 기록과 프리미엄을 이어서 볼 수 있어요. 나중에 설정에서도 연결할 수 있어요.',
            style: t.bodyMedium?.copyWith(color: c.textSecondary),
          ),
          const Spacer(flex: 2),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56), backgroundColor: c.ink, foregroundColor: c.onInk),
            onPressed: _busy ? null : _google,
            icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Symbols.login_rounded, size: 20),
            label: Text(_busy ? '연결하는 중…' : AccountPage.googleLabel),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: c.textSecondary, minimumSize: const Size.fromHeight(44)),
            onPressed: _busy ? null : widget.onDone,
            child: const Text(AccountPage.laterLabel),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
