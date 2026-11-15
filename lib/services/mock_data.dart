import '../content/copy.dart';
import '../models/models.dart';
import '../compat/compat_engine.dart';

/// USE_MOCK=true 일 때 반환할 가짜 결과 (UI 개발/프리뷰용).
/// 실제 배포(USE_MOCK=false)에서는 사용되지 않는다.
class MockData {
  static AnalysisResult general({
    required UserProfile user,
    required AnalysisCategory category,
  }) {
    final partial = user.birthTimeUnknown;
    switch (category) {
      case AnalysisCategory.basic:
        return AnalysisResult(
          resultTitle: '${user.userName.isEmpty ? '당신' : user.userName}의 타고난 결',
          resultSummary:
              '일간 ${user.dayMaster ?? ''}을(를) 중심으로 보면, 스스로 방향을 정할 때 힘이 나는 사람입니다. '
              '다만 결정을 미루면 에너지가 흩어지기 쉬운 구조도 함께 보입니다.',
          confidenceStatus:
              partial ? ConfidenceStatus.partial : ConfidenceStatus.ok,
          keyPoint: '스스로 정할 때 강해지고, 미룰수록 약해집니다.',
          goodPoints: [
            '한 가지에 몰입하면 남다른 완성도를 냅니다.',
            '주변 분위기를 읽는 감각이 좋아 관계에서 신뢰를 얻습니다.',
          ],
          riskPoints: [
            '거절을 어려워해 스스로를 소모시키기 쉽습니다.',
            '큰 결정 앞에서 과도하게 재다가 기회를 놓칠 수 있습니다.',
          ],
          actionItems: [
            '이번 주 안에 미뤄둔 결정 1개를 골라 마감일을 정하세요.',
            '거절 문장 하나를 미리 만들어 두세요. (예: "지금은 어려워요")',
          ],
          warningMessage: AppCopy.commonNotice,
        );
      case AnalysisCategory.love:
        return AnalysisResult(
          resultTitle: '연애에서의 나, 그리고 상대의 시선',
          resultSummary:
              '당신은 상대에게 안정감을 주지만, 마음을 다 내보이기 전까지 시간이 걸리는 편입니다. '
              '상대는 그 신중함을 매력으로 느낄 수도, 벽으로 느낄 수도 있습니다.',
          confidenceStatus:
              partial ? ConfidenceStatus.partial : ConfidenceStatus.ok,
          keyPoint: '표현의 속도를 조금만 앞당기면 오해가 줄어듭니다.',
          goodPoints: [
            '한번 마음을 주면 깊고 꾸준합니다.',
            '상대의 감정 변화를 섬세하게 알아챕니다.',
          ],
          riskPoints: [
            '속마음을 늦게 꺼내 상대가 확신을 못 얻을 수 있습니다.',
            '서운함을 쌓아두다 한꺼번에 터뜨릴 위험이 있습니다.',
          ],
          actionItems: [
            '느낀 감정을 그날 안에 한 문장으로 표현해 보세요.',
            '서운한 점은 쌓지 말고 "지금" 가볍게 말하는 연습을 하세요.',
          ],
          warningMessage: AppCopy.commonNotice,
        );
      case AnalysisCategory.pattern:
        return AnalysisResult(
          resultTitle: '반복되는 패턴의 뿌리',
          resultSummary:
              '비슷한 상황에서 같은 선택을 반복하는 흐름이 보입니다. 이는 "안전"을 우선하는 성향과 연결됩니다. '
              '나쁜 게 아니라, 방향만 살짝 틀면 강점이 됩니다.',
          confidenceStatus:
              partial ? ConfidenceStatus.partial : ConfidenceStatus.ok,
          keyPoint: '문제는 능력이 아니라 "익숙한 선택"의 반복입니다.',
          goodPoints: [
            '위기에서 침착함을 잃지 않습니다.',
            '한번 신뢰한 관계·일에 오래 헌신합니다.',
          ],
          riskPoints: [
            '불편해도 익숙한 쪽을 고르다 성장 기회를 미룹니다.',
            '참다가 관계나 일을 갑자기 끊어내는 패턴이 나올 수 있습니다.',
          ],
          actionItems: [
            '최근 반복된 상황 1개를 적고, 평소와 "반대" 선택을 한 번만 해보세요.',
            '끊어내기 전에 "한 번의 대화"를 먼저 시도해 보세요.',
          ],
          warningMessage: AppCopy.commonNotice,
        );
      case AnalysisCategory.compatibility:
        return general(user: user, category: AnalysisCategory.love);
    }
  }

