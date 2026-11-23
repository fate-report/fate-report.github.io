/// 모든 노출 문구를 한 곳에 모아둠.
/// 화면에 보이는 글에는 내부 규칙 코드(K01~K10 등)를 쓰지 않는다.
library;

class AppCopy {
  // ── 홈 문구 ──
  static const appName = 'Fate Report';
  static const homeMainHeadline =
      '좋은 말만 해주는 운세가 아니라,\n만세력 기준으로 지금 고민을 풀어주는 사주 리포트';
  static const homeSubHeadline =
      '생년월일시로 계산한 사주를 바탕으로 성향, 연애, 궁합, 진로·재물, 올해 흐름을 다정하고 깊이 있게 풀어드립니다.';
  static const homeCtaLabel = '내 사주 리포트 시작하기';

  // ── 신뢰 카드 5개 ──
  static const trustCards = <TrustCard>[
    TrustCard('만세력으로 정확하게 계산해요',
        '태어난 날짜와 시간, 지역까지 반영해 사주를 계산하고 10년 단위 큰 흐름과 올해 운도 함께 봅니다.'),
    TrustCard('네 번 확인한 뒤 보여드려요',
        '계산이 맞는지, 반대로 봐도 말이 되는지, 쉬운 말로 풀렸는지, 빠진 내용은 없는지 확인합니다.'),
    TrustCard('근거가 있는 궁합 점수',
        '두 사람의 사주 글자를 항목별로 채점해 초록·노랑·빨강 신호등으로 보여드립니다.'),
    TrustCard('카톡처럼 쉬운 설명',
        '어려운 한자 용어 대신 술술 읽히는 이야기와 지금 해볼 행동을 알려드립니다.'),
    TrustCard('모를 땐 모른다고 말해요',
        '정보가 부족하거나 날짜·시간이 경계에 걸리면 억지로 단정하지 않고 그대로 알려드립니다.'),
  ];

  // ── 공통 주의 문구 ──
  static const commonNotice =
      '이 분석은 만세력과 명리학 해석을 바탕으로 한 참고용 리포트입니다. '
      '건강, 투자, 법률, 결혼, 이별, 합격, 실패를 확정하는 판단으로 사용해서는 안 됩니다.';

  static const compatNotice =
      '궁합 점수는 관계의 성공과 실패를 확정하는 점수가 아닙니다. '
      '두 사람이 얼마나 잘 맞고 어디를 조율하면 좋은지 보는 참고 지표입니다.';

  // ── FAQ ──
  static const faqs = <FaqItem>[
    FaqItem(
      '내 사주를 몰라도 되나요?',
      '네. 생년월일과 태어난 시간만 입력하면 자동으로 계산됩니다. 이미 알고 있는 사주 글자가 있다면 2단계에서 직접 고칠 수도 있습니다.',
    ),
    FaqItem(
      '궁합 점수는 어떻게 계산되나요?',
      '100점 만점입니다. 관계의 중심(35점), 생각과 표현 방식(20점), 서로 부족한 기운을 채워주는 정도(25점), 오래 갈 안정성(20점)을 더하고, 태어난 시간을 알면 최대 5점을 더하거나 뺍니다.',
    ),
    FaqItem(
      '태어난 시간을 모르면 점수가 깎이나요?',
      '아닙니다. 한쪽이라도 태어난 시간을 모르면 시간 부분만 빼고 나머지로 공정하게 분석합니다.',
    ),
    FaqItem(
      '리포트를 본 뒤 추가 질문도 할 수 있나요?',
      '네. 결과 화면 아래 [이어서 물어보기]에서 올해와 내년 비교, 자세한 근거, 한 줄 요약 등을 바로 물어볼 수 있습니다.',
    ),
    FaqItem(
      '이 분석을 투자나 결혼 결정에 그대로 써도 되나요?',
      '아닙니다. 참고용 리포트이며 건강, 투자, 결혼, 합격 등을 확정하는 판단으로 쓰면 안 됩니다.',
    ),
  ];

  // ── 신호등 설명 (80~100 초록 / 50~79 노랑 / 0~49 빨강) ──
  static const signalGreenDesc =
      '서로 잘 맞고 부족한 부분을 채워주는 편이라, 관계를 편하게 이어가기 좋습니다.';
  static const signalYellowDesc =
      '서로 끌리고 보완되는 면과 조율이 필요한 면이 함께 있어 대화 규칙과 관리가 중요합니다.';
  static const signalRedDesc =
      '생활 리듬이나 감정 표현 방식에서 부딪힘이 생기기 쉬워 세심한 거리 조절과 배려가 필요합니다.';
  static const signalGrayDesc = '정보가 부족해 신호등을 정하지 않았습니다.';

  static const loadingMessage = '사주를 분석하고 있어요...';
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
    plainName: '궁합 신호등',
    desc: '두 사람의 사주를 항목별로 채점하고, 잘 맞는 점과 조율할 점을 풀어드립니다.',
    needsPartner: true,
  ),
  CategoryInfo(
    category: AnalysisCategory.love,
    questionTitle: '그 사람이 나를 어떻게 볼까?',
    plainName: '연애 · 속마음',
    desc: '타고난 연애 스타일과 상대와의 감정 온도차, 다가갈 타이밍을 읽어봅니다.',
    needsPartner: true,
  ),
  CategoryInfo(
    category: AnalysisCategory.pattern,
    questionTitle: '나는 왜 비슷한 문제를 반복할까?',
    plainName: '반복 패턴 · 진로 · 재물',
    desc: '내가 반복하는 마음의 습관을 짚고, 진로·재물·인간관계의 해법을 찾아봅니다.',
  ),
  CategoryInfo(
    category: AnalysisCategory.basic,
    questionTitle: '내 타고난 기질과 올해 흐름은?',
    plainName: '내 사주 종합',
    desc: '타고난 성향과 2026년 올해의 흐름을 다정하게 풀어드립니다.',
  ),
];

/// 결과 화면 꼬리 질문에서 즉시 사용 가능한 확장 주제 배지
const comingSoonList = <String>[
  '올해와 내년 비교',
  '언제가 좋은 시기인지',
  '재회·연락 가능성',
  '돈이 들어오고 나가는 흐름',
  '나에게 맞는 직업·진로',
];
