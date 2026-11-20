import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fate_report/main.dart';
import 'package:fate_report/manseryeok/saju_calculator.dart';
import 'package:fate_report/manseryeok/solar_terms.dart';
import 'package:fate_report/manseryeok/lunar_converter.dart';
import 'package:fate_report/compat/compat_engine.dart';
import 'package:fate_report/models/models.dart';
import 'package:fate_report/services/prompt_builder.dart';

void main() {
  test('만세력 일주 기준일 검산 (1900-01-01=갑술, 2000-01-01=무오, 2026-11-16=갑오)', () {
    final s1900 = SajuCalculator.calculate(year: 1900, month: 1, day: 1);
    expect(s1900.dayPillar, '갑술');

    final s2000 = SajuCalculator.calculate(year: 2000, month: 1, day: 1);
    expect(s2000.dayPillar, '무오');

    final s2026 = SajuCalculator.calculate(year: 2026, month: 11, day: 16);
    expect(s2026.dayPillar, '갑오');
    expect(s2026.yearPillar, '병오');
  });

  test('정밀 24절기 절입 시각 검산 (2025 입춘 2/3, 2026 입춘 당일 시간 경계, 2026 경칩 3/5)', () {
    // 2025년 입춘은 2월 3일 밤 11시경이므로 2025-02-03은 절입일이 3일이어야 함
    final ipchun2025 = SolarTerms.entryTimeKst(2025, 0);
    expect(ipchun2025.month, 2);
    expect(ipchun2025.day, 3);

    // 2026년 2월 4일 입춘 시각(약 05:00 KST) 전후 출생자의 년주·월주 분기 검증
    final beforeIpchun2026 = SajuCalculator.calculate(
      year: 2026,
      month: 2,
      day: 4,
      hour: 2,
      minute: 30,
      applyLocalTime: false,
    );
    expect(beforeIpchun2026.yearPillar, '을사');
    expect(beforeIpchun2026.monthPillar, '기축');

    final afterIpchun2026 = SajuCalculator.calculate(
      year: 2026,
      month: 2,
      day: 4,
      hour: 6,
      minute: 30,
      applyLocalTime: false,
    );
    expect(afterIpchun2026.yearPillar, '병오');
    expect(afterIpchun2026.monthPillar, '경인');

    // 2026년 경칩은 3월 5일 밤 11시경이므로 3월 5일 절입일 확인
    final gyeongchip2026 = SolarTerms.entryTimeKst(2026, 1);
    expect(gyeongchip2026.month, 3);
    expect(gyeongchip2026.day, 5);
  });

  test('음력 평달 및 윤달(1995년 평8월 vs 윤8월) 변환 및 자정 경계 일주·시주 정합성 검산', () {
    final reg1995 = LunarConverter.toSolar(1995, 8, 15, isLeapMonth: false);
    expect(reg1995?.solarDate, DateTime(1995, 9, 9));

    final leap1995 = LunarConverter.toSolar(1995, 8, 15, isLeapMonth: true);
    expect(leap1995?.solarDate, DateTime(1995, 10, 9));

    // 1988년 서머타임 기간 새벽 00:20 서울 출생 -> 보정 후 전날(7/14) 22:48 해시(무술일 계해시)
    final dstMidnight = SajuCalculator.calculate(
      year: 1988,
      month: 7,
      day: 15,
      hour: 0,
      minute: 20,
      placeName: '서울',
      applyLocalTime: true,
    );
    expect(dstMidnight.dayPillar, '무술');
    expect(dstMidnight.hourPillar, '계해');
  });

  test('K07-R3 궁합 정량 채점 엔진 및 JEV 코드 사후 검증기 검산', () {
    final me = SajuCalculator.calculate(
      year: 2000,
      month: 1,
      day: 1, // 기묘년 병자월 무오일
      gender: 'male',
    );
    final partner = SajuCalculator.calculate(
      year: 2026,
      month: 11,
      day: 16, // 병오년 기해월 갑오일
      gender: 'female',
    );
    final comp = CompatEngine.compute(
      me: me,
      partner: partner,
      calendarClear: true,
    );
    expect(comp.compatibilityAvailable, true);
    expect(comp.detailedScores['A. 관계의 중심축'], 20); // 오-오 자형 예외(-5)

    // 시간 미상 사용자일 때 AI가 HIGH를 뱉어도 JevHarnessValidator가 MEDIUM(partial)으로 강제 클램핑하는지 검증
    final u = UserProfile(birthTimeUnknown: true);
    final res = AnalysisResult.fromJson({
      'confidenceLevel': 'HIGH',
      'resultTitle': '테스트',
      'keyPoint': '핵심',
      'briefingBody': '올해 2024년 갑진년 흐름은 좋습니다.',
      'resultSummary': '요약',
      'auditFooter': '[적용 기준: K04, K09 | 확신도: HIGH(높음)]',
    }, user: u);
    expect(res.confidenceStatus, ConfidenceStatus.partial);
    expect(res.auditFooter.contains('MEDIUM(보통)'), true);
    expect(res.briefingBody.contains('2024년'), false);
  });

  test('PromptBuilder에 K01~K10 무삭제 마스터 엔진이 포함되어 있다', () {
    final sys = PromptBuilder.systemInstruction();
    expect(sys.contains('[K01]'), true);
    expect(sys.contains('[K07-R3]'), true);
    expect(sys.contains('[K09]'), true);
    expect(sys.contains('[K10]'), true);
  });

  testWidgets('앱이 정상적으로 뜬다', (WidgetTester tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await tester.pumpWidget(const FateReportApp());
    await tester.pump();
    expect(find.text('FATE REPORT'), findsWidgets);
  });
}
