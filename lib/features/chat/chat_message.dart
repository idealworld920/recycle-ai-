enum ChatRole { user, ai }

/// 세션 안에서만 사는 말풍선 하나.
class ChatMessage {
  const ChatMessage({required this.role, required this.text, this.isError = false, this.pending = false});

  final ChatRole role;
  final String text;

  /// 전송 실패 메시지. 재시도 버튼을 보여준다.
  final bool isError;

  /// AI 응답을 기다리는 중.
  final bool pending;

  ChatMessage copyWith({String? text, bool? isError, bool? pending}) =>
      ChatMessage(role: role, text: text ?? this.text, isError: isError ?? this.isError, pending: pending ?? this.pending);
}
