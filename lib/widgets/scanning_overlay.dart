import 'dart:async';

import 'package:flutter/material.dart';

import '../core/mascot.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';

/// AI가 사진을 보는 동안 띄우는 풀스크린 오버레이. 차분하게 문구만 바뀐다.
///
/// 목표는 사진 선택 → 결과 3초. [startedAt] 기준으로 [slowAfter] 를 넘기면
/// 리뿅이 thinking 과 "조금만 기다려뿅" 으로 바뀐다.
class ScanningOverlay extends StatefulWidget {
  const ScanningOverlay({super.key, this.startedAt, this.slowAfter = const Duration(seconds: 3)});

  final DateTime? startedAt;
  final Duration slowAfter;

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
  Timer? _slowTimer;
  int _index = 0;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1600), (_) {
      if (mounted) setState(() => _index = (_index + 1) % ScanningOverlay.messages.length);
    });
    final started = widget.startedAt ?? DateTime.now();
    final left = widget.slowAfter - DateTime.now().difference(started);
    if (left.isNegative || left == Duration.zero) {
      _slow = true;
    } else {
      _slowTimer = Timer(left, () {
        if (mounted) setState(() => _slow = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _slowTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ColoredBox(
      color: c.background.withValues(alpha: 0.96),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _slow
              ? Column(
                  key: const ValueKey('slow'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MascotImage(Mascot.thinking, size: 132),
                    const SizedBox(height: AppSpacing.lg),
                    Text('조금만 기다려뿅', style: context.text.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text('사진이 어려워서 꼼꼼히 보는 중이에요', style: context.text.bodySmall),
                  ],
                )
              : Column(
                  key: const ValueKey('fast'),
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
      ),
    );
  }
}
