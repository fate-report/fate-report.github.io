/// 한국 서머타임(일광절약시간, DST) 보정.
/// 해당 기간에 태어난 경우 시계가 1시간 앞당겨져 있었으므로 1시간을 뺀다.
library;

class DstPeriod {
  final DateTime start;
  final DateTime end;
  const DstPeriod(this.start, this.end);
}

/// 한국에서 서머타임이 시행된 주요 기간들.
final List<DstPeriod> koreanDstPeriods = [
  // 1948~1960년 (여름철 시행)
  DstPeriod(DateTime(1948, 6, 1), DateTime(1948, 9, 13)),
  DstPeriod(DateTime(1949, 4, 3), DateTime(1949, 9, 11)),
  DstPeriod(DateTime(1950, 4, 1), DateTime(1950, 9, 10)),
  DstPeriod(DateTime(1951, 5, 6), DateTime(1951, 9, 9)),
  DstPeriod(DateTime(1955, 5, 5), DateTime(1955, 9, 9)),
  DstPeriod(DateTime(1956, 5, 20), DateTime(1956, 9, 30)),
  DstPeriod(DateTime(1957, 5, 5), DateTime(1957, 9, 22)),
  DstPeriod(DateTime(1958, 5, 4), DateTime(1958, 9, 21)),
  DstPeriod(DateTime(1959, 5, 3), DateTime(1959, 9, 20)),
  DstPeriod(DateTime(1960, 5, 1), DateTime(1960, 9, 18)),
  // 1987~1988년 (서울올림픽 대비)
  DstPeriod(DateTime(1987, 5, 10), DateTime(1987, 10, 11)),
  DstPeriod(DateTime(1988, 5, 8), DateTime(1988, 10, 9)),
];

/// 해당 일시가 서머타임 기간이면 true
bool isDst(DateTime dt) {
  for (final p in koreanDstPeriods) {
    if (dt.isAfter(p.start) && dt.isBefore(p.end)) return true;
  }
  return false;
}

/// 서머타임 보정: 기간이면 1시간을 뺀 시각 반환
DateTime applyDstCorrection(DateTime dt) {
  if (isDst(dt)) {
    return dt.subtract(const Duration(hours: 1));
  }
  return dt;
}
