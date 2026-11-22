/// 출생지 → 경도 매핑 (진태양시 보정용 — 대한민국 전국 161개 특·광역시·시·군 전수 수록).
/// 한국 표준시 기준 자오선은 135°E (1908~1911, 1954~1961년은 127.5°E).
/// 실제 경도와의 차이를 경도 1도당 4분으로 환산하여 진태양시를 보정한다.
library;

class BirthPlace {
  final String name; // 표시 및 저장 키 (동명 지역은 '경기 광주', '강원 고성', '경남 고성'으로 구분)
  final String region; // 광역 시·도 약칭 (서울, 경기, 강원, 충북, 충남, 전북, 전남, 경북, 경남, 제주 등)
  final String group; // UI 권역 필터 ('수도권' | '강원' | '충청·세종' | '전라' | '경상' | '제주')
  final double longitude; // 동경 (WGS84 시청·군청 대표 좌표)
  final List<String> aliases; // 구 행정구역·대표 신도시 검색 별칭 (예: 마산→창원, 분당→성남)

  const BirthPlace(
    this.name,
    this.longitude, {
    required this.region,
    required this.group,
    this.aliases = const [],
  });

  /// 표준시(135°E) 기준 대략적 진태양시 보정 분 (표시용)
  int get standardOffsetMinutes => ((longitude - koreaMeridian) * 4.0).round();

  /// 검색어 일치 여부 (시·군명, 광역시·도, 통합 전 지명/신도시 별칭 지원)
  bool matchesQuery(String rawQuery) {
    final q = rawQuery.trim().toLowerCase();
    if (q.isEmpty) return true;
    String normQ = q
        .replaceAll(RegExp(r'(특별시|광역시|특별자치시|특별자치도)$'), '')
        .trim();
    if (normQ.length >= 3) {
      normQ = normQ.replaceAll(RegExp(r'[시군구]$'), '').trim();
    }
    final targets = <String>[
      name.toLowerCase(),
      region.toLowerCase(),
      '${region.toLowerCase()} ${name.toLowerCase()}',
      group.toLowerCase(),
      for (final a in aliases) a.toLowerCase(),
    ];
    for (final t in targets) {
      if (t.contains(q) || (normQ.isNotEmpty && t.contains(normQ))) {
        return true;
      }
    }
    return false;
  }
}

/// UI 권역 필터 탭 순서
const birthPlaceGroups = <String>[
  '전체',
  '수도권',
  '강원',
  '충청·세종',
  '전라',
  '경상',
  '제주',
];

