import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../app_services.dart';
import '../models/recycle_result.dart';
import '../services/gemini_classifier.dart';
import '../widgets/category_badge.dart';
import '../widgets/scanning_overlay.dart';
import 'result_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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

    if (!services.settings.hasApiKey) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('API 키가 필요해요'),
          content: const Text('AI 판별에는 Google Gemini API 키가 필요해요.\nGoogle AI Studio에서 무료로 만들 수 있어요.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('나중에')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('설정으로 가기')),
          ],
        ),
      );
      if (go == true && mounted) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
      }
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
    final classifier = GeminiClassifier(apiKey: services.settings.apiKey);
    try {
      final bytes = await picked.readAsBytes();
      final mime = picked.mimeType ?? GeminiClassifier.mimeTypeFor(picked.name);
      final result = await classifier.classifyBytes(bytes, mimeType: mime);
      final saved = await services.history.add(result, imageBytes: bytes);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      await Navigator.push(context, MaterialPageRoute(builder: (_) => ResultScreen(result: saved, isNew: true)));
    } on ClassifyException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('알 수 없는 오류가 났어요: $e');
    } finally {
      classifier.dispose();
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
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Row(
                  children: [
                    Text('ReSAI', style: text.titleMedium),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                      icon: const Icon(Icons.settings_outlined),
                      tooltip: '설정',
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text('무엇을 버릴까요?', style: text.displaySmall),
                const SizedBox(height: 8),
                Text('사진 한 장이면 분류와 버리는 방법을 알려드려요.', style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 28),
                _ActionTile(
                  icon: Icons.photo_camera_outlined,
                  title: '사진 찍기',
                  subtitle: '카메라로 바로 촬영',
                  onTap: _busy ? null : () => _pick(ImageSource.camera),
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.photo_outlined,
                  title: '앨범에서 선택',
                  subtitle: '찍어둔 사진으로 판별',
                  onTap: _busy ? null : () => _pick(ImageSource.gallery),
                ),
                const SizedBox(height: 36),
                ListenableBuilder(
                  listenable: services.history,
                  builder: (context, _) => _StatsRow(items: services.history.items),
                ),
                const SizedBox(height: 36),
                ListenableBuilder(
                  listenable: services.history,
                  builder: (context, _) {
                    final recent = services.history.items.take(4).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('최근 판별', style: text.titleLarge),
                        const SizedBox(height: 4),
                        if (recent.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text('아직 판별한 물건이 없어요.', style: text.bodySmall),
                          )
                        else
                          for (var i = 0; i < recent.length; i++) ...[
                            _RecentRow(result: recent[i]),
                            if (i != recent.length - 1) const Divider(),
                          ],
                      ],
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

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.title, required this.subtitle, this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final primary = title == '사진 찍기';
    final bg = primary ? scheme.primary : scheme.surfaceContainer;
    final fg = primary ? scheme.onPrimary : scheme.onSurface;
    final sub = primary ? scheme.onPrimary.withValues(alpha: 0.7) : scheme.onSurfaceVariant;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Row(
            children: [
              Icon(icon, size: 28, color: fg),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.titleLarge?.copyWith(color: fg)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: text.bodySmall?.copyWith(color: sub)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: sub),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.items});

  final List<RecycleResult> items;

  @override
  Widget build(BuildContext context) {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final thisWeek = items.where((r) => r.createdAt.isAfter(weekAgo)).length;
    final recycled = items.where((r) => r.category.isRecyclable).length;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(color: scheme.surfaceContainer, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Expanded(child: _Stat(value: '${items.length}', label: '전체 판별')),
          _VDivider(),
          Expanded(child: _Stat(value: '$thisWeek', label: '이번 주')),
          _VDivider(),
          Expanded(child: _Stat(value: '$recycled', label: '재활용')),
        ],
      ),
    );
  }
}

class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 28, color: Theme.of(context).colorScheme.outline);
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(value, style: text.headlineSmall),
        const SizedBox(height: 2),
        Text(label, style: text.bodySmall),
      ],
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.result});

  final RecycleResult result;

  @override
  Widget build(BuildContext context) {
    final path = result.imagePath;
    final hasImage = path != null && File(path).existsSync();
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ResultScreen(result: result))),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(width: 48, height: 48, child: Image.file(File(path), fit: BoxFit.cover)),
                  )
                : CategoryIcon(category: result.category),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.itemName, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleSmall),
                  const SizedBox(height: 3),
                  Text(result.category.label, style: text.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
