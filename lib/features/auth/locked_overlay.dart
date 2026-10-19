import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_card.dart';

/// 익명 사용자에게 가려 보이는 영역. [child] 가 있으면 블러 + 자물쇠, 없으면 잠금 카드.
/// [locked] 가 false 면 child 를 그대로 보여준다.
class LockedOverlay extends StatelessWidget {
  const LockedOverlay({super.key, required this.message, required this.onConnect, this.child, this.locked = true});

  final String message;
  final VoidCallback onConnect;
  final Widget? child;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    if (!locked && child != null) return child!;

    final lockRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Symbols.lock_rounded, size: 18, color: c.textPrimary, fill: 1),
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.bodySmall?.copyWith(color: c.textPrimary))),
        const SizedBox(width: AppSpacing.sm),
        TextButton(
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm), minimumSize: const Size(0, 32)),
          onPressed: onConnect,
          child: const Text('연결'),
        ),
      ],
    );

    if (child == null) {
      return AppCard(
        soft: true,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.md),
        child: lockRow,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.md),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 가려지는 내용이 한 줄짜리면 잠금 안내가 위아래로 잘리므로 최소 높이를 확보한다.
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Opacity(opacity: 0.6, child: Center(child: child)),
              ),
            ),
          ),
          Positioned.fill(
            child: ColoredBox(
              color: c.background.withValues(alpha: 0.35),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(color: c.background, borderRadius: BorderRadius.circular(AppRadius.chip)),
                  child: lockRow,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
