import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';

/// 카드: radius 16, 그림자 없음, surface 배경, 패딩 20.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.onTap, this.padding, this.soft = false});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  /// 선택된 카드·정보 박스용 연한 primary 배경.
  final bool soft;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final body = Padding(padding: padding ?? const EdgeInsets.all(AppSpacing.lg), child: child);
    return Material(
      color: soft ? c.primarySoft : c.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: onTap == null ? body : InkWell(borderRadius: BorderRadius.circular(AppRadius.card), onTap: onTap, child: body),
    );
  }
}

/// 연한 primary 배경의 정보 박스.
class InfoBox extends StatelessWidget {
  const InfoBox({super.key, required this.child, this.icon});

  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      soft: true,
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: c.primary),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(child: child),
        ],
      ),
    );
  }
}
