import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../app_services.dart';
import '../../core/theme/app_theme.dart';
import '../../models/recycle_result.dart';
import '../../screens/result_screen.dart';
import '../../services/gemini_classifier.dart';
import '../legal/permission_primer.dart';
import '../../core/analytics.dart';
import '../premium/limit_block_sheet.dart';
import '../paywall/paywall_trigger.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    if (!services.premium.isPremium && !services.settings.inFreeGrace && services.freeLimits.classifyExhausted) {
      Analytics.log('classify_limit_hit', {'daily_count': services.freeLimits.classifyCountToday()});
      Analytics.log('classify_fail', {'reason': 'limit'});
      await PaywallTrigger(await SharedPreferences.getInstance()).markLimitHit();
      if (!context.mounted) return;
      final ok = await showLimitBlockSheet(context, kind: LimitKind.classify);
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
    Analytics.log('classify_start', {'source': source == ImageSource.camera ? 'camera' : 'gallery', 'photo_count': 1});

    // 사진 선택 → 결과 표시까지 재서 3초 목표를 지키는지 본다.
    final startedAt = DateTime.now();
    onBusy(startedAt);
    try {
      final bytes = await picked.readAsBytes();
      final mime = picked.mimeType ?? GeminiClassifier.mimeTypeFor(picked.name);
      final one = await classifyOne(services, bytes, mime);
      if (!context.mounted) return;
      final elapsed = DateTime.now().difference(startedAt);
      debugPrint('[classify] ${elapsed.inMilliseconds}ms (목표 3000ms)');
      HapticFeedback.mediumImpact();
      await context.pushPage(ResultScreen(result: one.result, imageBytes: bytes, isNew: true, toast: one.toast, elapsed: elapsed));
    } on ClassifyException catch (e) {
      Analytics.log('classify_fail', {'reason': failReason(e)});
      showError(e.message);
    } catch (e) {
      Analytics.log('classify_fail', {'reason': failReason(e)});
      showError('알 수 없는 오류가 났어요: $e');
    } finally {
      onBusy(null);
    }
  }

  /// classify_fail.reason: network|limit|timeout|unknown (문구에서만 판단, 내용은 보내지 않는다).
  static String failReason(Object e) {
    final m = e.toString();
    if (m.contains('시간') || m.contains('timeout') || m.contains('Timeout')) return 'timeout';
    if (m.contains('인터넷') || m.contains('네트워크') || m.contains('연결') || m.contains('network')) return 'network';
    if (m.contains('한도') || m.contains('다 썼')) return 'limit';
    return 'unknown';
  }

  /// 한 장 분류 + 저장(기록·무료 횟수·도감). 화면 이동은 하지 않는다. 여러 장 분류도 이걸 쓴다.
  static Future<ClassifiedOne> classifyOne(AppServices services, Uint8List bytes, String mimeType) async {
    final sw = Stopwatch()..start();
    final isFirst = !services.settings.firstClassifyDone;
    final result = await GeminiClassifier().classifyBytes(bytes, mimeType: mimeType, regionName: services.region.admin?.displayName);
    sw.stop();
    // 모델 응답 뒤의 저장 작업(기록·무료 횟수·도감)은 서로 독립이라 한꺼번에.
    final tip = services.tips.findForItem(result.itemName);
    final before = services.collection.collected;
    final results = await Future.wait<Object?>([
      services.history.addResult(result, imageBytes: bytes),
      if (!services.premium.isPremium) services.freeLimits.incrementClassify(),
      if (tip != null) services.collection.collect(tip, itemName: result.itemName) else Future.value(false),
    ]);
    Analytics.log('classify_done', {
      'category': result.category.key,
      'recyclable': result.category.isRecyclable,
      'confidence_bucket': Analytics.confidenceBucket(result.confidence),
      'elapsed_ms': sw.elapsedMilliseconds,
      'is_first': isFirst,
    });
    String? toast;
    if (results.last == true) {
      final total = services.collection.collected;
      toast = '도감에 추가됐어요 ($total/${services.collection.total})';
      Analytics.log('collection_unlock', {'item_id': tip!.id, 'total_count': total});
      for (final level in const [10, 30, 50]) {
        if (before < level && total >= level) Analytics.log('badge_earned', {'level': level});
      }
    }
    return ClassifiedOne(result, toast);
  }
}

class ClassifiedOne {
  const ClassifiedOne(this.result, this.toast);
  final RecycleResult result;
  final String? toast;
}
