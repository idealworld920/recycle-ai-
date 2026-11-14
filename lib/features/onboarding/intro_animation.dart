import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// 리뿅이 말풍선: 흰 배경, 1px 테두리, radius 16, 꼬리는 위쪽 가운데(기본) 또는 왼쪽.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({super.key, required this.text, this.tail = BubbleTail.top});

  final String text;
  final BubbleTail tail;

  static const _tailSize = 10.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final body = Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: c.background,
        border: Border.all(color: c.divider),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Text(text, style: context.text.bodyMedium?.copyWith(color: c.textPrimary)),
    );
    final tailWidget = CustomPaint(
      size: tail == BubbleTail.top ? const Size(_tailSize * 2, _tailSize) : const Size(_tailSize, _tailSize * 2),
      painter: _TailPainter(fill: c.background, stroke: c.divider, tail: tail),
    );
    return switch (tail) {
      BubbleTail.top => Column(mainAxisSize: MainAxisSize.min, children: [tailWidget, Transform.translate(offset: const Offset(0, -1), child: body)]),
      BubbleTail.left => Row(mainAxisSize: MainAxisSize.min, children: [tailWidget, Flexible(child: Transform.translate(offset: const Offset(-1, 0), child: body))]),
    };
  }
}

enum BubbleTail { top, left }

class _TailPainter extends CustomPainter {
  const _TailPainter({required this.fill, required this.stroke, required this.tail});

  final Color fill;
  final Color stroke;
  final BubbleTail tail;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (tail == BubbleTail.top) {
      path
        ..moveTo(0, size.height)
        ..lineTo(size.width / 2, 0)
        ..lineTo(size.width, size.height);
    } else {
      path
        ..moveTo(size.width, 0)
        ..lineTo(0, size.height / 2)
        ..lineTo(size.width, size.height);
    }
    canvas.drawPath(path, Paint()..color = stroke..style = PaintingStyle.stroke..strokeWidth = 1);
    // 테두리 위를 채워서 본체와 이어 보이게
    final inner = Path.from(path)..close();
    canvas.drawPath(inner, Paint()..color = fill);
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.fill != fill || old.stroke != stroke || old.tail != tail;
}
