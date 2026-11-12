import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../app_services.dart';
import '../../core/theme/app_theme.dart';
import '../../screens/result_screen.dart';
import '../../services/gemini_classifier.dart';
import '../legal/permission_primer.dart';
import '../premium/free_limits.dart';
import '../premium/premium_gate.dart';

/// 사진 선택 → AI 분류 → 결과 화면. 홈과 카메라 화면이 같이 쓴다.
///
/// [onBusy] 는 분류가 시작되면 시작 시각, 끝나면 null 로 불린다 (오버레이용).
/// [onPicked] 는 사진이 골라진 직후 (첫 카메라 힌트를 지우는 데 쓴다).
class ClassifyFlow {
  ClassifyFlow._();

  static final _picker = ImagePicker();

  static Future<void> run(
    BuildContext context,
    ImageSource source, {
    required void Function(DateTime? busySince) onBusy,
    VoidCallback? onPicked,
  }) async {
    HapticFeedback.lightImpact();
    final services = AppServices.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    void showError(String message) => messenger?.showSnackBar(SnackBar(content: Text(message)));

    if (!services.firebase.ready) {
      showError(services.firebase.error ?? 'AI 서버에 연결하지 못했어요. 설정에서 다시 연결해 주세요.');
      return;
    }
    if (!services.premium.isPremium && services.freeLimits.classifyExhausted) {
      final ok = await ensurePremium(context, reason: '오늘 무료 분류 ${FreeLimits.classifyPerDay}회를 다 썼어요. 프리미엄은 무제한이에요.');
      if (!ok) return;
    }
    if (!context.mounted) return;
    if (source == ImageSource.camera && !await PermissionPrimer.show(context, PermissionPrimer.camera)) return;
    if (!context.mounted) return;

    XFile? picked;
    try {
      picked = await _picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 80);
    } catch (_) {
      showError('사진을 가져오지 못했어요. 카메라와 사진 권한을 확인해 주세요.');
      return;
    }
    if (picked == null) return;
    onPicked?.call();

    // 사진 선택 → 결과 표시까지 재서 3초 목표를 지키는지 본다.
    final startedAt = DateTime.now();
    onBusy(startedAt);
    final classifier = GeminiClassifier();
    try {
      final bytes = await picked.readAsBytes();
      final mime = picked.mimeType ?? GeminiClassifier.mimeTypeFor(picked.name);
      final result = await classifier.classifyBytes(bytes, mimeType: mime, regionName: services.region.admin?.displayName);
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
      if (!context.mounted) return;
      final elapsed = DateTime.now().difference(startedAt);
      debugPrint('[classify] ${elapsed.inMilliseconds}ms (목표 3000ms)');
      HapticFeedback.mediumImpact();
      await context.pushPage(ResultScreen(result: result, imageBytes: bytes, isNew: true, toast: toast, elapsed: elapsed));
    } on ClassifyException catch (e) {
      showError(e.message);
    } catch (e) {
      showError('알 수 없는 오류가 났어요: $e');
    } finally {
      onBusy(null);
    }
  }
}
