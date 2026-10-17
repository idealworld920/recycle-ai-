import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/recycle_category.dart';
import '../models/recycle_result.dart';

/// 분류 실패를 사용자에게 보여줄 수 있는 메시지로 감싼 예외.
class ClassifyException implements Exception {
  const ClassifyException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Gemini 멀티모달 API로 사진 속 물건의 분리배출 방법을 판별한다.
class GeminiClassifier {
  GeminiClassifier({
    required this.apiKey,
    this.model = 'gemini-2.5-flash',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiKey;
  final String model;
  final http.Client _client;

  static const _endpoint = 'https://generativelanguage.googleapis.com/v1beta/models';

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

  Map<String, dynamic> get _responseSchema => {
        'type': 'OBJECT',
        'properties': {
          'itemName': {'type': 'STRING', 'description': '사진 속 물건 이름 (한국어)'},
          'category': {'type': 'STRING', 'enum': RecycleCategory.allKeys},
          'confidence': {'type': 'NUMBER', 'description': '0.0~1.0 사이의 확신도'},
          'steps': {
            'type': 'ARRAY',
            'items': {'type': 'STRING'},
          },
          'warnings': {
            'type': 'ARRAY',
            'items': {'type': 'STRING'},
          },
          'tip': {'type': 'STRING'},
        },
        'required': ['itemName', 'category', 'confidence', 'steps', 'warnings', 'tip'],
      };

  Future<RecycleResult> classify(File image) async {
    final bytes = await image.readAsBytes();
    return classifyBytes(bytes, mimeType: _mimeTypeFor(image.path));
  }

  Future<RecycleResult> classifyBytes(
    List<int> bytes, {
    String mimeType = 'image/jpeg',
  }) async {
    if (apiKey.isEmpty) {
      throw const ClassifyException('Gemini API 키가 없어요. 설정에서 키를 입력해 주세요.');
    }

    final body = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Encode(bytes),
              },
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.2,
        'response_mime_type': 'application/json',
        'response_schema': _responseSchema,
      },
    };

    http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$_endpoint/$model:generateContent'),
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': apiKey,
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 45));
    } on SocketException {
      throw const ClassifyException('인터넷 연결을 확인해 주세요.');
    } catch (e) {
      throw ClassifyException('요청 중 문제가 생겼어요: $e');
    }

    if (response.statusCode == 400 || response.statusCode == 403) {
      throw const ClassifyException('API 키가 올바르지 않아요. 설정에서 다시 확인해 주세요.');
    }
    if (response.statusCode == 429) {
      throw const ClassifyException('요청이 너무 많아요. 잠시 후 다시 시도해 주세요.');
    }
    if (response.statusCode != 200) {
      throw ClassifyException('서버 오류 (${response.statusCode})가 났어요. 다시 시도해 주세요.');
    }

    final text = extractText(response.body);
    try {
      return RecycleResult.fromAiJson(text);
    } on FormatException {
      throw const ClassifyException('AI 응답을 읽지 못했어요. 다시 찍어 주세요.');
    }
  }

  /// generateContent 응답에서 첫 후보의 텍스트만 꺼낸다.
  static String extractText(String responseBody) {
    final json = jsonDecode(responseBody) as Map<String, dynamic>;
    final candidates = json['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      final blockReason = (json['promptFeedback'] as Map?)?['blockReason'];
      throw ClassifyException(
        blockReason != null ? '사진을 분석할 수 없어요 ($blockReason).' : 'AI가 답을 주지 않았어요.',
      );
    }
    final content = (candidates.first as Map)['content'] as Map?;
    final parts = content?['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      throw const ClassifyException('AI 응답이 비어 있어요.');
    }
    return parts
        .map((p) => (p as Map)['text']?.toString() ?? '')
        .join()
        .trim();
  }

  static String _mimeTypeFor(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  void dispose() => _client.close();
}
