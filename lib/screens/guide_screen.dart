import 'package:flutter/material.dart';

import '../data/recycling_guide.dart';
import '../widgets/category_badge.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('분리배출 가이드')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: recyclingGuide.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final entry = recyclingGuide[i];
          final cat = entry.category;
          return Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: cat.color.withValues(alpha: 0.15),
                child: Icon(cat.icon, color: cat.color),
              ),
              title: Text(cat.label, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(entry.summary, maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => GuideDetailScreen(entry: entry)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class GuideDetailScreen extends StatelessWidget {
  const GuideDetailScreen({super.key, required this.entry});

  final GuideEntry entry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final cat = entry.category;
    return Scaffold(
      appBar: AppBar(title: Text(cat.label)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          CategoryBadge(category: cat, large: true),
          const SizedBox(height: 12),
          Text(entry.summary, style: text.titleMedium),
          const SizedBox(height: 20),
          _Section(
            title: '버리는 방법',
            icon: Icons.format_list_numbered,
            color: cat.color,
            items: [
              for (var i = 0; i < entry.howTo.length; i++) '${i + 1}. ${entry.howTo[i]}',
            ],
          ),
          _Section(
            title: '이런 건 돼요',
            icon: Icons.check_circle_outline,
            color: Colors.green,
            items: entry.allowed.map((e) => '• $e').toList(),
          ),
          _Section(
            title: '이런 건 안 돼요',
            icon: Icons.block,
            color: Colors.red,
            items: entry.notAllowed.map((e) => '• $e').toList(),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 10),
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(item, style: Theme.of(context).textTheme.bodyLarge),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
