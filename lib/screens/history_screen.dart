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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: history,
          builder: (context, _) {
            final items = history.items;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text('판별 기록', style: text.displaySmall)),
                    if (items.isNotEmpty)
                      TextButton(
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('기록을 모두 지울까요?'),
                              content: const Text('지운 기록은 되돌릴 수 없어요.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text('모두 삭제', style: TextStyle(color: scheme.error)),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) await history.clear();
                        },
                        child: Text('모두 삭제', style: TextStyle(color: scheme.onSurfaceVariant)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  items.isEmpty ? '판별한 물건이 여기에 쌓여요.' : '지금까지 ${items.length}개를 판별했어요.',
                  style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 100),
                    child: Column(
                      children: [
                        Icon(Icons.inbox_outlined, size: 44, color: scheme.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text('아직 기록이 없어요', style: text.titleMedium),
                      ],
                    ),
                  )
                else
                  for (var i = 0; i < items.length; i++) ...[
                    Dismissible(
                      key: ValueKey('${items[i].createdAt.toIso8601String()}-$i'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: scheme.errorContainer,
                        child: Icon(Icons.delete_outline_rounded, color: scheme.onErrorContainer),
                      ),
                      onDismissed: (_) => history.remove(items[i]),
                      child: _HistoryRow(result: items[i]),
                    ),
                    if (i != items.length - 1) const Divider(),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.result});

  final RecycleResult result;

  @override
  Widget build(BuildContext context) {
    final path = result.imagePath;
    final hasImage = path != null && File(path).existsSync();
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ResultScreen(result: result))),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(width: 52, height: 52, child: Image.file(File(path), fit: BoxFit.cover)),
                  )
                : CategoryIcon(category: result.category, size: 52),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.itemName, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleSmall),
                  const SizedBox(height: 3),
                  Text('${result.category.label}  ·  ${_relative(result.createdAt)}', style: text.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
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
    return '${d.month}월 ${d.day}일';
  }
}
