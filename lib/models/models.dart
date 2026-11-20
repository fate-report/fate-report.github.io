import '../content/copy.dart';
import '../manseryeok/ganzhi.dart';
import '../manseryeok/saju_calculator.dart';

/// 데이터 필드명 통일 (K04 동적 사용자 명식 슬롯 & K07-R3 & JEV 하네스 연동).

/// 사용자 입력 명식 정보
class UserProfile {
  String userName;
  String gender; // 'male' | 'female'
  DateTime? birthDate;
  String calendarType; // 'solar' | 'lunar' | 'lunar_leap' | 'unknown'
  String? birthTime; // 'HH:mm' or null(모름)
  bool birthTimeUnknown;
  String? birthPlace;
  bool applyLocalTime;

  String? yearPillar;
  String? monthPillar;
  String? dayPillar;
  String? hourPillar;
  String? dayMaster;
  String daeunSummary;
  List<String> boundaryWarnings;
  bool manualOverride; // 사용자가 STEP 2에서 직접 만세력 글자를 수정·확정했는지 여부

  UserProfile({
    this.userName = '',
    this.gender = 'female',
    this.birthDate,
    this.calendarType = 'solar',
    this.birthTime,
    this.birthTimeUnknown = false,
    this.birthPlace,
    this.applyLocalTime = true,
    this.yearPillar,
    this.monthPillar,
    this.dayPillar,
    this.hourPillar,
    this.dayMaster,
    this.daeunSummary = '',
    this.boundaryWarnings = const [],
    this.manualOverride = false,
  });

  bool get hasUnresolvedBoundary =>
      !manualOverride &&
      boundaryWarnings.any((w) => w.contains('경계') || w.contains('주의'));

  void applySaju(SajuResult r, {bool isManual = false}) {
    yearPillar = r.yearPillar;
    monthPillar = r.monthPillar;
    dayPillar = r.dayPillar;
    hourPillar = r.hourPillar;
    dayMaster = r.dayMaster;
    daeunSummary = r.daeunSummary;
    boundaryWarnings = r.boundaryWarnings;
    manualOverride = isManual;
  }

  SajuResult toSaju() {
    final yp = yearPillar ?? '';
    final mp = monthPillar ?? '';
    final dp = dayPillar ?? '';
    final hp = birthTimeUnknown ? null : hourPillar;
    final dm = (dayMaster != null && dayMaster!.isNotEmpty)
        ? dayMaster!
        : (dp.isNotEmpty ? dp[0] : '');
    return SajuResult(
      yearPillar: yp,
      monthPillar: mp,
      dayPillar: dp,
      hourPillar: hp,
      dayMaster: dm,
      hourUnknown: birthTimeUnknown || hp == null || hp.isEmpty,
      yearPillarHanja: pillarToHanja(yp),
      monthPillarHanja: pillarToHanja(mp),
      dayPillarHanja: pillarToHanja(dp),
      hourPillarHanja: hp == null ? null : pillarToHanja(hp),
      daeunSummary: daeunSummary,
      boundaryWarnings: boundaryWarnings,
    );
  }
}

/// 상대방 정보 (궁합/연애)
class PartnerProfile {
  String partnerName;
  String partnerGender;
  DateTime? partnerBirthDate;
  String partnerCalendarType;
  String? partnerBirthTime;
  bool partnerBirthTimeUnknown;
  String? partnerBirthPlace;
  bool partnerApplyLocalTime;
  String relationStatus;

  String? partnerYearPillar;
  String? partnerMonthPillar;
  String? partnerDayPillar;
  String? partnerHourPillar;
  String? partnerDayMaster;
  String partnerDaeunSummary;
  List<String> partnerBoundaryWarnings;
  bool partnerManualOverride;

  PartnerProfile({
    this.partnerName = '',
    this.partnerGender = 'male',
    this.partnerBirthDate,
    this.partnerCalendarType = 'solar',
    this.partnerBirthTime,
    this.partnerBirthTimeUnknown = false,
    this.partnerBirthPlace,
    this.partnerApplyLocalTime = true,
    this.relationStatus = '연애 중',
    this.partnerYearPillar,
    this.partnerMonthPillar,
    this.partnerDayPillar,
    this.partnerHourPillar,
    this.partnerDayMaster,
    this.partnerDaeunSummary = '',
    this.partnerBoundaryWarnings = const [],
    this.partnerManualOverride = false,
  });

