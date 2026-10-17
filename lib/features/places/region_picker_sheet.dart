import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_services.dart';
import '../../core/theme/app_sheet.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_chip.dart';
import 'region.dart';

/// 시/도 칩 → 시/군/구 목록. 고르면 저장하고 닫힌다.
Future<void> showRegionPickerSheet(BuildContext context) {
  return showAppSheet(
    context,
    title: '내 지역',
    initialSize: 0.85,
    builder: (ctx, controller) => _RegionPicker(controller: controller),
  );
}

class _RegionPicker extends StatefulWidget {
  const _RegionPicker({required this.controller});

  final ScrollController controller;

  @override
  State<_RegionPicker> createState() => _RegionPickerState();
}

class _RegionPickerState extends State<_RegionPicker> {
  String? _sido;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sido ??= AppServices.of(context).region.selected?.sido ?? AppServices.of(context).region.repository.sidos.first;
  }

  @override
  Widget build(BuildContext context) {
    final store = AppServices.of(context).region;
    final repo = store.repository;
    final t = context.text;
    final c = context.colors;
    final list = repo.inSido(_sido!);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('위치 권한 없이 직접 고르는 거라 언제든 바꿀 수 있어요.', style: t.bodySmall),
          ),
        ),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            children: [
              for (final s in repo.sidos) ...[
                AppChip(label: s, selected: s == _sido, onTap: () => setState(() => _sido = s)),
                const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: ListView.separated(
            controller: widget.controller,
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (_, i) {
              final r = list[i];
              final selected = store.selected?.id == r.id;
              return InkWell(
                onTap: () async {
                  await store.select(r);
                  if (context.mounted) Navigator.pop(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(child: Text(r.sigungu, style: selected ? t.titleSmall?.copyWith(color: c.primary) : t.bodyMedium)),
                      if (selected) Icon(Symbols.check_rounded, size: 20, color: c.primary),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 설정 등에서 쓰는 한 줄 표시.
String regionLabel(Region? r) => r?.name ?? '지역을 선택하세요';
