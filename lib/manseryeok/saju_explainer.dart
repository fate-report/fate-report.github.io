/// STEP 2 '나의 명식' 초보자용 대화체 해설 엔진 및 12시진 안내 도우미.
/// AI API를 호출하지 않고(0원·0초 지연) 확정된 만세력(SajuResult) 팩트만으로
/// 일간·오행 균형·현재 10년 대운을 이해하기 쉽게 풀어 설명한다.
library;

import 'birth_place.dart';
import 'ganzhi.dart';
import 'saju_calculator.dart';

class DaeunTimelineItem {
  final String pillar;
  final String hanja;
  final String ageRange;
  final bool isCurrent;
  final bool isTransitionYear;

  const DaeunTimelineItem({
    required this.pillar,
    required this.hanja,
    required this.ageRange,
    required this.isCurrent,
    this.isTransitionYear = false,
  });
}

class SajuEasySummary {
  final String dayMasterBadge; // 예: '큰 산 · 무토(戊土)'
  final String dayMasterStory; // 대화체 일간 성격 요약
  final String elementScopeLabel; // 예: '4주 8글자 기준' 또는 '3주 6글자 기준 (시주 제외)'
  final Map<String, int> elementCounts; // 목·화·토·금·수 개수
  final int totalChars; // 8 또는 6
  final String elementStory; // 대화체 오행 밸런스 해설
  final String? currentDaeunBadge; // 예: '병진(丙辰) 대운 · 23~32세'
  final String? currentDaeunStory; // 대화체 현재 10년 대운 해설
  final String daeunDirectionLabel; // 예: '순행 · 대운수 3'
  final List<DaeunTimelineItem> daeunTimeline;

  const SajuEasySummary({
    required this.dayMasterBadge,
    required this.dayMasterStory,
    required this.elementScopeLabel,
    required this.elementCounts,
    required this.totalChars,
    required this.elementStory,
    required this.currentDaeunBadge,
    required this.currentDaeunStory,
    required this.daeunDirectionLabel,
    required this.daeunTimeline,
  });
}

class SijinPreview {
  final String sijinLabel; // 예: '신시(申時)' 또는 '야자시(夜子時)'
  final String adjustedTimeText; // 예: '15:48'
  final String note; // 예: '서울 진태양시(-32분) 반영 시 약 15:48'
  final bool crossedToPrevDay;

  const SijinPreview({
    required this.sijinLabel,
    required this.adjustedTimeText,
    required this.note,
    required this.crossedToPrevDay,
  });
}

class SajuExplainer {
  static const Map<String, (String, String, String)> _dayMasterProfiles = {
    '갑': (
      '큰 나무',
      '갑목(甲木)',
      '곧게 뻗어 오르는 큰 나무처럼 추진력과 개척 정신이 뚜렷해요. 스스로 방향을 정해 밀고 나가는 리더형 기질입니다.'
    ),
    '을': (
      '유연한 화초',
      '을목(乙木)',
      '부드럽지만 쉽게 꺾이지 않는 덩굴·꽃나무 같은 기운이에요. 어떤 환경에도 유연하게 스며들어 끈기 있게 결과를 만들어냅니다.'
    ),
    '병': (
      '떠오르는 태양',
      '병화(丙火)',
      '주변을 환하게 비추는 태양처럼 솔직하고 밝은 에너지가 강해요. 열정과 표현력이 뛰어나 사람들의 시선을 자연스럽게 모읍니다.'
    ),
    '정': (
      '은은한 촛불',
      '정화(丁火)',
      '어둠을 밝히는 촛불처럼 섬세한 감각과 깊은 집중력을 지녔어요. 겉으로는 차분해도 속에는 단단한 열정과 배려가 살아 있습니다.'
    ),
    '무': (
      '묵직한 큰 산',
      '무토(戊土)',
      '쉽게 흔들리지 않는 큰 산처럼 중심이 단단하고 믿음직스러워요. 넓은 포용력으로 주변 사람들에게 안정감을 주는 성향입니다.'
    ),
    '기': (
      '비옥한 대지',
      '기토(己土)',
      '생명을 키워내는 비옥한 밭처럼 세심하고 실속 있는 기운이에요. 현실 감각이 뛰어나고 차근차근 신뢰와 결실을 쌓아갑니다.'
    ),
    '경': (
      '단단한 강철',
      '경금(庚金)',
      '원석과 강철처럼 결단력이 빠르고 원칙이 분명해요. 어려운 상황일수록 정면으로 돌파하는 추진력과 의리가 돋보입니다.'
    ),
    '신': (
      '정교한 보석',
      '신금(辛金)',
      '세공된 보석처럼 예리한 안목과 깔끔한 완성도를 추구해요. 감각이 섬세하고 자신의 기준을 단정하게 지켜내는 매력이 있습니다.'
    ),
    '임': (
      '넓고 깊은 바다',
      '임수(壬水)',
      '큰 바다처럼 스케일이 크고 유연한 지혜를 지녔어요. 상황 변화에 빠르게 대응하며 큰 그림을 그려나가는 힘이 강합니다.'
    ),
    '계': (
      '맑은 단비',
      '계수(癸水)',
      '조용히 스며드는 단비처럼 직관력과 감수성이 풍부해요. 남들이 놓치는 디테일을 읽어내고 부드럽게 해법을 찾는 재주가 있습니다.'
    ),
  };

