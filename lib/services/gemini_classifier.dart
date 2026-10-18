import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';

import '../core/ai_backend.dart';
import '../models/recycle_category.dart';
import '../models/recycle_result.dart';

/// 분류 실패를 사용자에게 보여줄 수 있는 메시지로 감싼 예외.
class ClassifyException implements Exception {
  const ClassifyException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Firebase AI Logic(firebase_ai) 로 사진 속 물건의 분리배출 방법을 판별한다.
/// API 키는 앱에 없고, App Check 토큰으로 Firebase 가 대신 호출한다.
class GeminiClassifier {
  GeminiClassifier({GenerativeModel? model}) : _model = model ?? _defaultModel();

  final GenerativeModel _model;

  static const prompt = '''
너는 한국의 분리배출 전문가야. 사진 속 가장 눈에 띄는 쓰레기/물건 하나를 보고
환경부 「재활용품 분리배출 가이드라인」 기준으로 어떻게 버려야 하는지 알려줘.

규칙:
- category 는 반드시 허용 목록 중 하나의 키로만 답해.
- 투명하고 색이 없는 페트병만 "pet", 색이 있거나 다른 플라스틱 용기는 "plastic".
- 우유팩/주스팩은 "paper_pack". 영수증, 코팅지, 기름 묻은 종이는 "general".
- 뼈, 조개껍데기, 과일 씨, 달걀껍질은 "general" (음식물 아님).
- 건전지, 형광등, 약은 "hazardous". 휴대폰, 충전기 같은 전자제품은 "electronics".
- 가구처럼 큰 물건은 "bulky".
- 사진에 쓰레기가 없거나 무엇인지 알 수 없으면 "unknown" 으로 답하고 이유를 tip 에 적어.
- steps 는 실제로 버리기 전에 해야 할 행동을 순서대로 2~5개, 각 한 문장.
- warnings 는 흔히 하는 실수나 주의할 점 0~3개. 없으면 빈 배열.
- tip 은 한 문장짜리 짧은 보충 설명.
- 모든 문장은 한국어 존댓말로, 간결하게.
''';

  static Schema responseSchema() => Schema.object(
        properties: {
          'itemName': Schema.string(description: '사진 속 물건 이름 (한국어)'),
          'category': Schema.enumString(enumValues: RecycleCategory.allKeys),
          'confidence': Schema.number(description: '0.0~1.0 사이의 확신도'),
          'steps': Schema.array(items: Schema.string()),
          'warnings': Schema.array(items: Schema.string()),
          'tip': Schema.string(),
        },
      );

  static GenerativeModel _defaultModel() => aiBackend().generativeModel(
        model: AiBackend.modelName,
        systemInstruction: Content.system(prompt),
        generationConfig: GenerationConfig(
          temperature: 0.2,
          responseMimeType: 'application/json',
          responseSchema: responseSchema(),
        ),
      );

  Future<RecycleResult> classifyBytes(Uint8List bytes, {String mimeType = 'image/jpeg'}) async {
    GenerateContentResponse response;
    try {
      response = await _model.generateContent([
        Content.multi([
          TextPart('이 사진 속 물건의 분리배출 방법을 알려줘.'),
          InlineDataPart(mimeType, bytes),
        ]),
      ]).timeout(const Duration(seconds: 45));
    } catch (e) {
      throw ClassifyException(AiBackend.friendlyAny(e));
    }

    final text = response.text?.trim() ?? '';
    if (text.isEmpty) {
      final reason = response.promptFeedback?.blockReason;
      throw ClassifyException(reason != null ? '사진을 분석할 수 없어요 ($reason).' : 'AI가 답을 주지 않았어요.');
    }
    try {
      return RecycleResult.fromAiJson(text);
    } on FormatException {
      throw const ClassifyException('AI 응답을 읽지 못했어요. 다시 찍어 주세요.');
    }
  }

  static String mimeTypeFor(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }
}
