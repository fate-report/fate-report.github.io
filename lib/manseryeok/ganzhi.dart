/// 천간(天干)·지지(地支)·오행(五行)·지장간·십성·12운성 표준 데이터 (K06, K09 기준).
library;

/// 천간 10개 (한글)
const heavenlyStems = ['갑', '을', '병', '정', '무', '기', '경', '신', '임', '계'];

/// 천간 한자
const heavenlyStemsHanja = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];

/// 지지 12개 (한글)
const earthlyBranches = [
  '자', '축', '인', '묘', '진', '사', '오', '미', '신', '유', '술', '해'
];

/// 지지 한자
const earthlyBranchesHanja = [
  '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'
];

/// 천간의 오행 (목화토금수) — K06, K09
const stemElements = {
  '갑': '목', '을': '목',
  '병': '화', '정': '화',
  '무': '토', '기': '토',
  '경': '금', '신': '금',
  '임': '수', '계': '수',
};

/// 지지의 본기 오행 (궁합 C항목 6글자 전용 및 기본 오행) — K06
const branchElements = {
  '자': '수', '축': '토', '인': '목', '묘': '목',
  '진': '토', '사': '화', '오': '화', '미': '토',
  '신': '금', '유': '금', '술': '토', '해': '수',
};

/// 천간의 음양 (양=true, 음=false)
const stemYang = {
  '갑': true, '을': false, '병': true, '정': false, '무': true,
  '기': false, '경': true, '신': false, '임': true, '계': false,
};

/// 지장간 표준표 (구조·통근·조후 해석용, K09 기준)
const Map<String, List<String>> branchHiddenStems = {
  '자': ['계'],
  '축': ['기', '계', '신'],
  '인': ['갑', '병', '무'],
  '묘': ['을'],
  '진': ['무', '을', '계'],
  '사': ['병', '무', '경'],
  '오': ['정', '기'],
  '미': ['기', '정', '을'],
  '신': ['경', '임', '무'],
  '유': ['신'],
  '술': ['무', '신', '정'],
  '해': ['임', '갑'],
};

/// 10천간 12운성 조견표 (화토동궁 적용, K09 기준)
const Map<String, Map<String, String>> twelveStagesTable = {
  '갑': {
    '해': '장생', '자': '목욕', '축': '관대', '인': '건록', '묘': '제왕', '진': '쇠',
    '사': '병', '오': '사', '미': '묘', '신': '절', '유': '태', '술': '양',
  },
  '을': {
    '오': '장생', '사': '목욕', '진': '관대', '묘': '건록', '인': '제왕', '축': '쇠',
    '자': '병', '해': '사', '술': '묘', '유': '절', '신': '태', '미': '양',
  },
  '병': {
    '인': '장생', '묘': '목욕', '진': '관대', '사': '건록', '오': '제왕', '미': '쇠',
    '신': '병', '유': '사', '술': '묘', '해': '절', '자': '태', '축': '양',
  },
  '정': {
    '유': '장생', '신': '목욕', '미': '관대', '오': '건록', '사': '제왕', '진': '쇠',
    '묘': '병', '인': '사', '축': '묘', '자': '절', '해': '태', '술': '양',
  },
  '무': {
    '인': '장생', '묘': '목욕', '진': '관대', '사': '건록', '오': '제왕', '미': '쇠',
    '신': '병', '유': '사', '술': '묘', '해': '절', '자': '태', '축': '양',
  },
  '기': {
    '유': '장생', '신': '목욕', '미': '관대', '오': '건록', '사': '제왕', '진': '쇠',
    '묘': '병', '인': '사', '축': '묘', '자': '절', '해': '태', '술': '양',
  },
  '경': {
    '사': '장생', '오': '목욕', '미': '관대', '신': '건록', '유': '제왕', '술': '쇠',
    '해': '병', '자': '사', '축': '묘', '인': '절', '묘': '태', '진': '양',
  },
  '신': {
    '자': '장생', '해': '목욕', '술': '관대', '유': '건록', '신': '제왕', '미': '쇠',
    '오': '병', '사': '사', '진': '묘', '묘': '절', '인': '태', '축': '양',
  },
  '임': {
    '신': '장생', '유': '목욕', '술': '관대', '해': '건록', '자': '제왕', '축': '쇠',
    '인': '병', '묘': '사', '진': '묘', '사': '절', '오': '태', '미': '양',
  },
  '계': {
    '묘': '장생', '인': '목욕', '축': '관대', '자': '건록', '해': '제왕', '술': '쇠',
    '유': '병', '신': '사', '미': '묘', '오': '절', '사': '태', '진': '양',
  },
};

