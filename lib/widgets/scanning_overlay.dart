import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';

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
    final c = context.colors;
    return ColoredBox(
      color: c.background.withValues(alpha: 0.96),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 3)),
            const SizedBox(height: AppSpacing.xl),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(ScanningOverlay.messages[_index], key: ValueKey(_index), style: context.text.titleSmall),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('잠시만 기다려 주세요', style: context.text.bodySmall),
          ],
        ),
      ),
    );
  }
}
