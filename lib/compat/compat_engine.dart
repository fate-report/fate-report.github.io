import 'dart:math' as math;
import '../manseryeok/ganzhi.dart';
import '../manseryeok/saju_calculator.dart';
import 'relations.dart';

/// 신호등 색상 (코드가 결정 — K07-R3 기준: 80~100 GREEN, 50~79 YELLOW, 0~49 RED)
enum SignalColor { green, yellow, red, gray }

/// 궁합 계산 결과 (K07-R3 점수·신호등·항목별 수식 근거).
class CompatComputation {
  final bool compatibilityAvailable;
  final int compatibilityScore; // 0~100
  final SignalColor signalColor;
  final Map<String, int> detailedScores;
  final Map<String, int> maxScores;
  final Map<String, String> itemFormulas; // 항목별 "기본 OO점 + 실제 작용 글자 가감 근거"
  final List<String> factsForAi; // AI가 설명할 구조적 사실 및 수식 로그
  final String? holdReason;
  final bool hourIncluded;
  final String? boundaryShiftNotice;

  const CompatComputation({
    required this.compatibilityAvailable,
    required this.compatibilityScore,
    required this.signalColor,
    required this.detailedScores,
    required this.maxScores,
    this.itemFormulas = const {},
    required this.factsForAi,
    required this.holdReason,
    this.hourIncluded = false,
    this.boundaryShiftNotice,
  });

  /// 프롬프트 상단 요약창 및 K04 슬롯에 주입할 K07-R3 정량 요약 텍스트
  String toK07SummaryBlock() {
    if (!compatibilityAvailable) {
      return '[궁합 정량 요약: 판정 보류 (GRAY) | 사유: ${holdReason ?? "정보 부족"}]';
    }
    final signalEmoji = switch (signalColor) {
      SignalColor.green => 'GREEN(🟢)',
      SignalColor.yellow => 'YELLOW(🟡)',
      SignalColor.red => 'RED(🔴)',
      SignalColor.gray => 'HOLD(⚪)',
    };
    final lines = <String>[
      '[궁합 정량 요약: 총점 $compatibilityScore점 ($signalEmoji)]',
    ];
    for (final entry in detailedScores.entries) {
      final k = entry.key;
      final v = entry.value;
      final m = maxScores[k];
      final formula = itemFormulas[k] ?? '';
      if (k == '시주 보정') {
        final sign = v > 0 ? '+$v' : '$v';
        lines.add('- $k ($sign점 / 범위 -5~+5): $formula');
      } else {
        lines.add('- $k ($v/${m ?? 0}점): $formula');
      }
    }
    if (boundaryShiftNotice != null && boundaryShiftNotice!.isNotEmpty) {
      lines.add('- ※ 시간 미상 경계 안내: $boundaryShiftNotice');
    }
    return lines.join('\n');
  }
}

/// [K07-R3] 궁합 기계채점표 정량규칙 엔진 (100% 무삭제 구현).
/// - A. 관계의 중심축 (기본 25점, 범위 0~35점)
/// - B. 생각과 표현 방식 (기본 11점, 범위 0~20점)
/// - C. 서로 부족한 부분의 보완 (기본 12점, 범위 0~25점)
/// - D. 생활과 장기 안정성 (기본 10점, 범위 0~20점)
/// - 시주 보정 (양쪽 시간 모두 확인 시에만 적용, 기본 0점, 범위 -5~+5점)
/// - 신호등: 80~100 GREEN / 50~79 YELLOW / 0~49 RED
class CompatEngine {
  static const Map<String, int> _baseMaxScores = {
    'A. 관계의 중심축': 35,
    'B. 생각과 표현 방식': 20,
    'C. 부족한 부분 보완': 25,
    'D. 생활과 장기 안정성': 20,
  };

