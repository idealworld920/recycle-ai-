import 'package:firebase_ai/firebase_ai.dart';

/// Gemini 를 어느 경로로 부를지 한 곳에서 정한다.
///
/// - `vertexAI()` : Vertex AI 경로. 콘솔에서 Vertex AI API 를 켜야 하고 Blaze 요금제 필요. 리전은 [location]
/// - `googleAI()` : Gemini Developer API (무료 Spark 요금제에서도 동작)
/// 둘 다 API 키는 앱에 들어가지 않고 Firebase App Check 로 보호된다.
class AiBackend {
  AiBackend._();

  /// Vertex AI 경로 사용. 무료 Spark 요금제로 돌릴 땐 false 로.
  static const bool useVertexAI = true;

  /// Vertex AI 리전. global 은 가장 가까운 리전으로 자동 라우팅.
  static const String location = 'global';
  /// 채팅·사진 분류가 함께 쓰는 모델. 여기 한 곳만 바꾸면 된다.
  static const String modelName = 'gemini-3.8-flash';

  static String friendlyError(FirebaseAIException e) {
    final m = e.message;
    if (m.contains('App Check') || m.contains('app-check')) return 'App Check 인증에 실패했어요. 디버그 토큰을 등록했는지 확인해 주세요.';
    if (m.contains('PERMISSION_DENIED') || m.contains('403')) return 'Firebase 콘솔에서 AI API 가 켜져 있는지 확인해 주세요.';
    if (m.contains('RESOURCE_EXHAUSTED') || m.contains('429')) return '요청이 너무 많아요. 잠시 후 다시 시도해 주세요.';
    if (m.contains('network') || m.contains('Failed host lookup')) return '인터넷 연결을 확인해 주세요.';
    return 'AI 호출에 실패했어요: $m';
  }
}

FirebaseAI aiBackend() => AiBackend.useVertexAI
    // firebase_ai 4.x 에서 vertexAI() 는 agentPlatform() 으로 이름이 바뀌는 중이라 deprecated 표시가 뜨지만 동작은 같다.
    // ignore: deprecated_member_use
    ? FirebaseAI.vertexAI(location: AiBackend.location)
    : FirebaseAI.googleAI();
