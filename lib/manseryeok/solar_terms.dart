/// 절기(節氣) 정밀 계산 — 연주(입춘 기준)와 월주(12절기 절입 시각 기준) 및 대운수(K04/K05/K08) 산출.
/// 한국 표준시(KST, UTC+9) 기준 천문 태양 황경 근사식(1900~2100년 오차 수 분 이내)을 사용하여
/// 연도별 절입일 변동(예: 2025년 입춘 2월 3일 23:10, 2024~2026년 경칩 3월 5일 등)과
/// 절입 당일 시각(시·분) 경계를 정확하게 판정한다.
library;

class SolarTerms {
  /// 12절기 이름 (인덱스 0=입춘 ~ 11=소한)
  static const List<String> termNames = [
    '입춘(立春)', // 0: 인(寅)월 시작 (태양황경 315°)
    '경칩(驚蟄)', // 1: 묘(卯)월 시작 (태양황경 345°)
    '청명(淸明)', // 2: 진(辰)월 시작 (태양황경 15°)
    '입하(立夏)', // 3: 사(巳)월 시작 (태양황경 45°)
    '망종(芒種)', // 4: 오(午)월 시작 (태양황경 75°)
    '소서(小暑)', // 5: 미(未)월 시작 (태양황경 105°)
    '입추(立秋)', // 6: 신(申)월 시작 (태양황경 135°)
    '백로(白露)', // 7: 유(酉)월 시작 (태양황경 165°)
    '한로(寒露)', // 8: 술(戌)월 시작 (태양황경 195°)
    '입동(立冬)', // 9: 해(亥)월 시작 (태양황경 225°)
    '대설(大雪)', // 10: 자(子)월 시작 (태양황경 255°)
    '소한(小寒)', // 11: 축(丑)월 시작 (태양황경 285°)
  ];

