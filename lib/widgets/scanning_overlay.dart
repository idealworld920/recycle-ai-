import 'dart:async';

import 'package:flutter/material.dart';

/// AI가 사진을 보는 동안 띄우는 풀스크린 오버레이. 차분하게 문구만 바뀐다.
class ScanningOverlay extends StatefulWidget {
  const ScanningOverlay({super.key});

  static const messages = [
    '사진을 확인하고 있어요',
    '재질과 라벨을 살펴보고 있어요',
    '분리배출 기준과 맞춰보고 있어요',
    '거의 다 됐어요',
  ];

  @override
  State<ScanningOverlay> createState() => _ScanningOverlayState();
}

class _ScanningOverlayState extends State<ScanningOverlay> {
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1600), (_) {
      if (mounted) setState(() => _index = (_index + 1) % ScanningOverlay.messages.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surface.withValues(alpha: 0.96),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 3, color: scheme.onSurface),
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                ScanningOverlay.messages[_index],
                key: ValueKey(_index),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 6),
            Text('잠시만 기다려 주세요', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
