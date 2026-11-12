import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/mascot.dart';
import '../../models/recycle_result.dart';
import '../../models/waste_group.dart';

/// 공유용 이미지 카드 1080x1350.
///
/// 위: 사용자 사진(없으면 분류 아이콘 자리) / 가운데: 품목명 + 분류 뱃지 + 이유 한 줄 /
/// 아래: 리뿅이(PNG) + "ReSAI" + 짧은 URL. 모두 dart:ui Canvas 로 그려서 새 패키지가 없다.
class ShareCard {
  ShareCard._();

  static const double width = 1080;
  static const double height = 1350;
  static const String shortUrl = 'idealworld920.github.io/recycle-ai-';
  static const String storeHint = 'Google Play 에서 ReSAI 검색';

  /// [groupColor]/[groupSoft] 는 테마 토큰에서 받는다 (Canvas 엔 BuildContext 가 없으므로).
  static Future<Uint8List> render({
    required RecycleResult result,
    Uint8List? photo,
    required Color groupColor,
    required Color groupSoft,
    required Color primary,
    required Color ink,
    required Color surface,
    required Color textSecondary,
    required Color divider,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, width, height));
    const pad = 72.0;
    final rrect = RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, width, height), Radius.zero);
    canvas.drawRRect(rrect, Paint()..color = Colors.white);

    // 1) 사진 영역 (상단 1080x720, 모서리 둥글게)
    const photoRect = Rect.fromLTWH(pad, pad, width - pad * 2, 640);
    final photoR = RRect.fromRectAndRadius(photoRect, const Radius.circular(40));
    canvas.save();
    canvas.clipRRect(photoR);
    canvas.drawRect(photoRect, Paint()..color = surface);
    final img = photo == null ? null : await _decode(photo, targetWidth: 1200);
    if (img != null) {
      _drawCover(canvas, img, photoRect);
      img.dispose();
    } else {
      _drawIcon(canvas, result.category.icon, photoRect.center, 180, groupColor);
    }
    canvas.restore();

    // 2) 품목명 + 뱃지 + 이유
    var y = photoRect.bottom + 56;
    final name = _text(result.itemName, const TextStyle(fontFamily: 'Pretendard', fontSize: 68, fontWeight: FontWeight.w700, color: Color(0xFF111111), height: 1.15), width - pad * 2, maxLines: 2);
    name.paint(canvas, Offset(pad, y));
    y += name.height + 24;

    final badgeLabel = result.category.label;
    final badgeText = _text(badgeLabel, TextStyle(fontFamily: 'Pretendard', fontSize: 30, fontWeight: FontWeight.w600, color: groupColor), 600);
    final badgeRect = RRect.fromRectAndRadius(Rect.fromLTWH(pad, y, badgeText.width + 44, badgeText.height + 22), const Radius.circular(999));
    canvas.drawRRect(badgeRect, Paint()..color = groupSoft);
    badgeText.paint(canvas, Offset(pad + 22, y + 11));
    final verdict = _text(result.category.isRecyclable ? '재활용 가능' : '재활용 불가', TextStyle(fontFamily: 'Pretendard', fontSize: 30, fontWeight: FontWeight.w500, color: textSecondary), 400);
    verdict.paint(canvas, Offset(pad + badgeRect.width + 24, y + 11));
    y += badgeRect.height + 28;

    final reason = result.reason.isNotEmpty ? result.reason : (result.steps.isNotEmpty ? result.steps.first : result.tip);
    if (reason.isNotEmpty) {
      final r = _text('왜? $reason', TextStyle(fontFamily: 'Pretendard', fontSize: 34, fontWeight: FontWeight.w500, color: const Color(0xFF111111), height: 1.4), width - pad * 2, maxLines: 3);
      r.paint(canvas, Offset(pad, y));
      y += r.height;
    }

    // 3) 하단: 구분선 + 리뿅이 + 로고 + URL
    const footerTop = height - 200.0;
    canvas.drawLine(Offset(pad, footerTop - 32), Offset(width - pad, footerTop - 32), Paint()..color = divider..strokeWidth = 2);
    final mascot = await _asset(Mascot.happy.png);
    if (mascot != null) {
      const size = 128.0;
      final src = Rect.fromLTWH(0, 0, mascot.width.toDouble(), mascot.height.toDouble());
      canvas.drawImageRect(mascot, src, Rect.fromLTWH(pad, footerTop, size, size), Paint()..filterQuality = FilterQuality.medium);
      mascot.dispose();
    }
    const textX = pad + 128 + 28;
    // 로고: 파란 둥근 네모 + R
    final logoRect = RRect.fromRectAndRadius(Rect.fromLTWH(textX, footerTop + 6, 52, 52), const Radius.circular(14));
    canvas.drawRRect(logoRect, Paint()..color = primary);
    _text('R', const TextStyle(fontFamily: 'Pretendard', fontSize: 34, fontWeight: FontWeight.w700, color: Colors.white), 52, align: TextAlign.center)
        .paint(canvas, Offset(textX, footerTop + 11));
    _text('ReSAI', TextStyle(fontFamily: 'Pretendard', fontSize: 40, fontWeight: FontWeight.w700, color: ink), 500)
        .paint(canvas, Offset(textX + 64, footerTop + 4));
    _text('찍으면 알려주는 AI 분리수거', TextStyle(fontFamily: 'Pretendard', fontSize: 28, fontWeight: FontWeight.w500, color: textSecondary), 700)
        .paint(canvas, Offset(textX, footerTop + 72));
    _text('$shortUrl  ·  $storeHint', TextStyle(fontFamily: 'Pretendard', fontSize: 24, fontWeight: FontWeight.w400, color: textSecondary), width - textX - pad)
        .paint(canvas, Offset(textX, footerTop + 116));

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    return data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  static TextPainter _text(String s, TextStyle style, double maxWidth, {int maxLines = 1, TextAlign align = TextAlign.left}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: style),
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: maxLines,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    return tp;
  }

  static void _drawIcon(Canvas canvas, IconData icon, Offset center, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(fontFamily: icon.fontFamily, package: icon.fontPackage, fontSize: size, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  static void _drawCover(Canvas canvas, ui.Image img, Rect dst) {
    final scale = (dst.width / img.width).clamp(dst.height / img.height, double.infinity);
    final sw = dst.width / scale, sh = dst.height / scale;
    final src = Rect.fromLTWH((img.width - sw) / 2, (img.height - sh) / 2, sw, sh);
    canvas.drawImageRect(img, src, dst, Paint()..filterQuality = FilterQuality.medium);
  }

  static Future<ui.Image?> _decode(Uint8List bytes, {int? targetWidth}) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: targetWidth);
      final frame = await codec.getNextFrame();
      codec.dispose();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  static Future<ui.Image?> _asset(String key) async {
    try {
      final data = await rootBundle.load(key);
      return await _decode(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    } catch (_) {
      return null;
    }
  }

  /// 재활용 4분류별 기본 색. 테마를 못 쓰는 곳(테스트)용.
  static Color fallbackGroupColor(WasteGroup g) => switch (g) {
        WasteGroup.recycle => const Color(0xFF2563EB),
        WasteGroup.general => const Color(0xFF6B6B6B),
        WasteGroup.food => const Color(0xFFD97706),
        WasteGroup.special => const Color(0xFFDC2626),
      };
}
