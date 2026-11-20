import 'ganzhi.dart';
import 'birth_place.dart';
import 'dst_correction.dart';
import 'solar_terms.dart';
import 'lunar_converter.dart';

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
    final kst = SajuCalculator.nowKst();
    final sajuYear = SajuCalculator.activeSeunYear(kst);
    final thisYearGanji = SajuCalculator.seunPillarOfYear(sajuYear);
    final nextYearGanji = SajuCalculator.seunPillarOfYear(sajuYear + 1);

    return '''
- 확정 4주: $yearPillar($yearPillarHanja)년 $monthPillar($monthPillarHanja)월 $dayPillar($dayPillarHanja)일 ${hourUnknown || hourPillar == null ? '(시간 미상 — 3주 6글자 기준)' : '$hourPillar($hourPillarHanja)시'} (기준 일간: $dm / ${stemElements[dm] ?? ''})
  • ${describePillar('년주', yearPillar)}
  • ${describePillar('월주', monthPillar)}
  • ${describePillar('일주', dayPillar, isDay: true)}
  • ${describePillar('시주', hourUnknown ? null : hourPillar)}
- 3주 6글자 본기 오행 분포(시주·지장간 제외, K07-R3 기준): $elText
- 대운 흐름(K04): ${daeunSummary.isEmpty ? '(미산출)' : daeunSummary}
- K05/K08 경계 점검: $warnText
- [시간 기준점 락 (K03·K10)]: 현재 연도(올해)는 ${kst.year}년($thisYearGanji년 세운)이며, 내년은 ${kst.year + 1}년($nextYearGanji년 세운)입니다.''';
  }
}

/// 만세력 계산기.
/// 계산만 담당 (AI 관여 없음). 60갑자 순환 + 정밀 절입 시각 기준 년·월주 + K04 대운 + K05/K08 경계 감지.
class SajuCalculator {
  /// 기준일: 양력 1900-01-01 은 '갑술일'(甲戌日).
  /// 甲(0), 戌(10) → 60갑자 인덱스 = 10.
  static final DateTime _refDateUtc = DateTime.utc(1900, 1, 1);
  static const int _refDayIndex = 10;

  /// 한국 표준시(KST, UTC+9) 기준 현재 시각 반환 (타임존 무관 단일 기준)
  static DateTime nowKst([DateTime? overrideNow]) {
    if (overrideNow != null) {
      return overrideNow.year >= 2026
          ? overrideNow
          : DateTime(
              2026,
              overrideNow.month,
              overrideNow.day,
              overrideNow.hour,
              overrideNow.minute,
            );
    }
    final utc = DateTime.now().toUtc();
    final kst = utc.add(const Duration(hours: 9));
    final y = kst.year >= 2026 ? kst.year : 2026;
    return DateTime(y, kst.month, kst.day, kst.hour, kst.minute);
  }

  /// K03 입춘 기준 현재 적용되는 세운 연도 반환
  static int activeSeunYear(DateTime kst) {
    final beforeIpchun = SolarTerms.isBeforeIpchun(
      kst.year,
      kst.month,
      kst.day,
      hour: kst.hour,
      minute: kst.minute,
    );
    return beforeIpchun ? (kst.year - 1) : kst.year;
  }

  /// 특정 연도의 K03 세운 간지 반환 (예: 2026 -> '병오(丙午)')
  static String seunPillarOfYear(int year) {
    final idx = ((year - 4) % 60 + 60) % 60;
    return '${ganzhiFromIndex(idx)}(${ganzhiHanjaFromIndex(idx)})';
  }

  /// 특정 연도의 양력 1~12월 절기 기준 월운(月運) 간지 조견표 생성 (사용자가 '몇 월', '상반기/하반기', '이번 달/다음 달' 질문 시 정밀 대응용)
  static String buildYearlyMonthPillars(int year, {String? dayMaster}) {
    // 양력 각 월 중순(15일) 기준 절기월 간지 산출:
    // 1월(축월, 직전년 년간 기준), 2월(인월, 당해 년간 기준) ~ 12월(자월, 당해 년간 기준)
    final curYearIdx = ((year - 4) % 60 + 60) % 60;
    final curYearStem = heavenlyStems[curYearIdx % 10];
    final prevYearIdx = ((year - 5) % 60 + 60) % 60;
    final prevYearStem = heavenlyStems[prevYearIdx % 10];

    final items = <String>[];
    for (int m = 1; m <= 12; m++) {
      // 양력 m월의 절기월 인덱스: 1월=11(축), 2월=0(인), 3월=1(묘) ... 12월=10(자)
      final mBrIdx = (m == 1) ? 11 : (m - 2);
      final yStem = (m == 1) ? prevYearStem : curYearStem;
      final mStem = _monthStem(yStem, mBrIdx);
      final mBranch = SolarTerms.monthBranchOrder[mBrIdx];
      final pillar = '$mStem$mBranch';
      final hanja = pillarToHanja(pillar);
      final tenGod = (dayMaster != null && dayMaster.isNotEmpty)
          ? '(${calculateTenGod(dayMaster, mStem)}/${calculateTenGod(dayMaster, (branchHiddenStems[mBranch] ?? const ['']).first)})'
          : '';
      items.add('$m월=$pillar($hanja)$tenGod');
    }
    return items.join(', ');
  }

