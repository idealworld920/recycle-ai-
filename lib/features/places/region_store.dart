import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'region.dart';

/// 사용자가 고른 시/구. 위치 권한 없이 수동 선택, 기기에만 저장.
class RegionStore extends ChangeNotifier {
  RegionStore(this._prefs, this.repository) {
    _selected = repository.byId(_prefs.getString(prefKey));
  }

  static const prefKey = 'region_v1';

  final SharedPreferences _prefs;
  final RegionRepository repository;
  Region? _selected;

  Region? get selected => _selected;

  static Future<RegionStore> load(RegionRepository repo) async => RegionStore(await SharedPreferences.getInstance(), repo);

  Future<void> select(Region? region) async {
    _selected = region;
    if (region == null) {
      await _prefs.remove(prefKey);
    } else {
      await _prefs.setString(prefKey, region.id);
    }
    notifyListeners();
  }
}
