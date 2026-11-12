import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_services.dart';
import '../../core/theme/app_sheet.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import 'admin_region.dart';
import 'region.dart';

/// 거주 지역 선택: 검색창 + 시/도 → 시/군/구 2단계. 고르면 저장하고 닫힌다.
Future<void> showRegionPickerSheet(BuildContext context) {
  return showAppSheet(
    context,
    title: '거주 지역',
    initialSize: 0.9,
    builder: (ctx, controller) => _RegionPicker(controller: controller),
  );
}

/// 예전 호출부 호환.
String regionLabel(Region? r) => r?.name ?? '지역을 선택하세요';

class _RegionPicker extends StatefulWidget {
  const _RegionPicker({required this.controller});

  final ScrollController controller;

  @override
  State<_RegionPicker> createState() => _RegionPickerState();
}

class _RegionPickerState extends State<_RegionPicker> {
  final _search = TextEditingController();
  AdminSido? _sido;
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _pick(AdminSigungu s) async {
    final store = AppServices.of(context).region;
    Navigator.of(context).pop();
    await store.selectAdmin(s);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppServices.of(context).region;
    final repo = store.adminRepository;
    final t = context.text;
    final c = context.colors;

    if (repo.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text('지역 데이터를 불러오지 못했어요.', style: t.bodyMedium),
      );
    }

    final results = _query.isEmpty ? const <AdminSigungu>[] : repo.search(_query);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
          child: TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: '시/군/구 검색 (예: 마포, 수원 장안)',
              prefixIcon: const Icon(Symbols.search_rounded, size: 20),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Symbols.close_rounded, size: 18),
                      onPressed: () => setState(() {
                        _search.clear();
                        _query = '';
                      }),
                    ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('위치 권한은 쓰지 않아요. 직접 고르고 언제든 바꿀 수 있어요.', style: t.bodySmall),
          ),
        ),
        Expanded(
          child: _query.isNotEmpty
              ? _SigunguList(items: results, controller: widget.controller, selected: store.code, onPick: _pick, emptyText: '검색 결과가 없어요')
              : _sido == null
                  ? _SidoList(sidos: repo.sidos, controller: widget.controller, current: store.admin, onPick: (s) => setState(() => _sido = s))
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.lg, 0),
                          child: Row(
                            children: [
                              IconButton(onPressed: () => setState(() => _sido = null), icon: const Icon(Symbols.arrow_back_rounded)),
                              Text(_sido!.name, style: t.titleSmall),
                              const Spacer(),
                              Text('${_sido!.sigungu.length}곳', style: t.bodySmall?.copyWith(color: c.textSecondary)),
                            ],
                          ),
                        ),
                        Expanded(child: _SigunguList(items: _sido!.sigungu, controller: widget.controller, selected: store.code, onPick: _pick)),
                      ],
                    ),
        ),
      ],
    );
  }
}

class _SidoList extends StatelessWidget {
  const _SidoList({required this.sidos, required this.controller, required this.current, required this.onPick});

  final List<AdminSido> sidos;
  final ScrollController controller;
  final AdminSigungu? current;
  final ValueChanged<AdminSido> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
      itemCount: sidos.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final s = sidos[i];
        final isCurrent = current?.sidoCode == s.code;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(s.name, style: t.bodyMedium?.copyWith(color: c.textPrimary)),
          subtitle: isCurrent ? Text('현재: ${current!.name}', style: t.bodySmall?.copyWith(color: c.primary)) : null,
          trailing: Icon(Symbols.chevron_right_rounded, color: c.textSecondary),
          onTap: () => onPick(s),
        );
      },
    );
  }
}

class _SigunguList extends StatelessWidget {
  const _SigunguList({required this.items, required this.controller, required this.selected, required this.onPick, this.emptyText});

  final List<AdminSigungu> items;
  final ScrollController controller;
  final String? selected;
  final ValueChanged<AdminSigungu> onPick;
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    if (items.isEmpty) {
      return Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Text(emptyText ?? '', style: t.bodySmall));
    }
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final s = items[i];
        final on = s.code == selected;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(s.displayName, style: t.bodyMedium?.copyWith(color: on ? c.primary : c.textPrimary, fontWeight: on ? FontWeight.w600 : null)),
          trailing: on ? Icon(Symbols.check_rounded, color: c.primary) : null,
          onTap: () => onPick(s),
        );
      },
    );
  }
}
