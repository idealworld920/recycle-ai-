import 'dart:io';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../models/recycle_result.dart';
import '../widgets/category_badge.dart';
import 'result_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = AppServices.of(context).history;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: history,
          builder: (context, _) {
            final items = history.items;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('내 판별 기록 🗂️', style: text.headlineMedium),
                          const SizedBox(height: 4),
                          Text(items.isEmpty ? '아직 비어 있어요.' : '지금까지 ${items.length}개 판별했어요.', style: text.bodySmall),
                        ],
                      ),
                    ),
                    if (items.isNotEmpty)
                      IconButton.filledTonal(
                        tooltip: '전체 삭제',
                        icon: const Icon(Icons.delete_sweep_outlined),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('기록을 모두 지울까요?'),
                              content: const Text('지구 점수도 같이 사라져요 😢'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
                                FilledButton(
                                  style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('삭제'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) await history.clear();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Column(
                      children: [
                        const Text('📭', style: TextStyle(fontSize: 56)),
                        const SizedBox(height: 12),
                        Text('첫 판별을 해볼까요?', style: text.titleMedium),
                      ],
                    ),
                  )
                else
                  for (var i = 0; i < items.length; i++)
                    Dismissible(
                      key: ValueKey('${items[i].createdAt.toIso8601String()}-$i'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 22),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onErrorContainer),
                      ),
                      onDismissed: (_) => history.remove(items[i]),
                      child: _HistoryTile(result: items[i]),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.result});

  final RecycleResult result;

  @override
  Widget build(BuildContext context) {
    final path = result.imagePath;
    final hasImage = path != null && File(path).existsSync();
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ResultScreen(result: result))),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(width: 56, height: 56, child: Image.file(File(path), fit: BoxFit.cover)),
                      )
                    : EmojiTile(category: result.category, size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(result.itemName, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleSmall),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          CategoryBadge(category: result.category),
                          const SizedBox(width: 8),
                          Flexible(child: Text(_relative(result.createdAt), style: text.bodySmall, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _relative(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${d.month}/${d.day}';
  }
}
