import 'package:flutter/material.dart';

import '../../app_services.dart';
import 'tip_card.dart';
import 'tip_model.dart';

/// 검색창 + 분류 칩 + 팁 카드 리스트.
class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key, this.initialQuery = '', this.showBackButton = false});

  /// 결과 화면에서 "팁 더 보기"로 들어올 때 미리 채울 검색어.
  final String initialQuery;

  /// 탭이 아니라 push 로 열렸을 때 앱바를 보여준다.
  final bool showBackButton;

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialQuery);
  TipCategory? _category;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppServices.of(context).tips;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final results = repo.search(_controller.text, category: _category);

    final body = ListView(
      padding: EdgeInsets.fromLTRB(20, widget.showBackButton ? 4 : 20, 20, 24),
      children: [
        if (!widget.showBackButton) ...[
          Text('분리배출 팁', style: text.displaySmall),
          const SizedBox(height: 8),
          Text('품목 이름으로 찾아보세요. 환경부 기준으로 정리했어요.',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 20),
        ],
        TextField(
          controller: _controller,
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: '예: 페트병, 치킨 뼈, 건전지',
            prefixIcon: Icon(Icons.search_rounded, color: scheme.onSurfaceVariant),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => setState(_controller.clear),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(label: '전체', selected: _category == null, onTap: () => setState(() => _category = null)),
              for (final c in TipCategory.values) ...[
                const SizedBox(width: 8),
                _FilterChip(
                  label: c.label,
                  dot: c.color,
                  selected: _category == c,
                  onTap: () => setState(() => _category = _category == c ? null : c),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (results.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Column(
              children: [
                Icon(Icons.search_off_rounded, size: 40, color: scheme.onSurfaceVariant),
                const SizedBox(height: 10),
                Text('찾는 품목이 없어요', style: text.titleMedium),
                const SizedBox(height: 4),
                Text('다른 이름으로 검색하거나 사진으로 판별해 보세요.', style: text.bodySmall),
              ],
            ),
          )
        else ...[
          Text('${results.length}개', style: text.labelMedium),
          const SizedBox(height: 8),
          for (final tip in results) ...[
            TipCard(tip: tip),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );

    if (widget.showBackButton) {
      return Scaffold(appBar: AppBar(title: const Text('분리배출 팁')), body: body);
    }
    return Scaffold(body: SafeArea(child: body));
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap, this.dot});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primary : scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dot != null) ...[
                Container(width: 7, height: 7, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
