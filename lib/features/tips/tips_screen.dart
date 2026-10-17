import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_services.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_chip.dart';
import 'tip_card.dart';
import 'tip_model.dart';

/// 검색창 + 분류 칩 + 팁 카드 리스트.
class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key, this.initialQuery = '', this.showBackButton = false});

  final String initialQuery;
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
    final t = context.text;
    final c = context.colors;
    final results = repo.search(_controller.text, category: _category);

    final body = ListView(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, widget.showBackButton ? AppSpacing.xs : AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
      children: [
        if (!widget.showBackButton) ...[
          Text('분리배출 팁', style: t.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text('품목 이름으로 찾아보세요. 환경부 기준으로 정리했어요.', style: t.bodySmall),
          const SizedBox(height: AppSpacing.lg),
        ],
        TextField(
          controller: _controller,
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: '예: 페트병, 치킨 뼈, 건전지',
            prefixIcon: Icon(Symbols.search_rounded, color: c.textSecondary),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(icon: const Icon(Symbols.close_rounded), onPressed: () => setState(_controller.clear)),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              AppChip(label: '전체', selected: _category == null, onTap: () => setState(() => _category = null)),
              for (final cat in TipCategory.values) ...[
                const SizedBox(width: AppSpacing.sm),
                AppChip(
                  label: cat.label,
                  selected: _category == cat,
                  onTap: () => setState(() => _category = _category == cat ? null : cat),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        if (results.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxl * 2),
            child: Column(
              children: [
                Icon(Symbols.search_off_rounded, size: 40, color: c.textSecondary),
                const SizedBox(height: AppSpacing.sm),
                Text('찾는 품목이 없어요', style: t.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text('다른 이름으로 검색하거나 사진으로 판별해 보세요.', style: t.bodySmall),
              ],
            ),
          )
        else ...[
          Text('${results.length}개', style: t.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          for (final tip in results) ...[
            TipCard(tip: tip),
            const SizedBox(height: AppSpacing.sm),
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
