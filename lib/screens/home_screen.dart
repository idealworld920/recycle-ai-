import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../app_services.dart';
import '../models/recycle_result.dart';
import '../services/gemini_classifier.dart';
import '../theme/app_theme.dart';
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
          title: const Text('API 키가 필요해요 🔑'),
          content: const Text('AI 판별에는 Google Gemini API 키가 필요해요.\nGoogle AI Studio에서 무료로 만들 수 있어요.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('나중에')),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('설정으로'),
            ),
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
      _showError('사진을 가져오지 못했어요. 카메라/사진 권한을 확인해 주세요.');
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

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('안녕 👋', style: text.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 2),
                          Text('오늘은 뭐 버려?', style: text.headlineMedium),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                      icon: const Icon(Icons.tune_rounded),
                      tooltip: '설정',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _HeroCard(onCamera: () => _pick(ImageSource.camera), onGallery: () => _pick(ImageSource.gallery), busy: _busy),
                const SizedBox(height: 14),
                ListenableBuilder(
                  listenable: services.history,
                  builder: (context, _) => _StatsRow(items: services.history.items),
                ),
                const SizedBox(height: 28),
                ListenableBuilder(
                  listenable: services.history,
                  builder: (context, _) {
                    final recent = services.history.items.take(4).toList();
                    if (recent.isEmpty) return const _EmptyRecent();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('최근 판별 🕘', style: text.titleLarge),
                        const SizedBox(height: 12),
                        ...recent.map((r) => _RecentTile(result: r)),
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onCamera, required this.onGallery, required this.busy});

  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppShape.card + 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.lime.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text('AI 판별', style: TextStyle(color: AppColors.lime, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
              const Spacer(),
              const Text('♻️', style: TextStyle(fontSize: 26)),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            '찰칵 한 번이면\n분리배출 끝 ✨',
            style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700, height: 1.25, letterSpacing: -0.6),
          ),
          const SizedBox(height: 6),
          Text(
            '어디에 버릴지, 뭘 떼야 하는지까지 알려줘요.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14.5),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: busy ? null : onCamera,
            icon: const Text('📸', style: TextStyle(fontSize: 20)),
            label: const Text('사진 찍기'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: busy ? null : onGallery,
            style: TextButton.styleFrom(foregroundColor: Colors.white, minimumSize: const Size.fromHeight(44)),
            icon: const Icon(Icons.photo_library_outlined, size: 20),
            label: const Text('갤러리에서 고르기'),
          ),
        ],
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
    return Row(
      children: [
        Expanded(child: _StatCard(emoji: '🌍', value: '${recycled * 10}', label: '지구 점수')),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(emoji: '🔥', value: '$thisWeek', label: '이번 주 판별')),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(emoji: '♻️', value: '$recycled', label: '재활용 성공')),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.emoji, required this.value, required this.label});

  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(value, style: text.titleLarge?.copyWith(fontSize: 22)),
            Text(label, style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppShape.card),
      ),
      child: Column(
        children: [
          const Text('🗑️', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 10),
          Text('아직 판별한 게 없어요', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('첫 사진 찍고 지구 점수 받아가요 🌍', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.result});

  final RecycleResult result;

  @override
  Widget build(BuildContext context) {
    final path = result.imagePath;
    final hasImage = path != null && File(path).existsSync();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ResultScreen(result: result))),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(width: 52, height: 52, child: Image.file(File(path), fit: BoxFit.cover)),
                      )
                    : EmojiTile(category: result.category),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(result.itemName, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 6),
                      CategoryBadge(category: result.category),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
