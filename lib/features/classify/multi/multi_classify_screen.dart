import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app_services.dart';
import '../../../core/mascot.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../screens/result_screen.dart';
import '../../../services/gemini_classifier.dart';
import '../../../widgets/category_badge.dart';
import '../../premium/free_limits.dart';
import '../classify_flow.dart';

/// 여러 장 순차 분류 (프리미엄). 최대 [maxPhotos]장, "n/10 분류 중" + 리뿅이 thinking.
/// 결과는 리스트(썸네일·품목·뱃지)로, 탭하면 개별 결과 화면. 실패한 장은 [다시 시도]. 공유는 개별 결과에서만.
class MultiClassifyScreen extends StatefulWidget {
  const MultiClassifyScreen({super.key, required this.photos});

  final List<XFile> photos;

  static const maxPhotos = 10;

  /// 오늘 더 분류할 수 있는 장수. 프리미엄이면 [maxPhotos], 무료면 남은 한도.
  static int allowance({required bool premium, required int usedToday}) =>
      premium ? maxPhotos : (FreeLimits.classifyPerDay - usedToday).clamp(0, maxPhotos);

  @override
  State<MultiClassifyScreen> createState() => _MultiClassifyScreenState();
}

class _MultiItem {
  _MultiItem(this.file);
  final XFile file;
  Uint8List? bytes;
  ClassifiedOne? done;
  String? error;
  bool running = false;
}

class _MultiClassifyScreenState extends State<MultiClassifyScreen> {
  late final List<_MultiItem> _items = widget.photos.take(MultiClassifyScreen.maxPhotos).map(_MultiItem.new).toList();
  bool _busy = false;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runAll());
  }

  Future<void> _runAll() async {
    if (_busy) return;
    setState(() => _busy = true);
    for (var i = 0; i < _items.length; i++) {
      final it = _items[i];
      if (it.done != null) continue;
      setState(() => _current = i);
      await _runOne(it);
      if (!mounted) return;
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _runOne(_MultiItem it) async {
    final services = AppServices.of(context);
    if (!services.premium.isPremium && !services.settings.inFreeGrace && services.freeLimits.classifyExhausted) {
      setState(() => it.error = '오늘 ${FreeLimits.classifyPerDay}장까지 가능해요. 내일 다시 시도해 주세요.');
      return;
    }
    setState(() {
      it.running = true;
      it.error = null;
    });
    try {
      it.bytes ??= await it.file.readAsBytes();
      final mime = it.file.mimeType ?? GeminiClassifier.mimeTypeFor(it.file.name);
      it.done = await ClassifyFlow.classifyOne(services, it.bytes!, mime);
    } on ClassifyException catch (e) {
      it.error = e.message;
    } catch (e) {
      it.error = '분류하지 못했어요. 다시 시도해 주세요.';
    } finally {
      if (mounted) setState(() => it.running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final c = context.colors;
    final doneCount = _items.where((i) => i.done != null).length;
    return Scaffold(
      appBar: AppBar(title: const Text('여러 장 분류')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
        children: [
          if (_busy)
            Row(
              children: [
                const MascotImage(Mascot.thinking, size: 56),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_current + 1}/${_items.length} 분류 중', style: t.titleSmall),
                      const SizedBox(height: AppSpacing.xs),
                      LinearProgressIndicator(value: (_current + 0.5) / _items.length, color: c.primary, backgroundColor: c.surface),
                    ],
                  ),
                ),
              ],
            )
          else
            Text('$doneCount/${_items.length}장 완료', style: t.titleSmall),
          const SizedBox(height: AppSpacing.base),
          for (final it in _items) ...[
            _ItemRow(item: it, onRetry: () => _runOne(it), onOpen: it.done == null ? null : () => context.pushPage(ResultScreen(result: it.done!.result, imageBytes: it.bytes, isNew: false))),
            const Divider(),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text('공유는 각 결과 화면에서 할 수 있어요.', style: t.bodySmall),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.onRetry, required this.onOpen});

  final _MultiItem item;
  final VoidCallback onRetry;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final c = context.colors;
    final done = item.done;
    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.button),
              child: item.bytes == null
                  ? Container(width: 56, height: 56, color: c.surface)
                  : Image.memory(item.bytes!, width: 56, height: 56, fit: BoxFit.cover),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: done != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(done.result.itemName, style: t.titleSmall),
                        const SizedBox(height: AppSpacing.xs),
                        CategoryBadge.of(done.result.category),
                      ],
                    )
                  : item.running
                      ? Text('분류 중…', style: t.bodySmall)
                      : item.error != null
                          ? Text(item.error!, style: t.bodySmall?.copyWith(color: c.error))
                          : Text('대기 중', style: t.bodySmall),
            ),
            if (item.error != null && !item.running)
              TextButton(onPressed: onRetry, child: const Text('다시 시도'))
            else if (done != null)
              Icon(Symbols.chevron_right_rounded, color: c.textSecondary),
          ],
        ),
      ),
    );
  }
}