  /// 음력/윤달 여부를 반영하여 실제 양력 생년월일로 변환
  static DateTime resolveSolarBirthDate(
    DateTime rawDate,
    String calendarType,
  ) {
    if (calendarType == 'lunar' || calendarType == 'lunar_leap') {
      final conv = LunarConverter.toSolar(
        rawDate.year,
        rawDate.month,
        rawDate.day,
        isLeapMonth: calendarType == 'lunar_leap',
      );
      if (conv != null) return conv.solarDate;
    }
    return rawDate;
  }

  /// 한국 표준 만세력 기준 만 나이 및 연 나이(세는나이) 단일 계산
  static (int manAge, int koreanAge) calculateAges(
    DateTime rawBirthDate,
    String calendarType, {
    DateTime? now,
  }) {
    final kst = nowKst(now);
    final solarBirth = resolveSolarBirthDate(rawBirthDate, calendarType);
    final koreanAge = (kst.year - solarBirth.year + 1).clamp(1, 120);
    final beforeBirthday = kst.month < solarBirth.month ||
        (kst.month == solarBirth.month && kst.day < solarBirth.day);
    final manAge =
        (kst.year - solarBirth.year - (beforeBirthday ? 1 : 0)).clamp(0, 120);
    return (manAge, koreanAge);
  }

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

    int sYear = year;
    int sMonth = month;
    int sDay = day;

    final isLunar = calendarType == 'lunar' || calendarType == 'lunar_leap';
    final isLeapReq = calendarType == 'lunar_leap';

    if (isLunar) {
      final conv = LunarConverter.toSolar(
        year,
        month,
        day,
        isLeapMonth: isLeapReq,
      );
      if (conv != null) {
        sYear = conv.solarDate.year;
        sMonth = conv.solarDate.month;
        sDay = conv.solarDate.day;
        if (conv.wasDayClamped) {
          warnings.add(
            '[음력 소월(29일) 자동 보정] 해당 음력 월은 29일까지 있는 작은달(小月)이므로 29일 기준으로 양력 $sYear년 $sMonth월 $sDay일로 변환했습니다.',
          );
        }
        if (conv.isLeapMonthApplied) {
          warnings.add(
            '[음력 윤달→양력 자동 변환 완료] 음력 $year년 윤$month월 ${conv.wasDayClamped ? 29 : day}일 → 양력 $sYear년 $sMonth월 $sDay일로 정밀 변환했습니다.',
          );
        } else if (conv.hasLeapMonthInSameMonth) {
          warnings.add(
            '[K08 음력·윤달 경계 확인] 음력 $year년 $month월 $day일 → 양력 $sYear년 $sMonth월 $sDay일(평달 기준)로 변환했습니다. $year년은 윤$month월이 존재하는 해이므로 윤달 출생이시라면 STEP 1에서 [음력(윤달)]을 선택해 주세요.',
          );
        } else {
          warnings.add(
            '[음력→양력 자동 변환 완료] 음력 $year년 $month월 $day일 → 양력 $sYear년 $sMonth월 $sDay일로 자동 변환하여 계산했습니다.',
          );
        }
      } else {
        warnings.add(
          '[K08 음력 입력 주의] 음력 변환 범위(1920~2035년) 밖의 날짜입니다. STEP 2에서 만세력 글자를 직접 확인·수정해 주세요.',
        );
      }
    }

    // 1) 기본 일시 및 서머타임/진태양시(역사적 표준자오선 127.5°E/135.0°E 포함) 보정
    final rawDt = DateTime(sYear, sMonth, sDay, hour ?? 12, minute ?? 0);
    final dstDt = hourUnknown ? rawDt : applyDstCorrection(rawDt);
    DateTime solarDt = dstDt;
    if (!hourUnknown && applyLocalTime) {
      final offset = trueSolarOffsetMinutes(placeName, birthDate: dstDt);
      solarDt = dstDt.add(Duration(minutes: offset.round()));
    }

