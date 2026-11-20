import '../content/copy.dart';
import '../manseryeok/ganzhi.dart';
import '../models/models.dart';
import '../compat/compat_engine.dart';

/// USE_MOCK=true 일 때 반환할 K01~K10 마스터 엔진 규격 시뮬레이션 결과.
/// 실제 계산된 사용자의 사주 8글자·일간·오행 분포·K07-R3 채점표를 반영하여
/// 다정한 카톡형 투트랙 브리핑과 하네스 4 확신도 배지를 생성한다.
class MockData {
  static AnalysisResult general({
    required UserProfile user,
    PartnerProfile? partner,
    required AnalysisCategory category,
    String userQuestion = '',
  }) {
    final s = user.toSaju();
    final callName =
        user.userName.trim().isEmpty ? '회원님' : '${user.userName.trim()}님';
    final dm = s.dayMaster.isEmpty ? '갑' : s.dayMaster;
    final dmEl = stemElements[dm] ?? '목';
    final partial = s.hourUnknown || s.hasBoundaryWarning;
    final confStatus = partial ? ConfidenceStatus.partial : ConfidenceStatus.ok;
    final confTag = partial ? 'MEDIUM(보통)' : 'HIGH(높음)';
    final kRules = partial ? 'K04, K05, K06, K08, K09, K10' : 'K04, K06, K09, K10';

    final stemTrait = _dayMasterTrait(dm);
    final elMap = s.sixCharElements;
    final richEls = elMap.entries
        .where((e) => e.value >= 2)
        .map((e) => e.key)
        .toList();
    final zeroEls = elMap.entries
        .where((e) => e.value == 0)
        .map((e) => e.key)
        .toList();

    final q = userQuestion.trim();
    final hasQ = q.isNotEmpty;
    final qIntro = hasQ
        ? '질문해 주신 "$q"에 대해 $callName의 확정 명식(${s.yearPillar}년 ${s.monthPillar}월 ${s.dayPillar}일)을 기준으로 먼저 명확한 결론부터 말씀드릴게요.\n\n'
        : '';

    switch (category) {
      case AnalysisCategory.basic:
        final body = '''$qIntro결론부터 말씀드리면, $callName은 스스로 납득이 되는 명확한 기준이 섰을 때 누구보다 단단한 추진력을 발휘하는 사람이에요. 지금처럼 생각이 많아지는 시기에는 모든 걸 한 번에 완벽히 해내려 하기보다, 내 에너지를 어디에 먼저 쓸지 우선순위를 좁히는 것이 가장 유리합니다.

타고난 기질의 중심($dm·$dmEl 기운)을 보면 $stemTrait 성향이 자리 잡고 있어요. 겉으로는 주변 분위기에 잘 맞추고 무던해 보여도, 내면에는 나만의 자존심과 기준선이 꽤 뚜렷한 편입니다. 그래서 남들이 시키는 대로만 움직이는 환경보다는 내가 직접 흐름을 설계하고 납득할 수 있을 때 집중력이 몇 배로 살아납니다.

현실과 일터에서는 책임감이 강해 한 번 맡은 일은 끝까지 해내지만, 정작 본인이 지치고 있다는 신호는 뒤늦게 알아채는 경우가 많아요. ${richEls.isNotEmpty ? '특히 사주 구조상 ${richEls.join('·')} 기운이 뚜렷하게 힘을 쓰고 있어 몰입할 때의 폭발력이 크지만, ' : ''}${zeroEls.isNotEmpty ? '상대적으로 ${zeroEls.join('·')} 기운이 비어 있는 구간에서는 완벽주의 때문에 결정을 미루거나 혼자 속앓이를 하기 쉽습니다.' : '에너지가 한쪽으로 쏠릴 때 체력 소모가 빨라질 수 있습니다.'}

올해 2026년 병오(丙午)년 흐름은 $callName의 숨어 있던 표현력과 활동 반경을 밖으로 강하게 끌어내는 시기예요. 새로운 제안이나 환경 변화가 들어올 가능성이 높은데, 이때 조급하게 속도를 내기보다 내 체력과페이스부터 지키는 것이 올해 성패를 가릅니다.${s.hourUnknown ? '\n\n참고로 현재 출생시간이 입력되지 않아 시주를 제외한 3주 6글자 기준으로 분석해 드렸어요. 정확한 출생시간을 확인해 시주까지 더하면 말년 운과 세부 진로 적합도를 한층 더 정밀하게 보실 수 있습니다.' : ''}''';

        return AnalysisResult(
          resultTitle: hasQ
              ? '$callName의 질문 맞춤형 사주 브리핑'
              : '$callName의 타고난 중심과 2026년 흐름 브리핑',
          keyPoint: hasQ
              ? '"$q"에 대한 해답은 완벽주의를 내려놓고 내 기준에 맞는 핵심 1가지에 집중하는 것입니다.'
              : '내 기준이 설 때 가장 강해지며, 올해는 완벽주의를 내려놓고 선택과 집중을 할 때 길이 열립니다.',
          briefingTitle: hasQ ? '질문 맞춤 심층 브리핑' : '마스터 심층 브리핑',
          briefingBody: body,
          resultSummary: hasQ
              ? ''
              : '$callName은 $stemTrait 기질을 바탕으로 스스로 방향을 정할 때 큰 성취를 만드는 구조입니다. 올해 병오년에는 활동 폭이 넓어지는 만큼 오버페이스를 줄이는 것이 핵심입니다.',
          confidenceStatus: confStatus,
          goodPoints: [
            '스스로 납득한 목표에는 끝까지 파고드는 높은 몰입도와 책임감을 지니고 있습니다.',
            '주변의 흐름을 읽으면서도 내면의 중심을 쉽게 잃지 않는 단단한 자존감이 강점입니다.',
          ],
          riskPoints: [
            '혼자 완벽하게 준비하려다 타이밍을 놓치거나, 피로가 쌓여도 내색하지 못해 번아웃이 올 수 있습니다.',
            '올해 강한 불(火) 기운의 영향으로 마음이 급해지거나 성급한 결론을 내리지 않도록 템포 조절이 필요합니다.',
          ],
          actionItems: [
            '이번 달 해야 할 일 중 가장 중요한 핵심 1가지만 남기고 나머지는 과감히 순서를 미루세요.',
            '중요한 결정이나 답변은 감정이 올라온 당일 바로 하지 말고 하루만 자고 일어나서 확정하세요.',
          ],
          auditFooter: '[적용 기준: $kRules | 확신도: $confTag]',
          warningMessage: AppCopy.commonNotice,
        );

      case AnalysisCategory.love:
        final pName = (partner != null && partner.partnerName.trim().isNotEmpty)
            ? partner.partnerName.trim()
            : '상대분';
        final body = '''
결론부터 말씀드리면, 지금 $callName의 연애 흐름에서는 상대의 반응 하나하나에 의미를 부여하기보다 내 감정 표현의 타이밍을 반 박자만 앞당기는 것이 관계를 가장 유리하게 이끕니다.

$callName은 연애할 때 마음이 가벼운 사람이 전혀 아니에요. $stemTrait 기질이 바탕에 있어서, 한 번 내 사람이라고 느끼면 깊고 진중하게 마음을 쓰지만 반대로 확신이 서기 전까지는 내 속마음을 쉽게 다 보여주지 않는 방어막이 함께 작동합니다.

그러다 보니 $pName 입장에서는 $callName이 나를 정말 좋아하는 건지, 아니면 거리를 두고 재고 있는 건지 헷갈려 할 순간이 생기기 쉬워요. 나는 배려한다고 참았던 서운함이 쌓였다가 어느 날 차가운 말투나 거리두기로 툭 튀어나오면 상대는 갑작스러운 벽을 느끼게 됩니다.

지금 필요한 건 거창한 고백이나 밀당이 아니라, 작고 솔직한 일상 감정을 그때그때 흘려보내는 대화예요. 서운한 점이 생겼을 때 혼자 결론을 내리지 말고 부드럽게 내 컨디션과 마음을 먼저 공유하면 관계의 긴장감이 훨씬 빠르게 풀릴 거예요.''';

        return AnalysisResult(
          resultTitle: '$callName의 연애 심리와 관계 흐름 브리핑',
          keyPoint: '속마음을 아끼다 한꺼번에 거리 두는 패턴만 줄이면 관계 주도권을 편안하게 가져올 수 있습니다.',
          briefingBody: body,
          resultSummary:
              '신중하고 깊은 애정을 가진 구조이나, 표현을 아끼다 오해가 생기기 쉽습니다. 서운함을 쌓아두지 않고 당일에 가볍게 공유하는 소통법이 핵심입니다.',
          confidenceStatus: confStatus,
          goodPoints: [
            '한 번 신뢰가 쌓이면 흔들림 없이 상대를 지지하고 배려하는 깊은 지속력이 있습니다.',
            '상대의 미세한 기분 변화와 분위기를 빠르게 알아채는 섬세한 감수성을 지녔습니다.',
          ],
          riskPoints: [
            '상대에게 확신을 받기 전까지 내 감정을 숨기려다 타이밍이 어긋날 수 있습니다.',
            '서운함을 혼자 참다가 한계치가 넘으면 예고 없이 마음을 닫아버리는 패턴을 주의해야 합니다.',
          ],
          actionItems: [
            '상대의 연락 속도나 말투 하나로 속마음을 단정 짓지 말고, 궁금한 점은 가볍게 직접 물어보세요.',
            '고마운 감정이나 반가움은 생각났을 때 미루지 말고 그 자리에서 한 문장으로 표현해 보세요.',
          ],
          auditFooter: '[적용 기준: $kRules | 확신도: $confTag]',
          warningMessage: AppCopy.commonNotice,
        );

      case AnalysisCategory.pattern:
        final body = '''
결론부터 짚어드리면, $callName이 중요한 순간마다 비슷한 피로감을 겪는 이유는 의지나 능력이 부족해서가 아니라 '안전한 완벽함'을 확인하기 전에는 쉽게 발을 떼지 않는 내면의 방어 습관 때문이에요.

$callName의 사주 원국을 보면 $stemTrait 에너지가 중심을 잡고 있어, 내가 통제할 수 있는 범위 안에서는 놀라울 만큼 안정적인 성과를 냅니다. 하지만 예상치 못한 변수가 생기거나 내 기준에 100% 차지 않는 상황이 오면, 실패할까 봐 아예 시작을 미루거나 반대로 혼자 모든 짐을 떠안으려는 경향이 강해집니다.

인간관계와 진로에서도 이 패턴이 똑같이 반복돼요. 처음에는 좋은 사람으로 남고 싶어서 무리한 부탁이나 불편한 감정을 다 받아주다가, 내 에너지가 바닥나면 어느 순간 관계를 한꺼번에 정리해 버리는 식이죠.

이 고리를 끊는 가장 확실한 방법은 '70점짜리 실행'과 '작은 거절'을 일상화하는 것입니다. 처음부터 완벽한 계획을 세우려 하지 말고 일단 작게 움직이면서 수정해 나가면, 타고난 강점이 지치지 않고 오래 빛을 발하게 됩니다.''';

        return AnalysisResult(
          resultTitle: '$callName의 반복 패턴 원인과 현실 돌파구',
          keyPoint: '완벽해야 움직이는 습관과 참았다가 끊어내는 관계 패턴만 바꾸면 에너지 소모가 절반으로 줄어듭니다.',
          briefingBody: body,
          resultSummary:
              '책임감과 기준이 높아 스스로를 몰아붙이다 지치는 패턴이 반복되기 쉽습니다. 기준선을 조금 낮춰 빠르게 실행하고 초기에 선을 긋는 연습이 필요합니다.',
          confidenceStatus: confStatus,
          goodPoints: [
            '위기 상황에서도 감정적으로 무너지지 않고 현실적인 해결책을 찾아내는 복원력이 뛰어납니다.',
            '내가 정한 분야에서는 끝까지 책임을 다해 주변의 두터운 신임을 얻습니다.',
          ],
          riskPoints: [
            '거절을 미루다 혼자 과부하에 걸린 뒤 관계를 급격히 차단하는 극단적 소모를 조심해야 합니다.',
            '준비가 덜 되었다는 이유로 좋은 기회를 눈앞에서 흘려보내기 쉽습니다.',
          ],
          actionItems: [
            '내키지 않는 약속이나 부탁을 받았을 때 "확인해 보고 내일 말씀드릴게요"라고 완충 시간을 확보하세요.',
            '고민 중인 계획이 있다면 완벽한 준비 대신 오늘 당장 30분 안에 끝낼 수 있는 첫 단계만 실행하세요.',
          ],
          auditFooter: '[적용 기준: $kRules | 확신도: $confTag]',
          warningMessage: AppCopy.commonNotice,
        );

      case AnalysisCategory.compatibility:
        return general(
          user: user,
          partner: partner,
          category: AnalysisCategory.love,
          userQuestion: userQuestion,
        );
    }
  }