/// 대한민국 전국 161개 특·광역시·시·군 경도표 (동경)
const birthPlaces = <BirthPlace>[
  // ── 특별시 · 광역시 · 특별자치시 (8) ──
  BirthPlace('서울', 126.978,
      region: '서울', group: '수도권', aliases: ['강남', '송파', '서초', '마포', '영등포', '강서', '노원', '은평', '관악', '종로']),
  BirthPlace('인천', 126.705,
      region: '인천', group: '수도권', aliases: ['강화', '옹진', '송도', '부평', '청라', '영종']),
  BirthPlace('부산', 129.075,
      region: '부산', group: '경상', aliases: ['기장', '해운대', '서면', '동래', '사하']),
  BirthPlace('대구', 128.601,
      region: '대구', group: '경상', aliases: ['군위', '달성', '수성', '달서']),
  BirthPlace('대전', 127.385,
      region: '대전', group: '충청·세종', aliases: ['유성', '둔산', '대덕']),
  BirthPlace('광주', 126.851,
      region: '광주', group: '전라', aliases: ['광산', '상무', '전남 광주']),
  BirthPlace('울산', 129.311,
      region: '울산', group: '경상', aliases: ['울주', '언양']),
  BirthPlace('세종', 127.289,
      region: '세종', group: '충청·세종', aliases: ['연기', '조치원']),

  // ── 경기도 (31개 시·군) ──
  BirthPlace('수원', 127.028,
      region: '경기', group: '수도권', aliases: ['영통', '광교', '팔달']),
  BirthPlace('용인', 127.178,
      region: '경기', group: '수도권', aliases: ['수지', '기흥', '처인']),
  BirthPlace('고양', 126.832,
      region: '경기', group: '수도권', aliases: ['일산', '덕양', '화정']),
  BirthPlace('화성', 126.831,
      region: '경기', group: '수도권', aliases: ['동탄', '봉담', '향남']),
  BirthPlace('성남', 127.138,
      region: '경기', group: '수도권', aliases: ['분당', '판교', '위례', '수정', '중원']),
  BirthPlace('부천', 126.766, region: '경기', group: '수도권'),
  BirthPlace('남양주', 127.216, region: '경기', group: '수도권'),
  BirthPlace('안산', 126.831, region: '경기', group: '수도권'),
  BirthPlace('평택', 127.113, region: '경기', group: '수도권'),
  BirthPlace('안양', 126.957, region: '경기', group: '수도권'),
  BirthPlace('시흥', 126.803, region: '경기', group: '수도권'),
  BirthPlace('파주', 126.780, region: '경기', group: '수도권'),
  BirthPlace('김포', 126.716, region: '경기', group: '수도권'),
  BirthPlace('의정부', 127.034, region: '경기', group: '수도권'),
  BirthPlace('경기 광주', 127.255, region: '경기', group: '수도권'),
  BirthPlace('하남', 127.215, region: '경기', group: '수도권'),
  BirthPlace('광명', 126.865, region: '경기', group: '수도권'),
  BirthPlace('군포', 126.935, region: '경기', group: '수도권'),
  BirthPlace('양주', 127.046, region: '경기', group: '수도권'),
  BirthPlace('오산', 127.077, region: '경기', group: '수도권'),
  BirthPlace('이천', 127.435, region: '경기', group: '수도권'),
  BirthPlace('안성', 127.279, region: '경기', group: '수도권'),
  BirthPlace('구리', 127.130, region: '경기', group: '수도권'),
  BirthPlace('의왕', 126.968, region: '경기', group: '수도권'),
  BirthPlace('포천', 127.200, region: '경기', group: '수도권'),
  BirthPlace('양평', 127.488, region: '경기', group: '수도권'),
  BirthPlace('여주', 127.637, region: '경기', group: '수도권'),
  BirthPlace('동두천', 127.061, region: '경기', group: '수도권'),
  BirthPlace('과천', 126.988, region: '경기', group: '수도권'),
  BirthPlace('가평', 127.510, region: '경기', group: '수도권'),
  BirthPlace('연천', 127.075, region: '경기', group: '수도권'),

  // ── 강원특별자치도 (18개 시·군) ──
  BirthPlace('춘천', 127.729, region: '강원', group: '강원'),
  BirthPlace('원주', 127.920, region: '강원', group: '강원'),
  BirthPlace('강릉', 128.896, region: '강원', group: '강원'),
  BirthPlace('동해', 129.114, region: '강원', group: '강원'),
  BirthPlace('태백', 128.986, region: '강원', group: '강원'),
  BirthPlace('속초', 128.592, region: '강원', group: '강원'),
  BirthPlace('삼척', 129.165, region: '강원', group: '강원'),
  BirthPlace('홍천', 127.889, region: '강원', group: '강원'),
  BirthPlace('횡성', 127.985, region: '강원', group: '강원'),
  BirthPlace('영월', 128.462, region: '강원', group: '강원'),
  BirthPlace('평창', 128.391, region: '강원', group: '강원'),
  BirthPlace('정선', 128.661, region: '강원', group: '강원'),
  BirthPlace('철원', 127.313, region: '강원', group: '강원'),
  BirthPlace('화천', 127.708, region: '강원', group: '강원'),
  BirthPlace('양구', 127.990, region: '강원', group: '강원'),
  BirthPlace('인제', 128.170, region: '강원', group: '강원'),
  BirthPlace('강원 고성', 128.468, region: '강원', group: '강원'),
  BirthPlace('양양', 128.619, region: '강원', group: '강원'),

  // ── 충청북도 (11개 시·군) ──
  BirthPlace('청주', 127.489,
      region: '충북', group: '충청·세종', aliases: ['청원', '오창', '오송']),
  BirthPlace('충주', 127.926, region: '충북', group: '충청·세종'),
  BirthPlace('제천', 128.191, region: '충북', group: '충청·세종'),
  BirthPlace('보은', 127.730, region: '충북', group: '충청·세종'),
  BirthPlace('옥천', 127.571, region: '충북', group: '충청·세종'),
  BirthPlace('영동', 127.783, region: '충북', group: '충청·세종'),
  BirthPlace('증평', 127.582, region: '충북', group: '충청·세종'),
  BirthPlace('진천', 127.443, region: '충북', group: '충청·세종'),
  BirthPlace('괴산', 127.787, region: '충북', group: '충청·세종'),
  BirthPlace('음성', 127.690, region: '충북', group: '충청·세종'),
  BirthPlace('단양', 128.366, region: '충북', group: '충청·세종'),

  // ── 충청남도 (15개 시·군) ──
  BirthPlace('천안', 127.114, region: '충남', group: '충청·세종'),
  BirthPlace('공주', 127.119, region: '충남', group: '충청·세종'),
  BirthPlace('보령', 126.613, region: '충남', group: '충청·세종'),
  BirthPlace('아산', 127.002, region: '충남', group: '충청·세종'),
  BirthPlace('서산', 126.450, region: '충남', group: '충청·세종'),
  BirthPlace('논산', 127.099, region: '충남', group: '충청·세종'),
  BirthPlace('계룡', 127.249, region: '충남', group: '충청·세종'),
  BirthPlace('당진', 126.630, region: '충남', group: '충청·세종'),
  BirthPlace('금산', 127.489, region: '충남', group: '충청·세종'),
  BirthPlace('부여', 126.910, region: '충남', group: '충청·세종'),
  BirthPlace('서천', 126.692, region: '충남', group: '충청·세종'),
  BirthPlace('청양', 126.802, region: '충남', group: '충청·세종'),
  BirthPlace('홍성', 126.661, region: '충남', group: '충청·세종'),
  BirthPlace('예산', 126.845, region: '충남', group: '충청·세종'),
  BirthPlace('태안', 126.298, region: '충남', group: '충청·세종'),

  // ── 전북특별자치도 (14개 시·군) ──
  BirthPlace('전주', 127.148, region: '전북', group: '전라'),
  BirthPlace('군산', 126.737, region: '전북', group: '전라'),
  BirthPlace('익산', 126.958, region: '전북', group: '전라'),
  BirthPlace('정읍', 126.856, region: '전북', group: '전라'),
  BirthPlace('남원', 127.390, region: '전북', group: '전라'),
  BirthPlace('김제', 126.881, region: '전북', group: '전라'),
  BirthPlace('완주', 127.162, region: '전북', group: '전라'),
  BirthPlace('진안', 127.425, region: '전북', group: '전라'),
  BirthPlace('무주', 127.661, region: '전북', group: '전라'),
  BirthPlace('장수', 127.521, region: '전북', group: '전라'),
  BirthPlace('임실', 127.289, region: '전북', group: '전라'),
  BirthPlace('순창', 127.138, region: '전북', group: '전라'),
  BirthPlace('고창', 126.702, region: '전북', group: '전라'),
  BirthPlace('부안', 126.733, region: '전북', group: '전라'),

  // ── 전라남도 (22개 시·군) ──
  BirthPlace('목포', 126.392, region: '전남', group: '전라'),
  BirthPlace('여수', 127.662, region: '전남', group: '전라'),
  BirthPlace('순천', 127.487, region: '전남', group: '전라'),
  BirthPlace('나주', 126.711, region: '전남', group: '전라'),
  BirthPlace('광양', 127.696, region: '전남', group: '전라'),
  BirthPlace('담양', 126.988, region: '전남', group: '전라'),
  BirthPlace('곡성', 127.292, region: '전남', group: '전라'),
  BirthPlace('구례', 127.463, region: '전남', group: '전라'),
  BirthPlace('고흥', 127.285, region: '전남', group: '전라'),
  BirthPlace('보성', 127.080, region: '전남', group: '전라'),
  BirthPlace('화순', 126.986, region: '전남', group: '전라'),
  BirthPlace('장흥', 126.907, region: '전남', group: '전라'),
  BirthPlace('강진', 126.767, region: '전남', group: '전라'),
  BirthPlace('해남', 126.599, region: '전남', group: '전라'),
  BirthPlace('영암', 126.697, region: '전남', group: '전라'),
  BirthPlace('무안', 126.482, region: '전남', group: '전라'),
  BirthPlace('함평', 126.517, region: '전남', group: '전라'),
  BirthPlace('영광', 126.512, region: '전남', group: '전라'),
  BirthPlace('장성', 126.785, region: '전남', group: '전라'),
  BirthPlace('완도', 126.755, region: '전남', group: '전라'),
  BirthPlace('진도', 126.263, region: '전남', group: '전라'),
  BirthPlace('신안', 126.351, region: '전남', group: '전라'),

  // ── 경상북도 (22개 시·군) ──
  BirthPlace('포항', 129.365, region: '경북', group: '경상'),
  BirthPlace('경주', 129.225, region: '경북', group: '경상'),
  BirthPlace('김천', 128.114, region: '경북', group: '경상'),
  BirthPlace('안동', 128.729, region: '경북', group: '경상'),
  BirthPlace('구미', 128.344, region: '경북', group: '경상'),
  BirthPlace('영주', 128.624, region: '경북', group: '경상'),
  BirthPlace('영천', 128.939, region: '경북', group: '경상'),
  BirthPlace('상주', 128.159, region: '경북', group: '경상'),
  BirthPlace('문경', 128.187, region: '경북', group: '경상'),
  BirthPlace('경산', 128.741, region: '경북', group: '경상'),
  BirthPlace('의성', 128.697, region: '경북', group: '경상'),
  BirthPlace('청송', 129.057, region: '경북', group: '경상'),
  BirthPlace('영양', 129.112, region: '경북', group: '경상'),
  BirthPlace('영덕', 129.365, region: '경북', group: '경상'),
  BirthPlace('청도', 128.734, region: '경북', group: '경상'),
  BirthPlace('고령', 128.263, region: '경북', group: '경상'),
  BirthPlace('성주', 128.283, region: '경북', group: '경상'),
  BirthPlace('칠곡', 128.402, region: '경북', group: '경상'),
  BirthPlace('예천', 128.453, region: '경북', group: '경상'),
  BirthPlace('봉화', 128.732, region: '경북', group: '경상'),
  BirthPlace('울진', 129.400, region: '경북', group: '경상'),
  BirthPlace('울릉', 130.906, region: '경북', group: '경상'),

  // ── 경상남도 (18개 시·군) ──
  BirthPlace('창원', 128.681,
      region: '경남', group: '경상', aliases: ['마산', '진해']),
  BirthPlace('진주', 128.108, region: '경남', group: '경상'),
  BirthPlace('통영', 128.433, region: '경남', group: '경상'),
  BirthPlace('사천', 128.064, region: '경남', group: '경상'),
  BirthPlace('김해', 128.889, region: '경남', group: '경상'),
  BirthPlace('밀양', 128.746, region: '경남', group: '경상'),
  BirthPlace('거제', 128.621, region: '경남', group: '경상'),
  BirthPlace('양산', 129.037, region: '경남', group: '경상'),
  BirthPlace('의령', 128.262, region: '경남', group: '경상'),
  BirthPlace('함안', 128.406, region: '경남', group: '경상'),
  BirthPlace('창녕', 128.492, region: '경남', group: '경상'),
  BirthPlace('경남 고성', 128.322, region: '경남', group: '경상'),
  BirthPlace('남해', 127.892, region: '경남', group: '경상'),
  BirthPlace('하동', 127.751, region: '경남', group: '경상'),
  BirthPlace('산청', 127.873, region: '경남', group: '경상'),
  BirthPlace('함양', 127.725, region: '경남', group: '경상'),
  BirthPlace('거창', 127.909, region: '경남', group: '경상'),
  BirthPlace('합천', 128.166, region: '경남', group: '경상'),

  // ── 제주특별자치도 (2개 시) ──
  BirthPlace('제주', 126.531, region: '제주', group: '제주'),
  BirthPlace('서귀포', 126.560, region: '제주', group: '제주'),
];