    if (!hourUnknown && isDst(rawDt)) {
      warnings.add(
        '[K05 서머타임(DST) 자동 보정] 대한민국 서머타임 시행 기간 출생으로 1시간을 차감하여 계산했습니다.',
      );
    }

    // K05/K08 절입 시각 전후 24시간 경계 점검
    final termWarn = SolarTerms.checkTermBoundaryWarning(
      solarDt.year,
      solarDt.month,
      solarDt.day,
      hour: hourUnknown ? null : solarDt.hour,
      minute: hourUnknown ? null : solarDt.minute,
    );
    if (termWarn != null) {
      warnings.add('[K05/K08 절기 경계] $termWarn');
    }

    // 2) 일주(日柱) 및 자정/자시(23:00~01:00) 경계 정합성 처리
    // - 서머타임(-1h)이나 진태양시 보정으로 실제 태양시가 전날 22:59 이전(해시 등)으로 넘어간 경우:
    //   일주 날짜도 반드시 보정된 날짜(solarDt)를 따라야 일주와 시주가 분리되지 않는다.
    // - 실제 태양시가 23:00~23:59(자시)인 경우:
    //   • 표준시(dstDt)가 이미 자정(00:00) 이후(예: 00:15 KST -> 진태양시 전날 23:43)이면 조자시(朝子時)이므로 당일(dstDt) 일주를 사용한다.
    //   • 표준시(dstDt)가 자정 이전(예: 23:40 KST -> 진태양시 당일 23:08)이면 야자시/정자시 경계 구간이다.
    int dayYear = sYear;
    int dayMonth = sMonth;
    int dayDay = sDay;

    if (!hourUnknown) {
      final solarDateOnly = DateTime(solarDt.year, solarDt.month, solarDt.day);
      final dstDateOnly = DateTime(dstDt.year, dstDt.month, dstDt.day);
      if (solarDt.hour < 23 && solarDateOnly.isBefore(dstDateOnly)) {
        // 진태양시 보정 후 전날 해시(21:00~22:59) 이전으로 넘어간 경우
        dayYear = solarDt.year;
        dayMonth = solarDt.month;
        dayDay = solarDt.day;
      } else {
        // 서머타임 보정만으로도 자정 이전으로 넘어간 경우(예: 00:30 DST -> 전날 23:30) dstDt 날짜를 따른다
        dayYear = dstDt.year;
        dayMonth = dstDt.month;
        dayDay = dstDt.day;
      }
    }

    final daysDiff =
        DateTime.utc(dayYear, dayMonth, dayDay).difference(_refDateUtc).inDays;
    final dayIdx = ((_refDayIndex + daysDiff) % 60 + 60) % 60;
    final dayStem = heavenlyStems[dayIdx % 10];
    final dayBranch = earthlyBranches[dayIdx % 12];

    // 3) 년주(年柱) & 4) 월주(月柱): 정밀 절입 시각(입춘·12절기 시·분) 기준 산출
    final effYear = hourUnknown ? sYear : solarDt.year;
    final effMonth = hourUnknown ? sMonth : solarDt.month;
    final effDay = hourUnknown ? sDay : solarDt.day;
    final effHour = hourUnknown ? 12 : solarDt.hour;
    final effMin = hourUnknown ? 0 : solarDt.minute;

    final monthBr = SolarTerms.monthBranchIndex(
      effYear,
      effMonth,
      effDay,
      hour: effHour,
      minute: effMin,
    );
    final beforeIpchun = SolarTerms.isBeforeIpchun(
      effYear,
      effMonth,
      effDay,
      hour: effHour,
      minute: effMin,
    );
    final sajuYear = beforeIpchun ? (effYear - 1) : effYear;

    // 1864년이 갑자년(년간지 index 0). (year-4)%60 공식 사용.
    final yearIdx = ((sajuYear - 4) % 60 + 60) % 60;
    final yearStem = heavenlyStems[yearIdx % 10];
    final yearBranch = earthlyBranches[yearIdx % 12];

    final monthBranchStr = SolarTerms.monthBranchOrder[monthBr];
    final monthStem = _monthStem(yearStem, monthBr);

