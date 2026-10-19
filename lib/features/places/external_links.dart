import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// 외부 링크·지도 앱 열기. 실패하면 false.
class ExternalLinks {
  ExternalLinks._();

  static Future<bool> open(String url) async {
    try {
      return await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// 약국을 지도 앱에서 검색. [area] 는 사용자가 설정한 지역 이름(예: "서울 마포구").
  /// 지역이 있으면 그 지역 기준으로, 없으면 현재 위치 기준으로 검색한다.
  /// Android 는 geo: 로 설치된 지도 앱, 그 외는 네이버 지도 웹.
  static Future<bool> openNearbyPharmacy({String? area}) async {
    final q = Uri.encodeComponent(area == null || area.isEmpty ? '약국' : '$area 약국');
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      if (await open('geo:0,0?q=$q')) return true;
    }
    return open('https://map.naver.com/p/search/$q');
  }
}
