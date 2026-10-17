import 'package:flutter/material.dart';

import '../data/recycling_guide.dart';
import '../widgets/category_badge.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            Text('분리배출 가이드', style: text.displaySmall),
            const SizedBox(height: 8),
            Text('분류별로 버리는 방법을 정리했어요. 인터넷 없이도 볼 수 있어요.',
                style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            for (var i = 0; i < recyclingGuide.length; i++) ...[
              _GuideRow(entry: recyclingGuide[i]),
              if (i != recyclingGuide.length - 1) const Divider(),
            ],
          ],
        ),
      ),
    );
  }
}

class _GuideRow extends StatelessWidget {
  const _GuideRow({required this.entry});

  final GuideEntry entry;

  @override
  Widget build(BuildContext context) {
    final cat = entry.category;
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GuideDetailScreen(entry: entry))),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            CategoryIcon(category: cat),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat.label, style: text.titleSmall),
                  const SizedBox(height: 3),
                  Text(entry.summary, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        ),
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
    final scheme = Theme.of(context).colorScheme;
    final cat = entry.category;
    return Scaffold(
      appBar: AppBar(title: Text(cat.label)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          CategoryIcon(category: cat, size: 64, radius: 20),
          const SizedBox(height: 16),
          Text(entry.summary, style: text.headlineSmall),
          const SizedBox(height: 28),
          Text('버리는 방법', style: text.titleLarge),
          const SizedBox(height: 4),
          for (var i = 0; i < entry.howTo.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                    child: Text('${i + 1}', style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Padding(padding: const EdgeInsets.only(top: 2), child: Text(entry.howTo[i], style: text.bodyLarge))),
                ],
              ),
            ),
            if (i != entry.howTo.length - 1) const Divider(),
          ],
          const SizedBox(height: 28),
          _ListSection(title: '이런 건 돼요', icon: Icons.check_rounded, iconColor: scheme.tertiary, items: entry.allowed),
          const SizedBox(height: 28),
          _ListSection(title: '이런 건 안 돼요', icon: Icons.close_rounded, iconColor: scheme.error, items: entry.notAllowed),
        ],
      ),
    );
  }
}

class _ListSection extends StatelessWidget {
  const _ListSection({required this.title, required this.icon, required this.iconColor, required this.items});

  final String title;
  final IconData icon;
  final Color iconColor;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: text.titleLarge),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          decoration: BoxDecoration(color: scheme.surfaceContainer, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, size: 18, color: iconColor),
                      const SizedBox(width: 10),
                      Expanded(child: Text(items[i], style: text.bodyMedium)),
                    ],
                  ),
                ),
                if (i != items.length - 1) Divider(color: scheme.surfaceContainerHigh),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
