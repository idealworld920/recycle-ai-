import 'package:flutter/material.dart';

import '../data/recycling_guide.dart';
import '../theme/app_theme.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('분리배출 가이드 📚', style: text.headlineMedium),
                    const SizedBox(height: 4),
                    Text('헷갈리는 것들, 여기 다 있어요. 오프라인도 OK.', style: text.bodySmall),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _GuideTile(entry: recyclingGuide[i]),
                  childCount: recyclingGuide.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideTile extends StatelessWidget {
  const _GuideTile({required this.entry});

  final GuideEntry entry;

  @override
  Widget build(BuildContext context) {
    final cat = entry.category;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: cat.color.withValues(alpha: isDark ? 0.2 : 0.13),
      borderRadius: BorderRadius.circular(AppShape.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppShape.card),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GuideDetailScreen(entry: entry))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cat.emoji, style: const TextStyle(fontSize: 34)),
              const Spacer(),
              Text(cat.label, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                entry.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
              ),
            ],
          ),
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
    final cat = entry.category;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text('${cat.emoji} ${cat.label}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cat.color.withValues(alpha: isDark ? 0.22 : 0.14),
              borderRadius: BorderRadius.circular(AppShape.card + 4),
            ),
            child: Row(
              children: [
                Expanded(child: Text(entry.summary, style: text.titleMedium)),
                const SizedBox(width: 12),
                Text(cat.emoji, style: const TextStyle(fontSize: 44)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _Section(
            title: '이렇게 버려요 👇',
            items: [for (var i = 0; i < entry.howTo.length; i++) entry.howTo[i]],
            numbered: true,
          ),
          _Section(title: '이런 건 돼요 ✅', items: entry.allowed, chipColor: AppColors.green),
          _Section(title: '이런 건 안 돼요 ❌', items: entry.notAllowed, chipColor: const Color(0xFFEF4444)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('🤔', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(child: Text('이것도 헷갈려요? 사진 찍으면 AI가 바로 알려줘요.', style: text.bodyMedium)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.items, this.numbered = false, this.chipColor});

  final String title;
  final List<String> items;
  final bool numbered;
  final Color? chipColor;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.titleLarge),
          const SizedBox(height: 10),
          if (numbered)
            for (var i = 0; i < items.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(9)),
                      child: Text('${i + 1}', style: const TextStyle(color: AppColors.lime, fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Padding(padding: const EdgeInsets.only(top: 2), child: Text(items[i], style: text.bodyLarge))),
                  ],
                ),
              )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in items)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: (chipColor ?? AppColors.ink).withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(item, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
