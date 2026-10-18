import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../app_services.dart';
import 'boot_report.dart';
import 'firebase_session.dart';
import 'theme/app_spacing.dart';
import 'theme/app_theme.dart';

/// 홈 상단의 작은 배너. 시작 단계에서 실패한 게 있으면 이유를 한 줄로 보여준다.
class BootBanner extends StatelessWidget {
  const BootBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppServices.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([services.boot, services.firebase]),
      builder: (context, _) {
        final lines = _lines(services.boot, services.firebase);
        if (lines.isEmpty || services.boot.dismissed || services.boot.silent) return const SizedBox.shrink();
        final c = context.colors;
        final t = context.text;
        final canRetry = !services.firebase.ready && !services.firebase.busy;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
            decoration: BoxDecoration(color: c.warningSoft, borderRadius: BorderRadius.circular(AppRadius.card)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(Symbols.info_rounded, size: 18, color: c.warningText),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('일부 기능을 준비하지 못했어요', style: t.labelLarge?.copyWith(color: c.warningText)),
                      for (final l in lines) Text(l, style: t.bodySmall?.copyWith(color: c.warningText)),
                      if (canRetry)
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: c.warningText,
                          ),
                          onPressed: services.firebase.init,
                          child: const Text('다시 연결'),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: services.boot.dismiss,
                  icon: Icon(Symbols.close_rounded, size: 18, color: c.warningText),
                  visualDensity: VisualDensity.compact,
                  tooltip: '닫기',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static List<String> _lines(BootReport boot, FirebaseSession firebase) {
    final out = <String>[];
    if (!firebase.busy && !firebase.ready && firebase.error != null) out.add('AI·동기화: ${firebase.error}');
    if (firebase.ready && firebase.firestoreError != null) out.add('동기화: ${firebase.firestoreError}');
    for (final i in boot.issues) {
      out.add('${i.step}: ${i.message}');
    }
    return out;
  }
}
