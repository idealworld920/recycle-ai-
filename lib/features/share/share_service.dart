import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app_services.dart';
import '../../core/theme/app_theme.dart';
import '../../models/recycle_result.dart';
import 'share_card.dart';

/// 결과 카드를 그려서 시스템 공유 시트(카카오톡 등)로 보낸다. 공유 횟수는 users/{uid}.shareCount 에 누적.
class ShareService {
  ShareService._();

  static Future<bool> shareResult(BuildContext context, {required RecycleResult result, Uint8List? photo}) async {
    final services = AppServices.of(context);
    final c = context.colors;
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    try {
      final png = await ShareCard.render(
        result: result,
        photo: photo,
        groupColor: c.groupColor(result.category.group),
        groupSoft: c.groupSoft(result.category.group),
        primary: c.primary,
        ink: c.ink,
        surface: c.surface,
        textSecondary: c.textSecondary,
        divider: c.divider,
      );
      final text = '${result.itemName}은(는) ${result.category.label}! ${result.reason.isNotEmpty ? result.reason : ''}\n'
          '찍으면 알려주는 AI 분리수거, ReSAI · https://${ShareCard.shortUrl}';
      final ShareResult r;
      if (kIsWeb) {
        r = await SharePlus.instance.share(ShareParams(text: text, sharePositionOrigin: origin));
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/resai_share_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(png, flush: true);
        r = await SharePlus.instance.share(ShareParams(
          files: [XFile(file.path, mimeType: 'image/png', name: 'resai.png')],
          text: text,
          subject: 'ReSAI 분리배출 결과',
          sharePositionOrigin: origin,
        ));
      }
      if (r.status == ShareResultStatus.dismissed) return false;
      // 공유 횟수 누적 (실패해도 조용히)
      unawaitedCount(services);
      return true;
    } catch (e) {
      debugPrint('공유 실패: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('공유 이미지를 만들지 못했어요. 잠시 후 다시 시도해 주세요.')));
      }
      return false;
    }
  }

  static void unawaitedCount(AppServices services) {
    services.auth.service.mergeUserDoc({'shareCount': FieldValue.increment(1), 'lastSharedAt': FieldValue.serverTimestamp()}).catchError((_) {});
  }
}
