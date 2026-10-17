import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_ai/models/recycle_category.dart';
import 'package:recycle_ai/models/recycle_result.dart';
import 'package:recycle_ai/services/gemini_classifier.dart';

void main() {
  group('RecycleCategory.fromKey', () {
    test('정확한 키를 찾는다', () {
      expect(RecycleCategory.fromKey('pet'), RecycleCategory.pet);
      expect(RecycleCategory.fromKey('paper_pack'), RecycleCategory.paperPack);
    });

    test('대소문자와 하이픈을 허용한다', () {
      expect(RecycleCategory.fromKey('Paper-Pack '), RecycleCategory.paperPack);
    });

    test('모르는 키는 unknown', () {
      expect(RecycleCategory.fromKey('banana'), RecycleCategory.unknown);
      expect(RecycleCategory.fromKey(null), RecycleCategory.unknown);
    });

    test('재활용 가능 여부', () {
      expect(RecycleCategory.plastic.isRecyclable, isTrue);
      expect(RecycleCategory.general.isRecyclable, isFalse);
      expect(RecycleCategory.food.isRecyclable, isFalse);
    });
  });

  group('RecycleResult.fromAiJson', () {
    const sample = '''
{
  "itemName": "생수 페트병",
  "category": "pet",
  "confidence": 0.93,
  "steps": ["내용물을 비우세요.", "라벨을 제거하세요.", "찌그러뜨려 뚜껑을 닫으세요."],
  "warnings": ["라벨은 비닐로 따로 버려요."],
  "tip": "투명 페트병은 전용 수거함에 넣어요."
}
''';

    test('정상 JSON을 파싱한다', () {
      final r = RecycleResult.fromAiJson(sample);
      expect(r.itemName, '생수 페트병');
      expect(r.category, RecycleCategory.pet);
      expect(r.confidencePercent, 93);
      expect(r.steps.length, 3);
      expect(r.warnings.single, contains('라벨'));
    });

    test('코드 펜스를 벗겨낸다', () {
      final r = RecycleResult.fromAiJson('```json\n$sample\n```');
      expect(r.category, RecycleCategory.pet);
    });

    test('퍼센트 확신도를 0~1로 보정한다', () {
      final r = RecycleResult.fromAiJson('{"itemName":"캔","category":"can","confidence":88,"steps":[],"warnings":[],"tip":""}');
      expect(r.confidence, closeTo(0.88, 0.001));
    });

    test('빈 이름은 기본값으로 채운다', () {
      final r = RecycleResult.fromAiJson('{"itemName":"","category":"unknown","confidence":0.1,"steps":[],"warnings":[],"tip":"흐릿해요"}');
      expect(r.itemName, '알 수 없는 물건');
    });

    test('toMap / fromMap 왕복', () {
      final original = RecycleResult.fromAiJson(sample).copyWith(imagePath: '/tmp/a.jpg');
      final restored = RecycleResult.fromMap(original.toMap());
      expect(restored.itemName, original.itemName);
      expect(restored.category, original.category);
      expect(restored.imagePath, '/tmp/a.jpg');
      expect(restored.createdAt, original.createdAt);
    });
  });

  group('GeminiClassifier.extractText', () {
    test('첫 후보의 텍스트를 꺼낸다', () {
      const body = '{"candidates":[{"content":{"parts":[{"text":"{\\"a\\":1}"}]}}]}';
      expect(GeminiClassifier.extractText(body), '{"a":1}');
    });

    test('후보가 없으면 ClassifyException', () {
      expect(
        () => GeminiClassifier.extractText('{"candidates":[],"promptFeedback":{"blockReason":"SAFETY"}}'),
        throwsA(isA<ClassifyException>()),
      );
    });
  });
}
