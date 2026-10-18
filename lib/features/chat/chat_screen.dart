import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_services.dart';
import '../../core/firebase_session.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_chip.dart';
import '../premium/free_limits.dart';
import '../premium/premium_gate.dart';
import 'chat_bubble.dart';
import 'chat_message.dart';
import 'chat_service.dart';
import 'usage_repository.dart';

/// "물어보기" 탭. 대화는 세션 안에서만 유지된다.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  static const suggestions = ['컵라면 용기는?', '깨진 유리는?', '택배 상자 테이프는?'];

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMessage> _messages = [];

  ChatService? _service;
  UsageRepository? _usage;
  int? _remaining;
  bool _sending = false;
  String? _lastFailedText;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = AppServices.of(context).firebase;
    session.removeListener(_onSessionChanged);
    session.addListener(_onSessionChanged);
    _onSessionChanged();
  }

  void _onSessionChanged() {
    final session = AppServices.of(context).firebase;
    final uid = session.uid;
    if (uid != null && _usage?.uid != uid) {
      _service = ChatService();
      _usage = UsageRepository(uid: uid);
      _refreshRemaining();
    }
    if (mounted) setState(() {});
  }

  Future<void> _refreshRemaining() async {
    final usage = _usage;
    if (usage == null) return;
    try {
      final r = (FreeLimits.chatPerDay - await usage.todayCount()).clamp(0, FreeLimits.chatPerDay);
      if (mounted) setState(() => _remaining = r);
    } catch (_) {
      // 오프라인 등. 표시만 못 할 뿐 질문은 시도할 수 있다.
    }
  }

  @override
  void dispose() {
    AppServices.of(context).firebase.removeListener(_onSessionChanged);
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String raw) async {
    final text = raw.trim();
    final service = _service;
    final usage = _usage;
    if (text.isEmpty || _sending || service == null || usage == null) return;

    _controller.clear();
    setState(() {
      _sending = true;
      _lastFailedText = null;
      _messages.removeWhere((m) => m.isError);
      _messages.add(ChatMessage(role: ChatRole.user, text: text));
      _messages.add(const ChatMessage(role: ChatRole.ai, text: '', pending: true));
    });
    _scrollToEnd();

    try {
      final premiumStore = AppServices.of(context).premium;
      final premium = premiumStore.isPremium;
      final count = await usage.todayCount();
      if (!premium && count >= FreeLimits.chatPerDay) {
        _replacePending(ChatMessage(
          role: ChatRole.ai,
          text: premiumStore.available
              ? '오늘 무료 질문 ${FreeLimits.chatPerDay}회를 다 썼어요. 프리미엄은 무제한이에요.'
              : '오늘 무료 질문 ${FreeLimits.chatPerDay}회를 다 썼어요. 내일 다시 물어봐 주세요.',
        ));
        setState(() => _remaining = 0);
        if (mounted) {
          final ok = await ensurePremium(context, reason: '오늘 무료 질문 ${FreeLimits.chatPerDay}회를 다 썼어요.');
          if (ok && mounted) _send(text);
        }
        return;
      }
      final answer = await service.send(text);
      await usage.increment();
      _replacePending(ChatMessage(role: ChatRole.ai, text: answer));
      setState(() => _remaining = premium ? null : (FreeLimits.chatPerDay - count - 1).clamp(0, FreeLimits.chatPerDay));
    } on ChatException catch (e) {
      _lastFailedText = text;
      _replacePending(ChatMessage(role: ChatRole.ai, text: e.message, isError: true));
    } catch (e) {
      _lastFailedText = text;
      _replacePending(ChatMessage(role: ChatRole.ai, text: '문제가 생겼어요: $e', isError: true));
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToEnd();
    }
  }

  void _retry() {
    final text = _lastFailedText;
    if (text == null) return;
    setState(() {
      // 실패한 질문과 에러 말풍선을 지우고 다시 보낸다.
      _messages.removeWhere((m) => m.isError);
      final idx = _messages.lastIndexWhere((m) => m.role == ChatRole.user && m.text == text);
      if (idx >= 0) _messages.removeAt(idx);
    });
    _send(text);
  }

  void _replacePending(ChatMessage m) {
    if (!mounted) return;
    setState(() {
      final i = _messages.lastIndexWhere((x) => x.pending);
      if (i >= 0) {
        _messages[i] = m;
      } else {
        _messages.add(m);
      }
    });
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = AppServices.of(context).firebase;
    final text = context.text;
    final c = context.colors;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: Text('물어보기', style: text.headlineSmall)),
                  if (AppServices.of(context).premium.isPremium)
                    Text('프리미엄 · 무제한', style: text.bodySmall)
                  else if (_remaining != null)
                    Text('오늘 남은 질문 $_remaining/${FreeLimits.chatPerDay}', style: text.bodySmall),
                ],
              ),
            ),
            Expanded(
              child: !session.ready
                  ? _NotReady(session: session)
                  : _messages.isEmpty
                      ? _Welcome(onPick: _send)
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
                          itemCount: _messages.length,
                          itemBuilder: (_, i) => ChatBubble(
                            message: _messages[i],
                            onRetry: _messages[i].isError ? _retry : null,
                          ),
                        ),
            ),
            if (session.ready)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.xs, AppSpacing.base, AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        enabled: !_sending,
                        textInputAction: TextInputAction.send,
                        onSubmitted: _send,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: '이건 어디에 버리나요?',
                          contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.md),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: IconButton.filled(
                        onPressed: _sending ? null : () => _send(_controller.text),
                        style: IconButton.styleFrom(backgroundColor: c.ink, foregroundColor: c.onInk, disabledBackgroundColor: c.surface),
                        icon: _sending
                            ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: c.textSecondary))
                            : const Icon(Symbols.arrow_upward_rounded),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('분리배출, 헷갈리는 거 뭐든 물어보세요.', style: text.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          Text('이런 질문 어때요', style: text.titleSmall),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [for (final s in ChatScreen.suggestions) AppChip(label: s, onTap: () => onPick(s))],
          ),
        ],
      ),
    );
  }
}

class _NotReady extends StatelessWidget {
  const _NotReady({required this.session});

  final FirebaseSession session;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Symbols.cloud_off_rounded, size: 40, color: c.textSecondary),
          const SizedBox(height: AppSpacing.md),
          Text(session.busy ? '연결하는 중이에요' : 'AI 도우미에 연결하지 못했어요', style: text.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(session.error ?? '', textAlign: TextAlign.center, style: text.bodySmall),
          const SizedBox(height: AppSpacing.base),
          if (!session.busy) TextButton(onPressed: session.init, child: const Text('다시 연결')),
        ],
      ),
    );
  }
}
