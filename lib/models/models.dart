import '../content/copy.dart';
import '../manseryeok/saju_calculator.dart';

/// 데이터 필드명 통일 (나중에 DB 붙이기 쉽게).

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
  });

  void applySaju(SajuResult r) {
    yearPillar = r.yearPillar;
    monthPillar = r.monthPillar;
    dayPillar = r.dayPillar;
    hourPillar = r.hourPillar;
    dayMaster = r.dayMaster;
  }

  SajuResult toSaju() => SajuResult(
        yearPillar: yearPillar ?? '',
        monthPillar: monthPillar ?? '',
        dayPillar: dayPillar ?? '',
        hourPillar: hourPillar,
        dayMaster: dayMaster ?? '',
        hourUnknown: birthTimeUnknown || hourPillar == null,
        yearPillarHanja: '',
        monthPillarHanja: '',
        dayPillarHanja: '',
        hourPillarHanja: null,
      );
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
  });

  void applySaju(SajuResult r) {
    partnerYearPillar = r.yearPillar;
    partnerMonthPillar = r.monthPillar;
    partnerDayPillar = r.dayPillar;
    partnerHourPillar = r.hourPillar;
    partnerDayMaster = r.dayMaster;
  }

  SajuResult toSaju() => SajuResult(
        yearPillar: partnerYearPillar ?? '',
        monthPillar: partnerMonthPillar ?? '',
        dayPillar: partnerDayPillar ?? '',
        hourPillar: partnerHourPillar,
        dayMaster: partnerDayMaster ?? '',
        hourUnknown: partnerBirthTimeUnknown || partnerHourPillar == null,
        yearPillarHanja: '',
        monthPillarHanja: '',
        dayPillarHanja: '',
        hourPillarHanja: null,
      );
}

/// confidenceStatus: 'ok' | 'partial' | 'hold'
enum ConfidenceStatus { ok, partial, hold }

/// 일반 분석 결과 스키마
class AnalysisResult {
  final String resultTitle;
  final String resultSummary;
  final ConfidenceStatus confidenceStatus;
  final String keyPoint;
  final List<String> goodPoints;
  final List<String> riskPoints;
  final List<String> actionItems;
  final String warningMessage;

  const AnalysisResult({
    required this.resultTitle,
    required this.resultSummary,
    required this.confidenceStatus,
    required this.keyPoint,
    required this.goodPoints,
    required this.riskPoints,
    required this.actionItems,
    required this.warningMessage,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> j) {
    return AnalysisResult(
      resultTitle: (j['resultTitle'] ?? '분석 결과').toString(),
      resultSummary: (j['resultSummary'] ?? '').toString(),
      confidenceStatus: _parseConfidence(j['confidenceStatus']),
      keyPoint: (j['keyPoint'] ?? '').toString(),
      goodPoints: _strList(j['goodPoints']),
      riskPoints: _strList(j['riskPoints']),
      actionItems: _strList(j['actionItems']),
      warningMessage: (j['warningMessage'] ?? AppCopy.commonNotice).toString(),
    );
  }
}

/// 궁합 전용 결과 스키마
class CompatResult {
  final bool compatibilityAvailable;
  final int compatibilityScore;
  final String signalColor;
  final Map<String, int> detailedScores;
  final Map<String, int> maxScores;
  final List<String> goodParts;
  final List<String> riskParts;
  final String finalJudgment;
  final List<String> actionItems;
  final String? holdReason;

  const CompatResult({
    required this.compatibilityAvailable,
    required this.compatibilityScore,
    required this.signalColor,
    required this.detailedScores,
    required this.maxScores,
    required this.goodParts,
    required this.riskParts,
    required this.finalJudgment,
    required this.actionItems,
    required this.holdReason,
  });
}

ConfidenceStatus _parseConfidence(dynamic v) {
  switch (v?.toString()) {
    case 'hold':
      return ConfidenceStatus.hold;
    case 'partial':
      return ConfidenceStatus.partial;
    default:
      return ConfidenceStatus.ok;
  }
}

List<String> _strList(dynamic v) {
  if (v is List) return v.map((e) => e.toString()).toList();
  return const [];
}
