import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app_services.dart';
import '../models/recycle_result.dart';
import '../services/gemini_classifier.dart';
import '../widgets/category_badge.dart';
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
    final services = AppServices.of(context);

    if (!services.settings.hasApiKey) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('API 키가 필요해요'),
          content: const Text(
            'AI 판별에는 Google Gemini API 키가 필요해요.\n'
            'Google AI Studio에서 무료로 만들 수 있어요.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('나중에')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('설정으로')),
          ],
        ),
      );
      if (go == true && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
      }
      return;
    }

    XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 82,
      );
    } catch (e) {
      _showError('사진을 가져오지 못했어요. 카메라/사진 권한을 확인해 주세요.');
      return;
    }
    if (picked == null) return;

    setState(() => _busy = true);
    final file = File(picked.path);
    final classifier = GeminiClassifier(apiKey: services.settings.apiKey);
    try {
      final result = await classifier.classify(file);
      final saved = await services.history.add(result, file);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ResultScreen(result: saved)),
      );
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('분리수거 AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '설정',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Card(
                color: scheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.recycling, size: 40, color: scheme.onPrimaryContainer),
                      const SizedBox(height: 12),
                      Text(
                        '이거 어디에 버리지?',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: scheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '사진 한 장이면 AI가 분류와 버리는 방법을 알려드려요.',
                        style: TextStyle(color: scheme.onPrimaryContainer),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 64,
                child: FilledButton.icon(
                  onPressed: _busy ? null : () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 28),
                  label: const Text('사진 찍어서 판별', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('갤러리에서 고르기', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 28),
              ListenableBuilder(
                listenable: services.history,
                builder: (context, _) {
                  final recent = services.history.items.take(5).toList();
                  if (recent.isEmpty) {
                    return const _EmptyRecent();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('최근 판별', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ...recent.map((r) => _RecentTile(result: r)),
                    ],
                  );
                },
              ),
            ],
          ),
          if (_busy)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.45),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'AI가 살펴보는 중...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.eco_outlined, size: 48, color: scheme.outline),
          const SizedBox(height: 8),
          Text(
            '아직 판별한 물건이 없어요.\n첫 사진을 찍어 보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.outline),
          ),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 48,
            height: 48,
            child: hasImage
                ? Image.file(File(path), fit: BoxFit.cover)
                : ColoredBox(
                    color: result.category.color.withValues(alpha: 0.15),
                    child: Icon(result.category.icon, color: result.category.color),
                  ),
          ),
        ),
        title: Text(result.itemName, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: CategoryBadge(category: result.category),
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ResultScreen(result: result)),
        ),
      ),
    );
  }
}
