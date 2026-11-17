import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../app_services.dart';
import '../core/mascot.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';
import '../features/classify/classify_flow.dart';
import '../features/classify/multi/multi_classify_screen.dart';
import '../features/onboarding/intro_animation.dart';
import '../features/premium/premium_gate.dart';
import '../widgets/scanning_overlay.dart';

/// 온보딩 직후 바로 뜨는 카메라 화면. 뒤로가기 → 홈.
///
/// 들어오자마자 시스템 카메라를 열고([autoOpen]), 취소하면 이 화면에서 다시 고를 수 있다.
/// 첫 1회만 상단에 리뿅이 말풍선(firstCameraHintShown). 5초 뒤 또는 사진을 고르면 사라진다.
class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key, this.autoOpen = true});

  final bool autoOpen;

  static const hintText = '뭐든 가져와뿅! 리뿅이가 알려주겠뿅!';
  static const hintDuration = Duration(seconds: 5);

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  bool _hint = false;
  bool _busy = false;
  bool _multi = false;
  DateTime? _busySince;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final settings = AppServices.of(context).settings;
      if (!settings.firstCameraHintShown) {
        setState(() => _hint = true);
        settings.markFirstCameraHintShown();
        _hintTimer = Timer(CaptureScreen.hintDuration, _hideHint);
      }
      if (widget.autoOpen) _pick(ImageSource.camera);
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  void _hideHint() {
    _hintTimer?.cancel();
    if (mounted && _hint) setState(() => _hint = false);
  }

  /// "여러 장" 토글: 프리미엄만. 무료는 잠금 아이콘 → 안내.
  Future<void> _toggleMulti(bool on) async {
    if (!on) {
      setState(() => _multi = false);
      return;
    }
    final services = AppServices.of(context);
    if (!services.premium.isPremium) {
      await ensurePremium(context, reason: '여러 장 분류는 프리미엄에서 열려요', source: PaywallSource.multi);
      if (!mounted || !services.premium.isPremium) return;
    }
    setState(() => _multi = true);
  }

  /// 여러 장: 갤러리는 한 번에 최대 10장, 카메라는 한 장씩 찍고 "한 장 더?"를 묻는다.
  Future<void> _pickMulti(ImageSource source) async {
    if (_busy) return;
    final picker = ImagePicker();
    final services = AppServices.of(context);
    final used = services.freeLimits.classifyCountToday();
    final allowance = MultiClassifyScreen.allowance(premium: services.premium.isPremium || services.settings.inFreeGrace, usedToday: used);
    if (allowance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('오늘은 더 분류할 수 없어요. 내일 다시 시도해 주세요.')));
      return;
    }
    List<XFile> files = [];
    try {
      if (source == ImageSource.gallery) {
        files = await picker.pickMultiImage(maxWidth: 1024, maxHeight: 1024, imageQuality: 80, limit: MultiClassifyScreen.maxPhotos);
      } else {
        while (files.length < MultiClassifyScreen.maxPhotos) {
          final x = await picker.pickImage(source: ImageSource.camera, maxWidth: 1024, maxHeight: 1024, imageQuality: 80);
          if (x == null) break;
          files.add(x);
          if (!mounted) return;
          final more = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('${files.length}장 찍었어요'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('분류 시작')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('한 장 더')),
              ],
            ),
          );
          if (more != true) break;
        }
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('사진을 가져오지 못했어요. 카메라와 사진 권한을 확인해 주세요.')));
      return;
    }
    if (files.isEmpty || !mounted) return;
    _hideHint();
    if (files.length > allowance) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오늘 $allowance장까지 가능해요. 앞의 $allowance장만 분류할게요.')));
      files = files.take(allowance).toList();
    }
    await context.pushPage(MultiClassifyScreen(photos: files));
  }

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    if (_multi) return _pickMulti(source);
    await ClassifyFlow.run(
      context,
      source,
      onPicked: _hideHint,
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
    final t = context.text;
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('사진으로 분류')),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _hint
                        ? Row(
                            key: const ValueKey('hint'),
                            children: [
                              const MascotImage(Mascot.wink, size: 48),
                              const SizedBox(width: AppSpacing.xs),
                              const Flexible(child: SpeechBubble(text: CaptureScreen.hintText, tail: BubbleTail.left)),
                            ],
                          )
                        : const SizedBox(height: 48, key: ValueKey('nohint')),
                  ),
                  const Spacer(),
                  Container(
                    width: 96,
                    height: 96,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(AppRadius.sheet)),
                    child: Icon(Symbols.photo_camera_rounded, size: 44, color: c.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('버릴 물건을 찍어 주세요', style: t.headlineSmall, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.md),
                  Text('물건이 잘 보이게 찍으면 더 정확해요. 사진은 저장하지 않아요.',
                      style: t.bodyMedium?.copyWith(color: c.textSecondary), textAlign: TextAlign.center),
                  const Spacer(),
                  ListenableBuilder(
                    listenable: AppServices.of(context).premium,
                    builder: (context, _) {
                      final premium = AppServices.of(context).premium.isPremium;
                      return SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _multi,
                        onChanged: _busy ? null : _toggleMulti,
                        title: Row(
                          children: [
                            Text('여러 장 (최대 ${MultiClassifyScreen.maxPhotos}장)', style: t.bodyMedium),
                            if (!premium) ...[const SizedBox(width: AppSpacing.xs), Icon(Symbols.lock_rounded, size: 16, color: c.textSecondary)],
                          ],
                        ),
                        subtitle: Text(premium ? '한 번에 여러 장을 차례로 분류해요.' : '프리미엄에서 열려요.', style: t.bodySmall),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                    onPressed: _busy ? null : () => _pick(ImageSource.camera),
                    icon: const Icon(Symbols.photo_camera_rounded, size: 24),
                    label: const Text('사진 찍기'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                    icon: const Icon(Symbols.photo_library_rounded, size: 20),
                    label: const Text('갤러리에서 고르기'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: c.textSecondary),
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('나중에 할게요'),
                  ),
                ],
              ),
            ),
          ),
          if (_busy) Positioned.fill(child: ScanningOverlay(startedAt: _busySince)),
        ],
      ),
    );
  }
}
