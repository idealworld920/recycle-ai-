import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'admin_region.dart';
import 'region.dart';

/// 거주 지역. 위치 권한 없이 수동 선택.
///
/// - 선택값은 행정표준코드(시군구 5자리)로 기기에 저장하고, 로그인돼 있으면 users/{uid}.region 에도 올린다.
/// - 기기 값이 없고 서버 값이 있으면(기기 변경 등) 서버 값을 받아온다.
/// - 대형폐기물 링크 등 예전 지역 데이터(`Region`)는 이름으로 매칭해 그대로 쓴다.
class RegionStore extends ChangeNotifier {
  RegionStore(this._prefs, this.repository, {AdminRegionRepository? admin}) : adminRepository = admin ?? AdminRegionRepository.empty() {
    _admin = adminRepository.byCode(_prefs.getString(codePrefKey));
    // v1(이름 기반) 저장값 이관
    if (_admin == null) {
      final legacy = repository.byId(_prefs.getString(prefKey));
      if (legacy != null) _admin = _findAdmin(legacy.sido, legacy.sigungu);
    }
  }

  static const prefKey = 'region_v1';
  static const codePrefKey = 'region_code_v2';

  final SharedPreferences _prefs;
  final RegionRepository repository;
  final AdminRegionRepository adminRepository;
  AdminSigungu? _admin;

  /// 서버 반영 훅. main 에서 Firestore 쓰기로 연결한다. 없으면 기기에만 저장.
  Future<void> Function(Map<String, dynamic> region)? onRemoteSave;

  /// 고른 시/군/구 (행정코드 포함).
  AdminSigungu? get admin => _admin;
  String? get code => _admin?.code;
  bool get isSet => _admin != null;
  String get displayName => _admin?.displayName ?? '지역을 선택하세요';

  /// 대형폐기물·수거함 링크용 예전 지역 레코드. 없는 지역이면 null.
  Region? get selected => _admin == null ? null : repository.all.where((r) => r.sido == _admin!.sidoShort && r.sigungu == _admin!.name).firstOrNull;

  static Future<RegionStore> load(RegionRepository repo, {AdminRegionRepository? admin}) async =>
      RegionStore(await SharedPreferences.getInstance(), repo, admin: admin);

  Future<void> selectAdmin(AdminSigungu? region) async {
    _admin = region;
    if (region == null) {
      await _prefs.remove(codePrefKey);
      await _prefs.remove(prefKey);
    } else {
      await _prefs.setString(codePrefKey, region.code);
    }
    notifyListeners();
    final hook = onRemoteSave;
    if (hook != null) {
      try {
        await hook(region?.toUserDoc() ?? const {});
      } catch (e) {
        debugPrint('지역 서버 저장 실패: $e');
      }
    }
  }

  /// 예전 API (대형폐기물 화면 등). 이름으로 행정 지역을 찾아 저장한다.
  Future<void> select(Region? region) => selectAdmin(region == null ? null : _findAdmin(region.sido, region.sigungu));

  /// 서버 users/{uid}.region 을 받아 기기에 없을 때만 채운다.
  void adoptRemote(Map<String, dynamic>? remote) {
    if (_admin != null || remote == null) return;
    final found = adminRepository.byCode(remote['code'] as String?);
    if (found == null) return;
    _admin = found;
    _prefs.setString(codePrefKey, found.code);
    notifyListeners();
  }

  AdminSigungu? _findAdmin(String sidoShort, String sigungu) =>
      adminRepository.all.where((a) => a.sidoShort == sidoShort && a.name == sigungu).firstOrNull;
}
