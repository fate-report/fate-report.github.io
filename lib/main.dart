import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'services/app_state.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const FateReportApp());
}

/// 데스크톱 웹(마우스 드래그·트랙패드)과 모바일(터치) 모두에서 휠 피커 및 가로 스크롤이 부드럽게 작동하도록 확장
class _FateScrollBehavior extends MaterialScrollBehavior {
  const _FateScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}

class FateReportApp extends StatelessWidget {
  const FateReportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'Fate Report',
        debugShowCheckedModeBanner: false,
        scrollBehavior: const _FateScrollBehavior(),
        theme: AppTheme.light,
        home: const HomeScreen(),
      ),
    );
  }
}
