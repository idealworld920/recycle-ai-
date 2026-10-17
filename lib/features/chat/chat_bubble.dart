import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import 'chat_message.dart';

/// 사용자: 오른쪽 검정, AI: 왼쪽 surface.
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message, this.onRetry});

  final ChatMessage message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final isUser = message.role == ChatRole.user;

    final bg = isUser ? c.ink : (message.isError ? c.errorSoft : c.surface);
    final fg = isUser ? c.onInk : (message.isError ? c.error : c.textPrimary);

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(AppSpacing.base),
      topRight: const Radius.circular(AppSpacing.base),
      bottomLeft: Radius.circular(isUser ? AppSpacing.base : AppSpacing.xs),
      bottomRight: Radius.circular(isUser ? AppSpacing.xs : AppSpacing.base),
    );

    final Widget body = message.pending
        ? const _TypingDots()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message.text, style: t.bodyMedium?.copyWith(color: fg)),
              if (message.isError && onRetry != null) ...[
                const SizedBox(height: AppSpacing.sm),
                InkWell(
                  onTap: onRetry,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Symbols.refresh_rounded, size: 16, color: fg),
                      const SizedBox(width: AppSpacing.xs),
                      Text('다시 시도', style: t.labelLarge?.copyWith(fontSize: 13, color: fg)),
                    ],
                  ),
                ),
              ],
            ],
          );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.md),
          decoration: BoxDecoration(color: bg, borderRadius: radius),
          child: body,
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.colors.textSecondary;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Opacity(
                opacity: ((_c.value * 3 - i) % 3).abs() < 1 ? 1.0 : 0.35,
                child: Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              ),
            ),
        ],
      ),
    );
  }
}
