import 'package:flutter_test/flutter_test.dart';

import 'package:fate_report/main.dart';
import 'package:fate_report/manseryeok/saju_calculator.dart';
import 'package:fate_report/compat/compat_engine.dart';
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

  test('K07-R3 궁합 정량 채점 엔진 검산 (A~D 항목 및 자형 예외 검증)', () {
    // 같은 일지이면서 자형(오-오)일 때 A항목: 25 + 3 - 8 = 20점 검증
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
    expect(comp.detailedScores.containsKey('B. 생각과 표현 방식'), true);
    expect(comp.detailedScores.containsKey('C. 부족한 부분 보완'), true);
    expect(comp.detailedScores.containsKey('D. 생활과 장기 안정성'), true);
  });

  test('PromptBuilder에 K01~K10 무삭제 마스터 엔진이 포함되어 있다', () {
    final sys = PromptBuilder.systemInstruction();
    expect(sys.contains('[K01]'), true);
    expect(sys.contains('[K07-R3]'), true);
    expect(sys.contains('[K09]'), true);
    expect(sys.contains('[K10]'), true);
  });

  testWidgets('앱이 정상적으로 뜬다', (WidgetTester tester) async {
    await tester.pumpWidget(const FateReportApp());
    await tester.pump();
    expect(find.text('Fate Report'), findsWidgets);
  });
}