  static const Map<String, String> _elementNoun = {
    '목': '나무(목)',
    '화': '불(화)',
    '토': '흙(토)',
    '금': '쇠(금)',
    '수': '물(수)',
  };

  static const Map<String, String> _elementStrengthDesc = {
    '목': '성장력과 시작하는 힘이',
    '화': '열정과 표현 에너지가',
    '토': '안정감과 버티는 중심력이',
    '금': '결단력과 정리·실행력이',
    '수': '유연한 사고와 지혜가',
  };

  static const Map<String, String> _elementNeedDesc = {
    '목': '새로운 시작이나 돌파력을',
    '화': '감정 표현이나 활력 충전을',
    '토': '생활 리듬과 중심 잡기를',
    '금': '우선순위 정리와 결단력을',
    '수': '여유와 유연한 관점 전환을',
  };

  static String _joinWithAnd(String a, String b) {
    // '나무(목)', '쇠(금)'은 받침 있음 → '과', '불(화)', '흙(토)', '물(수)'는 받침 없음 → '와'
    final hasBatchim = a.endsWith('목)') || a.endsWith('금)');
    return hasBatchim ? '$a과 $b' : '$a와 $b';
  }

  static const Map<String, String> _tenGodTheme = {
    '비견': '나만의 주체성과 독립적인 기반을 단단히 세워가는',
    '겁재': '경쟁 속에서 돌파력을 키우고 활동 무대를 넓혀가는',
    '식신': '꾸준한 실력과 나만의 콘텐츠·결과물을 만들어가는',
    '상관': '틀을 깨는 표현력과 새로운 변화·도전이 활발해지는',
    '편재': '활동 반경이 커지고 실질적인 기회와 재물 흐름을 넓혀가는',
    '정재': '안정적인 수입·자산과 탄탄한 현실 기반을 다져가는',
    '편관': '책임감 있는 역할이나 굵직한 과제를 돌파하며 성장하는',
    '정관': '사회적 신뢰·직장·명예가 차분히 자리 잡아가는',
    '편인': '남다른 통찰·전문성·기획력이 깊어지고 시야가 넓어지는',
    '정인': '배움·자격·문서운과 주변의 든든한 도움을 받기 좋은',
  };