    // 5) 시주(時柱): 시지(2시간 단위) + 시두법(일간 기준, K01)
    String? hourStem;
    String? hourBranchStr;
    if (!hourUnknown) {
      final rawHourBrIdx = _hourBranchIndex(dstDt.hour);
      final corrHourBrIdx = _hourBranchIndex(solarDt.hour);
      hourBranchStr = earthlyBranches[corrHourBrIdx];

      // 자정 이전 밤 자시(진태양시 23:00~23:59 이면서 dstDt가 23시대인 야자시 구간):
      // 야자시법에서는 일주는 당일(dayStem)을 유지하되 시주 천간은 다음날 일간(nextDayStem)의 시두법을 적용하고,
      // 정자시법에서는 일주와 시주 모두 다음날 일주(nextDayPillar) 기준으로 넘어간다.
      final isNightJasiBeforeMidnight =
          solarDt.hour == 23 && dstDt.hour == 23;
      if (isNightJasiBeforeMidnight) {
        final nextDayIdx = (dayIdx + 1) % 60;
        final nextDayStem = heavenlyStems[nextDayIdx % 10];
        final nextDayPillar = ganzhiFromIndex(nextDayIdx);
        // 야자시 표준 시두법(익일 일간 기준 자시 천간) 적용
        hourStem = _hourStem(nextDayStem, corrHourBrIdx);
        final yajaHourPillar = hourStem + hourBranchStr;
        final sameDayHourPillar =
            _hourStem(dayStem, corrHourBrIdx) + hourBranchStr;
        warnings.add(
          '[K05/K08 야자시·정자시 경계] 밤 23시~24시 자시 출생입니다. 야자시 기준(${dayStem + dayBranch}일 $yajaHourPillar시)으로 계산되었으며, 정자시(23시 일주 변경) 기준으로는 [${nextDayPillar}일 $yajaHourPillar시], 당일 시두법 기준으로는 [${dayStem + dayBranch}일 $sameDayHourPillar시]가 됩니다. 사용하시는 만세력 기준에 맞춰 STEP 2에서 직접 수정할 수 있습니다.',
        );
      } else {
        hourStem = _hourStem(dayStem, corrHourBrIdx);
        if (dstDt.hour == 0 && solarDt.hour == 23) {
          warnings.add(
            '[K05/K08 조자시(00:00~00:31) 확인] 자정(00:00) 이후 출생으로 진태양시 보정 후에도 당일 조자시(${dayStem + dayBranch}일 ${hourStem + hourBranchStr}시)로 확정되었습니다.',
          );
        }
      }

      // K05/K08 시지 경계(보정 전후 시지 변동) 점검
      if (rawHourBrIdx != corrHourBrIdx) {
        final rawPillar =
            _hourStem(dayStem, rawHourBrIdx) + earthlyBranches[rawHourBrIdx];
        final corrPillar = hourStem + hourBranchStr;
        warnings.add(
          '[K05 시지 경계] 출생시각이 시지 경계 30분 이내여서 표준시($rawPillar시)와 진태양시 보정($corrPillar시) 간 시주가 다릅니다.',
        );
      }
    }

