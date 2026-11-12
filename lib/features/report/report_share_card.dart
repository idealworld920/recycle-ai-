import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/mascot.dart';
import '../share/share_card.dart';
import 'report_calculator.dart';

/// 월간 리포트 공유 이미지. 1080x1350(피드) / 1080x1920(스토리).
class ReportShareCard {
  ReportShareCard._();

  static const caption = '탄소 절감량은 공개 자료 기반 참고용 추정치이며 실제 절감량과 다를 수 있습니다.';

  static Future<Uint8List> render(
    MonthlyReport report, {
    bool story = false,
    required Color primary,
    required Color ink,
    required Color surface,
    required Color textSecondary,
    required Color divider,
  }) async {
    final w = ShareCard.width;
    final h = story ? 1920.0 : 1350.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.white);
    const pad = 72.0;
    var y = story ? 220.0 : 96.0;

    _t('ReSAI 월간 리포트', TextStyle(fontFamily: 'Pretendard', fontSize: 30, fontWeight: FontWeight.w600, color: textSecondary), w - pad * 2).paint(canvas, Offset(pad, y));
    y += 48;
    _t(report.title, TextStyle(fontFamily: 'Pretendard', fontSize: 72, fontWeight: FontWeight.w700, color: ink, height: 1.15), w - pad * 2).paint(canvas, Offset(pad, y));
    y += story ? 150 : 120;

    // 핵심 숫자 3개
    final showCarbon = report.carbon.showable;
    final tiles = <(String, String, String)>[
      ('분류', '${report.total}', '개'),
      ('재활용률', report.recycleRate == null ? '-' : '${report.recycleRate}', '%'),
      if (showCarbon) ('탄소 절감', '약 ${report.carbon.kg.toStringAsFixed(1)}', 'kg') else ('수거일 체크', '${report.checkinCount}', '회'),
    ];
    final tileW = (w - pad * 2 - 24 * 2) / 3;
    final tileH = story ? 300.0 : 260.0;
    for (var i = 0; i < tiles.length; i++) {
      final x = pad + i * (tileW + 24);
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(x, y, tileW, tileH), const Radius.circular(36));
      canvas.drawRRect(r, Paint()..color = surface);
      _t(tiles[i].$1, TextStyle(fontFamily: 'Pretendard', fontSize: 28, fontWeight: FontWeight.w500, color: textSecondary), tileW - 40)
          .paint(canvas, Offset(x + 28, y + 30));
      final big = _t(tiles[i].$2, TextStyle(fontFamily: 'Pretendard', fontSize: tiles[i].$2.length > 6 ? 54 : 72, fontWeight: FontWeight.w700, color: i == 0 ? primary : ink), tileW - 40);
      big.paint(canvas, Offset(x + 28, y + tileH - 40 - big.height - 44));
      _t(tiles[i].$3, TextStyle(fontFamily: 'Pretendard', fontSize: 28, fontWeight: FontWeight.w500, color: textSecondary), tileW - 40)
          .paint(canvas, Offset(x + 28, y + tileH - 40 - 32));
    }
    y += tileH + 40;

    if (report.topItems.isNotEmpty) {
      _t('가장 많이 분류한 품목', TextStyle(fontFamily: 'Pretendard', fontSize: 30, fontWeight: FontWeight.w600, color: ink), w - pad * 2).paint(canvas, Offset(pad, y));
      y += 52;
      for (var i = 0; i < report.topItems.length; i++) {
        final it = report.topItems[i];
        _t('${i + 1}. ${it.name}', TextStyle(fontFamily: 'Pretendard', fontSize: 34, fontWeight: FontWeight.w500, color: ink), w - pad * 2 - 160)
            .paint(canvas, Offset(pad, y));
        final cnt = _t('${it.count}회', TextStyle(fontFamily: 'Pretendard', fontSize: 30, fontWeight: FontWeight.w500, color: textSecondary), 160, align: TextAlign.right);
        cnt.paint(canvas, Offset(w - pad - 160, y + 2));
        y += 52;
      }
    }

    // 하단: 마스코트(idle PNG) + 로고 + URL + 추정치 문구
    final footerTop = h - (showCarbon ? 260 : 220);
    canvas.drawLine(Offset(pad, footerTop - 28), Offset(w - pad, footerTop - 28), Paint()..color = divider..strokeWidth = 2);
    final mascot = await _asset(Mascot.idle.png);
    if (mascot != null) {
      final src = Rect.fromLTWH(0, 0, mascot.width.toDouble(), mascot.height.toDouble());
      final scale = 128 / mascot.height;
      canvas.drawImageRect(mascot, src, Rect.fromLTWH(pad, footerTop, mascot.width * scale, 128), Paint()..filterQuality = FilterQuality.medium);
      mascot.dispose();
    }
    const textX = pad + 128 + 28;
    final logoRect = RRect.fromRectAndRadius(Rect.fromLTWH(textX, footerTop + 6, 52, 52), const Radius.circular(14));
    canvas.drawRRect(logoRect, Paint()..color = primary);
    _t('R', const TextStyle(fontFamily: 'Pretendard', fontSize: 34, fontWeight: FontWeight.w700, color: Colors.white), 52, align: TextAlign.center).paint(canvas, Offset(textX, footerTop + 11));
    _t('ReSAI', TextStyle(fontFamily: 'Pretendard', fontSize: 40, fontWeight: FontWeight.w700, color: ink), 500).paint(canvas, Offset(textX + 64, footerTop + 4));
    _t('찍으면 알려주는 AI 분리수거  ·  ${ShareCard.shortUrl}', TextStyle(fontFamily: 'Pretendard', fontSize: 26, fontWeight: FontWeight.w500, color: textSecondary), w - textX - pad)
        .paint(canvas, Offset(textX, footerTop + 72));
    if (showCarbon) {
      _t(caption, TextStyle(fontFamily: 'Pretendard', fontSize: 22, fontWeight: FontWeight.w400, color: textSecondary), w - pad * 2, maxLines: 2)
          .paint(canvas, Offset(pad, footerTop + 150));
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(w.toInt(), h.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    return data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  static TextPainter _t(String s, TextStyle style, double maxWidth, {int maxLines = 1, TextAlign align = TextAlign.left}) =>
      TextPainter(text: TextSpan(text: s, style: style), textDirection: TextDirection.ltr, textAlign: align, maxLines: maxLines, ellipsis: '…')
        ..layout(maxWidth: maxWidth);

  static Future<ui.Image?> _asset(String key) async {
    try {
      final data = await rootBundle.load(key);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      final frame = await codec.getNextFrame();
      codec.dispose();
      return frame.image;
    } catch (_) {
      return null;
    }
  }
}