  /// 확정 명식(SajuResult)을 초보자도 단번에 이해하는 대화체 요약으로 변환
  static SajuEasySummary explain(SajuResult saju, {String? userName}) {
    final trimmedName = userName?.trim() ?? '';
    final prefix = trimmedName.isEmpty ? '이 사주는' : '$trimmedName님은';

    // 1. 일간(나를 상징하는 기운) 풀이
    final dm = saju.dayMaster.isNotEmpty
        ? saju.dayMaster
        : (saju.dayPillar.isNotEmpty ? saju.dayPillar[0] : '');
    final profile = _dayMasterProfiles[dm];
    final dayMasterBadge =
        profile != null ? '${profile.$1} · ${profile.$2}' : '$dm 일간';
    final dayMasterStory = profile != null
        ? '$prefix ${profile.$3}'
        : '$prefix $dm 기운을 중심으로 살아가는 사주입니다.';

    // 2. 4주 8글자(또는 시주 미상 시 3주 6글자) 오행 밸런스 풀이
    final counts = saju.displayElements;
    final totalChars = saju.displayElementCharCount;
    final scopeLabel =
        totalChars == 8 ? '4주 8글자 기준' : '3주 6글자 기준 (시주 제외)';

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = sorted.first.value;
    final topEls = sorted.where((e) => e.value == maxVal).toList();
    final subEls = sorted
        .where((e) => e.value >= 2 && e.value < maxVal)
        .toList();
    final zeroEls = sorted.where((e) => e.value == 0).toList();

    final buf = StringBuffer();
    if (topEls.length == 1) {
      final topKey = topEls.first.key;
      buf.write(
        '${_elementNoun[topKey]}($maxVal) 기운이 가장 뚜렷해 ${_elementStrengthDesc[topKey]} 강점이에요.',
      );
      if (subEls.isNotEmpty) {
        final subNames =
            subEls.map((e) => '${e.key}(${e.value})').join('·');
        buf.write(' 여기에 $subNames 기운이 함께 뒷받침해 줍니다.');
      }
    } else {
      final topNames =
          topEls.map((e) => '${_elementNoun[e.key]}(${e.value})').join(' · ');
      buf.write('$topNames 기운이 나란히 중심을 이루고 있어요.');
    }

    if (zeroEls.isEmpty) {
      buf.write(' 다섯 가지 오행이 빠짐없이 고루 갖추어져 균형감이 좋습니다.');
    } else if (zeroEls.length == 1) {
      final z = zeroEls.first.key;
      buf.write(
        ' 반면 ${_elementNoun[z]} 기운은 비어 있어 ${_elementNeedDesc[z]} 의식적으로 챙기면 균형이 더 좋아집니다.',
      );
    } else {
      final zNames = zeroEls.map((e) => _elementNoun[e.key]!).join('·');
      buf.write(
        ' 반면 $zNames 기운은 비어 있어 여유를 두고 부족한 영역을 보완해 주면 흐름이 훨씬 부드러워집니다.',
      );
    }

    // 3. 대운 파싱 및 현재 10년 흐름 쉬운 해설
    final timeline = _parseDaeunTimeline(saju.daeunSummary);
    final dirMatch = RegExp(r'^(순행|역행)\s*\(대운수\s*(\d+)').firstMatch(
      saju.daeunSummary,
    );
    final daeunDirLabel = dirMatch != null
        ? '${dirMatch.group(1)} · 대운수 ${dirMatch.group(2)}'
        : '';

    DaeunTimelineItem? active;
    for (final item in timeline) {
      if (item.isCurrent) {
        active = item;
        break;
      }
    }

    String? currentBadge;
    String? currentStory;
    if (active != null && active.pillar.length >= 2) {
      final transitionSuffix = active.isTransitionYear ? ' · 올해 전환기' : '';
      currentBadge =
          '${active.pillar}(${active.hanja}) 대운 · ${active.ageRange}$transitionSuffix';
      final dStem = active.pillar[0];
      final dBranch = active.pillar[1];
      final sEl = stemElements[dStem];
      final bEl = branchElements[dBranch];
      final elPhrase = (sEl != null && bEl != null)
          ? (sEl == bEl
              ? '${_elementNoun[sEl]} 기운이 집중해서 들어오는'
              : '${_joinWithAnd(_elementNoun[sEl]!, _elementNoun[bEl]!)} 기운이 함께 들어오는')
          : '새로운 기운이 펼쳐지는';

      final tgStem = dm.isNotEmpty ? calculateTenGod(dm, dStem) : '';
      final mainHidden = (branchHiddenStems[dBranch] ?? const ['']).first;
      final tgBranch = (dm.isNotEmpty && mainHidden.isNotEmpty)
          ? calculateTenGod(dm, mainHidden)
          : '';
      final theme = _tenGodTheme[tgBranch] ??
          _tenGodTheme[tgStem] ??
          '새로운 변화와 성장을 차분히 만들어가는';

      final transitionLead = active.isTransitionYear
          ? '올해 막 새 10년 운으로 넘어가는 전환기예요. '
          : '';
      currentStory =
          '${transitionLead}지금(${active.ageRange})은 $elPhrase 10년입니다. $theme 흐름이에요.';
    } else if (saju.daeunSummary.contains('초년 대운 진입 전')) {
      currentBadge = '초년 대운 진입 전';
      currentStory = '아직 첫 10년 대운이 시작되기 전으로, 타고난 원국과 해마다 바뀌는 세운의 영향을 크게 받는 시기예요.';
    }

    return SajuEasySummary(
      dayMasterBadge: dayMasterBadge,
      dayMasterStory: dayMasterStory,
      elementScopeLabel: scopeLabel,
      elementCounts: counts,
      totalChars: totalChars,
      elementStory: buf.toString(),
      currentDaeunBadge: currentBadge,
      currentDaeunStory: currentStory,
      daeunDirectionLabel: daeunDirLabel,
      daeunTimeline: timeline,
    );
  }

