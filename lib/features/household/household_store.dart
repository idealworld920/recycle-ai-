import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../schedule/pickup_schedule.dart';
import 'household_model.dart';
import 'household_repository.dart';
import '../../core/analytics.dart';

/// 현재 사용자의 집. 수거일·체크인·프리미엄을 집 단위로 공유한다.
class HouseholdStore extends ChangeNotifier {
  // ignore: prefer_initializing_formals
  HouseholdStore(this._repo, {SharedPreferences? prefs}) : _prefs = prefs {
    _followSchedule = _prefs?.getBool(followPrefKey) ?? true;
  }

  /// 참여할 때 "집 설정으로 바꿀까요?" 에서 아니오를 고르면 false: 내 수거일을 유지한다.
  static const followPrefKey = 'household_follow_schedule';

  final HouseholdRepository _repo;
  final SharedPreferences? _prefs;
  String? _uid;
  Household? _household;
  Map<WasteType, MemberCheckin> _todayCheckins = const {};
  String _today = '';
  bool _busy = false;
  bool _followSchedule = true;
  StreamSubscription<Household?>? _hSub;
  StreamSubscription<Map<WasteType, MemberCheckin>>? _cSub;

  Household? get household => _household;
  bool get active => _household != null;
  List<HouseholdMember> get members => _household?.members ?? const [];
  Map<WasteType, MemberCheckin> get todayCheckins => _todayCheckins;
  bool get busy => _busy;
  String? get uid => _uid;
  HouseholdMember? get me => _household?.member(_uid);
  bool get isOwner => _household?.isOwner(_uid) ?? false;
  bool get followSchedule => _followSchedule;

  /// 방장 구독으로 열린 프리미엄 (멤버 전원).
  bool get familyPlanActive => _household?.premiumActiveAt(DateTime.now()) ?? false;
  DateTime? get familyPlanUntil => _household?.premiumUntil;

  Future<void> setFollowSchedule(bool v) async {
    _followSchedule = v;
    await _prefs?.setBool(followPrefKey, v);
    notifyListeners();
  }

  Future<void> attachUser(String? uid) async {
    _uid = uid;
    await _detach();
    if (uid == null) return;
    try {
      final id = await _repo.householdIdOf(uid);
      if (id != null) _listen(id);
    } catch (e) {
      debugPrint('집 정보 불러오기 실패: $e');
    }
  }

  void _listen(String id) {
    _hSub?.cancel();
    _hSub = _repo.watch(id).listen((h) {
      // 내보내졌거나 집이 삭제되면 조용히 떨어진다.
      if (h == null || (_uid != null && h.member(_uid) == null)) {
        _detach();
        return;
      }
      _household = h;
      notifyListeners();
    }, onError: (Object e) {
      debugPrint('집 구독 오류: $e');
      _detach();
    });
    _listenToday(id);
  }

  void _listenToday(String id) {
    final key = PickupSchedule.dateKey(DateTime.now());
    if (key == _today && _cSub != null) return;
    _today = key;
    _cSub?.cancel();
    _cSub = _repo.watchCheckins(id, key).listen((c) {
      _todayCheckins = c;
      notifyListeners();
    }, onError: (_) {});
  }

  Future<void> _detach() async {
    await _hSub?.cancel();
    await _cSub?.cancel();
    _hSub = null;
    _cSub = null;
    _household = null;
    _todayCheckins = const {};
    notifyListeners();
  }

  Future<Household> create(String nickname) async {
    final uid = _uid;
    if (uid == null) throw const HouseholdException('로그인 상태가 아니에요.');
    return _run(() async {
      final h = await _repo.create(uid: uid, nickname: nickname);
      _household = h;
      _listen(h.id);
      Analytics.log('household_create');
      return h;
    });
  }

  Future<void> join(String code, String nickname) async {
    if (_uid == null) throw const HouseholdException('로그인 상태가 아니에요.');
    Analytics.log('household_join_start');
    try {
      await _run(() async {
        final id = await _repo.join(code: code, nickname: nickname);
        await setFollowSchedule(true);
        _listen(id);
      });
      Analytics.log('household_join_success');
    } on HouseholdException catch (e) {
      Analytics.log('household_join_fail', {'reason': joinFailReason(e.code)});
      rethrow;
    } catch (e) {
      Analytics.log('household_join_fail', {'reason': 'network'});
      rethrow;
    }
  }

  Future<void> leave() async {
    if (_uid == null || _household == null) return;
    await _run(() async {
      await _repo.leave();
      await _detach();
    });
    Analytics.log('household_leave');
  }

  /// household_join_fail.reason: invalid|expired|full|network (Functions 오류 코드 기준).
  static String joinFailReason(String? code) => switch (code) {
        'not-found' || 'invalid-argument' => 'invalid',
        'deadline-exceeded' => 'expired',
        'resource-exhausted' => 'full',
        'unavailable' || 'deadline' => 'network',
        _ => 'invalid',
      };

  Future<void> removeMember(String uid) => _run(() => _repo.removeMember(uid));
  Future<void> transferOwner(String uid) => _run(() => _repo.transferOwner(uid));

  Future<String?> regenerateInvite() async {
    final h = _household;
    if (h == null || !isOwner) return null;
    return _run(() => _repo.regenerateInvite(h.id));
  }

  /// 집 수거일 바꾸기. 모든 멤버에게 스트림으로 반영된다.
  Future<void> setSchedule(PickupSchedule s) async {
    final h = _household;
    if (h == null) return;
    await _repo.setSchedule(h.id, s);
  }

  /// [버렸어요] 집 단위. 같은 날 같은 종류를 누가 이미 눌렀으면 다시 쓰지 않는다.
  Future<bool> checkIn(WasteType type) async {
    final h = _household;
    final m = me;
    if (h == null || m == null) return false;
    _listenToday(h.id);
    if (_todayCheckins.containsKey(type)) return false;
    await _repo.checkIn(h.id, _today, type, m);
    return true;
  }

  Future<T> _run<T>(Future<T> Function() action) async {
    _busy = true;
    notifyListeners();
    try {
      return await action();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }
}
