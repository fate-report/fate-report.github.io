import 'ganzhi.dart';
import 'birth_place.dart';
import 'dst_correction.dart';
import 'solar_terms.dart';

/// 사주 계산 결과 (K01~K05, K08, K09 메타데이터 포함).
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

  final String daeunSummary; // K04 대운 흐름
  final List<String> boundaryWarnings; // K05/K08 경계 주의사항

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
    this.daeunSummary = '',
    this.boundaryWarnings = const [],
  });

  bool get hasBoundaryWarning => boundaryWarnings.isNotEmpty;

  /// 3주 6글자(년·월·일간 + 년·월·일지 본기) 오행 분포 산출 (K06, K07-R3 C항목 전용)
  Map<String, int> get sixCharElements {
    final counts = <String, int>{'목': 0, '화': 0, '토': 0, '금': 0, '수': 0};
    for (final p in [yearPillar, monthPillar, dayPillar]) {
      if (p.length >= 2) {
        final sEl = stemElements[p[0]];
        final bEl = branchElements[p[1]];
        if (sEl != null) counts[sEl] = (counts[sEl] ?? 0) + 1;
        if (bEl != null) counts[bEl] = (counts[bEl] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// 프롬프트 K04/K09 슬롯에 주입할 상세 명식 구조 요약 생성
  String toDetailedSlotText({String gender = 'female'}) {
    if (dayPillar.length < 2) return '(명식 미확정)';
    final dm = dayMaster.isNotEmpty ? dayMaster : dayPillar[0];

    String describePillar(String label, String? p, {bool isDay = false}) {
      if (p == null || p.length < 2) return '$label: (미상/제외)';
      final stem = p[0];
      final branch = p[1];
      final hanja = pillarToHanja(p);
      final sEl = stemElements[stem] ?? '';
      final bEl = branchElements[branch] ?? '';
      final stemTenGod = isDay ? '본원(일간)' : calculateTenGod(dm, stem);
      final hidden = branchHiddenStems[branch] ?? const [];
      final hiddenDesc = hidden
          .map((h) => '$h(${calculateTenGod(dm, h)})')
          .join('·');
      final stage12 = calculateTwelveStage(dm, branch);
      return '$label: $p($hanja) [천간:$stem($sEl/$stemTenGod) | 지지:$branch(본기:$bEl, 지장간:$hiddenDesc, 12운성:$stage12)]';
    }

    final elMap = sixCharElements;
    final elText = elMap.entries.map((e) => '${e.key}${e.value}').join(' / ');
    final warnText = boundaryWarnings.isEmpty
        ? '없음 (정상 확정)'
        : boundaryWarnings.join(' | ');

    return '''
- 확정 4주: $yearPillar($yearPillarHanja)년 $monthPillar($monthPillarHanja)월 $dayPillar($dayPillarHanja)일 ${hourUnknown || hourPillar == null ? '(시간 미상 — 3주 6글자 기준)' : '$hourPillar($hourPillarHanja)시'} (기준 일간: $dm / ${stemElements[dm] ?? ''})
  • ${describePillar('년주', yearPillar)}
  • ${describePillar('월주', monthPillar)}
  • ${describePillar('일주', dayPillar, isDay: true)}
  • ${describePillar('시주', hourUnknown ? null : hourPillar)}
- 3주 6글자 본기 오행 분포(시주·지장간 제외, K07-R3 기준): $elText
- 대운 흐름(K04): ${daeunSummary.isEmpty ? '(미산출)' : daeunSummary}
- K05/K08 경계 점검: $warnText''';
  }
}

/// 만세력 계산기.
/// 계산만 담당 (AI 관여 없음). 60갑자 순환 + 절기 기준 월주 + K04 대운 + K05/K08 경계 감지.
class SajuCalculator {
  /// 기준일: 양력 1900-01-01 은 '갑술일'(甲戌日).
  /// 甲(0), 戌(10) → 60갑자 인덱스 = 10.
  /// 검산:
  /// - 1900-01-01 (diff=0) → idx 10 = 갑술(甲戌)
  /// - 2000-01-01 (diff=36524) → (10+36524)%60 = 54 = 무오(戊午)
  /// - 2026-11-16 (diff=46340) → (10+46340)%60 = 30 = 갑오(甲午)
  static final DateTime _refDateUtc = DateTime.utc(1900, 1, 1);
  static const int _refDayIndex = 10;

  static SajuResult calculate({
    required int year,
    required int month,
    required int day,
    int? hour,
    int? minute,
    String? placeName,
    bool applyLocalTime = true,
    String gender = 'female',
    String calendarType = 'solar',
  }) {
    final hourUnknown = hour == null;
    final warnings = <String>[];

    if (calendarType == 'lunar') {
      warnings.add(
        '[K08 음력 입력 주의] 음력 생일이 입력되었습니다. STEP 2에서 만세력 글자(년·월·일·시주)가 본인 실제 만세력과 일치하는지 확인하거나 직접 수정해 주세요.',
      );
    }

    // K05/K08 절입일 전후 48시간 경계 점검
    final termWarn = SolarTerms.checkTermBoundaryWarning(year, month, day);
    if (termWarn != null) {
      warnings.add('[K05/K08 절기 경계] $termWarn');
    }

    // 1) 기본 일시 및 서머타임/진태양시 보정 (시주 산출용)
    DateTime rawDt = DateTime(year, month, day, hour ?? 12, minute ?? 0);
    DateTime solarDt = applyDstCorrection(rawDt);
    if (applyLocalTime && !hourUnknown) {
      final offset = trueSolarOffsetMinutes(placeName);
      solarDt = solarDt.add(Duration(minutes: offset.round()));
    }

    // 2) 일주(日柱): 출생 양력 날짜(UTC 기준 경과일수)로 정확히 산출
    final daysDiff = DateTime.utc(year, month, day).difference(_refDateUtc).inDays;
    final dayIdx = ((_refDayIndex + daysDiff) % 60 + 60) % 60;
    final dayStem = heavenlyStems[dayIdx % 10];
    final dayBranch = earthlyBranches[dayIdx % 12];

    // 3) 년주(年柱): 입춘 기준. 월지 인덱스가 '축'(11)이고 1~2월 초면 전년 처리.
    final monthBr = SolarTerms.monthBranchIndex(year, month, day);
    int sajuYear = year;
    if ((month == 1) || (month == 2 && monthBr == 11)) {
      sajuYear = year - 1;
    }
    // 1864년이 갑자년(년간지 index 0). (year-4)%60 공식 사용.
    final yearIdx = ((sajuYear - 4) % 60 + 60) % 60;
    final yearStem = heavenlyStems[yearIdx % 10];
    final yearBranch = earthlyBranches[yearIdx % 12];

    // 4) 월주(月柱): 월지는 절기로, 월간은 '오호둔'(년간 기준, K02)
    final monthBranchStr = SolarTerms.monthBranchOrder[monthBr];
    final monthStem = _monthStem(yearStem, monthBr);

    // 5) 시주(時柱): 시지(2시간 단위) + 시두법(일간 기준, K01)
    String? hourStem;
    String? hourBranchStr;
    if (!hourUnknown) {
      final rawHourBrIdx = _hourBranchIndex(rawDt.hour);
      final corrHourBrIdx = _hourBranchIndex(solarDt.hour);
      hourBranchStr = earthlyBranches[corrHourBrIdx];
      hourStem = _hourStem(dayStem, corrHourBrIdx);

      // K05/K08 시지 경계(보정 전후 시지 변동) 및 야자시(23시 전후) 점검
      if (rawHourBrIdx != corrHourBrIdx) {
        final rawPillar = _hourStem(dayStem, rawHourBrIdx) + earthlyBranches[rawHourBrIdx];
        final corrPillar = hourStem + hourBranchStr;
        warnings.add(
          '[K05 시지 경계] 출생시각이 시지 경계 30분 이내여서 표준시($rawPillar시)와 진태양시 보정($corrPillar시) 간 시주가 다릅니다.',
        );
      }
      if (rawDt.hour == 23 || solarDt.hour == 23) {
        warnings.add(
          '[K05/K08 자시(야자시/조자시) 경계] 23시~00시 무렵 출생으로 야자시/조자시 적용 기준에 따라 일주·시주가 달라질 수 있습니다.',
        );
      }
    }

    // 6) 대운(大運) 산출 (K04 순역행 공식)
    final daeunText = buildDaeunSummary(
      yearStem: yearStem,
      monthPillar: monthStem + monthBranchStr,
      gender: gender,
      birthYear: year,
      birthMonth: month,
      birthDay: day,
    );

    final yPillar = yearStem + yearBranch;
    final mPillar = monthStem + monthBranchStr;
    final dPillar = dayStem + dayBranch;
    final hPillar = hourUnknown ? null : (hourStem! + hourBranchStr!);

    return SajuResult(
      yearPillar: yPillar,
      monthPillar: mPillar,
      dayPillar: dPillar,
      hourPillar: hPillar,
      dayMaster: dayStem,
      hourUnknown: hourUnknown,
      yearPillarHanja: pillarToHanja(yPillar),
      monthPillarHanja: pillarToHanja(mPillar),
      dayPillarHanja: pillarToHanja(dPillar),
      hourPillarHanja: hPillar == null ? null : pillarToHanja(hPillar),
      daeunSummary: daeunText,
      boundaryWarnings: warnings,
    );
  }

  /// K04 대운 방향 및 10년 대운 리스트 생성
  /// 양년(갑·병·무·경·임) 남 / 음년(을·정·기·신·계) 여 → 순행
  /// 음년 남 / 양년 여 → 역행
  static String buildDaeunSummary({
    required String yearStem,
    required String monthPillar,
    required String gender,
    required int birthYear,
    required int birthMonth,
    required int birthDay,
  }) {
    final isYangYear = stemYang[yearStem] ?? true;
    final isMale = gender == 'male';
    final forward = (isYangYear && isMale) || (!isYangYear && !isMale);
    final dirLabel = forward ? '순행' : '역행';

    final mIdx = ganzhiIndexOf(monthPillar);
    if (mIdx < 0) return '';

    final startAge = SolarTerms.estimateDaeunAge(
      year: birthYear,
      month: birthMonth,
      day: birthDay,
      forward: forward,
    );

    final pillars = <String>[];
    for (int i = 1; i <= 8; i++) {
      final step = forward ? (mIdx + i) : (mIdx - i);
      final p = ganzhiFromIndex(step);
      final hanja = ganzhiHanjaFromIndex(step);
      final aStart = startAge + (i - 1) * 10;
      final aEnd = aStart + 9;
      pillars.add('$p($hanja)[$aStart~$aEnd세]');
    }
    return '$dirLabel (대운수 약 $startAge, 절입일 근사 기준): ${pillars.join(' → ')}';
  }

  /// 오호둔(K02 월두법): 년간에 따라 인월(寅月)의 월간이 정해지고 순행.
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
    final idx = (startIdx + monthBranchIdx) % 10;
    return heavenlyStems[idx];
  }

  /// 시지 인덱스: 23~01시=자(0), 01~03=축(1) ... 2시간 단위 (K01).
  static int _hourBranchIndex(int hour) {
    return (((hour + 1) ~/ 2) % 12);
  }

  /// 시두법(K01): 일간에 따라 자시(子時)의 시간(時干)이 정해지고 순행.
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
