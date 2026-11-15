import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../content/copy.dart';
import '../models/models.dart';
import '../compat/compat_engine.dart';
import 'prompt_builder.dart';
import 'mock_data.dart';

/// AI 호출 예외 유형 (화면이 죽지 않게 구분해서 처리)
enum AiErrorType { rateLimit, credit, network, parse, unknown }

class AiException implements Exception {
  final AiErrorType type;
  final String message;
  AiException(this.type, this.message);

  String get userMessage {
    switch (type) {
      case AiErrorType.rateLimit:
      case AiErrorType.credit:
        return AppCopy.rateLimitMessage;
      default:
        return '분석 중 문제가 발생했어요. 잠시 후 다시 시도해주세요.';
    }
  }
}

/// AI 서비스 - generateAnalysis()가 진입점.
/// 교체 지점은 _callModel 하나.
class AiService {
  /// mock 스위치 (--dart-define=USE_MOCK=true). 기본 true.
  static const bool useMock =
      bool.fromEnvironment('USE_MOCK', defaultValue: true);

  /// AI 프록시 서버 URL (--dart-define=AI_PROXY_URL=/api/analyze).
  static const String proxyUrl =
      String.fromEnvironment('AI_PROXY_URL', defaultValue: '');

  /// 일반 분석 생성 (기본/연애/반복패턴)
  static Future<AnalysisResult> generateAnalysis({
    required UserProfile user,
    required AnalysisCategory category,
    required String userQuestion,
  }) async {
    if (useMock || proxyUrl.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 900));
      return MockData.general(user: user, category: category);
    }

    final system = PromptBuilder.systemInstruction();
    final prompt = PromptBuilder.buildGeneral(
      user: user,
      category: category,
      userQuestion: userQuestion,
    );
    final json = await _callModel(system: system, prompt: prompt);
    try {
      return AnalysisResult.fromJson(json);
    } catch (e) {
      throw AiException(AiErrorType.parse, '응답 해석 실패: $e');
    }
  }

  /// 궁합 분석 생성. 점수/신호등은 CompatEngine(코드)이 결정 → AI는 설명만.
  static Future<CompatResult> generateCompatibility({
    required UserProfile user,
    required PartnerProfile partner,
    required CompatComputation comp,
    required String userQuestion,
  }) async {
    if (useMock || proxyUrl.isEmpty || !comp.compatibilityAvailable) {
      await Future.delayed(const Duration(milliseconds: 900));
      return MockData.compat(comp);
    }

    final system = PromptBuilder.systemInstruction();
    final prompt = PromptBuilder.buildCompatibility(
      user: user,
      partner: partner,
      comp: comp,
      userQuestion: userQuestion,
    );
    final json = await _callModel(system: system, prompt: prompt);

    return CompatResult(
      compatibilityAvailable: true,
      compatibilityScore: comp.compatibilityScore, // 코드 값 우선
      signalColor: comp.signalColor.name, // 코드 값 우선
      detailedScores: comp.detailedScores,
      maxScores: comp.maxScores,
      goodParts: _strList(json['goodParts']),
      riskParts: _strList(json['riskParts']),
      finalJudgment: (json['finalJudgment'] ?? '').toString(),
      actionItems: _strList(json['actionItems']),
      holdReason: null,
    );
  }

  /// 실제 모델 호출 (프록시 서버 경유). 교체 지점은 여기 하나.
  static Future<Map<String, dynamic>> _callModel({
    required String system,
    required String prompt,
  }) async {
    try {
      // 상대경로(/api/analyze)면 현재 사이트 도메인 기준으로 절대경로화.
      final uri = proxyUrl.startsWith('http')
          ? Uri.parse(proxyUrl)
          : Uri.base.resolve(proxyUrl);
      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'system': system, 'prompt': prompt}),
          )
          .timeout(const Duration(seconds: 45));

      if (resp.statusCode == 429) {
        throw AiException(AiErrorType.rateLimit, '요청 과다');
      }
      if (resp.statusCode == 402) {
        throw AiException(AiErrorType.credit, '크레딧 부족');
      }
      if (resp.statusCode != 200) {
        throw AiException(AiErrorType.unknown, 'HTTP ${resp.statusCode}');
      }
      final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
      if (decoded is Map<String, dynamic>) return decoded;
      throw AiException(AiErrorType.parse, '형식 오류');
    } on AiException {
      rethrow;
    } on TimeoutException {
      throw AiException(AiErrorType.network, '시간 초과');
    } catch (e) {
      throw AiException(AiErrorType.network, e.toString());
    }
  }

  static List<String> _strList(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    return const [];
  }
}
