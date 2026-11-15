/// 천간(天干)·지지(地支)·오행(五行) 기본 데이터.
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

/// 천간의 오행 (목화토금수)
const stemElements = {
  '갑': '목', '을': '목',
  '병': '화', '정': '화',
  '무': '토', '기': '토',
  '경': '금', '신': '금',
  '임': '수', '계': '수',
};

/// 지지의 오행
const branchElements = {
  '자': '수', '축': '토', '인': '목', '묘': '목',
  '진': '토', '사': '화', '오': '화', '미': '토',
  '신': '금', '유': '금', '술': '토', '해': '수',
};

/// 천간의 음양 (양=true)
const stemYang = {
  '갑': true, '을': false, '병': true, '정': false, '무': true,
  '기': false, '경': true, '신': false, '임': true, '계': false,
};

/// 60갑자 인덱스로부터 간지 문자열 반환
String ganzhiFromIndex(int idx) {
  final i = ((idx % 60) + 60) % 60;
  return heavenlyStems[i % 10] + earthlyBranches[i % 12];
}

String ganzhiHanjaFromIndex(int idx) {
  final i = ((idx % 60) + 60) % 60;
  return heavenlyStemsHanja[i % 10] + earthlyBranchesHanja[i % 12];
}

/// 천간 인덱스
int stemIndex(String stem) => heavenlyStems.indexOf(stem);

/// 지지 인덱스
int branchIndex(String branch) => earthlyBranches.indexOf(branch);
