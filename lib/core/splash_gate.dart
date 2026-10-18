import 'dart:async';

import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

/// 앱 자체 스플래시. [until] 이 끝나거나 [maxWait] 가 지나면 무조건 [child] 로 넘어간다.
///
/// Firebase 초기화·로그인이 실패하거나 느려도 홈이 막히지 않게 하는 안전장치.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.until, required this.child, this.maxWait = const Duration(seconds: 3)});

  final Future<void> until;
  final Duration maxWait;
  final Widget child;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _done = false;
  Timer? _deadline;

  @override
  void initState() {
    super.initState();
    _deadline = Timer(widget.maxWait, _finish);
    widget.until.then((_) => _finish(), onError: (_) => _finish());
  }

  void _finish() {
    _deadline?.cancel();
    _deadline = null;
    if (mounted && !_done) setState(() => _done = true);
  }

  @override
  void dispose() {
    _deadline?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: _done
          ? widget.child
          : Scaffold(
              key: const ValueKey('splash'),
              backgroundColor: c.background,
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset('assets/branding/logo_192.png', width: 96, height: 96, filterQuality: FilterQuality.medium),
                    ),
                    const SizedBox(height: 16),
                    Text('ReSAI', style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
    );
  }
}
