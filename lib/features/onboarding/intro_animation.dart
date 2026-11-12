import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/mascot.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// 온보딩 0단계: 흰 화면 가운데 리뿅이 등장 GIF(240px) 1회 재생.
///
/// GIF 자체의 반복은 무시하고 타이머로 제어한다: [gifLength] 가 지나면 마지막 프레임 PNG 로 바꿔 멈추고,
/// [bubbleAt] 에 말풍선이 400ms 페이드인, [finishAt] 에 [onFinished]. 아무 데나 탭하면 즉시 끝낸다.
/// "애니메이션 줄이기" 가 켜져 있으면 정지 이미지를 [reducedHold] 만 보여주고 넘어간다.
class OnboardingIntro extends StatefulWidget {
  const OnboardingIntro({super.key, required this.onFinished, this.reduceMotion = false});

  final VoidCallback onFinished;
  final bool reduceMotion;

  static const gifLength = Duration(milliseconds: 2000);
  static const bubbleAt = Duration(milliseconds: 1600);
  static const finishAt = Duration(milliseconds: 2600);
  static const reducedHold = Duration(milliseconds: 1000);
  static const bubbleText = '리뿅이 등장했뿅!';

  @override
  State<OnboardingIntro> createState() => _OnboardingIntroState();
}

class _OnboardingIntroState extends State<OnboardingIntro> {
  final List<Timer> _timers = [];
  bool _playing = true;
  bool _bubble = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    if (widget.reduceMotion) {
      _playing = false;
      _bubble = true;
      _timers.add(Timer(OnboardingIntro.reducedHold, _finish));
      return;
    }
    _timers.add(Timer(OnboardingIntro.bubbleAt, () => _set(() => _bubble = true)));
    _timers.add(Timer(OnboardingIntro.gifLength, () => _set(() => _playing = false)));
    _timers.add(Timer(OnboardingIntro.finishAt, _finish));
  }

  void _set(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    for (final t in _timers) {
      t.cancel();
    }
    widget.onFinished();
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _finish,
      child: ColoredBox(
        color: c.background,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                _playing ? Mascot.intro.gif : Mascot.intro.png,
                width: 240,
                height: 240,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
              ),
              const SizedBox(height: AppSpacing.base),
              AnimatedOpacity(
                opacity: _bubble ? 1 : 0,
                duration: widget.reduceMotion ? Duration.zero : const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                child: const SpeechBubble(text: OnboardingIntro.bubbleText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
