import 'package:flutter/material.dart';

import '../app_services.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AppServices.of(context).firebase;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListenableBuilder(
        listenable: session,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text('AI 연결', style: text.titleLarge),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: scheme.surfaceContainer, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Icon(
                    session.ready ? Icons.check_circle_rounded : Icons.cloud_off_outlined,
                    color: session.ready ? scheme.tertiary : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(session.ready ? '연결됨' : (session.busy ? '연결하는 중' : '연결 안 됨'), style: text.titleSmall),
                        if (session.ready && session.uid != null)
                          Text('익명 ID ${session.uid!.substring(0, 6)}…', style: text.bodySmall)
                        else if (session.error != null)
                          Text(session.error!, style: text.bodySmall),
                      ],
                    ),
                  ),
                  if (!session.ready && !session.busy)
                    TextButton(onPressed: session.init, child: const Text('다시 연결')),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('API 키는 앱에 저장되지 않아요. Firebase 가 대신 AI 를 호출해요.', style: text.bodySmall),
            const SizedBox(height: 32),
            Text('앱 정보', style: text.titleLarge),
            const SizedBox(height: 8),
            Text(
              'ReSAI(리사이) 0.1.0\n'
              '사진 한 장으로 올바른 분리배출 방법을 알려주는 앱이에요.\n'
              '판별 결과는 참고용이며, 최종 기준은 거주 지역 지자체 안내를 따라 주세요.',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