  static CompatResult compat(
    CompatComputation comp, {
    UserProfile? user,
    PartnerProfile? partner,
    String userQuestion = '',
  }) {
    if (!comp.compatibilityAvailable) {
      return CompatResult(
        compatibilityAvailable: false,
        compatibilityScore: 0,
        signalColor: 'gray',
        detailedScores: const {},
        maxScores: const {},
        itemFormulas: const {},
        briefingBody:
            '현재 두 분의 정확한 사주 명식(최소 년·월·일주 6글자) 또는 양/음력 기준이 모두 확인되지 않아 K08 강제 브레이크 원칙에 따라 궁합 점수 산출을 보류했습니다.\n\n억지로 점수를 찍어내기보다 정확한 생년월일 정보를 확인한 뒤 다시 분석받으시는 것이 가장 정직하고 신뢰할 수 있는 방법입니다.',
        goodParts: const [],
        riskParts: const [],
        finalJudgment:
            '정보가 부족해 궁합 신호등을 확정하지 않았습니다(K08 판정 보류). 상대방의 생년월일과 양/음력 여부를 확인해 주세요.',
        actionItems: const [
          '상대방의 정확한 생년월일(양력/음력 여부)을 먼저 확인해 보세요.',
          '만세력 캡처나 사주 글자를 알고 계신다면 STEP 2 명식 확인 화면에서 직접 입력하실 수 있습니다.',
        ],
        auditFooter: '[적용 기준: K04, K08 | 확신도: LOW(낮음)]',
        holdReason: comp.holdReason,
      );
    }

    final myName = (user == null || user.userName.trim().isEmpty)
        ? '회원님'
        : '${user.userName.trim()}님';
    final pName = (partner == null || partner.partnerName.trim().isEmpty)
        ? '상대분'
        : partner.partnerName.trim();

    final summaryBlock = comp.toK07SummaryBlock();
    final confLabel = comp.hourIncluded ? 'HIGH(높음)' : 'MEDIUM(보통)';
    final footer =
        '[적용 기준: K04, K06, K07-R3, K08, K09, K10 | 확신도: $confLabel]';

    final signalIntro = switch (comp.signalColor) {
      SignalColor.green =>
        '결론부터 말씀드리면, $myName과 $pName은 서로의 기질과 현실 리듬이 안정적으로 맞물리는 초록불(GREEN) 궁합이에요. 억지로 애쓰지 않아도 자연스럽게 호흡이 맞고 서로에게 든든한 내 편이 되어줄 수 있는 구조입니다.',
      SignalColor.yellow =>
        '결론부터 말씀드리면, $myName과 $pName은 서로를 끌어당기는 매력과 현실적인 온도차가 함께 존재하는 노란불(YELLOW) 궁합이에요. 기본적인 인연의 힘은 충분하지만, 갈등이 생겼을 때 푸는 방식이 달라서 대화 규칙을 맞춰가는 것이 핵심입니다.',
      SignalColor.red =>
        '결론부터 말씀드리면, $myName과 $pName은 타고난 생활 리듬과 감정 처리 방식이 정면으로 부딪히기 쉬운 빨간불(RED) 궁합이에요. 서로 다른 매력에 강하게 끌릴 수는 있지만, 오래 함께하려면 자존심 싸움을 피하는 의식적인 거리 조절이 꼭 필요합니다.',
      SignalColor.gray => '판정 보류 상태입니다.',
    };

    final body = '''
$summaryBlock

$signalIntro

**두 사람이 서로에게 끌리는 진짜 이유 (중심축과 오행 보완)**
${comp.itemFormulas['A. 관계의 중심축'] ?? ''}
${comp.itemFormulas['C. 부족한 부분 보완'] ?? ''}
두 분의 명식을 나란히 놓고 보면, 혼자일 때 은근히 비어 있던 정서적 갈증이나 현실적 빈틈을 상대방의 에너지가 채워주는 지점이 분명하게 작동하고 있어요. 대화의 결(B항목)에서도 서로의 관점이 자극이 되어 함께 있을 때 시야가 넓어지는 장점이 있습니다.

**현실 연애와 대화에서 조심해야 할 마찰 포인트**
${comp.itemFormulas['D. 생활과 장기 안정성'] ?? ''}
가까워질수록 내 기준을 상대에게도 당연하게 기대하기 쉬워요. 한쪽은 즉시 대화로 결론을 내고 싶어 하는 반면 다른 한쪽은 혼자 생각을 정리할 시간이 필요할 때, 이를 '애정이 식었다'거나 '나를 무시한다'고 오해하면 불필요한 감정 소모가 커집니다.

**2026년 병오년 관계 조언 및 시너지 전략**
올해는 주변 일정이나 환경 변화가 빨라지면서 사소한 말투 하나로 자존심 마찰이 생기기 쉬운 시기입니다. 갈등이 올라올 때는 누가 맞는지 따지기보다 "지금 우리 둘 다 지쳐 있으니 내일 다시 이야기하자"라고 먼저 숨 고르기 신호를 주는 쪽이 관계의 진짜 주도권을 쥐게 됩니다.${comp.boundaryShiftNotice != null ? '\n\n※ ${comp.boundaryShiftNotice}' : ''}''';

    return CompatResult(
      compatibilityAvailable: true,
      compatibilityScore: comp.compatibilityScore,
      signalColor: comp.signalColor.name,
      detailedScores: comp.detailedScores,
      maxScores: comp.maxScores,
      itemFormulas: comp.itemFormulas,
      briefingBody: body,
      goodParts: _goodFromFacts(comp),
      riskParts: _riskFromFacts(comp),
      finalJudgment: _judgment(comp, myName, pName),
      actionItems: const [
        '서운한 감정이 올라올 때는 추측해서 단정 짓지 말고, 내가 바라는 행동을 구체적인 한 문장으로 요청하세요.',
        '갈등 상황에서 대화가 길어지면 30분~하루 정도 생각 정리 시간을 갖기로 두 사람만의 타임아웃 규칙을 정해두세요.',
      ],
      auditFooter: footer,
      holdReason: null,
      boundaryShiftNotice: comp.boundaryShiftNotice,
    );
  }