/// 표준 자오선 (한국 표준시)
const double koreaMeridian = 135.0;

/// 도시명으로 BirthPlace 찾기 (정확 일치 → '시/군' 접미사 제거 일치)
BirthPlace? findBirthPlace(String? placeName) {
  if (placeName == null) return null;
  final trimmed = placeName.trim();
  if (trimmed.isEmpty) return null;

  for (final p in birthPlaces) {
    if (p.name == trimmed) return p;
  }

  String normalized = trimmed
      .replaceAll(RegExp(r'(특별시|광역시|특별자치시|특별자치도)$'), '')
      .trim();
  if (normalized.length >= 3) {
    normalized = normalized.replaceAll(RegExp(r'[시군]$'), '').trim();
  }
  if (normalized.isNotEmpty) {
    for (final p in birthPlaces) {
      if (p.name == normalized) return p;
    }
    for (final p in birthPlaces) {
      if (p.aliases.contains(normalized)) return p;
    }
  }
  return null;
}

/// 도시명으로 경도 찾기 (없으면 서울 기준 126.978°E)
double longitudeOf(String? placeName) {
  return findBirthPlace(placeName)?.longitude ?? 126.978;
}

/// 특정 출생일시 기준 대한민국 표준 자오선 반환
/// - 1908.04.01 ~ 1911.12.31 및 1954.03.21 ~ 1961.08.09: 동경 127.5° (UTC+08:30)
/// - 그 외 기간: 동경 135.0° (UTC+09:00)
double standardMeridianForDate(DateTime? birthDate) {
  if (birthDate == null) return koreaMeridian;
  final d = DateTime(birthDate.year, birthDate.month, birthDate.day);
  final p1Start = DateTime(1908, 4, 1);
  final p1End = DateTime(1912, 1, 1);
  final p2Start = DateTime(1954, 3, 21);
  final p2End = DateTime(1961, 8, 10);
  if ((!d.isBefore(p1Start) && d.isBefore(p1End)) ||
      (!d.isBefore(p2Start) && d.isBefore(p2End))) {
    return 127.5;
  }
  return koreaMeridian;
}

/// 진태양시 보정 분(minute). 경도 1도당 4분.
/// (실제경도 - 당시 표준자오선) * 4 → 보통 음수(한국은 135보다 서쪽이라 시계를 늦춤)
double trueSolarOffsetMinutes(String? placeName, {DateTime? birthDate}) {
  final lon = longitudeOf(placeName);
  final meridian = standardMeridianForDate(birthDate);
  return (lon - meridian) * 4.0;
}
