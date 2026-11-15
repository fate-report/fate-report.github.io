import '../content/copy.dart';
import '../models/models.dart';
import '../compat/compat_engine.dart';

/// promptBuilder - AI에게 보낼 프롬프트를 구성.
/// 계산값은 "읽기 전용 컨텍스트"로만 넣고, AI가 재산출하지 못하게 한다.
class PromptBuilder {
  static String systemInstruction() {
    return '''
당신은 신뢰형 사주 리포트 서비스의 해석 담당입니다. 아래 규칙을 반드시 지키세요.

[역할 분리 - 매우 중요]
- 사주팔자(년주·월주·일주·시주)와 궁합 점수·신호등은 이미 코드로 계산되어 주어집니다.
- 당신은 계산하지 않습니다. 주어진 값을 "쉽게 해석/설명"만 합니다.
- 명식 값이나 점수를 지어내거나 바꾸지 마세요. 응답에 명식 값을 되돌려 넣지 마세요.

[말투]
- 항상 한국어, 쉬운 말. 어려운 명리학 용어는 최소화하고 쓰면 바로 풀어 설명.

[립서비스 방지]
- 좋은 점을 말하면 위험한 점도 반드시 함께 말합니다.
- 건강, 투자, 합격, 재회, 이별, 결혼을 "무조건 된다/안 된다"로 단정하지 않습니다.
- 상대방의 실제 마음을 100% 단정하지 않습니다.

[결론 의무]
- "상황에 따라 다릅니다"로 끝내지 말고 반드시 결론과 행동 방향을 제시합니다.
- 모든 결과 마지막에 "지금 할 일(actionItems)"을 1~3개 제시합니다.

[판정 보류]
- 정보가 부족하면 confidenceStatus를 'hold'로 표시합니다.
- 출생시간이 없으면 시주 관련 판단은 하지 않습니다.

[정서적 배려]
- 사용자가 정서적으로 힘들어 보이면, 사주가 심리 상담을 대체하지 않음을 부드럽게 안내합니다.

반드시 지정된 JSON 스키마로만 응답하세요. 코드블록 없이 순수 JSON만 출력합니다.
''';
  }

  static String buildGeneral({
    required UserProfile user,
    required AnalysisCategory category,
    required String userQuestion,
  }) {
    final s = user.toSaju();
    final hourInfo =
        s.hourUnknown ? '시주: (출생시간 모름 → 판정 보류)' : '시주: ${s.hourPillar}';
    final categoryName = _categoryName(category);

    return '''
[분석 유형] $categoryName

[코드가 계산한 명식 - 읽기 전용, 변경 금지]
- 이름/닉네임: ${user.userName}
- 성별: ${user.gender == 'male' ? '남성' : '여성'}
- 년주: ${s.yearPillar}
- 월주: ${s.monthPillar}
- 일주: ${s.dayPillar}
- $hourInfo
- 일간(day master): ${s.dayMaster}

[사용자 고민/질문]
$userQuestion

위 명식을 근거로 "$categoryName" 관점에서 해석해 주세요.
- 출생시간이 없으면 confidenceStatus를 'partial' 또는 'hold'로 설정하세요.
- 좋은 점(goodPoints)과 조심할 점(riskPoints)을 반드시 함께 제시하세요.

응답 JSON 스키마:
{
  "resultTitle": "짧은 제목",
  "resultSummary": "2~4문장 요약",
  "confidenceStatus": "ok" | "partial" | "hold",
  "keyPoint": "가장 핵심 한 줄",
  "goodPoints": ["...", "..."],
  "riskPoints": ["...", "..."],
  "actionItems": ["지금 할 일 1~3개"],
  "warningMessage": "${AppCopy.commonNotice}"
}
''';
  }

  static String buildCompatibility({
    required UserProfile user,
    required PartnerProfile partner,
    required CompatComputation comp,
    required String userQuestion,
  }) {
    final me = user.toSaju();
    final p = partner.toSaju();

    if (!comp.compatibilityAvailable) {
      return '''
[궁합 해석 - 판정 보류]
코드 판정 결과: 판정 보류(GRAY). 사유: ${comp.holdReason}

두 사람 정보:
- 나: 일주 ${me.dayPillar}, 일간 ${me.dayMaster}
- 상대: 일주 ${p.dayPillar.isEmpty ? '(없음)' : p.dayPillar}

판정을 확정하지 말고, 왜 보류인지 사용자가 이해하도록 부드럽게 설명하고,
정보를 보완할 방법(예: 상대 생년월일시 확인)을 actionItems로 안내하세요.

응답 JSON 스키마:
{
  "goodParts": [],
  "riskParts": [],
  "finalJudgment": "판정 보류 설명",
  "actionItems": ["보완 방법 1~3개"],
  "holdReason": "${comp.holdReason}"
}
''';
    }

    final scoreText = comp.detailedScores.entries
        .map((e) => '  - ${e.key}: ${e.value}/${comp.maxScores[e.key]}')
        .join('\n');
    final factsText = comp.factsForAi.map((f) => '  - $f').join('\n');

    return '''
[궁합 해석 - 점수/신호등은 코드가 이미 결정했습니다. 바꾸지 마세요.]

코드 판정 결과 (읽기 전용):
- 총점: ${comp.compatibilityScore}/100
- 신호등: ${comp.signalColor.name.toUpperCase()}
- 세부 점수:
$scoreText

코드가 감지한 구조적 사실 (이 사실에 근거해서만 설명):
$factsText

두 사람 명식 (읽기 전용):
- 나: 일주 ${me.dayPillar}, 일간 ${me.dayMaster}
- 상대: 일주 ${p.dayPillar}, 일간 ${p.dayMaster}, 관계상태: ${partner.relationStatus}

[사용자 고민]
$userQuestion

위 "코드가 감지한 사실"만 근거로, 좋은 부분(goodParts)과 조심할 부분(riskParts)을 쉽게 설명하세요.
점수·색깔을 새로 매기지 말고, 주어진 결과의 의미를 풀어서 설명만 하세요.
finalJudgment에는 결론 + 관계 관리 방향을 담고, actionItems를 1~3개 제시하세요.

응답 JSON 스키마:
{
  "goodParts": ["...", "..."],
  "riskParts": ["...", "..."],
  "finalJudgment": "결론과 관리 방향",
  "actionItems": ["지금 할 일 1~3개"],
  "holdReason": null
}
''';
  }

  static String _categoryName(AnalysisCategory c) {
    switch (c) {
      case AnalysisCategory.basic:
        return '내 사주 기본 분석';
      case AnalysisCategory.love:
        return '연애·속마음';
      case AnalysisCategory.pattern:
        return '반복 패턴 분석';
      case AnalysisCategory.compatibility:
        return '궁합 신호등';
    }
  }
}
