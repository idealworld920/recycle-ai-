import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_services.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _controller = TextEditingController();
  bool _obscure = true;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      final settings = AppServices.of(context).settings;
      _controller.text = settings.isUsingBuildTimeKey ? '' : settings.apiKey;
      _loaded = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final settings = AppServices.of(context).settings;
    await settings.saveApiKey(_controller.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_controller.text.trim().isEmpty ? 'API 키를 지웠어요.' : 'API 키를 저장했어요.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppServices.of(context).settings;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          Text('Gemini API 키', style: text.titleLarge),
          const SizedBox(height: 6),
          Text('AI 판별에 사용돼요. 키는 이 기기에만 저장되고 Google 서버로만 전송돼요.',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            obscureText: _obscure,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              hintText: settings.isUsingBuildTimeKey ? '앱에 내장된 키 사용 중 (덮어쓰려면 입력)' : 'AIza… 로 시작하는 키',
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text('키 만드는 방법', style: text.titleLarge),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: scheme.surfaceContainer, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1. Google AI Studio에 접속해요.\n'
                    '2. "Get API key" → "Create API key"를 눌러요.\n'
                    '3. 만들어진 키를 복사해서 위에 붙여 넣어요.\n\n'
                    '무료 등급으로도 충분히 쓸 수 있어요.', style: text.bodyMedium),
                const SizedBox(height: 8),
                TextButton.icon(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () => launchUrl(Uri.parse('https://aistudio.google.com/apikey'), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Google AI Studio 열기'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text('앱 정보', style: text.titleLarge),
          const SizedBox(height: 8),
          Text('ReSAI(리사이) 0.1.0\n'
              '사진 한 장으로 올바른 분리배출 방법을 알려주는 앱이에요.\n'
              '판별 결과는 참고용이며, 최종 기준은 거주 지역 지자체 안내를 따라 주세요.',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: FilledButton(onPressed: _save, child: const Text('저장')),
      ),
    );
  }
}
