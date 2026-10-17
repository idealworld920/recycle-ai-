import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_services.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// 시스템 권한 팝업 직전에 왜 필요한지 한 줄로 설명한다. 종류별로 한 번만.
class PermissionPrimer {
  PermissionPrimer._();

  static const camera = 'camera';
  static const notification = 'notification';

  static Future<bool> show(BuildContext context, String kind) async {
    final settings = AppServices.of(context).settings;
    if (settings.primerShown(kind)) return true;
    final (icon, title, body) = switch (kind) {
      camera => (Symbols.photo_camera_rounded, '카메라를 사용할게요', '사진은 분리배출 판별에만 쓰고 서버에 저장하지 않아요.'),
      _ => (Symbols.notifications_rounded, '알림을 보낼게요', '수거일 전날과 퀴즈가 있을 때만 알려드려요. 설정에서 언제든 끌 수 있어요.'),
    };
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, size: 22, color: ctx.colors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(body),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: ctx.colors.textSecondary),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('다음에'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('확인')),
        ],
      ),
    );
    if (ok == true) await settings.markPrimerShown(kind);
    return ok == true;
  }
}
