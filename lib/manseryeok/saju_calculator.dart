import 'ganzhi.dart';
import 'birth_place.dart';
import 'dst_correction.dart';
import 'solar_terms.dart';

/// 사주 계산 결과.
class SajuResult {
  final String yearPillar;
  final String monthPillar;
  final String dayPillar;
  final String? hourPillar; // 시간 모름이면 null
  final String dayMaster; // 일간
  final bool hourUnknown;

  final String yearPillarHanja;
  final String monthPillarHanja;
  final String dayPillarHanja;
  final String? hourPillarHanja;

  const SajuResult({
    required this.yearPillar,
    required this.monthPillar,
    required this.dayPillar,
    required this.hourPillar,
    required this.dayMaster,
    required this.hourUnknown,
    required this.yearPillarHanja,
    required this.monthPillarHanja,
    required this.dayPillarHanja,
    required this.hourPillarHanja,
  });
}

/// 만세력 계산기.
/// 계산만 담당 (AI 관여 없음). 60갑자 순환 + 절기 기준 월주.
class SajuCalculator {
  /// 기준일: 1900-01-01 은 '경자일'(庚子日).
  /// 경(6) 자(0) → 60갑자 인덱스 = 간(6), 지(0). 인덱스 계산: 36.
  /// 甲=0 기준으로 庚=6, 子=0 → ganzhi index where stem%10==6, branch%12==0 → 36.
  static final DateTime _refDate = DateTime(1900, 1, 1);
  static const int _refDayIndex = 56; // 1900-01-01 (2000-01-01=갑진 기준 역산)

  static SajuResult calculate({
    required int year,
    required int month,
    required int day,
    int? hour,
    int? minute,
    String? placeName,
    bool applyLocalTime = true,
  }) {
    final hourUnknown = hour == null;

    // 1) 기본 일시
    DateTime dt = DateTime(year, month, day, hour ?? 12, minute ?? 0);

    // 2) 서머타임 보정
    dt = applyDstCorrection(dt);

    // 3) 진태양시 보정 (분 단위)
    if (applyLocalTime) {
      final offset = trueSolarOffsetMinutes(placeName);
      dt = dt.add(Duration(minutes: offset.round()));
    }

    // 보정 후 날짜가 바뀔 수 있으므로 다시 추출
    final cy = dt.year;
    final cm = dt.month;
    final cd = dt.day;
    final ch = dt.hour;

    // 4) 일주(日柱): 기준일로부터 경과일수
    final daysDiff = DateTime(cy, cm, cd).difference(_refDate).inDays;
    final dayIdx = ((_refDayIndex + daysDiff) % 60 + 60) % 60;
    final dayStem = heavenlyStems[dayIdx % 10];
    final dayBranch = earthlyBranches[dayIdx % 12];

    // 5) 년주(年柱): 입춘 기준. 월지 인덱스가 '축'(11)이고 1~2월 초면 전년 처리.
    final monthBr = SolarTerms.monthBranchIndex(cy, cm, cd);
    int sajuYear = cy;
    // 입춘(인월, index 0) 이전이면 전년도로 간주
    // monthBr 가 '축'(11)이고 실제 달이 1~2월 초순이면 전년
    if ((cm == 1) || (cm == 2 && monthBr == 11)) {
      sajuYear = cy - 1;
    }
    // 1864년이 갑자년(년간지 index 0). (year-4)%60 공식 사용.
    final yearIdx = ((sajuYear - 4) % 60 + 60) % 60;
    final yearStem = heavenlyStems[yearIdx % 10];
    final yearBranch = earthlyBranches[yearIdx % 12];

    // 6) 월주(月柱): 월지는 절기로, 월간은 '오호둔'(년간 기준)
    final monthBranchStr = SolarTerms.monthBranchOrder[monthBr];
    final monthStem = _monthStem(yearStem, monthBr);

    // 7) 시주(時柱): 시지(2시간 단위) + 시두법(일간 기준)
    String? hourStem;
    String? hourBranchStr;
    if (!hourUnknown) {
      final hourBranchIdx = _hourBranchIndex(ch);
      hourBranchStr = earthlyBranches[hourBranchIdx];
      hourStem = _hourStem(dayStem, hourBranchIdx);
    }

    String hanja(String stem, String branch) {
      final si = heavenlyStems.indexOf(stem);
      final bi = earthlyBranches.indexOf(branch);
      return heavenlyStemsHanja[si] + earthlyBranchesHanja[bi];
    }

    return SajuResult(
      yearPillar: yearStem + yearBranch,
      monthPillar: monthStem + monthBranchStr,
      dayPillar: dayStem + dayBranch,
      hourPillar: hourUnknown ? null : (hourStem! + hourBranchStr!),
      dayMaster: dayStem,
      hourUnknown: hourUnknown,
      yearPillarHanja: hanja(yearStem, yearBranch),
      monthPillarHanja: hanja(monthStem, monthBranchStr),
      dayPillarHanja: hanja(dayStem, dayBranch),
      hourPillarHanja:
          hourUnknown ? null : hanja(hourStem!, hourBranchStr!),
    );
  }

  /// 오호둔: 년간에 따라 인월(寅月)의 월간이 정해지고 순행.
  /// 갑기년→병인두, 을경년→무인두, 병신년→경인두, 정임년→임인두, 무계년→갑인두.
  static String _monthStem(String yearStem, int monthBranchIdx) {
    const startStemByYear = {
      '갑': '병', '기': '병',
      '을': '무', '경': '무',
      '병': '경', '신': '경',
      '정': '임', '임': '임',
      '무': '갑', '계': '갑',
    };
    final startStem = startStemByYear[yearStem]!;
    final startIdx = heavenlyStems.indexOf(startStem);
    // monthBranchIdx: 0=인월 → startStem, 이후 순행
    final idx = (startIdx + monthBranchIdx) % 10;
    return heavenlyStems[idx];
  }

  /// 시지 인덱스: 23~01시=자(0), 01~03=축(1) ... 2시간 단위.
  static int _hourBranchIndex(int hour) {
    // 23시, 0시 → 자
    return (((hour + 1) ~/ 2) % 12);
  }

  /// 시두법: 일간에 따라 자시(子時)의 시간(時干)이 정해지고 순행.
  /// 갑기일→갑자시, 을경일→병자시, 병신일→무자시, 정임일→경자시, 무계일→임자시.
  static String _hourStem(String dayStem, int hourBranchIdx) {
    const startStemByDay = {
      '갑': '갑', '기': '갑',
      '을': '병', '경': '병',
      '병': '무', '신': '무',
      '정': '경', '임': '경',
      '무': '임', '계': '임',
    };
    final startStem = startStemByDay[dayStem]!;
    final startIdx = heavenlyStems.indexOf(startStem);
    final idx = (startIdx + hourBranchIdx) % 10;
    return heavenlyStems[idx];
  }
}
