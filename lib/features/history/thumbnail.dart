import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// 사진 바이트를 작은 PNG 로 줄여 base64 로 돌려준다. 크기 제한을 못 맞추면 null.
///
/// 새 패키지 없이 dart:ui 로만 처리하므로 모바일·웹 모두에서 동작한다.
Future<String?> makeThumbBase64(Uint8List bytes, {int maxBytes = 10 * 1024}) async {
  for (final side in const [96, 72, 56, 40]) {
    try {
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: side, targetHeight: side);
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      frame.image.dispose();
      codec.dispose();
      if (data == null) continue;
      final encoded = base64Encode(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      if (encoded.length <= maxBytes) return encoded;
    } catch (_) {
      return null;
    }
  }
  return null;
}
