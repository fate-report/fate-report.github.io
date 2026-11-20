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

/// AI 서비스 — K01~K10 마스터 엔진 & 4인 JEV 하네스(프롬프트 + 코드 사후 검증기) 연동.
class AiService {
  /// 프로덕션에서 가짜 Mock으로 빠지지 않도록 기본값을 false로 설정 (--dart-define=USE_MOCK=true 일 때만 Mock 사용).
  static const bool useMock =
      bool.fromEnvironment('USE_MOCK', defaultValue: false);

  /// AI 프록시 서버 URL (기본값 '/api/analyze').
  static const String proxyUrl =
      String.fromEnvironment('AI_PROXY_URL', defaultValue: '/api/analyze');

  /// 일반 분석 생성 (기본/연애/반복패턴) + JEV 코드 사후 검증
  static Future<AnalysisResult> generateAnalysis({
    required UserProfile user,
    PartnerProfile? partner,
    CompatComputation? comp,
    required AnalysisCategory category,
    required String userQuestion,
  }) async {
    if (useMock || proxyUrl.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 500));
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
      return AnalysisResult.fromJson(json, user: user, partner: partner);
    } catch (e) {
      throw AiException(AiErrorType.parse, '응답 해석 실패: $e');
    }
  }

  /// 궁합 분석 생성. K07-R3 점수/신호등/수식근거는 CompatEngine(코드)이 100% 결정하며,
  /// 본문 내 [궁합 정량 요약] 블록 역시 코드 사후 검증기(하네스 1)가 1점의 오차도 없도록 강제 고정한다.
  static Future<CompatResult> generateCompatibility({
    required UserProfile user,
    required PartnerProfile partner,
    required CompatComputation comp,
    required String userQuestion,
  }) async {
    if (!comp.compatibilityAvailable) {
      return MockData.compat(
        comp,
        user: user,
        partner: partner,
        userQuestion: userQuestion,
      );
    }
    if (useMock || proxyUrl.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 500));
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

    final rawBody = JevHarnessValidator.sanitizeText(
      (json['briefingBody'] ?? json['finalJudgment'] ?? '').toString(),
    );
    final rawFinal = JevHarnessValidator.sanitizeText(
      (json['finalJudgment'] ?? '').toString(),
    );
    if (rawBody.isEmpty && rawFinal.isEmpty) {
      throw AiException(AiErrorType.parse, '궁합 브리핑 본문이 비어 있습니다.');
    }

    // 하네스 1 코드 검증: 본문 상단 [궁합 정량 요약] 블록을 코드가 계산한 comp.toK07SummaryBlock()으로 강제 잠금
    final lockedBody = _enforceK07SummaryBlockInBriefing(
      rawBody.isNotEmpty ? rawBody : rawFinal,
      comp,
    );

    final shouldDowngrade = !comp.hourIncluded ||
        user.hasUnresolvedBoundary ||
        partner.hasUnresolvedBoundary;
    final jevLockStr =
        (json['jevLock'] ?? json['jevAudit'] ?? '').toString().trim();

    final (_, enforcedFooter) =
        JevHarnessValidator.enforceConfidenceAndFooter(
      rawConf: (json['confidenceLevel'] ??
              (comp.hourIncluded ? 'HIGH' : 'MEDIUM'))
          .toString(),
      rawFooter: (json['auditFooter'] ?? '').toString(),
      appliedRules: const ['K04', 'K06', 'K07-R3', 'K08', 'K09', 'K10'],
      shouldDowngradeToMedium: shouldDowngrade,
      jevLock: jevLockStr,
    );

    return CompatResult(
      compatibilityAvailable: true,
      compatibilityScore: comp.compatibilityScore, // 코드 값 100% Lock
      signalColor: comp.signalColor.name, // 코드 값 100% Lock
      detailedScores: comp.detailedScores,
      maxScores: comp.maxScores,
      itemFormulas: comp.itemFormulas,
      briefingTitle: JevHarnessValidator.sanitizeText(
        (json['briefingTitle'] ?? '마스터 궁합 브리핑 (K07-R3 · K09)').toString(),
      ),
      briefingBody: lockedBody,
      goodTitle: JevHarnessValidator.sanitizeText(
        (json['goodTitle'] ?? '잘 맞는 시너지 요인').toString(),
      ),
      goodParts: _strList(json['goodParts'])
          .map(JevHarnessValidator.sanitizeText)
          .where((s) => s.isNotEmpty)
          .toList(),
      riskTitle: JevHarnessValidator.sanitizeText(
        (json['riskTitle'] ?? '조심할 마찰 요인').toString(),
      ),
      riskParts: _strList(json['riskParts'])
          .map(JevHarnessValidator.sanitizeText)
          .where((s) => s.isNotEmpty)
          .toList(),
      finalJudgment: rawFinal.isNotEmpty ? rawFinal : '두 사람의 다름을 이해하고 대화 리듬을 맞추는 것이 핵심입니다.',
      actionTitle: JevHarnessValidator.sanitizeText(
        (json['actionTitle'] ?? '지금 바로 해볼 현실 전략').toString(),
      ),
      actionItems: _strList(json['actionItems'])
          .map(JevHarnessValidator.sanitizeText)
          .where((s) => s.isNotEmpty)
          .toList(),
      auditFooter: enforcedFooter,
      holdReason: null,
      boundaryShiftNotice: comp.boundaryShiftNotice,
      jevLock: jevLockStr,
    );
  }

  /// 본문(briefingBody) 내 AI가 타이핑한 [궁합 정량 요약...] 문단을 코드 확정 블록으로 교체/삽입
  static String _enforceK07SummaryBlockInBriefing(
    String body,
    CompatComputation comp,
  ) {
    final canonicalBlock = comp.toK07SummaryBlock().trim();
    final paras = body
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (paras.isEmpty) {
      return canonicalBlock;
    }
    if (paras.first.startsWith('[궁합 정량 요약')) {
      paras[0] = canonicalBlock;
      return paras.join('\n\n');
    }
    // 다른 문단에 [궁합 정량 요약이 있으면 제거 후 최상단에 코드 확정본 배치
    paras.removeWhere((p) => p.startsWith('[궁합 정량 요약'));
    return '$canonicalBlock\n\n${paras.join('\n\n')}';
  }

  /// 꼬리 질문(후속 대화) 답변 생성 + JEV 코드 사후 검증
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
      await Future.delayed(const Duration(milliseconds: 450));
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
    final answer = JevHarnessValidator.sanitizeText(
      (json['answer'] ?? json['briefingBody'] ?? '').toString(),
    );
    if (answer.isEmpty) {
      throw AiException(AiErrorType.parse, '후속 질문 답변이 비어 있습니다.');
    }

    final shouldDowngrade =
        user.birthTimeUnknown || user.hasUnresolvedBoundary;
    final (_, enforcedFooter) =
        JevHarnessValidator.enforceConfidenceAndFooter(
      rawConf: (json['confidenceLevel'] ??
              (shouldDowngrade ? 'MEDIUM' : 'HIGH'))
          .toString(),
      rawFooter: (json['auditFooter'] ?? '').toString(),
      appliedRules: _strList(json['appliedKRules']),
      shouldDowngradeToMedium: shouldDowngrade,
      jevLock: (json['jevLock'] ?? '').toString(),
    );

    return ChatTurn(
      role: 'assistant',
      text: answer,
      auditFooter: enforcedFooter,
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