  bool get hasUnresolvedBoundary =>
      !partnerManualOverride &&
      partnerBoundaryWarnings.any((w) => w.contains('경계') || w.contains('주의'));

  void applySaju(SajuResult r, {bool isManual = false}) {
    partnerYearPillar = r.yearPillar;
    partnerMonthPillar = r.monthPillar;
    partnerDayPillar = r.dayPillar;
    partnerHourPillar = r.hourPillar;
    partnerDayMaster = r.dayMaster;
    partnerDaeunSummary = r.daeunSummary;
    partnerBoundaryWarnings = r.boundaryWarnings;
    partnerManualOverride = isManual;
  }

  SajuResult toSaju() {
    final yp = partnerYearPillar ?? '';
    final mp = partnerMonthPillar ?? '';
    final dp = partnerDayPillar ?? '';
    final hp = partnerBirthTimeUnknown ? null : partnerHourPillar;
    final dm = (partnerDayMaster != null && partnerDayMaster!.isNotEmpty)
        ? partnerDayMaster!
        : (dp.isNotEmpty ? dp[0] : '');
    return SajuResult(
      yearPillar: yp,
      monthPillar: mp,
      dayPillar: dp,
      hourPillar: hp,
      dayMaster: dm,
      hourUnknown: partnerBirthTimeUnknown || hp == null || hp.isEmpty,
      yearPillarHanja: pillarToHanja(yp),
      monthPillarHanja: pillarToHanja(mp),
      dayPillarHanja: pillarToHanja(dp),
      hourPillarHanja: hp == null ? null : pillarToHanja(hp),
      daeunSummary: partnerDaeunSummary,
      boundaryWarnings: partnerBoundaryWarnings,
    );
  }
}

/// confidenceStatus: 'ok'(HIGH) | 'partial'(MEDIUM) | 'hold'(LOW)
enum ConfidenceStatus { ok, partial, hold }

/// 코드 레벨 4인 JEV 하네스 사후 검증기 (Post-Validator)
class JevHarnessValidator {
  /// 이스케이프된 줄바꿈(\\n), 마크다운 헤더(###), 과거 연도 환각('올해 2024년' 등)을 정제
  static String sanitizeText(String raw) {
    if (raw.isEmpty) return '';
    final kst = SajuCalculator.nowKst();
    final curY = kst.year;
    final sajuY = SajuCalculator.activeSeunYear(kst);
    final curGanji = SajuCalculator.seunPillarOfYear(sajuY);

    var s = raw
        .replaceAll(r'\n\n', '\n\n')
        .replaceAll(r'\n', '\n')
        .replaceAll('\r\n', '\n');

    // 하네스 1: '올해 2024년(갑진년)' / '올해 2025년(을사년)' 과거 시점 오기 자동 교정
    s = s.replaceAll(
      RegExp(r'올해\s*\(?\s*202[45]년?\s*(갑진년|을사년)?\s*\)?'),
      '올해($curY년 $curGanji년)',
    );
    s = s.replaceAll(
      RegExp(r'202[45]년\s*올해'),
      '$curY년 올해',
    );
    return s.trim();
  }