    // 6) 대운(大運) 산출 (K04 순역행 공식 + 정밀 절입 시각 간격)
    final daeunText = buildDaeunSummary(
      yearStem: yearStem,
      monthPillar: monthStem + monthBranchStr,
      gender: gender,
      birthYear: effYear,
      birthMonth: effMonth,
      birthDay: effDay,
      birthHour: effHour,
      birthMinute: effMin,
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

  /// STEP 2에서 사용자가 직접 사주 8글자를 수정했을 때 대운(daeunSummary)과 K01/K02 정합성을 즉시 재계산
  static SajuResult recalculateWithManualPillars({
    required String yearPillar,
    required String monthPillar,
    required String dayPillar,
    String? hourPillar,
    required String gender,
    DateTime? birthDate,
    String calendarType = 'solar',
  }) {
    final yp = yearPillar.trim();
    final mp = monthPillar.trim();
    final dp = dayPillar.trim();
    final hp = (hourPillar == null || hourPillar.trim().isEmpty)
        ? null
        : hourPillar.trim();
    final dm = dp.isNotEmpty ? dp[0] : '';

    // 음력 생일인 경우 양력으로 먼저 변환하여 대운수와 나이를 정확히 계산
    final solarBirth = birthDate != null
        ? resolveSolarBirthDate(birthDate, calendarType)
        : DateTime(1995, 6, 15);

    final daeun = (yp.isNotEmpty && mp.length >= 2)
        ? buildDaeunSummary(
            yearStem: yp[0],
            monthPillar: mp,
            gender: gender,
            birthYear: solarBirth.year,
            birthMonth: solarBirth.month,
            birthDay: solarBirth.day,
          )
        : '';

    final manualWarnings = <String>[
      '[K04 수동 확정 완료] 사용자가 직접 확인·수정한 명식(K04 최우선 기준)으로 고정되었습니다.',
    ];

    // K02(월두법) 및 K01(시두법) 간지 조합 정합성 참고 안내
    if (yp.length >= 2 && mp.length >= 2) {
      final mBrIdx = SolarTerms.monthBranchOrder.indexOf(mp[1]);
      if (mBrIdx >= 0) {
        final expectedMStem = _monthStem(yp[0], mBrIdx);
        if (expectedMStem != mp[0]) {
          manualWarnings.add(
            '[K02 월두법 참고] 입력하신 년간(${yp[0]}) 기준 ${mp[1]}월의 표준 월주는 "$expectedMStem${mp[1]}"이나, 사용자 수동 확정값("$mp")을 우선 적용합니다.',
          );
        }
      }
    }
    if (dp.length >= 2 && hp != null && hp.length >= 2) {
      final hBrIdx = earthlyBranches.indexOf(hp[1]);
      if (hBrIdx >= 0) {
        final expectedHStem = _hourStem(dp[0], hBrIdx);
        if (expectedHStem != hp[0] && hBrIdx != 0) {
          manualWarnings.add(
            '[K01 시두법 참고] 입력하신 일간(${dp[0]}) 기준 ${hp[1]}시의 표준 시주는 "$expectedHStem${hp[1]}"이나, 사용자 수동 확정값("$hp")을 우선 적용합니다.',
          );
        }
      }
    }

    return SajuResult(
      yearPillar: yp,
      monthPillar: mp,
      dayPillar: dp,
      hourPillar: hp,
      dayMaster: dm,
      hourUnknown: hp == null,
      yearPillarHanja: pillarToHanja(yp),
      monthPillarHanja: pillarToHanja(mp),
      dayPillarHanja: pillarToHanja(dp),
      hourPillarHanja: hp == null ? null : pillarToHanja(hp),
      daeunSummary: daeun,
      boundaryWarnings: manualWarnings,
    );
  }

  /// K04 대운 방향 및 10년 대운 리스트 생성 (현재 나이 및 현재 해당 대운 핀포인트 표시)
  /// 양년(갑·병·무·경·임) 남 / 음년(을·정·기·신·계) 여 → 순행
  /// 음년 남 / 양년 여 → 역행
  static String buildDaeunSummary({
    required String yearStem,
    required String monthPillar,
    required String gender,
    required int birthYear,
    required int birthMonth,
    required int birthDay,
    int birthHour = 12,
    int birthMinute = 0,
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
      hour: birthHour,
      minute: birthMinute,
      forward: forward,
    );

    final kst = nowKst();
    final currentYear = kst.year;
    final beforeBirthday = kst.month < birthMonth ||
        (kst.month == birthMonth && kst.day < birthDay);
    final manAge =
        (currentYear - birthYear - (beforeBirthday ? 1 : 0)).clamp(0, 120);
    final koreanAge = (currentYear - birthYear + 1).clamp(1, 120);

    String currentDaeunTag = '';
    final pillars = <String>[];
    for (int i = 1; i <= 8; i++) {
      final step = forward ? (mIdx + i) : (mIdx - i);
      final p = ganzhiFromIndex(step);
      final hanja = ganzhiHanjaFromIndex(step);
      final aStart = startAge + (i - 1) * 10;
      final aEnd = aStart + 9;
      // 한국 명리 표준 대운수는 연 나이(세는나이, koreanAge) 기준이므로 koreanAge 단일 기준으로 판정하여
      // 대운 전환 연도(koreanAge == aStart)에 이전 대운이 잘못 선택되는 Off-by-One 버그를 방지한다.
      final isCurrent = koreanAge >= aStart && koreanAge <= aEnd;
      if (isCurrent && currentDaeunTag.isEmpty) {
        final transitionNote = (koreanAge == aStart) ? '·올해 대운 전환기' : '·현재';
        currentDaeunTag = '$p($hanja)[$aStart~$aEnd세$transitionNote]';
        pillars.add('★$p($hanja)[$aStart~$aEnd세$transitionNote]');
      } else {
        pillars.add('$p($hanja)[$aStart~$aEnd세]');
      }
    }
    final activeDesc =
        currentDaeunTag.isEmpty ? '초년 대운 진입 전' : currentDaeunTag;
    return '$dirLabel (대운수 $startAge | $currentYear년 현재 만 $manAge세·연 $koreanAge세 → 현재 대운: $activeDesc): ${pillars.join(' → ')}';
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
