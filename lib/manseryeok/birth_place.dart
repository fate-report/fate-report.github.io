/// 출생지 → 경도 매핑 (진태양시 보정용).
/// 한국 표준시 기준 자오선은 135°E. 실제 경도와의 차이를 분 단위로 보정.
library;

class BirthPlace {
  final String name;
  final double longitude;
  const BirthPlace(this.name, this.longitude);
}

/// 주요 도시 경도 (동경)
const birthPlaces = <BirthPlace>[
  BirthPlace('서울', 126.978),
  BirthPlace('인천', 126.705),
  BirthPlace('수원', 127.028),
  BirthPlace('춘천', 127.729),
  BirthPlace('강릉', 128.896),
  BirthPlace('대전', 127.385),
  BirthPlace('청주', 127.489),
  BirthPlace('전주', 127.148),
  BirthPlace('광주', 126.851),
  BirthPlace('목포', 126.392),
  BirthPlace('대구', 128.601),
  BirthPlace('포항', 129.365),
  BirthPlace('부산', 129.075),
  BirthPlace('울산', 129.311),
  BirthPlace('창원', 128.681),
  BirthPlace('제주', 126.531),
];

/// 표준 자오선 (한국 표준시)
const double koreaMeridian = 135.0;

/// 도시명으로 경도 찾기 (없으면 서울 기준)
double longitudeOf(String? placeName) {
  if (placeName == null) return 126.978;
  final p = birthPlaces.where((e) => e.name == placeName);
  return p.isNotEmpty ? p.first.longitude : 126.978;
}

/// 진태양시 보정 분(minute). 경도 1도당 4분.
/// (실제경도 - 표준자오선) * 4 → 보통 음수(한국은 135보다 서쪽이라 시계를 늦춤)
double trueSolarOffsetMinutes(String? placeName) {
  final lon = longitudeOf(placeName);
  return (lon - koreaMeridian) * 4.0;
}
