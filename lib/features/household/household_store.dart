import 'dart:async';

import 'package:flutter/foundation.dart';

import '../schedule/pickup_schedule.dart';
import 'household_model.dart';
import 'household_repository.dart';

/// 현재 사용자의 집. 수거일·체크인을 집 단위로 공유한다.
class HouseholdStore extends ChangeNotifier {
  HouseholdStore(this._repo);

  final HouseholdRepository _repo;
  String? _uid;
  Household? _household;
  List<HouseholdMember> _members = const [];
  Map<WasteType, MemberCheckin> _todayCheckins = const {};
  String _today = '';
  bool _busy = false;
  StreamSubscription<Household?>? _hSub;
  StreamSubscription<List<HouseholdMember>>? _mSub;
  StreamSubscription<Map<WasteType, MemberCheckin>>? _cSub;

  Household? get household => _household;
  bool get active => _household != null;
  List<HouseholdMember> get members => _members;
  Map<WasteType, MemberCheckin> get todayCheckins => _todayCheckins;
  bool get busy => _busy;
  HouseholdMember? get me => _members.where((m) => m.uid == _uid).firstOrNull;

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
    _hSub = _repo.watch(id).listen((h) {
      _household = h;
      if (h == null) _detach();
      notifyListeners();
    });
    _mSub = _repo.watchMembers(id).listen((m) {
      _members = m;
      notifyListeners();
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
    });
  }

  Future<void> _detach() async {
    await _hSub?.cancel();
    await _mSub?.cancel();
    await _cSub?.cancel();
    _hSub = _mSub = null;
    _cSub = null;
    _household = null;
    _members = const [];
    _todayCheckins = const {};
    notifyListeners();
  }

  Future<Household> create(String nickname) async {
    final uid = _uid;
    if (uid == null) throw const HouseholdException('로그인 상태가 아니에요.');
    return _run(() async {
      final h = await _repo.create(uid: uid, nickname: nickname);
      _listen(h.id);
      return h;
    });
  }

  Future<void> join(String code, String nickname) async {
    final uid = _uid;
    if (uid == null) throw const HouseholdException('로그인 상태가 아니에요.');
    await _run(() async {
      final id = await _repo.join(code: code, uid: uid, nickname: nickname);
      _listen(id);
    });
  }

  Future<void> leave() async {
    final uid = _uid;
    final h = _household;
    if (uid == null || h == null) return;
    await _run(() async {
      await _repo.leave(householdId: h.id, uid: uid);
      await _detach();
    });
  }

  /// 집 수거일 바꾸기. 모든 멤버에게 스트림으로 반영된다.
  Future<void> setSchedule(PickupSchedule s) async {
    final h = _household;
    if (h == null) return;
    await _repo.setSchedule(h.id, s);
  }

  Future<void> checkIn(WasteType type) async {
    final h = _household;
    final m = me;
    if (h == null || m == null) return;
    _listenToday(h.id);
    await _repo.checkIn(h.id, _today, type, m);
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
