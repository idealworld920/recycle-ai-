import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_services.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../legal/legal_links.dart';
import '../legal/legal_webview_screen.dart';

/// 온보딩 마지막 동의 화면. 필수 2개 + 선택 1개.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _terms = false;
  bool _privacy = false;
  bool _notify = false;
  bool _saving = false;

  bool get _all => _terms && _privacy && _notify;
  bool get _requiredOk => _terms && _privacy;

  void _toggleAll(bool v) => setState(() {
        _terms = v;
        _privacy = v;
        _notify = v;
      });

  Future<void> _done() async {
    final services = AppServices.of(context);
    setState(() => _saving = true);
    await services.settings.saveConsent(terms: true, privacy: true, notifications: _notify, version: LegalLinks.version);
    await services.settings.setQuizReminder(_notify);
    await services.settings.setOnboarded(true);
    final now = DateTime.now().toIso8601String();
    await services.auth.service.mergeUserDoc({
      'consent': {
        'terms': now,
        'privacy': now,
        'notifications': _notify,
        'version': LegalLinks.version,
      },
    });
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xxl, AppSpacing.lg, AppSpacing.xl),
                children: [
                  Text('시작하기 전에\n확인해 주세요', style: t.headlineSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Text('ReSAI 는 로그인 없이 쓸 수 있고, 사진은 저장하지 않아요.', style: t.bodySmall),
                  const SizedBox(height: AppSpacing.xl),
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.xs),
                    child: Column(
                      children: [
                        _Row(
                          label: '모두 동의',
                          value: _all,
                          onChanged: _toggleAll,
                          bold: true,
                        ),
                        const Divider(),
                        _Row(
                          label: '[필수] 이용약관',
                          value: _terms,
                          onChanged: (v) => setState(() => _terms = v),
                          onView: () => LegalWebViewScreen.open(context, title: '이용약관', url: LegalLinks.terms),
                        ),
                        _Row(
                          label: '[필수] 개인정보처리방침',
                          value: _privacy,
                          onChanged: (v) => setState(() => _privacy = v),
                          onView: () => LegalWebViewScreen.open(context, title: '개인정보처리방침', url: LegalLinks.privacy),
                        ),
                        _Row(
                          label: '[선택] 퀴즈·안내 알림 받기',
                          value: _notify,
                          onChanged: (v) => setState(() => _notify = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('선택 항목은 동의하지 않아도 모든 기능을 쓸 수 있어요. 수거일 알림은 수거일을 설정할 때 따로 물어봐요.',
                      style: t.bodySmall?.copyWith(color: c.textSecondary)),
                ],
              ),
            ),
            SafeArea(
              minimum: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.base),
              child: FilledButton(
                onPressed: _requiredOk && !_saving ? _done : null,
                child: Text(_saving ? '저장하는 중…' : '동의하고 시작'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, required this.onChanged, this.onView, this.bold = false});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onView;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final c = context.colors;
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(value ? Symbols.check_circle_rounded : Symbols.circle_rounded, size: 24, color: value ? c.primary : c.textDisabled, fill: value ? 1 : 0),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(label, style: bold ? t.titleSmall : t.bodyMedium)),
            if (onView != null)
              TextButton(
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm), minimumSize: const Size(0, 36)),
                onPressed: onView,
                child: const Text('보기'),
              ),
          ],
        ),
      ),
    );
  }
}