  /// 하네스 4: 시간 미상 또는 미확정 절기/자시 경계가 있을 때 확신도(Confidence)를 MEDIUM 이하로 강제 클램핑
  static (ConfidenceStatus, String) enforceConfidenceAndFooter({
    required String rawConf,
    required String rawFooter,
    required List<String> appliedRules,
    required bool shouldDowngradeToMedium,
    String? jevLock,
  }) {
    var status = _parseConfidence(rawConf);
    if (shouldDowngradeToMedium && status == ConfidenceStatus.ok) {
      status = ConfidenceStatus.partial;
    }

    final confLabel = switch (status) {
      ConfidenceStatus.ok => 'HIGH(높음)',
      ConfidenceStatus.partial => 'MEDIUM(보통)',
      ConfidenceStatus.hold => 'LOW(낮음)',
    };

    final rulesText =
        appliedRules.isNotEmpty ? appliedRules.join(', ') : 'K04, K06, K09, K10';
    var footer = rawFooter.trim();
    if (footer.isEmpty) {
      footer = '[적용 기준: $rulesText | 확신도: $confLabel]';
    } else if (shouldDowngradeToMedium && footer.contains('HIGH')) {
      footer = footer
          .replaceAll('HIGH(높음)', 'MEDIUM(보통)')
          .replaceAll('HIGH', 'MEDIUM(보통)');
    }
    return (status, footer);
  }
}

/// 일반 분석 결과 스키마 (투트랙 줄글 브리핑 + JEV 하네스 4 태그 포함)
class AnalysisResult {
  final String resultTitle;
  final String resultSummary;
  final String briefingTitle;
  final String briefingBody; // 0절 투트랙 다문단 브리핑 전문
  final ConfidenceStatus confidenceStatus;
  final String keyPoint;
  final String goodTitle;
  final List<String> goodPoints;
  final String riskTitle;
  final List<String> riskPoints;
  final String actionTitle;
  final List<String> actionItems;
  final String auditFooter; // [적용 기준: K04, K09... | 확신도: HIGH(높음)]
  final String warningMessage;
  final String jevLock; // 4인 하네스 내부 검산 로그

  const AnalysisResult({
    required this.resultTitle,
    required this.resultSummary,
    this.briefingTitle = '마스터 심층 브리핑',
    this.briefingBody = '',
    required this.confidenceStatus,
    required this.keyPoint,
    this.goodTitle = '유리한 기회 · 강점 요인',
    required this.goodPoints,
    this.riskTitle = '주의할 리스크 요인',
    required this.riskPoints,
    this.actionTitle = '지금 바로 해볼 현실 전략',
    required this.actionItems,
    this.auditFooter = '[적용 기준: K04, K06, K09, K10 | 확신도: HIGH(높음)]',
    required this.warningMessage,
    this.jevLock = '',
  });

  factory AnalysisResult.fromJson(
    Map<String, dynamic> j, {
    UserProfile? user,
    PartnerProfile? partner,
  }) {
    final confStr =
        (j['confidenceLevel'] ?? j['confidenceStatus'] ?? 'HIGH').toString();
    final applied = _strList(j['appliedKRules']);
    final jevLockStr = (j['jevLock'] ?? j['jevAudit'] ?? '').toString().trim();

    final body = JevHarnessValidator.sanitizeText(
      (j['briefingBody'] ?? j['resultSummary'] ?? '').toString(),
    );
    final summary = JevHarnessValidator.sanitizeText(
      (j['resultSummary'] ?? '').toString(),
    );
    final keyPt = JevHarnessValidator.sanitizeText(
      (j['keyPoint'] ?? '').toString(),
    );

    if (body.isEmpty && summary.isEmpty) {
      throw const FormatException('AI 응답 본문(briefingBody)이 비어 있습니다.');
    }

    final shouldDowngrade = (user != null &&
            (user.birthTimeUnknown || user.hasUnresolvedBoundary)) ||
        (partner != null &&
            partner.partnerBirthDate != null &&
            (partner.partnerBirthTimeUnknown || partner.hasUnresolvedBoundary));

    final (enforcedConf, enforcedFooter) =
        JevHarnessValidator.enforceConfidenceAndFooter(
      rawConf: confStr,
      rawFooter: (j['auditFooter'] ?? '').toString(),
      appliedRules: applied.isNotEmpty
          ? applied
          : const ['K04', 'K06', 'K09', 'K10'],
      shouldDowngradeToMedium: shouldDowngrade,
      jevLock: jevLockStr,
    );

    final goods = _strList(j['goodPoints'])
        .map(JevHarnessValidator.sanitizeText)
        .where((s) => s.isNotEmpty)
        .toList();
    final risks = _strList(j['riskPoints'])
        .map(JevHarnessValidator.sanitizeText)
        .where((s) => s.isNotEmpty)
        .toList();
    final actions = _strList(j['actionItems'])
        .map(JevHarnessValidator.sanitizeText)
        .where((s) => s.isNotEmpty)
        .toList();

    return AnalysisResult(
      resultTitle: JevHarnessValidator.sanitizeText(
        (j['resultTitle'] ?? '사주 심층 브리핑').toString(),
      ),
      resultSummary: summary,
      briefingTitle: JevHarnessValidator.sanitizeText(
        (j['briefingTitle'] ?? '마스터 심층 브리핑').toString(),
      ),
      briefingBody: body.isNotEmpty ? body : summary,
      confidenceStatus: enforcedConf,
      keyPoint: keyPt,
      goodTitle: JevHarnessValidator.sanitizeText(
        (j['goodTitle'] ?? '유리한 기회 · 강점 요인').toString(),
      ),
      goodPoints: goods,
      riskTitle: JevHarnessValidator.sanitizeText(
        (j['riskTitle'] ?? '주의할 리스크 요인').toString(),
      ),
      riskPoints: risks,
      actionTitle: JevHarnessValidator.sanitizeText(
        (j['actionTitle'] ?? '지금 바로 해볼 현실 전략').toString(),
      ),
      actionItems: actions,
      auditFooter: enforcedFooter,
      warningMessage: (j['warningMessage'] ?? AppCopy.commonNotice).toString(),
      jevLock: jevLockStr,
    );
  }
}

