import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_services.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_card.dart';
import 'link_flows.dart';

/// "기기 바꿔도 기록 지키기" 유도 배너. [promptKey] 로 한 번만.
class LinkBanner extends StatelessWidget {
  const LinkBanner({super.key, required this.promptKey, required this.title, required this.body});

  final String promptKey;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final auth = AppServices.of(context).auth;
    final t = context.text;
    final c = context.colors;
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        if (auth.isLinked || auth.isDismissed(promptKey)) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.base),
          child: AppCard(
            soft: true,
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Symbols.cloud_done_rounded, size: 20, color: c.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(title, style: t.titleSmall)),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(body, style: t.bodySmall),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: c.textSecondary),
                      onPressed: () => auth.dismissPrompt(promptKey),
                      child: const Text('닫기'),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (await connectGoogle(context)) await auth.dismissPrompt(promptKey);
                      },
                      child: const Text('연결'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
