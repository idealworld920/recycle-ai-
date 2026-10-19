import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../app_services.dart';
import '../core/boot_banner.dart';
import '../core/theme/app_sheet.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/auth_store.dart';
import '../features/auth/link_banner.dart';
import '../features/history/history_record.dart';
import '../features/legal/permission_primer.dart';
import '../features/premium/free_limits.dart';
import '../features/premium/premium_gate.dart';
import '../features/schedule/app_actions.dart';
import '../features/schedule/pickup_card.dart';
import '../features/tips/tip_card.dart';
import '../features/tips/tip_model.dart';
import '../features/tips/tips_repository.dart';
import '../services/gemini_classifier.dart';
import '../widgets/app_chip.dart';
import '../widgets/scanning_overlay.dart';
import 'result_screen.dart';
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
  final _picker = ImagePicker();
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
    HapticFeedback.lightImpact();
    final services = AppServices.of(context);

    if (!services.firebase.ready) {
      _showError(services.firebase.error ?? 'AI 서버에 연결하지 못했어요. 설정에서 다시 연결해 주세요.');
      return;
    }
    if (!services.premium.isPremium && services.freeLimits.classifyExhausted) {
      final ok = await ensurePremium(context, reason: '오늘 무료 분류 ${FreeLimits.classifyPerDay}회를 다 썼어요. 프리미엄은 무제한이에요.');
      if (!ok) return;
    }
    if (!mounted) return;
    if (source == ImageSource.camera && !await PermissionPrimer.show(context, PermissionPrimer.camera)) return;
    if (!mounted) return;

    XFile? picked;
    try {
      picked = await _picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 80);
    } catch (_) {
      _showError('사진을 가져오지 못했어요. 카메라와 사진 권한을 확인해 주세요.');
      return;
    }
    if (picked == null) return;

    setState(() => _busy = true);
    final classifier = GeminiClassifier();
    try {
      final bytes = await picked.readAsBytes();
      final mime = picked.mimeType ?? GeminiClassifier.mimeTypeFor(picked.name);
      final result = await classifier.classifyBytes(bytes, mimeType: mime);
      // 모델 응답 뒤의 저장 작업(기록·무료 횟수·도감)은 서로 독립이라 한꺼번에.
      final tip = services.tips.findForItem(result.itemName);
      final results = await Future.wait<Object?>([
        services.history.addResult(result, imageBytes: bytes),
        if (!services.premium.isPremium) services.freeLimits.incrementClassify(),
        if (tip != null) services.collection.collect(tip, itemName: result.itemName) else Future.value(false),
      ]);
      String? toast;
      if (results.last == true) {
        toast = '도감에 추가됐어요 (${services.collection.collected}/${services.collection.total})';
      }
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      await context.pushPage(ResultScreen(result: result, imageBytes: bytes, isNew: true, toast: toast));
    } on ClassifyException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('알 수 없는 오류가 났어요: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
          if (_busy) const Positioned.fill(child: ScanningOverlay()),
        ],
      ),
    );
  }
}
