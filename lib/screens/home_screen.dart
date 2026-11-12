import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../app_services.dart';
import '../core/boot_banner.dart';
import '../core/theme/app_sheet.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/auth_store.dart';
import '../features/classify/classify_flow.dart';
import '../features/auth/link_banner.dart';
import '../features/history/history_record.dart';
import '../features/places/region_picker_sheet.dart';
import '../features/stats/stats_calculator.dart';
import '../features/schedule/app_actions.dart';
import '../features/schedule/pickup_card.dart';
import '../features/tips/tip_card.dart';
import '../features/tips/tip_model.dart';
import '../features/tips/tips_repository.dart';
import '../widgets/app_chip.dart';
import '../widgets/scanning_overlay.dart';
import 'settings_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  /// "자주 찾는 품목" 칩에 보여줄 tips.json id 목록.
  /// 기록이 없을 때 보여주는 기본 목록. 기록이 쌓이면 사용자가 실제로 분류한 품목이 앞에 온다.
  static const frequentTipIds = [
    'pet_bottle', 'cup_noodle', 'delivery_box', 'battery', 'broken_glass', 'ice_pack', 'chicken_bone', 'mask', 'coffee_cup',
  ];

  /// 최근 90일 분류 기록에서 많이 나온 품목 순 → 부족하면 기본 목록으로 채운다. 최대 9개.
  static List<Tip> frequentTips(TipsRepository tips, List<HistoryRecord> history, {DateTime? now}) {
    final since = (now ?? DateTime.now()).subtract(const Duration(days: 90));
    final counts = <String, int>{};
    final byId = <String, Tip>{};
    for (final r in history) {
      if (r.date.isBefore(since)) continue;
      final tip = tips.findForItem(r.itemName);
      if (tip == null) continue;
      counts[tip.id] = (counts[tip.id] ?? 0) + 1;
      byId[tip.id] = tip;
    }
    final mine = counts.keys.toList()..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    final out = <Tip>[for (final id in mine) byId[id]!];
    for (final id in frequentTipIds) {
      if (out.length >= 9) break;
      if (out.any((t) => t.id == id)) continue;
      final tip = tips.all.where((x) => x.id == id).firstOrNull;
      if (tip != null) out.add(tip);
    }
    return out;
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? _busySince;
  bool _busy = false;
  int _handledSeq = 0;

  @override
  void initState() {
    super.initState();
    AppActions.instance.pending.addListener(_onAction);
    // 알림으로 앱이 켜진 경우: 첫 프레임 뒤에 처리.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onAction());
  }

  @override
  void dispose() {
    AppActions.instance.pending.removeListener(_onAction);
    super.dispose();
  }

  void _onAction() {
    final action = AppActions.instance.pending.value;
    if (action == null || action.$2 == _handledSeq) return;
    _handledSeq = action.$2;
    if (action.$1 == AppActions.openCamera) {
      Navigator.of(context).popUntil((r) => r.isFirst);
      _pick(ImageSource.camera);
    }
  }

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    await ClassifyFlow.run(
      context,
      source,
      onBusy: (since) {
        if (!mounted) return;
        setState(() {
          _busy = since != null;
          _busySince = since;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = AppServices.of(context);
    final tips = services.tips;
    final t = context.text;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
              children: [
                Row(
                  children: [
                    Text('ReSAI', style: t.titleSmall),
                    const Spacer(),
                    IconButton(
                      onPressed: () => showSettingsSheet(context),
                      icon: const Icon(Symbols.settings_rounded),
                      tooltip: '설정',
                    ),
                  ],
                ),
                const BootBanner(),
                const SizedBox(height: AppSpacing.base),
                ListenableBuilder(
                  listenable: AppServices.of(context).history,
                  builder: (context, _) => AppServices.of(context).history.items.length >= 10
                      ? const LinkBanner(
                          promptKey: AuthStore.keyHistory10,
                          title: '기기 바꿔도 기록 지키기',
                          body: '기록이 10건 넘게 쌓였어요. 구글로 연결해 두면 기기를 바꿔도 그대로예요.',
                        )
                      : const SizedBox.shrink(),
                ),
                Text('오늘은 뭘 버릴까요?', style: t.headlineSmall),
                const SizedBox(height: AppSpacing.lg),
                const PickupCard(),
                const _HomeFooterLines(),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _busy ? null : () => _pick(ImageSource.camera),
                        icon: const Icon(Symbols.photo_camera_rounded, size: 24),
                        label: const Text('사진 찍기'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    SizedBox(
                      width: 96,
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                        style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                        icon: const Icon(Symbols.photo_library_rounded, size: 20),
                        label: const Text('갤러리'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text('자주 찾는 품목', style: t.titleMedium),
                const SizedBox(height: AppSpacing.md),
                ListenableBuilder(
                  listenable: services.history,
                  builder: (context, _) {
                    final frequent = HomeScreen.frequentTips(tips, services.history.items);
                    return SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        itemCount: frequent.length,
                        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (_, i) => AppChip(
                          label: frequent[i].name,
                          onTap: () => showAppSheet(
                            context,
                            initialSize: 0.5,
                            builder: (ctx, controller) => ListView(
                              controller: controller,
                              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                              children: [TipCard(tip: frequent[i])],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          if (_busy) Positioned.fill(child: ScanningOverlay(startedAt: _busySince)),
        ],
      ),
    );
  }
}


/// 수거일 카드 아래 한 줄짜리 안내들: 이번 달 요약(→ 기록 탭), 지역 미설정 안내(→ 지역 설정).
class _HomeFooterLines extends StatelessWidget {
  const _HomeFooterLines();

  @override
  Widget build(BuildContext context) {
    final services = AppServices.of(context);
    final c = context.colors;
    final t = context.text;
    return ListenableBuilder(
      listenable: Listenable.merge([services.history, services.region]),
      builder: (context, _) {
        final summary = StatsCalculator.monthlySummary(services.history.items, DateTime.now());
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (summary.total > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              InkWell(
                borderRadius: BorderRadius.circular(AppSpacing.sm),
                onTap: () => AppActions.instance.fire(AppActions.openHistory),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      Icon(Symbols.bar_chart_rounded, size: 18, color: c.textSecondary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text('이번 달 ${summary.total}개 분류 · 재활용 ${summary.recycleRate ?? 0}%', style: t.bodySmall?.copyWith(color: c.textPrimary))),
                      Icon(Symbols.chevron_right_rounded, size: 18, color: c.textSecondary),
                    ],
                  ),
                ),
              ),
            ],
            if (!services.region.isSet) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(Symbols.location_on_rounded, size: 18, color: c.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text('지역을 설정하면 우리 동네 기준으로 알려드려요', style: t.bodySmall)),
                  TextButton(
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm), minimumSize: const Size(0, 32)),
                    onPressed: () => showRegionPickerSheet(context),
                    child: const Text('설정'),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
