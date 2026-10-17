#!/usr/bin/env bash
# CI 나 Firebase 없이 빌드만 할 때 쓰는 자리표시자 설정을 만들어요.
# 실제 값은 `flutterfire configure` 가 만드는 lib/firebase_options.dart 와
# android/app/google-services.json 을 쓰고, 이 두 파일은 커밋하지 않아요.
# GitHub Secrets 에 FIREBASE_OPTIONS_DART / GOOGLE_SERVICES_JSON 이 있으면 그 내용을 씁니다.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f lib/firebase_options.dart ]; then
  if [ -n "${FIREBASE_OPTIONS_DART:-}" ]; then
    printf '%s' "$FIREBASE_OPTIONS_DART" > lib/firebase_options.dart
    echo "firebase_options.dart: secret 사용"
  else
    cat > lib/firebase_options.dart <<'DART'
// 자리표시자. 실제 파일은 `flutterfire configure` 로 생성하세요.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => const FirebaseOptions(
        apiKey: 'placeholder',
        appId: '1:000000000000:android:0000000000000000000000',
        messagingSenderId: '000000000000',
        projectId: 'placeholder',
      );
}
DART
    echo "firebase_options.dart: 자리표시자 생성"
  fi
fi

if [ ! -f android/app/google-services.json ]; then
  if [ -n "${GOOGLE_SERVICES_JSON:-}" ]; then
    printf '%s' "$GOOGLE_SERVICES_JSON" > android/app/google-services.json
    echo "google-services.json: secret 사용"
  else
    cat > android/app/google-services.json <<'JSON'
{
  "project_info": {
    "project_number": "000000000000",
    "project_id": "placeholder",
    "storage_bucket": "placeholder.appspot.com"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:000000000000:android:0000000000000000000000",
        "android_client_info": { "package_name": "com.idealworld.recycle_ai" }
      },
      "oauth_client": [],
      "api_key": [ { "current_key": "placeholder" } ],
      "services": { "appinvite_service": { "other_platform_oauth_client": [] } }
    }
  ],
  "configuration_version": "1"
}
JSON
    echo "google-services.json: 자리표시자 생성"
  fi
fi
