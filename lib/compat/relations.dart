/// 지지(地支) 간의 관계 테이블 — 충/형/해/합/삼합.
/// 궁합 판정에 사용. (코드가 결정, AI 관여 없음)
library;

/// 육충(六沖): 정면 충돌하는 지지 쌍
const Map<String, String> branchClash = {
  '자': '오', '오': '자',
  '축': '미', '미': '축',
  '인': '신', '신': '인',
  '묘': '유', '유': '묘',
  '진': '술', '술': '진',
  '사': '해', '해': '사',
};

/// 육해(六害): 서로 방해하는 지지 쌍
const Map<String, String> branchHarm = {
  '자': '미', '미': '자',
  '축': '오', '오': '축',
  '인': '사', '사': '인',
  '묘': '진', '진': '묘',
  '신': '해', '해': '신',
  '유': '술', '술': '유',
};

/// 삼형(三刑)·상형 조합 (대표적인 형살)
const List<List<String>> branchPunish = [
  ['인', '사', '신'], // 무은지형
  ['축', '술', '미'], // 지세지형
  ['자', '묘'], // 무례지형
];

/// 육합(六合): 서로 끌리는 지지 쌍
const Map<String, String> branchHarmony = {
  '자': '축', '축': '자',
  '인': '해', '해': '인',
  '묘': '술', '술': '묘',
  '진': '유', '유': '진',
  '사': '신', '신': '사',
  '오': '미', '미': '오',
};

/// 삼합(三合): 강하게 결속하는 세 지지
const List<List<String>> branchTrine = [
  ['신', '자', '진'], // 수국
  ['해', '묘', '미'], // 목국
  ['인', '오', '술'], // 화국
  ['사', '유', '축'], // 금국
];

bool isClash(String a, String b) => branchClash[a] == b;
bool isHarm(String a, String b) => branchHarm[a] == b;
bool isHarmony(String a, String b) => branchHarmony[a] == b;

bool isPunish(String a, String b) {
  for (final set in branchPunish) {
    if (set.contains(a) && set.contains(b) && a != b) return true;
  }
  return false;
}

bool isTrine(String a, String b) {
  for (final set in branchTrine) {
    if (set.contains(a) && set.contains(b) && a != b) return true;
  }
  return false;
}

/// 천간 오행 상생/상극 판정용
const Map<String, String> stemElement = {
  '갑': '목', '을': '목', '병': '화', '정': '화', '무': '토',
  '기': '토', '경': '금', '신': '금', '임': '수', '계': '수',
};

/// 오행 상생 (생하는 대상)
const Map<String, String> elementGenerates = {
  '목': '화', '화': '토', '토': '금', '금': '수', '수': '목',
};

/// 오행 상극 (극하는 대상)
const Map<String, String> elementControls = {
  '목': '토', '토': '수', '수': '화', '화': '금', '금': '목',
};
