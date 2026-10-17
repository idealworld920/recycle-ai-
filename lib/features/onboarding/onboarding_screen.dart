import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import 'consent_screen.dart';

/// 최초 실행: 소개 3장 → 동의 화면.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    (Symbols.photo_camera_rounded, '찍으면 알려줘요', '사진 한 장이면 어디에 버릴지, 뭘 떼야 하는지 바로 알려드려요. 사진은 저장하지 않아요.'),
    (Symbols.calendar_today_rounded, '수거일을 잊지 않게', '우리 동네 수거일을 정해두면 전날 저녁에 알려드리고, 홈 위젯에 D-day 가 떠요.'),
    (Symbols.lock_open_rounded, '로그인 없이 시작', '익명으로 바로 쓸 수 있어요. 기록을 지키고 싶을 때만 구글을 연결하면 돼요.'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pages.length) {
      _controller.nextPage(duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final c = context.colors;
    return Scaffold(
      body: PageView(
        controller: _controller,
        physics: _page == _pages.length ? const NeverScrollableScrollPhysics() : null,
        onPageChanged: (i) => setState(() => _page = i),
        children: [
          for (final (icon, title, body) in _pages)
            SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TextButton.styleFrom(foregroundColor: c.textSecondary),
                      onPressed: () => _controller.animateToPage(_pages.length, duration: const Duration(milliseconds: 200), curve: Curves.easeOut),
                      child: const Text('건너뛰기'),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(AppSpacing.lg)),
                          child: Icon(icon, size: 32, color: c.textPrimary),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(title, style: t.headlineSmall),
                        const SizedBox(height: AppSpacing.md),
                        Text(body, style: t.bodyMedium?.copyWith(color: c.textSecondary)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _pages.length; i++)
                        Container(
                          width: i == _page ? 20 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                          decoration: BoxDecoration(color: i == _page ? c.ink : c.divider, borderRadius: BorderRadius.circular(AppRadius.chip)),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.base),
                    child: FilledButton(onPressed: _next, child: const Text('다음')),
                  ),
                ],
              ),
            ),
          ConsentScreen(onDone: widget.onDone),
        ],
      ),
    );
  }
}
