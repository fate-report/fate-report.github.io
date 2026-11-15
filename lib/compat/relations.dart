/// 천간(天干)·지지(地支) 간의 관계 테이블 — K06 표준 기준표 (100% 무삭제 구현).
/// 궁합 K07-R3 정량 판정에 사용. (코드가 결정, AI 암산 오류 차단)
library;

/// 천간합 (甲-己, 乙-庚, 丙-辛, 丁-壬, 戊-癸)
const Map<String, String> stemHarmony = {
  '갑': '기', '기': '갑',
  '을': '경', '경': '을',
  '병': '신', '신': '병',
  '정': '임', '임': '정',
  '무': '계', '계': '무',
};

/// 육합(六合): 자-축, 인-해, 묘-술, 진-유, 사-신, 오-미
const Map<String, String> branchHarmony = {
  '자': '축', '축': '자',
  '인': '해', '해': '인',
  '묘': '술', '술': '묘',
  '진': '유', '유': '진',
  '사': '신', '신': '사',
  '오': '미', '미': '오',
};

/// 육충(六沖): 자-오, 축-미, 인-신, 묘-유, 진-술, 사-해
const Map<String, String> branchClash = {
  '자': '오', '오': '자',
  '축': '미', '미': '축',
  '인': '신', '신': '인',
  '묘': '유', '유': '묘',
  '진': '술', '술': '진',
  '사': '해', '해': '사',
};

/// 육해(六害): 자-미, 축-오, 인-사, 묘-진, 신-해, 유-술
const Map<String, String> branchHarm = {
  '자': '미', '미': '자',
  '축': '오', '오': '축',
  '인': '사', '사': '인',
  '묘': '진', '진': '묘',
  '신': '해', '해': '신',
  '유': '술', '술': '유',
};

/// 파(破): 자-유, 축-진, 인-해, 묘-오, 사-신, 미-술
const Map<String, String> branchBreak = {
  '자': '유', '유': '자',
  '축': '진', '진': '축',
  '인': '해', '해': '인',
  '묘': '오', '오': '묘',
  '사': '신', '신': '사',
  '미': '술', '술': '미',
};

/// 형(刑, 이질 지지 간): 인-사, 사-신, 신-인 / 축-술, 술-미, 미-축 / 자-묘
const List<List<String>> branchPunishSets = [
  ['인', '사', '신'], // 무은지형
  ['축', '술', '미'], // 지세지형
  ['자', '묘'], // 무례지형
];

/// 자형(自刑, 동일 지지 간): 진-진, 오-오, 유-유, 해-해
const Set<String> selfPunishBranches = {'진', '오', '유', '해'};

/// 완전한 3글자 삼합(三合) — 세 글자 모두 존재할 때만 인정 (K06)
const List<Set<String>> completeTrineSets = [
  {'신', '자', '진'}, // 수
  {'해', '묘', '미'}, // 목
  {'인', '오', '술'}, // 화
  {'사', '유', '축'}, // 금
];

/// 완전한 3글자 방합(方合) — 세 글자 모두 존재할 때만 인정 (K06)
const List<Set<String>> completeDirectionalSets = [
  {'인', '묘', '진'}, // 목
  {'사', '오', '미'}, // 화
  {'신', '유', '술'}, // 금
  {'해', '자', '축'}, // 수
];

/// 완전한 3글자 삼형(三刑) — 세 글자 모두 존재할 때만 인정 (K06)
const List<Set<String>> completeThreePunishSets = [
  {'인', '사', '신'}, // 무은지형
  {'축', '술', '미'}, // 지세지형
];

bool isStemHarmony(String a, String b) =>
    a.isNotEmpty && b.isNotEmpty && stemHarmony[a] == b;

bool isHarmony(String a, String b) =>
    a.isNotEmpty && b.isNotEmpty && branchHarmony[a] == b;

bool isClash(String a, String b) =>
    a.isNotEmpty && b.isNotEmpty && branchClash[a] == b;

bool isHarm(String a, String b) =>
    a.isNotEmpty && b.isNotEmpty && branchHarm[a] == b;

bool isBreak(String a, String b) =>
    a.isNotEmpty && b.isNotEmpty && branchBreak[a] == b;

bool isSelfPunish(String a, String b) =>
    a.isNotEmpty && a == b && selfPunishBranches.contains(a);

/// 형(자형 포함) 여부 (K06/K07-R3)
bool isPunishOrSelfPunish(String a, String b) {
  if (a.isEmpty || b.isEmpty) return false;
  if (isSelfPunish(a, b)) return true;
  if (a == b) return false;
  for (final set in branchPunishSets) {
    if (set.contains(a) && set.contains(b)) return true;
  }
  return false;
}

/// 이질 지지 간 형 여부 (자형 제외)
bool isPunish(String a, String b) {
  if (a.isEmpty || b.isEmpty || a == b) return false;
  for (final set in branchPunishSets) {
    if (set.contains(a) && set.contains(b)) return true;
  }
  return false;
}

/// 4글자(년·월지) 집합 내 완전한 3글자 삼합 또는 방합 성립 여부
String? findCompleteTrineOrDirectional(Iterable<String> branches) {
  final set = branches.where((b) => b.isNotEmpty).toSet();
  for (final t in completeTrineSets) {
    if (set.containsAll(t)) return '완전 삼합(${t.join('')})';
  }
  for (final d in completeDirectionalSets) {
    if (set.containsAll(d)) return '완전 방합(${d.join('')})';
  }
  return null;
}

/// 4글자(년·월지) 집합 내 완전한 3글자 삼형 성립 여부
String? findCompleteThreePunish(Iterable<String> branches) {
  final set = branches.where((b) => b.isNotEmpty).toSet();
  for (final p in completeThreePunishSets) {
    if (set.containsAll(p)) return '완전 삼형(${p.join('')})';
  }
  return null;
}

/// 천간 오행 (K06)
const Map<String, String> stemElement = {
  '갑': '목', '을': '목', '병': '화', '정': '화', '무': '토',
  '기': '토', '경': '금', '신': '금', '임': '수', '계': '수',
};

/// 지지 본기 오행 (궁합 C항목 6글자 전용, K06)
const Map<String, String> branchMainElement = {
  '자': '수', '축': '토', '인': '목', '묘': '목', '진': '토', '사': '화',
  '오': '화', '미': '토', '신': '금', '유': '금', '술': '토', '해': '수',
};

/// 오행 상생 (생하는 대상)
const Map<String, String> elementGenerates = {
  '목': '화', '화': '토', '토': '금', '금': '수', '수': '목',
};

/// 오행 상극 (극하는 대상)
const Map<String, String> elementControls = {
  '목': '토', '토': '수', '수': '화', '화': '금', '금': '목',
};
