import 'package:flutter/material.dart';

import 'chat_message.dart';

/// 사용자: 오른쪽 검정, AI: 왼쪽 연회색(#F7F7F8).
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message, this.onRetry});

  final ChatMessage message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isUser = message.role == ChatRole.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isUser
        ? scheme.primary
        : message.isError
            ? scheme.errorContainer
            : (isDark ? scheme.surfaceContainer : const Color(0xFFF7F7F8));
    final fg = isUser
        ? scheme.onPrimary
        : message.isError
            ? scheme.onErrorContainer
            : scheme.onSurface;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isUser ? 18 : 4),
      bottomRight: Radius.circular(isUser ? 4 : 18),
    );

    Widget body;
    if (message.pending) {
      body = const _TypingDots();
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message.text, style: text.bodyMedium?.copyWith(color: fg)),
          if (message.isError && onRetry != null) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: onRetry,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, size: 16, color: fg),
                  const SizedBox(width: 4),
                  Text('다시 시도', style: text.labelLarge?.copyWith(color: fg, fontSize: 13)),
                ],
              ),
            ),
          ],
        ],
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
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
