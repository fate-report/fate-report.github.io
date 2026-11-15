import 'package:flutter_test/flutter_test.dart';

import 'package:fate_report/main.dart';

void main() {
  testWidgets('앱이 정상적으로 뜬다', (WidgetTester tester) async {
    await tester.pumpWidget(const FateReportApp());
    await tester.pump();
    // 홈 화면이 렌더링되는지 기본 확인
    expect(find.text('Fate Report'), findsWidgets);
  });
}
