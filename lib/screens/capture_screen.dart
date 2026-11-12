import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../app_services.dart';
import '../core/mascot.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';
import '../features/classify/classify_flow.dart';
import '../features/onboarding/intro_animation.dart';
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

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
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
