import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_services.dart';
import '../../core/mascot.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../legal/legal_links.dart';
import '../legal/legal_webview_screen.dart';

/// 온보딩 3페이지: 동의. 필수 2개(약관·개인정보) + 선택 1개(알림).
///
/// [시작하기] 를 누르면 기기에 저장하고 `users/{uid}.consent` 를 올린다.
/// 익명 로그인이 아직이면 보류해 두고, 로그인이 끝난 뒤 main 이 올린다. 알림 권한은 여기서 묻지 않는다.
class ConsentController extends ChangeNotifier {
  bool terms = false;
  bool privacy = false;
  bool marketing = false;
  bool saving = false;

  bool get all => terms && privacy && marketing;

  /// 필수 2개가 체크됐는가 → [시작하기] 활성 조건.
  bool get requiredOk => terms && privacy;
  bool get canStart => requiredOk && !saving;

  void set({bool? terms, bool? privacy, bool? marketing}) {
    this.terms = terms ?? this.terms;
    this.privacy = privacy ?? this.privacy;
    this.marketing = marketing ?? this.marketing;
    notifyListeners();
  }

  void toggleAll() {
    final v = !all;
    set(terms: v, privacy: v, marketing: v);
  }

  /// 기기에 저장 → (로그인돼 있으면) users/{uid}.consent → onboardingDone.
  Future<void> submit(AppServices services) async {
    if (!canStart) return;
    saving = true;
    notifyListeners();
    final settings = services.settings;
    await settings.saveConsent(terms: true, privacy: true, marketing: marketing, version: LegalLinks.version);
    // 익명 로그인이 끝났으면 바로 기록, 아니면 보류(main 의 attachAll 이 올린다).
    if (services.auth.uid != null) {
      try {
        await services.auth.service.mergeUserDoc({'consent': settings.consentDoc});
        await settings.markConsentSynced();
      } catch (_) {
        // 보류 상태로 남겨 두면 다음 기회에 올린다.
      }
    }
    await settings.setOnboarded(true);
    saving = false;
    notifyListeners();
  }
}

class ConsentPage extends StatelessWidget {
  const ConsentPage({super.key, required this.controller});

  final ConsentController controller;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final c = context.colors;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final ctl = controller;
        return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.base, AppSpacing.xl, AppSpacing.xl),
            children: [
              const MascotImage(Mascot.idle, size: 64),
              const SizedBox(height: AppSpacing.base),
              Text('시작하기 전에', style: t.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text('아래 항목을 확인해 주세요. 선택 항목은 동의하지 않아도 모든 기능을 쓸 수 있어요.', style: t.bodyMedium?.copyWith(color: c.textSecondary)),
              const SizedBox(height: AppSpacing.xl),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.xs),
                child: Column(
                  children: [
                    _ConsentRow(label: '모두 동의', value: ctl.all, onChanged: (_) => ctl.toggleAll(), bold: true),
                    const Divider(),
                    _ConsentRow(
                      label: '[필수] 이용약관 동의',
                      value: ctl.terms,
                      onChanged: (v) => ctl.set(terms: v),
                      onView: () => LegalWebViewScreen.open(context, title: '이용약관', url: LegalLinks.terms),
                    ),
                    _ConsentRow(
                      label: '[필수] 개인정보처리방침 동의',
                      value: ctl.privacy,
                      onChanged: (v) => ctl.set(privacy: v),
                      onView: () => LegalWebViewScreen.open(context, title: '개인정보처리방침', url: LegalLinks.privacy),
                    ),
                    _ConsentRow(
                      label: '[선택] 수거일·리포트 알림 받기',
                      value: ctl.marketing,
                      onChanged: (v) => ctl.set(marketing: v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('알림 권한은 수거일을 설정할 때 따로 물어봐요.', style: t.bodySmall),
            ],
          );
      },
    );
  }
}

class _ConsentRow extends StatelessWidget {
  const _ConsentRow({required this.label, required this.value, required this.onChanged, this.onView, this.bold = false});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onView;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final c = context.colors;
    return Semantics(
      checked: value,
      label: label,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Icon(
                value ? Symbols.check_box_rounded : Symbols.check_box_outline_blank_rounded,
                size: 24,
                color: value ? c.primary : c.textDisabled,
                fill: value ? 1 : 0,
              ),
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
      ),
    );
  }
}
