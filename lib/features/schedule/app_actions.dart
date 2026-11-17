import 'package:flutter/foundation.dart';

/// 알림·위젯에서 들어오는 딥링크 신호. 화면이 구독해서 처리한다.
class AppActions {
  AppActions._();

  static final AppActions instance = AppActions._();

  static const openCamera = 'camera';
  static const openReport = 'report';
  static const openHistory = 'history';

  /// 체험 종료 알림을 누르면 설정 → 프리미엄 관리.
  static const openPremium = 'premium';

  /// 수거일·가족 알림을 누르면 홈(수거일 카드)으로.
  static const openHome = 'home';

  /// 온보딩 직후: 홈 위에 카메라 화면을 띄운다 (HomeShell 이 처리).
  static const openCapture = 'capture';

  /// 값이 바뀔 때마다 한 번 처리한다. (같은 액션이 연속으로 와도 카운터가 바뀐다)
  final ValueNotifier<(String, int)?> pending = ValueNotifier(null);
  int _seq = 0;

  void fire(String action) => pending.value = (action, ++_seq);

  void clear() => pending.value = null;
}