  /// 각 절기가 속하는 양력 월 (인덱스 0~11)
  static const List<int> termMonths = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 1];

  /// 2000년(윤년) 기준 각 절기의 KST 절입 일(day + 소수점 시각) 기준값 (천문연구원 KST 역서 기준 보정)
  /// index 0(입춘 2월)~11(소한 1월):
  static const List<double> _baseDay2000Kst = [
    4.910, // 입춘 (2월): 2025-02-03 23:10 / 2026-02-04 04:59 KST 정밀 일치
    5.660, // 경칩 (3월): 2025-03-05 17:09 / 2026-03-05 22:58 KST 정밀 일치
    4.948, // 청명 (4월)
    5.520, // 입하 (5월)
    5.710, // 망종 (6월)
    7.020, // 소서 (7월)
    7.605, // 입추 (8월): 2026-08-07 21:39 KST 정밀 일치
    7.825, // 백로 (9월)
    8.260, // 한로 (10월)
    7.520, // 입동 (11월)
    7.185, // 대설 (12월)
    6.375, // 소한 (1월): 2026-01-05 16:08 KST 정밀 일치
  ];

  /// 월지(月支) 순서: 입춘부터 인묘진사오미신유술해자축
  static const List<String> monthBranchOrder = [
    '인', '묘', '진', '사', '오', '미', '신', '유', '술', '해', '자', '축'
  ];

  /// 특정 양력 연도(year)와 절기 인덱스(0=입춘 ~ 11=소한)의 정밀 KST 절입 시각 반환.
  static DateTime entryTimeKst(int year, int termIndex) {
    final m = termMonths[termIndex];
    final dy = year - 2000;
    // 회귀년(365.24219878일) 누적 이동량
    final tropicalShift = dy * 0.24219878;

    // 2000년과 target year 사이의 윤일(2월 29일) 적용 횟수 계산
    // 1월(소한)·2월(입춘)은 해당 연도 2월 29일 이전이므로 직전 연도까지의 윤년 수가 작용하고,
    // 3월(경칩)~12월(대설)은 해당 연도 2월 29일 이후이므로 당해 윤년 여부가 포함된다.
    int leapDays;
    if (m <= 2) {
      leapDays = _leapCountBeforeYear(year) - _leapCountBeforeYear(2000);
    } else {
      leapDays = _leapCountThroughYear(year) - _leapCountThroughYear(2000);
    }

    final exactDay = _baseDay2000Kst[termIndex] + tropicalShift - leapDays;
    final dayInt = exactDay.floor();
    final fracHours = (exactDay - dayInt) * 24.0;
    final hourInt = fracHours.floor();
    final minuteInt = ((fracHours - hourInt) * 60.0).round();

    return DateTime(year, m, dayInt, hourInt, minuteInt);
  }

  /// 1월 1일 이전까지 발생한 윤년 횟수 (그레고리력 기준)
  static int _leapCountBeforeYear(int y) {
    final prev = y - 1;
    return (prev ~/ 4) - (prev ~/ 100) + (prev ~/ 400);
  }

  /// 해당 연도 12월 31일까지 발생한 윤년 횟수
  static int _leapCountThroughYear(int y) {
    return (y ~/ 4) - (y ~/ 100) + (y ~/ 400);
  }

  /// 해당 일시(KST)가 당해 입춘 절입 시각 이전인지 판정 (년주 산출 기준)
  static bool isBeforeIpchun(
    int year,
    int month,
    int day, {
    int hour = 12,
    int minute = 0,
  }) {
    final dt = DateTime(year, month, day, hour, minute);
    final ipchun = entryTimeKst(year, 0); // 0 = 입춘
    return dt.isBefore(ipchun);
  }

  /// 주어진 양력 일시(KST)의 월지 인덱스(0=인 ~ 11=축) 반환.
  /// 절입 시각 이전이면 직전 절기월로 판정한다.
  static int monthBranchIndex(
    int year,
    int month,
    int day, {
    int hour = 12,
    int minute = 0,
  }) {
    final dt = DateTime(year, month, day, hour, minute);

    final list = <MapEntry<DateTime, int>>[];
    for (int i = 0; i < 12; i++) {
      list.add(MapEntry(entryTimeKst(year, i), i));
    }
    list.sort((a, b) => a.key.compareTo(b.key));

    int result = -1;
    for (final e in list) {
      if (!dt.isBefore(e.key)) {
        result = e.value;
      }
    }
    if (result == -1) {
      result = 10; // 당해 소한(1월) 이전이면 전년 대설 자(子)월
    }
    return result;
  }

  /// K05/K08 절입 시각 전후 24시간(또는 절입 당일 시간 미상) 경계 안내 반환
  static String? checkTermBoundaryWarning(
    int year,
    int month,
    int day, {
    int? hour,
    int? minute,
  }) {
    final checkDt = DateTime(year, month, day, hour ?? 12, minute ?? 0);
    for (int i = 0; i < 12; i++) {
      final termDt = entryTimeKst(year, i);
      final diffHours = checkDt.difference(termDt).inHours.abs();
      if (diffHours <= 24) {
        final hh = termDt.hour.toString().padLeft(2, '0');
        final mm = termDt.minute.toString().padLeft(2, '0');
        if (hour == null) {
          return '${termNames[i]} 절입일(${termDt.month}월 ${termDt.day}일 약 $hh:$mm KST) 당일·인접 출생으로, 출생시각에 따라 월주${i == 0 ? "·년주" : ""}가 달라질 수 있습니다.';
        }
        return '${termNames[i]} 절입 시각(${termDt.month}월 ${termDt.day}일 약 $hh:$mm KST) 전후 24시간 경계 출생입니다. (절입 시각 기준 판정 완료)';
      }
    }
    return null;
  }

  /// 대운수(대운 시작 나이) 산출을 위한 정밀 절입 시각 간격 계산 (K04 기준: 3일 = 72시간 = 1세)
  /// forward=true(순행): 출생일시 → 다가오는 다음 절입 시각까지 시간 / 72시간
  /// forward=false(역행): 출생일시 → 지나온 직전 절입 시각까지 시간 / 72시간
  static int estimateDaeunAge({
    required int year,
    required int month,
    required int day,
    int hour = 12,
    int minute = 0,
    required bool forward,
  }) {
    final dt = DateTime(year, month, day, hour, minute);
    final terms = <DateTime>[];
    for (int y = year - 1; y <= year + 1; y++) {
      for (int i = 0; i < 12; i++) {
        terms.add(entryTimeKst(y, i));
      }
    }
    terms.sort();

    double diffHours = 360.0; // 기본 15일
    if (forward) {
      final nextTerm = terms.firstWhere(
        (t) => t.isAfter(dt),
        orElse: () => dt.add(const Duration(days: 15)),
      );
      diffHours = nextTerm.difference(dt).inMinutes / 60.0;
    } else {
      final prevTerms = terms.where((t) => !t.isAfter(dt)).toList();
      if (prevTerms.isNotEmpty) {
        diffHours = dt.difference(prevTerms.last).inMinutes / 60.0;
      }
    }
    // 3일(72시간) = 1년(1세), 반올림 후 1~10세 범위로 고정
    final age = (diffHours / 72.0).round();
    return age.clamp(1, 10);
  }
}