/// 궁합 전용 결과 스키마 (K07-R3 정량 수식 근거 + 투트랙 브리핑 + JEV 하네스 4 태그)
class CompatResult {
  final bool compatibilityAvailable;
  final int compatibilityScore;
  final String signalColor;
  final Map<String, int> detailedScores;
  final Map<String, int> maxScores;
  final Map<String, String> itemFormulas;
  final String briefingTitle;
  final String briefingBody; // K07-R3 + K09 입체 궁합 브리핑 전문
  final String goodTitle;
  final List<String> goodParts;
  final String riskTitle;
  final List<String> riskParts;
  final String finalJudgment;
  final String actionTitle;
  final List<String> actionItems;
  final String auditFooter;
  final String? holdReason;
  final String? boundaryShiftNotice;
  final String jevLock;

  const CompatResult({
    required this.compatibilityAvailable,
    required this.compatibilityScore,
    required this.signalColor,
    required this.detailedScores,
    required this.maxScores,
    this.itemFormulas = const {},
    this.briefingTitle = '마스터 궁합 브리핑 (K07-R3 · K09)',
    this.briefingBody = '',
    this.goodTitle = '잘 맞는 시너지 요인',
    required this.goodParts,
    this.riskTitle = '조심할 마찰 요인',
    required this.riskParts,
    required this.finalJudgment,
    this.actionTitle = '지금 바로 해볼 현실 전략',
    required this.actionItems,
    this.auditFooter = '[적용 기준: K04, K06, K07-R3, K08, K09 | 확신도: HIGH(높음)]',
    required this.holdReason,
    this.boundaryShiftNotice,
    this.jevLock = '',
  });
}

/// 꼬리 질문(후속 대화) 메시지 모델
class ChatTurn {
  final String role; // 'user' | 'assistant'
  final String text;
  final String? auditFooter;

  const ChatTurn({
    required this.role,
    required this.text,
    this.auditFooter,
  });
}

ConfidenceStatus _parseConfidence(dynamic v) {
  final s = v?.toString().toUpperCase() ?? '';
  if (s.contains('HOLD') || s.contains('LOW') || s.contains('낮음')) {
    return ConfidenceStatus.hold;
  }
  if (s.contains('PARTIAL') || s.contains('MEDIUM') || s.contains('보통')) {
    return ConfidenceStatus.partial;
  }
  return ConfidenceStatus.ok;
}

List<String> _strList(dynamic v) {
  if (v is List) return v.map((e) => e.toString()).toList();
  return const [];
}