  /// 꼬리 질문(후속 대화) 시뮬레이션 응답
  static ChatTurn followUp({
    required UserProfile user,
    PartnerProfile? partner,
    CompatComputation? comp,
    required String followUpQuestion,
  }) {
    final s = user.toSaju();
    final callName =
        user.userName.trim().isEmpty ? '회원님' : '${user.userName.trim()}님';
    final q = followUpQuestion.trim();
    final conf = s.hourUnknown ? 'MEDIUM(보통)' : 'HIGH(높음)';

    if (q.contains('한 줄') || q.contains('짧게') || q.contains('결론만')) {
      return ChatTurn(
        role: 'assistant',
        text: comp != null
            ? '한 줄 결론: 두 분은 K07-R3 기준 총점 ${comp.compatibilityScore}점(${comp.signalColor.name.toUpperCase()})으로, 감정 속도 차이만 대화 규칙으로 맞추면 충분히 단단해질 관계입니다.'
            : '한 줄 결론: $callName은 내 기준이 명확할 때 가장 빛나는 분이니, 올해는 가짓수를 줄이고 핵심 한 가지에 집중하시는 것이 가장 유리합니다.',
        auditFooter: '[적용 기준: K04, K09, K10 | 확신도: $conf]',
      );
    }

    if (q.contains('명리') || q.contains('자세히') || q.contains('근거')) {
      return ChatTurn(
        role: 'assistant',
        text: '''
쉬운 결론부터 말씀드리면, $callName의 명식은 타고난 일간의 중심축과 월지의 계절 기운이 뚜렷해 자기 주도성이 핵심 무기가 되는 구조입니다.

명리적 근거(K04·K06·K09)로 자세히 풀어보면 다음과 같습니다.
${s.toDetailedSlotText(gender: user.gender)}

이처럼 표면 글자뿐 아니라 지지 속 지장간의 암장 기운이 일간과 맞물려 작동하기 때문에, 단편적인 오행 개수보다 에너지가 식상(표현·실행)에서 재성·관성(현실 결과물·안정)으로 어떻게 유통되는지가 중요합니다.${comp != null ? '\n\n또한 궁합에서는 K07-R3 정량 규칙에 따라 일지 중심축(A), 천간 소통(B), 6글자 본기 오행 상호 보완(C), 년·월지 장기 안정성(D)을 각각 독립 검산하여 총점 ${comp.compatibilityScore}점이 도출되었습니다.' : ''}''',
        auditFooter: '[적용 기준: K04, K06, K09, K10 | 확신도: $conf]',
      );
    }

    if (q.contains('내년') || q.contains('비교') || q.contains('올해')) {
      return ChatTurn(
        role: 'assistant',
        text: '''
결론부터 말씀드리면, **올해(2026 병오년)가 판을 벌이고 방향을 전환하는 시기**라면, **내년(2027 정미년)은 올해 벌인 일을 실속 있게 내 것으로 굳히는 정착의 시기**입니다.

**2026년 병오(丙午)년 흐름 — 확장과 속도 조절**
강한 화(火) 기운이 들어와 주변 환경이 빠르게 움직이고 새로운 제안이나 인간관계 자극이 많아집니다. 기회는 넓어지지만 조급해지기 쉬워 체력과 감정 소모를 관리해야 합니다.

**2027년 정미(丁未)년 흐름 — 내실과 안정화**
들뜬 에너지가 한층 차분해지면서, 실질적인 문서·자격·계약이나 관계의 안정감을 다지기에 훨씬 유리해집니다. 큰 결정이나 장기 계약은 올해 충분히 검토하고 내년에 확정 짓는 흐름이 가장 안전합니다.''',
        auditFooter: '[적용 기준: K03, K04, K06, K09, K10 | 확신도: $conf]',
      );
    }

    return ChatTurn(
      role: 'assistant',
      text: '''
방금 물어보신 부분을 $callName의 확정 명식(일간 ${s.dayMaster}) 기준으로 짚어드리면, 지금은 조급하게 상대나 환경을 바꾸려 하기보다 내가 통제할 수 있는 선택지에 에너지를 모으는 것이 가장 현명합니다.

$callName은 마음이 흔들릴 때일수록 혼자 머릿속으로만 시뮬레이션을 돌리다 지치기 쉬운데요. 이번 주에는 가장 현실적인 작은 행동 하나만 먼저 실행해 보시고, 그 반응을 보고 다음 스텝을 정하셔도 전혀 늦지 않습니다.''',
      auditFooter: '[적용 기준: K04, K06, K09, K10 | 확신도: $conf]',
    );
  }

