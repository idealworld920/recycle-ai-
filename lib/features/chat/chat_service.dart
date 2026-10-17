import 'package:firebase_ai/firebase_ai.dart';

import '../../core/ai_backend.dart';

class ChatException implements Exception {
  const ChatException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// firebase_ai 의 ChatSession 을 감싼 분리배출 도우미. 대화는 메모리에만 있다.
class ChatService {
  ChatService({GenerativeModel? model}) : _model = model ?? _defaultModel() {
    _chat = _model.startChat();
  }

  static const systemPrompt =
      "너는 ReSAI의 분리배출 도우미. 한국 환경부 기준으로 답하고, 지자체별로 다를 수 있으면 '거주 지역 확인 필요'라고 덧붙여. 3문장 이내, 친근한 존댓말.";

  final GenerativeModel _model;
  late ChatSession _chat;

  static GenerativeModel _defaultModel() => aiBackend().generativeModel(
        model: AiBackend.modelName,
        systemInstruction: Content.system(systemPrompt),
        generationConfig: GenerationConfig(temperature: 0.4, maxOutputTokens: 300),
      );

  Future<String> send(String text) async {
    try {
      final res = await _chat.sendMessage(Content.text(text)).timeout(const Duration(seconds: 40));
      final answer = res.text?.trim();
      if (answer == null || answer.isEmpty) throw const ChatException('답변이 비어 있어요. 다시 물어봐 주세요.');
      return answer;
    } on ChatException {
      rethrow;
    } on FirebaseAIException catch (e) {
      throw ChatException(AiBackend.friendlyError(e));
    } catch (e) {
      throw ChatException('요청 중 문제가 생겼어요: $e');
    }
  }

  void reset() => _chat = _model.startChat();
}
