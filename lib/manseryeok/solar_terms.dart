/// 절기(節氣) 계산 — 월주(月柱)의 지지를 정하는 기준.
/// 정밀 천문 계산 대신, 실용적으로 각 월의 절입일 근사값을 사용한다.
/// (사주에서 월은 '입춘'부터 한 해가 시작되고, 각 절기 경계로 월이 바뀐다)
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

  /// 월지(月支) 순서: 입춘부터 인묘진사오미신유술해자축
  static const List<String> monthBranchOrder = [
    '인', '묘', '진', '사', '오', '미', '신', '유', '술', '해', '자', '축'
  ];

  /// 주어진 양력 날짜의 월지 인덱스(0~11)를 반환.
  /// 절입일 이전이면 전 달 간지로 본다.
  static int monthBranchIndex(int year, int month, int day) {
    // 각 절기 경계를 연 단위 타임라인으로 만들어 비교
    // termDates는 입춘(2월)부터 시작하므로, 1월 소한은 전년 축월의 연장.
    final date = DateTime(year, month, day);

    // 올해 각 절기의 실제 DateTime
    final boundaries = <DateTime>[];
    for (final t in termDates) {
      int ty = year;
      // 소한(1월)은 배열 마지막이지만 연초이므로 그대로 올해
      boundaries.add(DateTime(ty, t[0], t[1]));
    }

    // termDates 순서대로: 입춘(2/4)...대설(12/7), 소한(1/6)
    // 소한은 1월이라 시간상 입춘보다 앞. 비교를 위해 정렬된 경계와 월지를 함께 만든다.
    final list = <MapEntry<DateTime, int>>[];
    for (int i = 0; i < termDates.length; i++) {
      final t = termDates[i];
      list.add(MapEntry(DateTime(year, t[0], t[1]), i));
    }
    list.sort((a, b) => a.key.compareTo(b.key));

    // date가 속하는 구간 찾기: 가장 최근에 지난 절기의 월지
    int result = -1;
    for (final e in list) {
      if (!date.isBefore(e.key)) {
        result = e.value;
      }
    }
    // date가 올해 첫 절기(소한, 1/6)보다도 이전이면 → 전년 대설 자월(인덱스10)
    if (result == -1) {
      result = 10; // 자
    }
    return result;
  }
}
