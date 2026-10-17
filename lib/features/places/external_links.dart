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

  /// 가까운 약국을 지도 앱에서 검색. Android 는 geo: 로 설치된 지도 앱, 그 외는 네이버 지도 웹.
  static Future<bool> openNearbyPharmacy() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      if (await open('geo:0,0?q=${Uri.encodeComponent('약국')}')) return true;
    }
    return open('https://map.naver.com/p/search/${Uri.encodeComponent('약국')}');
  }
}
