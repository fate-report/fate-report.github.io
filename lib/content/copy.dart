/// 모든 노출 문구를 한 곳에 모아둠 (K01~K10 마스터 엔진 & K07-R3 기준 반영).
library;

class AppCopy {
  // ── 홈 문구 ──
  static const appName = 'Fate Report';
  static const homeMainHeadline =
      '좋은 말만 해주는 운세가 아니라,\n만세력 기준으로 지금 고민을 풀어주는 사주 리포트';
  static const homeSubHeadline =
      '생년월일시와 명식(지장간·대운·세운)을 바탕으로 성향, 연애, 궁합, 진로·재물, 올해 흐름을 다정하고 깊이 있게 분석합니다.';
  static const homeCtaLabel = '내 사주 리포트 시작하기';

  // ── 신뢰 카드 5개 ──
  static const trustCards = <TrustCard>[
    TrustCard('K01~K10 정밀 만세력·통변', '겉글자뿐 아니라 지장간·조후·4대 축·대운/세운까지 입체 분석합니다.'),
    TrustCard('4인 전문가 하네스(JEV) 검산', '수식 감사·BLIND-FIRST 반증·일상어 번역·생략 방지 락을 거칩니다.'),
    TrustCard('K07-R3 정량 궁합 신호등', '3주 6글자(시간 확인 시 8글자)와 오행 보완을 1점 단위 근거로 채점합니다.'),
    TrustCard('카톡처럼 다정한 투트랙 브리핑', '어려운 한자 용어 대신 술술 읽히는 이야기와 현실 행동 전략을 드립니다.'),
    TrustCard('K08 경계·보류 안전장치', '절기·시지 경계나 정보 부족 시 억지 단정 없이 투명하게 안내합니다.'),
  ];

  // ── 공통 주의 문구 ──
  static const commonNotice =
      '이 분석은 만세력과 명리학적 해석(K01~K10)을 바탕으로 한 참고용 리포트입니다. '
      '건강, 투자, 법률, 결혼, 이별, 합격, 실패를 확정하는 판단으로 사용해서는 안 됩니다.';

  static const compatNotice =
      '궁합 점수(K07-R3)는 관계의 성공과 실패를 확정하는 점수가 아닙니다. '
      '두 사람의 중심축, 소통 방식, 6글자 오행 보완성, 장기 안정성을 보는 정량 참고 지표입니다.';

  // ── FAQ ──
  static const faqs = <FaqItem>[
    FaqItem(
      '만세력 정보가 없으면 분석이 안 되나요?',
      '생년월일시를 입력하면 자동 계산되며, STEP 2에서 알고 계신 만세력 글자(년·월·일·시주)로 직접 수정·고정(K04)할 수도 있습니다.',
    ),
    FaqItem(
      '궁합 점수는 어떻게 계산되나요?',
      'K07-R3 정량 규칙에 따라 A.관계 중심축(35점), B.생각·표현(20점), C.6글자 오행 보완(25점), D.장기 안정성(20점) 및 시주 보정(±5점)을 코드로 정밀 합산합니다.',
    ),
    FaqItem(
      '출생시간을 모르면 감점되나요?',
      '아닙니다. K07-R3 기준에 따라 한쪽이라도 출생시간을 모르면 감점 없이 시주만 제외하고 3주 6글자 기준으로 공정하게 분석합니다.',
    ),
    FaqItem(
      '리포트를 본 뒤 추가 질문도 할 수 있나요?',
      '네! 결과 화면 하단의 [이어서 물어보기] 창에서 올해 vs 내년 비교, 명리적 상세 근거, 한 줄 요약 등 꼬리 질문을 바로 이어가실 수 있습니다.',
    ),
    FaqItem(
      '이 분석을 투자나 결혼 결정에 그대로 써도 되나요?',
      '아닙니다. 참고용 리포트이며 건강, 투자, 결혼, 합격 등을 확정하는 판단으로 쓰면 안 됩니다.',
    ),
  ];

  // ── 신호등 설명 (K07-R3: 80~100 GREEN / 50~79 YELLOW / 0~49 RED) ──
  static const signalGreenDesc =
      '중심축과 오행 보완성이 탄탄하여 관계 관리 난이도가 낮고 시너지가 좋은 편입니다.';
  static const signalYellowDesc =
      '서로 끌리고 보완되는 면과 조율이 필요한 면이 함께 있어 대화 규칙과 관리가 중요합니다.';
  static const signalRedDesc =
      '생활 리듬이나 감정 표현 방식에서 부딪힘이 생기기 쉬워 세심한 거리 조절과 배려가 필요합니다.';
  static const signalGrayDesc = '핵심 명식 정보가 부족해 신호등을 확정하지 않았습니다 (K08 판정 보류).';

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

/// 분석 카테고리 (4대 코어 + 꼬리질문 확장)
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
    plainName: '궁합 신호등 (K07-R3)',
    desc: '두 사람의 6~8글자 명식과 오행 보완을 정량 채점하고 관계 역학을 풀어드립니다.',
    needsPartner: true,
  ),
  CategoryInfo(
    category: AnalysisCategory.love,
    questionTitle: '그 사람이 나를 어떻게 볼까?',
    plainName: '연애·속마음·관계운',
    desc: '타고난 연애 결과 상대와의 감정 온도차, 다가갈 타이밍을 읽어봅니다.',
    needsPartner: true,
  ),
  CategoryInfo(
    category: AnalysisCategory.pattern,
    questionTitle: '나는 왜 비슷한 문제를 반복할까?',
    plainName: '반복 패턴 · 진로 · 재물',
    desc: '내면의 방어기제와 에너지 유통 경로(진로·재물·인간관계) 해법을 짚어봅니다.',
  ),
  CategoryInfo(
    category: AnalysisCategory.basic,
    questionTitle: '내 타고난 기질과 올해 흐름은?',
    plainName: '내 사주 · 대운 · 세운 종합',
    desc: '4대 축(조후·억부·정서·유통)과 2026 병오년 흐름을 다정하게 브리핑합니다.',
  ),
];

/// 결과 화면 꼬리 질문에서 즉시 사용 가능한 확장 주제 배지
const comingSoonList = <String>[
  '올해(병오년) vs 내년(정미년) 비교',
  '대운·세운·월운 타이밍',
  '재회·연락 가능성 점검',
  '돈·재물 유통 경로',
  '직업·진로 적성 설계',
];