  static CompatComputation compute({
    required SajuResult me,
    required SajuResult partner,
    required bool calendarClear,
  }) {
    final facts = <String>[];
    final formulas = <String, String>{};

    // ── K08 강제 보류 조건 ──
    if (me.dayPillar.length < 2 || partner.dayPillar.length < 2) {
      return _hold('두 사람의 확정된 년·월·일주(최소 3주 6글자) 정보가 부족하여 궁합 판정을 보류합니다.');
    }
    if (!isValidGanzhiPillar(me.yearPillar) ||
        !isValidGanzhiPillar(me.monthPillar) ||
        !isValidGanzhiPillar(me.dayPillar) ||
        !isValidGanzhiPillar(partner.yearPillar) ||
        !isValidGanzhiPillar(partner.monthPillar) ||
        !isValidGanzhiPillar(partner.dayPillar)) {
      return _hold('년주·월주·일주(3주 6글자)가 모두 유효한 60갑자로 확인되어야 K07-R3 궁합을 계산할 수 있습니다.');
    }
    if (!calendarClear) {
      return _hold('양력/음력 여부가 명확하지 않아 K08 기준에 따라 판정을 보류합니다.');
    }

    final aYearStem = me.yearPillar[0];
    final aYearBranch = me.yearPillar[1];
    final aMonthStem = me.monthPillar[0];
    final aMonthBranch = me.monthPillar[1];
    final aDayStem = me.dayPillar[0];
    final aDayBranch = me.dayPillar[1];

    final bYearStem = partner.yearPillar[0];
    final bYearBranch = partner.yearPillar[1];
    final bMonthStem = partner.monthPillar[0];
    final bMonthBranch = partner.monthPillar[1];
    final bDayStem = partner.dayPillar[0];
    final bDayBranch = partner.dayPillar[1];

    // ─────────────────────────────────────────────
    // A. 관계의 중심축 (기본 25점, 범위 0~35점): 두 일지 1:1 비교
    // ─────────────────────────────────────────────
    int scoreA = 25;
    String descA;
    if (aDayBranch == bDayBranch && isSelfPunish(aDayBranch, bDayBranch)) {
      // 유일한 동시 적용 예외: 같은 일지(+3) + 자형(-8) = -5점
      scoreA += -5;
      descA =
          '기본 25점 + 일지 $aDayBranch-$bDayBranch 동일(+3)·자형(-8) 예외 동시 적용(-5점) = 20점';
      facts.add(
        '[A. 관계의 중심축] 두 일지가 $aDayBranch-$bDayBranch로 같으면서 자형에 해당하여 공감대(+3)와 자존심 마찰(-8)이 동시에 작용(-5점 → 20/35점).',
      );
    } else {
      final candA = <(int, String)>[];
      if (isHarmony(aDayBranch, bDayBranch)) {
        candA.add((10, '일지 $aDayBranch-$bDayBranch 육합(+10점)'));
      }
      if (aDayBranch == bDayBranch) {
        candA.add((3, '같은 일지 $aDayBranch-$bDayBranch(+3점)'));
      }
      if (isClash(aDayBranch, bDayBranch)) {
        candA.add((-12, '일지 $aDayBranch-$bDayBranch 직접 충(-12점)'));
      }
      if (isPunishOrSelfPunish(aDayBranch, bDayBranch)) {
        candA.add((-8, '일지 $aDayBranch-$bDayBranch 형(-8점)'));
      }
      if (isHarm(aDayBranch, bDayBranch)) {
        candA.add((-6, '일지 $aDayBranch-$bDayBranch 해(-6점)'));
      }
      if (isBreak(aDayBranch, bDayBranch)) {
        candA.add((-4, '일지 $aDayBranch-$bDayBranch 파(-4점)'));
      }

      final chosenA = _pickStrongest(candA);
      if (chosenA != null) {
        scoreA = (scoreA + chosenA.$1).clamp(0, 35);
        descA = '기본 25점 ${_fmtDelta(chosenA.$1)} (${chosenA.$2}) = $scoreA점';
        facts.add('[A. 관계의 중심축] ${chosenA.$2} 작용으로 $scoreA/35점.');
      } else {
        descA = '기본 25점 (일지 $aDayBranch-$bDayBranch 합·충·형·해·파 없음) = 25점';
        facts.add('[A. 관계의 중심축] 두 일지($aDayBranch-$bDayBranch) 간 직접 충돌이나 육합 없이 무난한 중심축(25/35점).');
      }
    }
    formulas['A. 관계의 중심축'] = descA;

    // ─────────────────────────────────────────────
    // B. 생각과 표현 방식 (기본 11점, 범위 0~20점)
    // ─────────────────────────────────────────────
    int scoreB = 11;
    final partsB = <String>['기본 11점'];
    final candDayStem = <(int, String)>[];
    if (isStemHarmony(aDayStem, bDayStem)) {
      candDayStem.add((6, '일간 $aDayStem-$bDayStem 천간합(+6점)'));
    }
    final aEl = stemElement[aDayStem];
    final bEl = stemElement[bDayStem];
    if (aEl != null && bEl != null) {
      if (elementGenerates[aEl] == bEl || elementGenerates[bEl] == aEl) {
        candDayStem.add((3, '일간 $aDayStem($aEl)-$bDayStem($bEl) 상생(+3점)'));
      } else if (aEl == bEl) {
        candDayStem.add((1, '일간 $aDayStem-$bDayStem 같은 $aEl 오행(+1점)'));
      } else if (elementControls[aEl] == bEl || elementControls[bEl] == aEl) {
        candDayStem.add((-2, '일간 $aDayStem($aEl)-$bDayStem($bEl) 상극(-2점)'));
      }
    }
    final chosenStem = _pickStrongest(candDayStem);
    if (chosenStem != null) {
      scoreB += chosenStem.$1;
      partsB.add(chosenStem.$2);
    }

    // 추가 천간합: A년간-B년간, A년간-B월간, A월간-B년간, A월간-B월간 4쌍 비교 (쌍당 +1, 최대 +3)
    final stemPairs = [
      ('A년간-B년간', aYearStem, bYearStem),
      ('A년간-B월간', aYearStem, bMonthStem),
      ('A월간-B년간', aMonthStem, bYearStem),
      ('A월간-B월간', aMonthStem, bMonthStem),
    ];
    final matchedStemPairs = <String>[];
    for (final sp in stemPairs) {
      if (isStemHarmony(sp.$2, sp.$3)) {
        matchedStemPairs.add('${sp.$1}(${sp.$2}-${sp.$3})');
      }
    }
    if (matchedStemPairs.isNotEmpty) {
      final addStemPts = math.min(matchedStemPairs.length, 3);
      scoreB += addStemPts;
      partsB.add('년·월간 추가 천간합 ${matchedStemPairs.join(', ')}(+$addStemPts점)');
    }
    scoreB = scoreB.clamp(0, 20);
    final descB = '${partsB.join(' + ')} = $scoreB점';
    formulas['B. 생각과 표현 방식'] = descB;
    facts.add('[B. 생각과 표현 방식] $descB ($scoreB/20점).');

    // ─────────────────────────────────────────────
    // C. 서로 부족한 부분의 보완 (기본 12점, 범위 0~25점)
    // ─────────────────────────────────────────────
    final aCounts = _sixCharCounts(
      [aYearStem, aMonthStem, aDayStem],
      [aYearBranch, aMonthBranch, aDayBranch],
    );
    final bCounts = _sixCharCounts(
      [bYearStem, bMonthStem, bDayStem],
      [bYearBranch, bMonthBranch, bDayBranch],
    );

    int plusC = 0;
    int minusC = 0;
    bool aHelpsB = false;
    bool bHelpsA = false;
    final plusReasons = <String>[];
    final minusReasons = <String>[];

    for (final el in const ['목', '화', '토', '금', '수']) {
      final ac = aCounts[el] ?? 0;
      final bc = bCounts[el] ?? 0;
      if (ac == 0 && bc >= 2) {
        plusC += 3;
        bHelpsA = true;
        plusReasons.add('나 부족($el:0)을 상대($el:$bc)가 보완(+3)');
      } else if (bc == 0 && ac >= 2) {
        plusC += 3;
        aHelpsB = true;
        plusReasons.add('상대 부족($el:0)을 나($el:$ac)가 보완(+3)');
      } else if (ac >= 2 && bc >= 2) {
        minusC -= 3;
        minusReasons.add('$el 오행 양측 과다($ac개/$bc개, -3)');
      }
    }
    if (aHelpsB && bHelpsA) {
      plusC += 2;
      plusReasons.add('상호 교차 보완 보너스(+2)');
    }

    final cappedPlusC = math.min(plusC, 13);
    final cappedMinusC = math.max(minusC, -9);
    final scoreC = (12 + cappedPlusC + cappedMinusC).clamp(0, 25);

    final aDistStr = aCounts.entries.map((e) => '${e.key}${e.value}').join('·');
    final bDistStr = bCounts.entries.map((e) => '${e.key}${e.value}').join('·');
    final reasonTokensC = <String>['기본 12점'];
    if (plusReasons.isNotEmpty) {
      reasonTokensC.add('${plusReasons.join(', ')}(가점 +$cappedPlusC점)');
    }
    if (minusReasons.isNotEmpty) {
      reasonTokensC.add('${minusReasons.join(', ')}(감점 $cappedMinusC점)');
    }
    if (plusReasons.isEmpty && minusReasons.isEmpty) {
      reasonTokensC.add('특이 결핍 보완 및 과다 중첩 없음(+0점)');
    }
    final descC =
        '${reasonTokensC.join(' + ')} = $scoreC점 [6글자 본기: 나($aDistStr) / 상대($bDistStr)]';
    formulas['C. 부족한 부분 보완'] = descC;
    facts.add('[C. 서로 부족한 부분의 보완] $descC ($scoreC/25점).');

    // ─────────────────────────────────────────────
    // D. 생활과 장기 안정성 (기본 10점, 범위 0~20점)
    // ─────────────────────────────────────────────
    int scoreD = 10;
    final partsD = <String>['기본 10점'];
    final ymPairs = [
      ('년지-년지', aYearBranch, bYearBranch),
      ('년지-월지', aYearBranch, bMonthBranch),
      ('월지-년지', aMonthBranch, bYearBranch),
      ('월지-월지', aMonthBranch, bMonthBranch),
    ];
    int directClashCountD = 0;
    for (final p in ymPairs) {
      final label = p.$1;
      final x = p.$2;
      final y = p.$3;
      final candD = <(int, String)>[];
      if (isHarmony(x, y)) candD.add((3, '$label($x-$y) 육합(+3)'));
      if (isClash(x, y)) candD.add((-3, '$label($x-$y) 충(-3)'));
      if (isPunishOrSelfPunish(x, y)) candD.add((-2, '$label($x-$y) 형(-2)'));
      if (isHarm(x, y)) candD.add((-2, '$label($x-$y) 해(-2)'));
      if (isBreak(x, y)) candD.add((-1, '$label($x-$y) 파(-1)'));

      final chosenD = _pickStrongest(candD);
      if (chosenD != null) {
        scoreD += chosenD.$1;
        partsD.add(chosenD.$2);
        if (isClash(x, y)) {
          directClashCountD++;
        }
      }
    }

    final fourBranches = [aYearBranch, aMonthBranch, bYearBranch, bMonthBranch];
    final completeGroup = findCompleteTrineOrDirectional(fourBranches);
    if (completeGroup != null) {
      scoreD += 4;
      partsD.add('년월지 4글자 내 $completeGroup 성립(+4)');
    }
    if (directClashCountD >= 2) {
      scoreD -= 3;
      partsD.add('년월지 직접 충 ${directClashCountD}회 누적(-3)');
    }
    final completePunish = findCompleteThreePunish(fourBranches);
    if (completePunish != null) {
      scoreD -= 5;
      partsD.add('년월지 4글자 내 $completePunish 성립(-5)');
    }
    scoreD = scoreD.clamp(0, 20);
    if (partsD.length == 1) {
      partsD.add('년·월지 4쌍 특이 가감 없음(+0)');
    }
    final descD = '${partsD.join(' + ')} = $scoreD점';
    formulas['D. 생활과 장기 안정성'] = descD;
    facts.add('[D. 생활과 장기 안정성] $descD ($scoreD/20점).');

    // ─────────────────────────────────────────────
    // 시주 보정 (양쪽 시간 모두 확인 시에만 적용, 기본 0점, 범위 -5~+5점)
    // ─────────────────────────────────────────────
    final bothHoursKnown = !me.hourUnknown &&
        !partner.hourUnknown &&
        (me.hourPillar?.length ?? 0) >= 2 &&
        (partner.hourPillar?.length ?? 0) >= 2;

    int scoreHour = 0;
    if (bothHoursKnown) {
      final aHourStem = me.hourPillar![0];
      final aHourBranch = me.hourPillar![1];
      final bHourStem = partner.hourPillar![0];
      final bHourBranch = partner.hourPillar![1];
      final partsH = <String>['기본 0점'];

      final candHB = <(int, String)>[];
      if (isHarmony(aHourBranch, bHourBranch)) {
        candHB.add((3, '시지 $aHourBranch-$bHourBranch 육합(+3)'));
      }
      if (aHourBranch == bHourBranch && !isSelfPunish(aHourBranch, bHourBranch)) {
        candHB.add((1, '같은 시지 $aHourBranch-$bHourBranch(+1)'));
      }
      if (isClash(aHourBranch, bHourBranch)) {
        candHB.add((-4, '시지 $aHourBranch-$bHourBranch 충(-4)'));
      }
      if (isPunishOrSelfPunish(aHourBranch, bHourBranch)) {
        candHB.add((-3, '시지 $aHourBranch-$bHourBranch 형(-3)'));
      }
      if (isHarm(aHourBranch, bHourBranch)) {
        candHB.add((-2, '시지 $aHourBranch-$bHourBranch 해(-2)'));
      }
      if (isBreak(aHourBranch, bHourBranch)) {
        candHB.add((-1, '시지 $aHourBranch-$bHourBranch 파(-1)'));
      }

      final chosenHB = _pickStrongest(candHB);
      if (chosenHB != null) {
        scoreHour += chosenHB.$1;
        partsH.add(chosenHB.$2);
      }

      // 두 시간(時干) 비교: 천간합 +1, 천간합이 없고 상생이면 +1 (동시 적용 불가)
      final ahEl = stemElement[aHourStem];
      final bhEl = stemElement[bHourStem];
      if (isStemHarmony(aHourStem, bHourStem)) {
        scoreHour += 1;
        partsH.add('시간 $aHourStem-$bHourStem 천간합(+1)');
      } else if (ahEl != null &&
          bhEl != null &&
          (elementGenerates[ahEl] == bhEl || elementGenerates[bhEl] == ahEl)) {
        scoreHour += 1;
        partsH.add('시간 $aHourStem($ahEl)-$bHourStem($bhEl) 상생(+1)');
      }

      scoreHour = scoreHour.clamp(-5, 5);
      final signH = scoreHour > 0 ? '+$scoreHour' : '$scoreHour';
      final descH = '${partsH.join(' + ')} = $signH점';
      formulas['시주 보정'] = descH;
      facts.add('[시주 보정] 양쪽 출생시간이 모두 확인되어 $descH 반영.');
    } else {
      facts.add('[시주 보정 제외] 한쪽 이상 출생시간 미상으로 K07-R3 규칙에 따라 양쪽 시주를 모두 제외(감점 없음, 3주 6글자 기준).');
    }

    // ─────────────────────────────────────────────
    // 총점 합산 및 신호등 판정 (80~100 GREEN / 50~79 YELLOW / 0~49 RED)
    // ─────────────────────────────────────────────
    final total = (scoreA + scoreB + scoreC + scoreD + scoreHour).clamp(0, 100);

    SignalColor color;
    if (total >= 80) {
      color = SignalColor.green;
    } else if (total >= 50) {
      color = SignalColor.yellow;
    } else {
      color = SignalColor.red;
    }

    // 시간 미상 시 45~54점, 75~84점이면 시주 보정(±5점)에 따른 신호등 경계 이동 가능성 안내
    String? shiftNotice;
    if (!bothHoursKnown) {
      if (total >= 75 && total <= 84) {
        shiftNotice =
            '현재 총점($total점)은 초록불/노란불 경계(80점) 구간으로, 추후 양측 시주 보정(-5~+5점) 확인 시 신호등 등급이 이동할 수 있습니다.';
        facts.add('[경계 이동 가능성] $shiftNotice');
      } else if (total >= 45 && total <= 54) {
        shiftNotice =
            '현재 총점($total점)은 노란불/빨간불 경계(50점) 구간으로, 추후 양측 시주 보정(-5~+5점) 확인 시 신호등 등급이 이동할 수 있습니다.';
        facts.add('[경계 이동 가능성] $shiftNotice');
      }
    }

    final detailed = <String, int>{
      'A. 관계의 중심축': scoreA,
      'B. 생각과 표현 방식': scoreB,
      'C. 부족한 부분 보완': scoreC,
      'D. 생활과 장기 안정성': scoreD,
      if (bothHoursKnown) '시주 보정': scoreHour,
    };

    final maxMap = <String, int>{
      ..._baseMaxScores,
      if (bothHoursKnown) '시주 보정': 5,
    };

    return CompatComputation(
      compatibilityAvailable: true,
      compatibilityScore: total,
      signalColor: color,
      detailedScores: detailed,
      maxScores: maxMap,
      itemFormulas: formulas,
      factsForAi: facts,
      holdReason: null,
      hourIncluded: bothHoursKnown,
      boundaryShiftNotice: shiftNotice,
    );
  }

