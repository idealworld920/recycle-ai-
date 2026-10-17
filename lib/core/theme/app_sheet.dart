import 'package:flutter/material.dart';

import 'app_spacing.dart';
import 'app_theme.dart';

/// 상세·설정용 바텀시트. 상단 radius 24, 핸들 바, 내용은 스크롤.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  String? title,
  required Widget Function(BuildContext context, ScrollController controller) builder,
  double initialSize = 0.72,
  double maxSize = 0.94,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: initialSize,
      minChildSize: 0.4,
      maxChildSize: maxSize,
      builder: (ctx, controller) => Column(
        children: [
          const SheetHandle(),
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.sm),
              child: Row(children: [Expanded(child: Text(title, style: ctx.text.titleMedium))]),
            ),
          Expanded(child: builder(ctx, controller)),
        ],
      ),
    ),
  );
}

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(color: context.colors.divider, borderRadius: BorderRadius.circular(AppRadius.chip)),
      ),
    );
  }
}
