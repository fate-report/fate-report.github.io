/// 모든 노출 문구를 한 곳에 모아둠 (나중에 글자만 쉽게 수정 가능하게).
library;

class AppCopy {
  // ── 홈 문구 ──
  static const appName = 'Fate Report';
  static const homeMainHeadline =
      '좋은 말만 해주는 운세가 아니라,\n만세력 기준으로 지금 고민을 풀어주는 사주 리포트';
  static const homeSubHeadline =
      '생년월일시와 명식 정보를 바탕으로 연애, 궁합, 속마음, 반복 패턴을 현실적으로 분석해드립니다.';
  static const homeCtaLabel = '내 사주 리포트 시작하기';

  // ── 신뢰 카드 5개 ──
  static const trustCards = <TrustCard>[
    TrustCard('만세력 기준 분석', '느낌이 아니라 계산된 명식으로 시작합니다.'),
    TrustCard('립서비스 방지', '좋은 점만 말하지 않고 위험한 점도 함께 말합니다.'),
    TrustCard('궁합 신호등', '초록·노랑·빨강으로 관계 관리 난이도를 보여줍니다.'),
    TrustCard('지금 할 일 제시', '분석으로 끝나지 않고 오늘 할 행동을 제안합니다.'),
    TrustCard('정보 부족 시 판정 보류', '억지로 단정하지 않고 보류로 안내합니다.'),
  ];

  // ── 공통 주의 문구 ──
  static const commonNotice =
      '이 분석은 만세력과 명리학적 해석을 바탕으로 한 참고용 리포트입니다. '
      '건강, 투자, 법률, 결혼, 이별, 합격, 실패를 확정하는 판단으로 사용해서는 안 됩니다.';

  static const compatNotice =
      '궁합 점수는 관계의 성공과 실패를 확정하는 점수가 아닙니다. '
      '두 사람의 구조적 보완성, 충돌 가능성, 관계 관리 난이도를 보는 참고 지표입니다.';

  // ── FAQ ──
  static const faqs = <FaqItem>[
    FaqItem(
      '만세력 정보가 없으면 분석이 안 되나요?',
      '생년월일시를 입력하면 자동으로 계산됩니다. 다만 출생시간이 없으면 일부 분석이 제한될 수 있습니다.',
    ),
    FaqItem(
      '궁합 점수는 관계 성공을 의미하나요?',
      '아닙니다. 구조적 보완성, 충돌 가능성, 관계 관리 난이도를 보는 참고 지표입니다.',
    ),
    FaqItem(
      '출생시간을 모르면 어떻게 되나요?',
      '시주 관련 판단은 제외하고 부분 분석으로 진행합니다.',
    ),
    FaqItem(
      '상대 일주가 없으면 궁합을 볼 수 있나요?',
      '상대 일주가 없으면 신호등 판정은 확정하지 않고 판정 보류로 처리합니다.',
    ),
    FaqItem(
      '이 분석을 투자나 결혼 결정에 그대로 써도 되나요?',
      '아닙니다. 참고용 리포트이며 건강, 투자, 결혼, 합격 등을 확정하는 판단으로 쓰면 안 됩니다.',
    ),
  ];

  // ── 신호등 설명 ──
  static const signalGreenDesc = '구조적 보완성이 좋고, 관계 관리 난이도가 낮은 편입니다.';
  static const signalYellowDesc = '보완되는 면과 충돌하는 면이 함께 있어, 관계 관리가 필요합니다.';
  static const signalRedDesc = '충돌 요소가 많아, 관계를 이어가려면 상당한 노력이 필요합니다.';
  static const signalGrayDesc = '정보가 부족해 신호등을 확정하지 않았습니다 (판정 보류).';

  static const loadingMessage = '명식을 분석하고 있어요...';
  static const rateLimitMessage = '지금 이용자가 많습니다. 잠시 후 다시 시도해주세요.';
}

class TrustCard {
  final String title;
  final String desc;
  const TrustCard(this.title, this.desc);
}

class FaqItem {
  final String q;
  final String a;
  const FaqItem(this.q, this.a);
}

/// MVP 카테고리 (딱 4개). 나머지는 "곧 공개" 배지.
enum AnalysisCategory { basic, compatibility, love, pattern }

class CategoryInfo {
  final AnalysisCategory category;
  final String questionTitle;
  final String plainName;
  final String desc;
  final bool needsPartner;

  const CategoryInfo({
    required this.category,
    required this.questionTitle,
    required this.plainName,
    required this.desc,
    this.needsPartner = false,
  });
}

const categoryList = <CategoryInfo>[
  CategoryInfo(
    category: AnalysisCategory.compatibility,
    questionTitle: '이 사람과 계속 만나도 될까?',
    plainName: '궁합 신호등',
    desc: '두 사람의 명식을 신호등으로 진단합니다.',
    needsPartner: true,
  ),
  CategoryInfo(
    category: AnalysisCategory.love,
    questionTitle: '그 사람이 나를 어떻게 볼까?',
    plainName: '연애·속마음',
    desc: '상대의 성향과 관계의 흐름을 읽어봅니다.',
    needsPartner: true,
  ),
  CategoryInfo(
    category: AnalysisCategory.pattern,
    questionTitle: '나는 왜 비슷한 문제를 반복할까?',
    plainName: '반복 패턴 분석',
    desc: '반복되는 삶의 패턴과 원인을 짚어봅니다.',
  ),
  CategoryInfo(
    category: AnalysisCategory.basic,
    questionTitle: '내 장점과 약점은 뭘까?',
    plainName: '내 사주 기본 분석',
    desc: '타고난 강점과 조심할 점을 정리합니다.',
  ),
];

/// 곧 공개 예정 (만들지 않고 배지만)
const comingSoonList = <String>[
  '오늘의 흐름',
  '올해 흐름',
  '재회 가능성',
  '돈·재물 흐름',
  '직업·진로',
];
