/// 절기(節氣) 계산 — 월주(月柱)의 지지를 정하는 기준 및 K05/K08 절입 경계 감지.
library;

class SolarTerms {
  /// 12절기의 대략적 양력 날짜 (월, 일). 절입일 근사.
  /// 인덱스 0=입춘(2월), 1=경칩(3월) ... 순서대로 월지 寅卯辰巳午未申酉戌亥子丑
  static const List<List<int>> termDates = [
    [2, 4],   // 입춘 → 인(寅)월 시작
    [3, 6],   // 경칩 → 묘(卯)
    [4, 5],   // 청명 → 진(辰)
    [5, 6],   // 입하 → 사(巳)
    [6, 6],   // 망종 → 오(午)
    [7, 7],   // 소서 → 미(未)
    [8, 8],   // 입추 → 신(申)
    [9, 8],   // 백로 → 유(酉)
    [10, 8],  // 한로 → 술(戌)
    [11, 7],  // 입동 → 해(亥)
    [12, 7],  // 대설 → 자(子)
    [1, 6],   // 소한 → 축(丑)
  ];

  static const List<String> termNames = [
    '입춘(立春)',
    '경칩(驚蟄)',
    '청명(淸明)',
    '입하(立夏)',
    '망종(芒種)',
    '소서(小暑)',
    '입추(立秋)',
    '백로(白露)',
    '한로(寒露)',
    '입동(立冬)',
    '대설(大雪)',
    '소한(小寒)',
  ];

  /// 월지(月支) 순서: 입춘부터 인묘진사오미신유술해자축
  static const List<String> monthBranchOrder = [
    '인', '묘', '진', '사', '오', '미', '신', '유', '술', '해', '자', '축'
  ];

  /// 주어진 양력 날짜의 월지 인덱스(0~11)를 반환.
  /// 절입일 이전이면 전 달 간지로 본다.
  static int monthBranchIndex(int year, int month, int day) {
    final date = DateTime.utc(year, month, day);

    final list = <MapEntry<DateTime, int>>[];
    for (int i = 0; i < termDates.length; i++) {
      final t = termDates[i];
      list.add(MapEntry(DateTime.utc(year, t[0], t[1]), i));
    }
    list.sort((a, b) => a.key.compareTo(b.key));

    int result = -1;
    for (final e in list) {
      if (!date.isBefore(e.key)) {
        result = e.value;
      }
    }
    if (result == -1) {
      result = 10; // 자(子)월
    }
    return result;
  }

  /// K05/K08 절입 전후 48시간(±1일) 경계 여부 및 해당 절기명 반환
  static String? checkTermBoundaryWarning(int year, int month, int day) {
    final date = DateTime.utc(year, month, day);
    for (int i = 0; i < termDates.length; i++) {
      final t = termDates[i];
      final termDt = DateTime.utc(year, t[0], t[1]);
      final diffDays = date.difference(termDt).inDays.abs();
      if (diffDays <= 1) {
        return '${termNames[i]} 절입일(${t[0]}월 ${t[1]}일경) 전후 48시간 경계에 해당하여 정확한 절입 시각에 따라 월주(입춘은 년주 포함)가 달라질 수 있습니다.';
      }
    }
    return null;
  }

  /// 대운수(대운 시작 나이) 산출을 위한 절입일 간격 계산 (K04 기준)
  /// forward=true(순행): 출생일 → 다가오는 다음 절입일까지 일수 / 3
  /// forward=false(역행): 출생일 → 지나온 직전 절입일까지 일수 / 3
  static int estimateDaeunAge({
    required int year,
    required int month,
    required int day,
    required bool forward,
  }) {
    final date = DateTime.utc(year, month, day);
    final terms = <DateTime>[];
    for (int y = year - 1; y <= year + 1; y++) {
      for (final t in termDates) {
        terms.add(DateTime.utc(y, t[0], t[1]));
      }
    }
    terms.sort();

    int days = 15;
    if (forward) {
      final nextTerm = terms.firstWhere(
        (t) => t.isAfter(date),
        orElse: () => date.add(const Duration(days: 15)),
      );
      days = nextTerm.difference(date).inDays;
    } else {
      final prevTerms = terms.where((t) => !t.isAfter(date)).toList();
      if (prevTerms.isNotEmpty) {
        days = date.difference(prevTerms.last).inDays;
      }
    }
    final age = (days / 3.0).round();
    return age.clamp(1, 10);
  }
}
