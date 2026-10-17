import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../app_services.dart';
import '../core/theme/app_sheet.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';
import '../features/pickup/pickup_day_card.dart';
import '../features/tips/tip_card.dart';
import '../services/gemini_classifier.dart';
import '../widgets/app_chip.dart';
import '../widgets/scanning_overlay.dart';
import 'result_screen.dart';
import 'settings_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  /// "자주 찾는 품목" 칩에 보여줄 tips.json id 목록.
  static const frequentTipIds = [
    'pet_bottle', 'cup_noodle', 'delivery_box', 'battery', 'broken_glass', 'ice_pack', 'chicken_bone', 'mask', 'coffee_cup',
  ];

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _picker = ImagePicker();
  bool _busy = false;

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    HapticFeedback.lightImpact();
    final services = AppServices.of(context);

    if (!services.firebase.ready) {
      _showError(services.firebase.error ?? 'AI 서버에 연결하지 못했어요. 설정에서 다시 연결해 주세요.');
      return;
    }

    XFile? picked;
    try {
      picked = await _picker.pickImage(source: source, maxWidth: 1280, maxHeight: 1280, imageQuality: 82);
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
      await services.history.addResult(result, imageBytes: bytes);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      await context.pushPage(ResultScreen(result: result, imageBytes: bytes, isNew: true));
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
    final tips = AppServices.of(context).tips;
    final t = context.text;
    final frequent = [
      for (final id in HomeScreen.frequentTipIds)
        ...tips.all.where((x) => x.id == id),
    ];

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
                const SizedBox(height: AppSpacing.base),
                Text('오늘은 뭘 버릴까요?', style: t.headlineSmall),
                const SizedBox(height: AppSpacing.lg),
                const PickupDayCard(),
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
                SizedBox(
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
