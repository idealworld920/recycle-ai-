import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../core/theme/app_theme.dart';
import '../features/chat/chat_screen.dart';
import '../features/history/history_screen.dart';
import '../features/schedule/app_actions.dart';
import '../features/tips/tips_screen.dart';
import 'guide_screen.dart';
import 'home_screen.dart';

/// 하단 탭: 홈 / 물어보기 / 팁 / 가이드 / 기록
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    AppActions.instance.pending.addListener(_onAction);
  }

  @override
  void dispose() {
    AppActions.instance.pending.removeListener(_onAction);
    super.dispose();
  }

  /// 알림을 누르면 홈 탭으로 옮기고, 카메라는 HomeScreen 이 같은 신호를 받아 연다.
  void _onAction() {
    final action = AppActions.instance.pending.value;
    if (action == null) return;
    if (action.$1 == AppActions.openCamera && _index != 0) setState(() => _index = 0);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
      const ChatScreen(),
      const TipsScreen(),
      const GuideScreen(),
      HistoryScreen(onGoHome: () => setState(() => _index = 0)),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: context.colors.divider))),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Symbols.home_rounded), selectedIcon: Icon(Symbols.home_rounded, fill: 1), label: '홈'),
            NavigationDestination(
              icon: Icon(Symbols.chat_bubble_rounded),
              selectedIcon: Icon(Symbols.chat_bubble_rounded, fill: 1),
              label: '물어보기',
            ),
            NavigationDestination(
              icon: Icon(Symbols.lightbulb_rounded),
              selectedIcon: Icon(Symbols.lightbulb_rounded, fill: 1),
              label: '팁',
            ),
            NavigationDestination(
              icon: Icon(Symbols.menu_book_rounded),
              selectedIcon: Icon(Symbols.menu_book_rounded, fill: 1),
              label: '가이드',
            ),
            NavigationDestination(icon: Icon(Symbols.history_rounded), selectedIcon: Icon(Symbols.history_rounded, fill: 1), label: '기록'),
          ],
        ),
      ),
    );
  }
}
