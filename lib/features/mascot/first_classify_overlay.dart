import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/mascot.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// 첫 분류 성공 1회: 검정 40% 오버레이 + happy 200px + 말풍선 + 0.8초 색종이(파랑·흰·연파랑). 탭 또는 2초 후 닫힌다.
/// "애니메이션 줄이기" 면 색종이 없이 토스트 한 줄.
const firstClassifyLine = '첫 분류 성공이뿅!! 도감에 1번째 친구 등록했뿅!';

Future<void> showFirstClassifyOverlay(BuildContext context) {
  if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(firstClassifyLine), duration: Duration(seconds: 2)));
    return Future.value();
  }
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '닫기',
    barrierColor: Colors.black.withValues(alpha: 0.4),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (ctx, _, _) => _FirstClassifyBody(onClose: () => Navigator.of(ctx).pop()),
  );
}

class _FirstClassifyBody extends StatefulWidget {
  const _FirstClassifyBody({required this.onClose});
  final VoidCallback onClose;

  @override
  State<_FirstClassifyBody> createState() => _FirstClassifyBodyState();
}

class _FirstClassifyBodyState extends State<_FirstClassifyBody> with SingleTickerProviderStateMixin {
  late final AnimationController _confetti = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  late final List<_Piece> _pieces = List.generate(28, (i) => _Piece.random(Random(i)));

  Timer? _autoClose;

  @override
  void initState() {
    super.initState();
    _confetti.forward();
    _autoClose = Timer(const Duration(seconds: 2), () {
      if (mounted) widget.onClose();
    });
  }

  @override
  void dispose() {
    _autoClose?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onClose,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _confetti,
                builder: (_, _) => CustomPaint(painter: _ConfettiPainter(_pieces, _confetti.value, [c.primary, c.onInk, c.primarySoft])),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MascotImage(Mascot.happy, size: 200),
                    const SizedBox(height: AppSpacing.base),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.base),
                      decoration: BoxDecoration(color: c.background, borderRadius: BorderRadius.circular(AppRadius.card)),
                      child: Text(firstClassifyLine, style: t.titleSmall, textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('탭하면 닫혀요', style: t.bodySmall?.copyWith(color: c.onInk)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Piece {
  _Piece(this.x, this.drift, this.size, this.color, this.spin);
  final double x, drift, size, spin;
  final int color;
  factory _Piece.random(Random r) => _Piece(r.nextDouble(), (r.nextDouble() - 0.5) * 0.3, 6 + r.nextDouble() * 6, r.nextInt(4), r.nextDouble() * 6);
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t, this.colors);
  final List<_Piece> pieces;
  final double t;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (t == 0) return;
    final paint = Paint();
    for (final p in pieces) {
      final y = -20 + t * (size.height * 0.7);
      final x = (p.x + p.drift * t) * size.width;
      paint.color = colors[p.color % colors.length].withValues(alpha: (1 - t).clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * t);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
