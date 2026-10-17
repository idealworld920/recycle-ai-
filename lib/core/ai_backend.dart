import 'package:firebase_ai/firebase_ai.dart';

/// Gemini 를 어느 경로로 부를지 한 곳에서 정한다.
///
/// - `agentPlatform()` : Vertex AI(Gemini Enterprise) 경로. 콘솔에서 Vertex AI API 를 켜야 하고 Blaze 요금제 필요
/// - `googleAI()` : Gemini Developer API (무료 Spark 요금제에서도 동작)
/// 둘 다 API 키는 앱에 들어가지 않고 Firebase App Check 로 보호된다.
class AiBackend {
  AiBackend._();

  /// Spark(무료) 요금제에서는 false. Blaze 로 올리고 Vertex AI 를 쓰려면 true.
  static const bool useVertexAI = false;
  static const String modelName = 'gemini-2.0-flash';

  static String friendlyError(FirebaseAIException e) {
    final m = e.message;
    if (m.contains('App Check') || m.contains('app-check')) return 'App Check 인증에 실패했어요. 디버그 토큰을 등록했는지 확인해 주세요.';
    if (m.contains('PERMISSION_DENIED') || m.contains('403')) return 'Firebase 콘솔에서 AI API 가 켜져 있는지 확인해 주세요.';
    if (m.contains('RESOURCE_EXHAUSTED') || m.contains('429')) return '요청이 너무 많아요. 잠시 후 다시 시도해 주세요.';
    if (m.contains('network') || m.contains('Failed host lookup')) return '인터넷 연결을 확인해 주세요.';
    return 'AI 호출에 실패했어요: $m';
  }
}

FirebaseAI aiBackend() => AiBackend.useVertexAI ? FirebaseAI.agentPlatform() : FirebaseAI.googleAI();
