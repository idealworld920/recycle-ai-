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
    return Scaffold(
      appBar: AppBar(
        title: const Text('판별 기록'),
        actions: [
          ListenableBuilder(
            listenable: history,
            builder: (context, _) => history.items.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: '전체 삭제',
                    icon: const Icon(Icons.delete_sweep_outlined),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('기록을 모두 지울까요?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
                            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제')),
                          ],
                        ),
                      );
                      if (ok == true) await history.clear();
                    },
                  ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: history,
        builder: (context, _) {
          final items = history.items;
          if (items.isEmpty) {
            return Center(
              child: Text('아직 기록이 없어요.',
                  style: TextStyle(color: Theme.of(context).colorScheme.outline)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final r = items[i];
              return Dismissible(
                key: ValueKey('${r.createdAt.toIso8601String()}-$i'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onErrorContainer),
                ),
                onDismissed: (_) => history.remove(r),
                child: _HistoryTile(result: r),
              );
            },
          );
        },
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
    final d = result.createdAt;
    final when =
        '${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 56,
            height: 56,
            child: hasImage
                ? Image.file(File(path), fit: BoxFit.cover)
                : ColoredBox(
                    color: result.category.color.withValues(alpha: 0.15),
                    child: Icon(result.category.icon, color: result.category.color),
                  ),
          ),
        ),
        title: Text(result.itemName, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              CategoryBadge(category: result.category),
              const SizedBox(width: 8),
              Text(when, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ResultScreen(result: result)),
        ),
      ),
    );
  }
}