/// 일간(dayMaster) 대비 대상 천간(targetStem)의 십성 산출 (K09 기준)
String calculateTenGod(String dayMaster, String targetStem) {
  final myEl = stemElements[dayMaster];
  final tEl = stemElements[targetStem];
  final myYang = stemYang[dayMaster];
  final tYang = stemYang[targetStem];
  if (myEl == null || tEl == null || myYang == null || tYang == null) return '';

  final samePolarity = myYang == tYang;
  if (myEl == tEl) return samePolarity ? '비견' : '겁재';

  const gen = {'목': '화', '화': '토', '토': '금', '금': '수', '수': '목'};
  const ctrl = {'목': '토', '토': '수', '수': '화', '화': '금', '금': '목'};

  if (gen[myEl] == tEl) return samePolarity ? '식신' : '상관';
  if (ctrl[myEl] == tEl) return samePolarity ? '편재' : '정재';
  if (ctrl[tEl] == myEl) return samePolarity ? '편관' : '정관';
  if (gen[tEl] == myEl) return samePolarity ? '편인' : '정인';
  return '';
}

/// 일간(dayMaster)과 지지(branch)의 12운성 반환
String calculateTwelveStage(String dayMaster, String branch) {
  return twelveStagesTable[dayMaster]?[branch] ?? '';
}

/// 60갑자 전체 리스트 (갑자 ~ 계해)
List<String> get allSixtyGanzhi =>
    List.generate(60, (i) => ganzhiFromIndex(i));

/// 한글 간지 2글자(예: '갑자')를 한자('甲子')로 변환
String pillarToHanja(String? pillar) {
  if (pillar == null || pillar.length < 2) return '';
  final si = heavenlyStems.indexOf(pillar[0]);
  final bi = earthlyBranches.indexOf(pillar[1]);
  if (si < 0 || bi < 0) return '';
  return heavenlyStemsHanja[si] + earthlyBranchesHanja[bi];
}

/// 60갑자 인덱스로부터 간지 문자열 반환
String ganzhiFromIndex(int idx) {
  final i = ((idx % 60) + 60) % 60;
  return heavenlyStems[i % 10] + earthlyBranches[i % 12];
}

String ganzhiHanjaFromIndex(int idx) {
  final i = ((idx % 60) + 60) % 60;
  return heavenlyStemsHanja[i % 10] + earthlyBranchesHanja[i % 12];
}

/// 한글 간지 2글자('갑자')로부터 60갑자 인덱스(0~59) 찾기
int ganzhiIndexOf(String pillar) {
  final p = pillar.trim();
  if (p.length != 2) return -1;
  for (int i = 0; i < 60; i++) {
    if (ganzhiFromIndex(i) == p) return i;
  }
  return -1;
}

/// 입력된 한글 2글자가 실제 60갑자에 존재하는 유효한 간지인지 검증 (예: '갑자'=true, '갑유'=false)
bool isValidGanzhiPillar(String? pillar) {
  if (pillar == null) return false;
  return ganzhiIndexOf(pillar) != -1;
}

/// 천간 인덱스
int stemIndex(String stem) => heavenlyStems.indexOf(stem);

/// 지지 인덱스
int branchIndex(String branch) => earthlyBranches.indexOf(branch);