  static String _dayMasterTrait(String dm) {
    switch (dm) {
      case '갑':
        return '곧게 뻗어 나가는 추진력과 리더십(甲木)';
      case '을':
        return '유연한 적응력과 끈기 있는 생명력(乙木)';
      case '병':
        return '밝고 솔직한 표현력과 확산 에너지(丙火)';
      case '정':
        return '따뜻한 배려심과 깊은 집중력(丁火)';
      case '무':
        return '묵직한 포용력과 흔들리지 않는 자존심(戊土)';
      case '기':
        return '실속 있는 조율 능력과 섬세한 현실 감각(己土)';
      case '경':
        return '분명한 원칙과 단호한 결단력(庚金)';
      case '신':
        return '정교하고 예리한 안목과 깔끔한 기준(辛金)';
      case '임':
        return '넓은 스케일과 유연한 지혜(壬水)';
      case '계':
        return '섬세한 공감 능력과 치밀한 기획력(癸水)';
      default:
        return '단단한 내면의 기준';
    }
  }

  static List<String> _goodFromFacts(CompatComputation c) {
    final good = c.factsForAi
        .where((f) =>
            f.contains('육합') ||
            f.contains('천간합') ||
            f.contains('상생') ||
            f.contains('보완') ||
            f.contains('삼합') ||
            f.contains('방합') ||
            f.contains('무난'))
        .toList();
    return good.isEmpty
        ? ['서로 다른 강점을 지녀 새로운 관점과 자극을 주고받을 수 있는 구조입니다.']
        : good;
  }

