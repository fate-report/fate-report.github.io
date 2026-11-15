import '../manseryeok/saju_calculator.dart';
import 'relations.dart';

/// 신호등 색상 (코드가 결정)
enum SignalColor { green, yellow, red, gray }

/// 궁합 계산 결과 (점수·신호등·사실 목록). AI는 이 결과를 "설명"만 한다.
class CompatComputation {
  final bool compatibilityAvailable;
  final int compatibilityScore; // 0~100
  final SignalColor signalColor;
  final Map<String, int> detailedScores;
  final Map<String, int> maxScores;
  final List<String> factsForAi; // AI가 설명할 근거 사실
  final String? holdReason;

  const CompatComputation({
    required this.compatibilityAvailable,
    required this.compatibilityScore,
    required this.signalColor,
    required this.detailedScores,
    required this.maxScores,
    required this.factsForAi,
    required this.holdReason,
  });
}

/// 궁합 규칙 엔진.
/// 점수 체계(100점): 정보신뢰도20 / 핵심자리25 / 오행보완20 / 충형해20 / 현실안정15
/// 강제 규칙:
///  - 상대 일주 없음 → 판정 보류(GRAY)
///  - 양/음력 불명확 → 판정 보류
///  - 일지 직접 충 → 최대 YELLOW
///  - 핵심 충돌 2개 이상 → 최대 YELLOW
class CompatEngine {
  static const Map<String, int> _maxScores = {
    '정보신뢰도': 20,
    '핵심자리': 25,
    '오행보완': 20,
    '충형해': 20,
    '현실안정': 15,
  };

  static CompatComputation compute({
    required SajuResult me,
    required SajuResult partner,
    required bool calendarClear,
  }) {
    final facts = <String>[];

    // ── 강제 보류 조건 ──
    if (partner.dayPillar.isEmpty) {
      return _hold('상대의 일주 정보가 없어 궁합을 확정할 수 없습니다.');
    }
    if (!calendarClear) {
      return _hold('양력/음력 여부가 명확하지 않아 판정을 보류합니다.');
    }

    final myDayStem = me.dayMaster;
    final myDayBranch = _branchOf(me.dayPillar);
    final pDayStem = partner.dayMaster;
    final pDayBranch = _branchOf(partner.dayPillar);

    // 1) 정보신뢰도 (20): 양쪽 일주 명확하면 만점, 시주까지 있으면 보너스 유지
    int infoScore = 20;
    if (me.hourUnknown || partner.hourUnknown) {
      infoScore = 16;
      facts.add('한쪽 이상 출생시간이 없어 시주 기반 판단은 제외했습니다.');
    } else {
      facts.add('양쪽 명식 정보가 충분해 신뢰도가 높습니다.');
    }

    // 2) 핵심자리 (25): 일간·일지 관계
    int coreScore = 12; // 기본 중간
    int coreConflicts = 0;
    bool directDayClash = false;

    // 일지 합/삼합 → 가점
    if (isHarmony(myDayBranch, pDayBranch)) {
      coreScore += 9;
      facts.add('일지가 육합(六合) 관계로, 서로 끌리고 편안함을 느끼기 쉽습니다.');
    } else if (isTrine(myDayBranch, pDayBranch)) {
      coreScore += 8;
      facts.add('일지가 삼합(三合) 관계로, 목표를 향해 협력하기 좋은 조화가 있습니다.');
    }
    // 일지 충 → 감점 + 강제상한
    if (isClash(myDayBranch, pDayBranch)) {
      coreScore -= 6;
      coreConflicts++;
      directDayClash = true;
      facts.add('일지가 정면으로 충(沖)하여, 생활 리듬·가치관에서 부딪힘이 생기기 쉽습니다.');
    }
    if (isPunish(myDayBranch, pDayBranch)) {
      coreScore -= 4;
      coreConflicts++;
      facts.add('일지에 형(刑)의 요소가 있어, 서로를 압박하는 긴장이 나타날 수 있습니다.');
    }
    if (isHarm(myDayBranch, pDayBranch)) {
      coreScore -= 3;
      coreConflicts++;
      facts.add('일지에 해(害)의 요소가 있어, 사소한 오해가 쌓이기 쉽습니다.');
    }
    coreScore = coreScore.clamp(0, 25);

    // 3) 오행보완 (20): 일간 오행의 상생/상극
    int elementScore = 10;
    final myEl = stemElement[myDayStem];
    final pEl = stemElement[pDayStem];
    if (myEl != null && pEl != null) {
      if (elementGenerates[myEl] == pEl || elementGenerates[pEl] == myEl) {
        elementScore = 18;
        facts.add('일간 오행이 서로 생(生)해주는 관계로, 기운을 북돋아 줍니다.');
      } else if (myEl == pEl) {
        elementScore = 13;
        facts.add('일간 오행이 같아, 가치관은 비슷하나 자극은 적을 수 있습니다.');
      } else if (elementControls[myEl] == pEl || elementControls[pEl] == myEl) {
        elementScore = 7;
        facts.add('일간 오행이 서로 극(剋)하는 면이 있어, 주도권 다툼이 생길 수 있습니다.');
      }
    }

    // 4) 충형해 리스크 (20): 적을수록 고득점
    int riskScore = 20;
    riskScore -= coreConflicts * 5;
    riskScore = riskScore.clamp(0, 20);
    if (coreConflicts == 0) {
      facts.add('핵심 자리에서 큰 충·형·해가 거의 없어 안정적입니다.');
    }

    // 5) 현실안정 (15): 종합 가중 근사
    int stableScore = 8;
    if (isHarmony(myDayBranch, pDayBranch) || isTrine(myDayBranch, pDayBranch)) {
      stableScore += 5;
    }
    if (directDayClash) stableScore -= 3;
    stableScore = stableScore.clamp(0, 15);

    final detailed = {
      '정보신뢰도': infoScore,
      '핵심자리': coreScore,
      '오행보완': elementScore,
      '충형해': riskScore,
      '현실안정': stableScore,
    };
    int total = detailed.values.fold(0, (a, b) => a + b);

    // ── 신호등 판정 ──
    SignalColor color;
    if (total >= 75) {
      color = SignalColor.green;
    } else if (total >= 55) {
      color = SignalColor.yellow;
    } else {
      color = SignalColor.red;
    }
    // 강제 상한: 일지 직접 충 또는 핵심충돌 2개 이상 → 최대 YELLOW
    if ((directDayClash || coreConflicts >= 2) && color == SignalColor.green) {
      color = SignalColor.yellow;
      facts.add('[규칙] 핵심 자리 충돌이 있어 초록불까지는 올리지 않았습니다.');
    }

    return CompatComputation(
      compatibilityAvailable: true,
      compatibilityScore: total,
      signalColor: color,
      detailedScores: detailed,
      maxScores: _maxScores,
      factsForAi: facts,
      holdReason: null,
    );
  }

  static CompatComputation _hold(String reason) => CompatComputation(
        compatibilityAvailable: false,
        compatibilityScore: 0,
        signalColor: SignalColor.gray,
        detailedScores: const {},
        maxScores: _maxScores,
        factsForAi: const [],
        holdReason: reason,
      );

  static String _branchOf(String pillar) =>
      pillar.length >= 2 ? pillar.substring(1) : '';
}
