import 'dart:async';

import 'package:flutter/foundation.dart';

import 'analytics.dart';

/// 사용자 속성 한 묶음. 계산은 순수 함수([compute])로 두어 테스트한다. 이메일·구 단위 지역 등 식별 정보는 넣지 않는다.
class UserProps {
  UserProps._();

  /// 테스터 계정. is_tester 는 이 목록이거나 debug 빌드면 true. (이메일 자체는 어떤 이벤트에도 보내지 않는다)
  static const testerEmails = {'iy093452@gmail.com', 'idealworld13@gmail.com'};

  static bool isTester(String? email) => kDebugMode || (email != null && testerEmails.contains(email.trim().toLowerCase()));

  static Map<String, String> compute({
    required String? email,
    required bool anonymous,
    required String premiumStatus, // none|trial|active|cancelled|expired
    required String? regionSido, // 시도명 (구 단위 금지)
    required bool inHousehold,
    required bool isOwner,
    required int collected,
    required int installDays,
  }) =>
      {
        'is_tester': isTester(email).toString(),
        'premium_status': premiumStatus,
        'region_set': (regionSido != null).toString(),
        'region_sido': regionSido ?? 'none',
        'in_household': inHousehold.toString(),
        'household_role': !inHousehold ? 'none' : (isOwner ? 'owner' : 'member'),
        'auth_type': anonymous ? 'anonymous' : 'google',
        'collection_bucket': Analytics.collectionBucket(collected),
        'install_age_bucket': Analytics.installAgeBucket(installDays),
      };
}

/// 저장소들이 바뀔 때마다 사용자 속성을 다시 계산해 보낸다 (같은 값은 Analytics 가 걸러낸다).
class UserPropsSync {
  UserPropsSync({required this.listenables, required this.read});

  final List<Listenable> listenables;
  final Map<String, String> Function() read;
  Timer? _debounce;

  void start() {
    for (final l in listenables) {
      l.addListener(_schedule);
    }
    _schedule();
  }

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => unawaited(Analytics.setUserProperties(read())));
  }

  void dispose() {
    _debounce?.cancel();
    for (final l in listenables) {
      l.removeListener(_schedule);
    }
  }
}
