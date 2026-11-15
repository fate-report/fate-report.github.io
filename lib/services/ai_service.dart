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

/// AI 서비스 — K01~K10 마스터 엔진 & 4인 JEV 하네스 연동.
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
    PartnerProfile? partner,
    CompatComputation? comp,
    required AnalysisCategory category,
    required String userQuestion,
  }) async {
    if (useMock || proxyUrl.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 850));
      return MockData.general(
        user: user,
        partner: partner,
        category: category,
        userQuestion: userQuestion,
      );
    }

    final system = PromptBuilder.systemInstruction();
    final prompt = PromptBuilder.buildGeneral(
      user: user,
      partner: partner,
      comp: comp,
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

  /// 궁합 분석 생성. K07-R3 점수/신호등/수식근거는 CompatEngine(코드)이 100% 결정 → AI는 K09 입체 통변.
  static Future<CompatResult> generateCompatibility({
    required UserProfile user,
    required PartnerProfile partner,
    required CompatComputation comp,
    required String userQuestion,
  }) async {
    if (useMock || proxyUrl.isEmpty || !comp.compatibilityAvailable) {
      await Future.delayed(const Duration(milliseconds: 850));
      return MockData.compat(
        comp,
        user: user,
        partner: partner,
        userQuestion: userQuestion,
      );
    }

    final system = PromptBuilder.systemInstruction();
    final prompt = PromptBuilder.buildCompatibility(
      user: user,
      partner: partner,
      comp: comp,
      userQuestion: userQuestion,
    );
    final json = await _callModel(system: system, prompt: prompt);

    final defaultFooter =
        '[적용 기준: K04, K06, K07-R3, K08, K09, K10 | 확신도: ${comp.hourIncluded ? 'HIGH(높음)' : 'MEDIUM(보통)'}]';

    return CompatResult(
      compatibilityAvailable: true,
      compatibilityScore: comp.compatibilityScore, // 코드 값 우선 Lock
      signalColor: comp.signalColor.name, // 코드 값 우선 Lock
      detailedScores: comp.detailedScores,
      maxScores: comp.maxScores,
      itemFormulas: comp.itemFormulas,
      briefingBody: (json['briefingBody'] ?? json['finalJudgment'] ?? '').toString(),
      goodParts: _strList(json['goodParts']),
      riskParts: _strList(json['riskParts']),
      finalJudgment: (json['finalJudgment'] ?? '').toString(),
      actionItems: _strList(json['actionItems']),
      auditFooter: (json['auditFooter'] ?? defaultFooter).toString(),
      holdReason: null,
      boundaryShiftNotice: comp.boundaryShiftNotice,
    );
  }

  /// 꼬리 질문(후속 대화) 답변 생성 (0절 4항: 앞선 설명 반복 없이 핵심과 판단 근거에 집중)
  static Future<ChatTurn> generateFollowUp({
    required UserProfile user,
    PartnerProfile? partner,
    CompatComputation? comp,
    required AnalysisCategory category,
    required String initialBriefingSummary,
    required List<ChatTurn> history,
    required String followUpQuestion,
  }) async {
    if (useMock || proxyUrl.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 700));
      return MockData.followUp(
        user: user,
        partner: partner,
        comp: comp,
        followUpQuestion: followUpQuestion,
      );
    }

    final system = PromptBuilder.systemInstruction();
    final prompt = PromptBuilder.buildFollowUp(
      user: user,
      partner: partner,
      comp: comp,
      category: category,
      initialBriefingSummary: initialBriefingSummary,
      history: history,
      followUpQuestion: followUpQuestion,
    );
    final json = await _callModel(system: system, prompt: prompt);
    final answer = (json['answer'] ?? json['briefingBody'] ?? '').toString();
    final footer = (json['auditFooter'] ??
            '[적용 기준: K04, K06, K09, K10 | 확신도: ${user.birthTimeUnknown ? 'MEDIUM(보통)' : 'HIGH(높음)'}]')
        .toString();

    return ChatTurn(
      role: 'assistant',
      text: answer,
      auditFooter: footer,
    );
  }

  /// 실제 모델 호출 (프록시 서버 경유).
  static Future<Map<String, dynamic>> _callModel({
    required String system,
    required String prompt,
  }) async {
    try {
      final uri = proxyUrl.startsWith('http')
          ? Uri.parse(proxyUrl)
          : Uri.base.resolve(proxyUrl);
      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'system': system, 'prompt': prompt}),
          )
          .timeout(const Duration(seconds: 55));

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