  /// 절댓값이 가장 큰 점수 1개 선택 (절댓값이 같으면 감점 우선)
  static (int, String)? _pickStrongest(List<(int, String)> candidates) {
    if (candidates.isEmpty) return null;
    final sorted = List<(int, String)>.from(candidates);
    sorted.sort((a, b) {
      final cmpAbs = b.$1.abs().compareTo(a.$1.abs());
      if (cmpAbs != 0) return cmpAbs;
      // 절댓값이 같으면 음수(감점) 우선
      return a.$1.compareTo(b.$1);
    });
    return sorted.first;
  }

  /// 3주 6글자(년·월·일간 + 년·월·일지 본기) 오행 개수 산출
  static Map<String, int> _sixCharCounts(
    List<String> stems,
    List<String> branches,
  ) {
    final counts = <String, int>{'목': 0, '화': 0, '토': 0, '금': 0, '수': 0};
    for (final s in stems) {
      final el = stemElement[s];
      if (el != null) counts[el] = (counts[el] ?? 0) + 1;
    }
    for (final b in branches) {
      final el = branchMainElement[b];
      if (el != null) counts[el] = (counts[el] ?? 0) + 1;
    }
    return counts;
  }

  static String _fmtDelta(int d) => d >= 0 ? '+ $d점' : '- ${d.abs()}점';

  static CompatComputation _hold(String reason) => CompatComputation(
        compatibilityAvailable: false,
        compatibilityScore: 0,
        signalColor: SignalColor.gray,
        detailedScores: const {},
        maxScores: _baseMaxScores,
        itemFormulas: const {},
        factsForAi: const [],
        holdReason: reason,
      );
}