  static CompatResult compat(CompatComputation comp) {
    if (!comp.compatibilityAvailable) {
      return CompatResult(
        compatibilityAvailable: false,
        compatibilityScore: 0,
        signalColor: 'gray',
        detailedScores: const {},
        maxScores: const {},
        goodParts: const [],
        riskParts: const [],
        finalJudgment:
            '지금은 정보가 부족해 궁합을 확정하지 않았습니다. 억지로 점수를 내기보다, '
            '판정을 보류하는 것이 더 정직한 결과입니다.',
        actionItems: const [
          '상대의 정확한 생년월일(가능하면 출생시간)을 확인해 보세요.',
          '양력/음력 여부를 명확히 한 뒤 다시 시도해 보세요.',
        ],
        holdReason: comp.holdReason,
      );
    }
    final color = comp.signalColor.name;
    return CompatResult(
      compatibilityAvailable: true,
      compatibilityScore: comp.compatibilityScore,
      signalColor: color,
      detailedScores: comp.detailedScores,
      maxScores: comp.maxScores,
      goodParts: _goodFromFacts(comp),
      riskParts: _riskFromFacts(comp),
      finalJudgment: _judgment(comp),
      actionItems: const [
        '잘 맞는 부분은 서로 말로 인정해 주세요.',
        '부딪히는 주제는 규칙을 정해 감정이 아닌 방식으로 다루세요.',
      ],
      holdReason: null,
    );
  }

  static List<String> _goodFromFacts(CompatComputation c) {
    final good = c.factsForAi
        .where((f) =>
            f.contains('조화') ||
            f.contains('보완') ||
            f.contains('삼합') ||
            f.contains('신뢰도가 높') ||
            f.contains('거의 없'))
        .toList();
    return good.isEmpty
        ? ['서로의 다른 점이 오히려 새로운 자극이 될 수 있습니다.']
        : good;
  }

  static List<String> _riskFromFacts(CompatComputation c) {
    final risk = c.factsForAi
        .where((f) =>
            f.contains('충') ||
            f.contains('형') ||
            f.contains('해') ||
            f.contains('극') ||
            f.contains('제외'))
        .where((f) => !f.startsWith('[규칙]'))
        .toList();
    return risk.isEmpty
        ? ['큰 충돌은 적지만, 방심하면 무관심으로 흐를 수 있습니다.']
        : risk;
  }

  static String _judgment(CompatComputation c) {
    switch (c.signalColor) {
      case SignalColor.green:
        return '구조적으로 잘 맞는 편입니다. 다만 좋은 궁합도 관리하지 않으면 식습니다. '
            '지금의 편안함을 당연하게 여기지 마세요.';
      case SignalColor.yellow:
        return '보완되는 면과 부딪히는 면이 함께 있습니다. 관계 관리 난이도가 중간 이상이니, '
            '충돌 주제를 미리 정해두면 충분히 좋은 관계가 될 수 있습니다.';
      case SignalColor.red:
        return '충돌 요소가 많은 구조입니다. 불가능하다는 뜻이 아니라, 이어가려면 서로의 '
            '노력이 확실히 필요하다는 신호입니다.';
      case SignalColor.gray:
        return '판정 보류';
    }
  }
}