  static List<String> _riskFromFacts(CompatComputation c) {
    final risk = c.factsForAi
        .where((f) =>
            f.contains('충') ||
            f.contains('형') ||
            f.contains('해') ||
            f.contains('파') ||
            f.contains('상극') ||
            f.contains('과다') ||
            f.contains('제외'))
        .toList();
    return risk.isEmpty
        ? ['정면충돌 요소는 적으나, 편안함에 익숙해져 표현을 생략하면 거리감이 생길 수 있습니다.']
        : risk;
  }

  static String _judgment(CompatComputation c, String myName, String pName) {
    switch (c.signalColor) {
      case SignalColor.green:
        return '$myName과 $pName은 K07-R3 기준 ${c.compatibilityScore}점(초록불)으로 중심축과 오행 균형이 탄탄합니다. 서로의 다름을 인정하고 고마움을 자주 표현할수록 오래 안정감을 누릴 관계입니다.';
      case SignalColor.yellow:
        return '$myName과 $pName은 K07-R3 기준 ${c.compatibilityScore}점(노란불)으로 끌림과 보완성이 분명하지만, 갈등 시 대화 템포 조절이 필요한 관계입니다. 서운함을 쌓아두지 않는 소통 규칙이 핵심입니다.';
      case SignalColor.red:
        return '$myName과 $pName은 K07-R3 기준 ${c.compatibilityScore}점(빨간불)으로 생활 리듬이나 자존심 충돌이 나타날 수 있는 구조입니다. 서로를 바꾸려 하기보다 적정한 개인 공간과 대화 예절을 지키는 노력이 필요합니다.';
      case SignalColor.gray:
        return '판정 보류';
    }
  }
}