  static List<DaeunTimelineItem> _parseDaeunTimeline(String summary) {
    if (summary.isEmpty) return const [];
    final colonIdx = summary.lastIndexOf('): ');
    final body = colonIdx >= 0 ? summary.substring(colonIdx + 3) : summary;
    final matches = RegExp(
      r'(★?)([갑을병정무기경신임계][자축인묘진사오미신유술해])\(([^)]+)\)\[([^\]]+)\]',
    ).allMatches(body);

    final list = <DaeunTimelineItem>[];
    for (final m in matches) {
      final star = m.group(1) ?? '';
      final pillar = m.group(2) ?? '';
      final hanja = m.group(3) ?? '';
      final rawBracket = m.group(4) ?? '';
      final isTransition = rawBracket.contains('전환기');
      final cleanAge = rawBracket.split('·').first.trim();
      list.add(
        DaeunTimelineItem(
          pillar: pillar,
          hanja: hanja,
          ageRange: cleanAge,
          isCurrent: star == '★' || rawBracket.contains('현재') || isTransition,
          isTransitionYear: isTransition,
        ),
      );
    }
    return list;
  }

  /// 출생시간 선택 시 실시간 12시진 및 진태양시 보정 미리보기 계산
  static SijinPreview describeSijin({
    required int hour24,
    required int minute,
    String? placeName,
    DateTime? birthDate,
    bool applyLocalTime = true,
  }) {
    final offsetMin = applyLocalTime
        ? trueSolarOffsetMinutes(placeName, birthDate: birthDate).round()
        : 0;
    final rawTotal = hour24 * 60 + minute + offsetMin;
    final crossedPrev = rawTotal < 0;
    final wrapped = ((rawTotal % 1440) + 1440) % 1440;
    final adjHour = wrapped ~/ 60;
    final adjMin = wrapped % 60;

    final brIdx = ((adjHour + 1) ~/ 2) % 12;
    final br = earthlyBranches[brIdx];
    final brHanja = earthlyBranchesHanja[brIdx];
    String sijinLabel;
    if (adjHour == 23) {
      sijinLabel = '야자시(夜子時)';
    } else if (adjHour == 0) {
      sijinLabel = '조자시(早子時)';
    } else {
      sijinLabel = '$br시($brHanja時)';
    }

    final hh = adjHour.toString().padLeft(2, '0');
    final mm = adjMin.toString().padLeft(2, '0');
    final adjText = '$hh:$mm';

    final place = findBirthPlace(placeName);
    final placeLabel = place?.name ?? '서울 기본';
    final offsetSign = offsetMin >= 0 ? '+$offsetMin분' : '$offsetMin분';

    final String note;
    if (!applyLocalTime) {
      note = '표준시 그대로 $adjText 기준';
    } else if (crossedPrev) {
      note = '$placeLabel 진태양시($offsetSign) 반영 시 전날 $adjText';
    } else {
      note = '$placeLabel 진태양시($offsetSign) 반영 시 약 $adjText';
    }

    return SijinPreview(
      sijinLabel: sijinLabel,
      adjustedTimeText: adjText,
      note: note,
      crossedToPrevDay: crossedPrev,
    );
  }
}
