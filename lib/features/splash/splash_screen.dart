import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/mascot.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../onboarding/intro_animation.dart' show SpeechBubble;
import 'splash_plan.dart';

/// 앱 스플래시. 흰 배경, 가운데 240px 리뿅이.
///
/// [plan] 대로 재생하고, 끝났는데 [ready](Firebase 초기화·익명 로그인·Remote Config)가 아직이면
/// r_thinking + "잠깐만뿅…" 으로 바꿔 기다린다. 전체 상한 [SplashPlan.maxTotal]. 탭하면 즉시 [onDone].
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.plan, required this.ready, required this.onDone, this.maxTotal = SplashPlan.maxTotal});

  final SplashPlan plan;
  final Future<void> ready;
  final ValueChanged<SplashPlan> onDone;
  final Duration maxTotal;

  static const waitingText = '잠깐만뿅…';
  static const introAsset = 'assets/branding/mascot/r_intro.gif';
  static const shortAsset = 'assets/branding/mascot/r_intro_short.gif';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _animTimer;
  Timer? _capTimer;
  bool _animDone = false;
  bool _ready = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    widget.ready.then((_) => _onReady(), onError: (_) => _onReady());
    _animTimer = Timer(widget.plan.length, () {
      _animDone = true;
      if (_ready) {
        _finish();
      } else if (mounted) {
        setState(() {});
      }
    });
    _capTimer = Timer(widget.maxTotal, _finish);
  }

  void _onReady() {
    _ready = true;
    if (_animDone) _finish();
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    _animTimer?.cancel();
    _capTimer?.cancel();
    widget.onDone(widget.plan);
  }

  @override
  void dispose() {
    _animTimer?.cancel();
    _capTimer?.cancel();
    super.dispose();
  }

  Widget _image() {
    final waiting = _animDone && !_ready;
    if (waiting) return const MascotImage(Mascot.thinking, size: 240);
    final p = widget.plan;
    final asset = switch (p.kind) {
      SplashKind.reduced => Mascot.intro.png,
      SplashKind.short => SplashScreen.shortAsset,
      _ => SplashScreen.introAsset,
    };
    return Image.asset(
      asset,
      width: 240,
      height: 240,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      // 디코딩 실패 시 정지 이미지로.
      errorBuilder: (_, _, _) => Image.asset(Mascot.intro.png, width: 240, height: 240, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox(width: 240, height: 240)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final waiting = _animDone && !_ready;
    final text = waiting ? SplashScreen.waitingText : widget.plan.text;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _finish,
      child: Scaffold(
        backgroundColor: c.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _image(),
              const SizedBox(height: AppSpacing.base),
              if (text != null) SpeechBubble(text: text),
            ],
          ),
        ),
      ),
    );
  }
}
