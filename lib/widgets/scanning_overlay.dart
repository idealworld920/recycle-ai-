import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// AI가 사진을 보는 동안 띄우는 풀스크린 오버레이. 문구가 돌아가며 바뀐다.
class ScanningOverlay extends StatefulWidget {
  const ScanningOverlay({super.key});

  static const messages = [
    ('👀', '쓰레기 째려보는 중'),
    ('🔍', '라벨이랑 재질 확인하는 중'),
    ('📚', '환경부 가이드 뒤적이는 중'),
    ('♻️', '어디로 보낼지 정하는 중'),
  ];

  @override
  State<ScanningOverlay> createState() => _ScanningOverlayState();
}

class _ScanningOverlayState extends State<ScanningOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _bounce =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (mounted) setState(() => _index = (_index + 1) % ScanningOverlay.messages.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (emoji, text) = ScanningOverlay.messages[_index];
    return ColoredBox(
      color: AppColors.ink.withValues(alpha: 0.92),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _bounce,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, -10 * _bounce.value),
                child: child,
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 72)),
            ),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                '$text...',
                key: ValueKey(_index),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 140,
              child: LinearProgressIndicator(
                minHeight: 6,
                color: AppColors.lime,
                backgroundColor: Color(0x33FFFFFF),
                borderRadius: BorderRadius.all(Radius.circular(99)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
