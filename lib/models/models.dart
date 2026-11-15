import '../content/copy.dart';
import '../manseryeok/ganzhi.dart';
import '../manseryeok/saju_calculator.dart';

/// 데이터 필드명 통일 (K04 동적 사용자 명식 슬롯 & K07-R3 & JEV 하네스 연동).

/// 사용자 입력 명식 정보
class UserProfile {
  String userName;
  String gender; // 'male' | 'female'
  DateTime? birthDate;
  String calendarType; // 'solar' | 'lunar' | 'unknown'
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

  void applySaju(SajuResult r) {
    yearPillar = r.yearPillar;
    monthPillar = r.monthPillar;
    dayPillar = r.dayPillar;
    hourPillar = r.hourPillar;
    dayMaster = r.dayMaster;
    daeunSummary = r.daeunSummary;
    boundaryWarnings = r.boundaryWarnings;
    manualOverride = false;
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
      boundaryWarnings: manualOverride ? const [] : boundaryWarnings,
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

  void applySaju(SajuResult r) {
    partnerYearPillar = r.yearPillar;
    partnerMonthPillar = r.monthPillar;
    partnerDayPillar = r.dayPillar;
    partnerHourPillar = r.hourPillar;
    partnerDayMaster = r.dayMaster;
    partnerDaeunSummary = r.daeunSummary;
    partnerBoundaryWarnings = r.boundaryWarnings;
    partnerManualOverride = false;
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
      boundaryWarnings:
          partnerManualOverride ? const [] : partnerBoundaryWarnings,
    );
  }
}

/// confidenceStatus: 'ok'(HIGH) | 'partial'(MEDIUM) | 'hold'(LOW)
enum ConfidenceStatus { ok, partial, hold }

/// 일반 분석 결과 스키마 (투트랙 줄글 브리핑 + JEV 하네스 4 태그 포함)
class AnalysisResult {
  final String resultTitle;
  final String resultSummary;
  final String briefingBody; // 0절 투트랙 다문단 브리핑 전문
  final ConfidenceStatus confidenceStatus;
  final String keyPoint;
  final List<String> goodPoints;
  final List<String> riskPoints;
  final List<String> actionItems;
  final String auditFooter; // [적용 기준: K04, K09... | 확신도: HIGH(높음)]
  final String warningMessage;

  const AnalysisResult({
    required this.resultTitle,
    required this.resultSummary,
    this.briefingBody = '',
    required this.confidenceStatus,
    required this.keyPoint,
    required this.goodPoints,
    required this.riskPoints,
    required this.actionItems,
    this.auditFooter = '[적용 기준: K04, K06, K09, K10 | 확신도: HIGH(높음)]',
    required this.warningMessage,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> j) {
    final confStr =
        (j['confidenceLevel'] ?? j['confidenceStatus'] ?? 'HIGH').toString();
    final applied = _strList(j['appliedKRules']);
    final defaultFooter = applied.isNotEmpty
        ? '[적용 기준: ${applied.join(', ')} | 확신도: ${_formatConfLabel(confStr)}]'
        : '[적용 기준: K04, K06, K09, K10 | 확신도: ${_formatConfLabel(confStr)}]';

    final body = (j['briefingBody'] ?? j['resultSummary'] ?? '').toString();
    final summary = (j['resultSummary'] ?? '').toString();

    return AnalysisResult(
      resultTitle: (j['resultTitle'] ?? '사주 심층 브리핑').toString(),
      resultSummary: summary.isNotEmpty ? summary : body,
      briefingBody: body.isNotEmpty ? body : summary,
      confidenceStatus: _parseConfidence(confStr),
      keyPoint: (j['keyPoint'] ?? '').toString(),
      goodPoints: _strList(j['goodPoints']),
      riskPoints: _strList(j['riskPoints']),
      actionItems: _strList(j['actionItems']),
      auditFooter: (j['auditFooter'] ?? defaultFooter).toString(),
      warningMessage: (j['warningMessage'] ?? AppCopy.commonNotice).toString(),
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
  final String briefingBody; // K07-R3 + K09 입체 궁합 브리핑 전문
  final List<String> goodParts;
  final List<String> riskParts;
  final String finalJudgment;
  final List<String> actionItems;
  final String auditFooter;
  final String? holdReason;
  final String? boundaryShiftNotice;

  const CompatResult({
    required this.compatibilityAvailable,
    required this.compatibilityScore,
    required this.signalColor,
    required this.detailedScores,
    required this.maxScores,
    this.itemFormulas = const {},
    this.briefingBody = '',
    required this.goodParts,
    required this.riskParts,
    required this.finalJudgment,
    required this.actionItems,
    this.auditFooter = '[적용 기준: K04, K06, K07-R3, K08, K09 | 확신도: HIGH(높음)]',
    required this.holdReason,
    this.boundaryShiftNotice,
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

String _formatConfLabel(String raw) {
  final u = raw.toUpperCase();
  if (u.contains('LOW') || u.contains('HOLD')) return 'LOW(낮음)';
  if (u.contains('MEDIUM') || u.contains('PARTIAL')) return 'MEDIUM(보통)';
  return 'HIGH(높음)';
}

List<String> _strList(dynamic v) {
  if (v is List) return v.map((e) => e.toString()).toList();
  return const [];
}
