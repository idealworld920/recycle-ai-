import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/analytics.dart';
import '../../core/mascot.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../schedule/app_actions.dart';

/// FCM (가족 공유 푸시). 토큰은 users/{uid}/fcmTokens/{deviceId} 에 기기별로 하나.
/// 포그라운드 수신은 상단 인앱 배너(리뿅이 + 말풍선), 탭 → 홈 수거일 카드. 로그아웃·데이터 삭제 때 토큰 문서를 지운다.
class PushService {
  PushService._();

  static final PushService instance = PushService._();

  static const deviceIdPref = 'push_device_id';

  String? _uid;
  String? _token;
  StreamSubscription<String>? _refreshSub;
  StreamSubscription<RemoteMessage>? _fgSub;
  StreamSubscription<RemoteMessage>? _openSub;
  bool _listening = false;

  /// 인앱 배너를 띄울 Overlay 를 찾기 위한 네비게이터 키 (main 이 넣어 준다).
  GlobalKey<NavigatorState>? navigatorKey;

  FirebaseMessaging get _fm => FirebaseMessaging.instance;

  /// 기기 식별자(앱 설치 단위, 랜덤). 토큰이 바뀌어도 같은 문서를 덮어쓴다.
  static Future<String> deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(deviceIdPref);
    if (id == null) {
      final r = Random.secure();
      id = List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      await prefs.setString(deviceIdPref, id);
    }
    return id;
  }

  /// Firebase 가 준비되고 uid 가 정해지면. uid 가 바뀌면 이전 토큰 문서는 [detach] 가 지운다.
  Future<void> attachUser(String? uid) async {
    if (kIsWeb) return;
    if (uid == _uid) return;
    if (_uid != null) await detach();
    _uid = uid;
    if (uid == null) return;
    try {
      _token = await _fm.getToken();
      if (_token != null) await _saveToken(_token!);
      _refreshSub ??= _fm.onTokenRefresh.listen((t) {
        _token = t;
        _saveToken(t);
      });
      _listen();
    } catch (e) {
      debugPrint('[push] 토큰 준비 실패: $e');
    }
  }

  Future<void> _saveToken(String token) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final id = await deviceId();
      await FirebaseFirestore.instance.collection('users').doc(uid).collection('fcmTokens').doc(id).set({
        'token': token,
        'platform': defaultTargetPlatform.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Analytics.log('fcm_token_saved');
    } catch (e) {
      debugPrint('[push] 토큰 저장 실패: $e');
    }
  }

  /// 로그아웃·계정 삭제·계정 전환: 이 기기의 토큰 문서 삭제 (더 이상 이 계정 푸시를 받지 않는다).
  Future<void> detach() async {
    final uid = _uid;
    _uid = null;
    if (uid == null || kIsWeb) return;
    try {
      final id = await deviceId();
      await FirebaseFirestore.instance.collection('users').doc(uid).collection('fcmTokens').doc(id).delete();
    } catch (e) {
      debugPrint('[push] 토큰 삭제 실패(무시): $e');
    }
  }

  void _listen() {
    if (_listening) return;
    _listening = true;
    _fgSub = FirebaseMessaging.onMessage.listen((m) {
      Analytics.log('push_received', {'type': m.data['type'] ?? 'family', 'foreground': true});
      _showBanner(m);
    });
    _openSub = FirebaseMessaging.onMessageOpenedApp.listen((m) {
      Analytics.log('push_received', {'type': m.data['type'] ?? 'family', 'foreground': false});
      Analytics.log('notification_tap', {'type': m.data['type'] ?? 'family'});
      AppActions.instance.fire(AppActions.openHome);
    });
    _fm.getInitialMessage().then((m) {
      if (m == null) return;
      Analytics.log('push_received', {'type': m.data['type'] ?? 'family', 'foreground': false, 'cold_start': true});
      Analytics.log('notification_tap', {'type': m.data['type'] ?? 'family'});
      AppActions.instance.fire(AppActions.openHome);
    }).catchError((_) {});
  }

  OverlayEntry? _banner;

  void _showBanner(RemoteMessage m) {
    final title = m.notification?.title ?? m.data['title']?.toString();
    final body = m.notification?.body ?? m.data['body']?.toString();
    if (body == null || body.isEmpty) return;
    final overlay = navigatorKey?.currentState?.overlay;
    if (overlay == null) return;
    _banner?.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _PushBanner(
        title: title,
        body: body,
        onTap: () {
          entry.remove();
          if (_banner == entry) _banner = null;
          Analytics.log('notification_tap', {'type': m.data['type'] ?? 'family', 'in_app': true});
          AppActions.instance.fire(AppActions.openHome);
        },
        onClose: () {
          entry.remove();
          if (_banner == entry) _banner = null;
        },
      ),
    );
    _banner = entry;
    overlay.insert(entry);
    Timer(const Duration(seconds: 5), () {
      if (_banner == entry) {
        entry.remove();
        _banner = null;
      }
    });
  }

  void dispose() {
    _refreshSub?.cancel();
    _fgSub?.cancel();
    _openSub?.cancel();
  }
}

/// 포그라운드 푸시 배너: 리뿅이 아이콘 + 말풍선 스타일.
class _PushBanner extends StatelessWidget {
  const _PushBanner({required this.title, required this.body, required this.onTap, required this.onClose});

  final String? title;
  final String body;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Positioned(
      left: AppSpacing.md,
      right: AppSpacing.md,
      top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: onTap,
          onVerticalDragEnd: (d) {
            if ((d.primaryVelocity ?? 0) < 0) onClose();
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: c.divider),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MascotImage(Mascot.wink, size: 40, animated: false),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null && title!.isNotEmpty) Text(title!, style: t.titleSmall),
                      Text(body, style: t.bodyMedium, maxLines: 3, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                IconButton(onPressed: onClose, iconSize: 18, color: c.textSecondary, tooltip: '닫기', icon: const Icon(Icons.close_rounded)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
