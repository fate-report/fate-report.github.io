import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 디자인 시스템 v2 - 프리미엄 에디토리얼(캔바) 스타일.
/// 밝은 크림/아이보리 베이스 + 딥 네이비/플럼 + 절제된 금색.
class AppColors {
  static const background = Color(0xFFFBF6EE);
  static const backgroundAlt = Color(0xFFF5EDE0);
  static const card = Color(0xFFFFFFFF);
  static const primary = Color(0xFF1A2138);
  static const primarySoft = Color(0xFF2E3550);
  static const accent = Color(0xFF453061);
  static const accentSoft = Color(0xFF6B5488);
  static const gold = Color(0xFFC9A646);
  static const goldLight = Color(0xFFE3C97A);
  static const muted = Color(0xFFF3EBDD);
  static const mutedForeground = Color(0xFF8A8578);
  static const ink70 = Color(0xB31A2138);

  static const signalGreen = Color(0xFF5FA57E);
  static const signalYellow = Color(0xFFCFA23C);
  static const signalRed = Color(0xFFC97B75);
  static const signalGray = Color(0xFFB0AA9E);

  static const goodBg = Color(0xFFEDF4EE);
  static const riskBg = Color(0xFFF8F1E1);
  static const noticeBg = Color(0xFFF1EFEA);
}

class AppRadius {
  static const double card = 24.0;
  static const double chip = 14.0;
  static const double button = 18.0;
}

class AppGradients {
  static const night = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A2138), Color(0xFF3A2C52), Color(0xFF6B5488)],
  );

  static const page = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFDF9F2), Color(0xFFF5ECDD)],
  );

  static const gold = LinearGradient(
    colors: [Color(0xFFD9BE72), Color(0xFFC9A646)],
  );

  static const primaryBtn = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A3252), Color(0xFF1A2138)],
  );
}

class AppShadows {
  static List<BoxShadow> get card => [
        BoxShadow(
          color: const Color(0xFF1A2138).withValues(alpha: 0.05),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: const Color(0xFF1A2138).withValues(alpha: 0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get elevated => [
        BoxShadow(
          color: const Color(0xFF453061).withValues(alpha: 0.12),
          blurRadius: 40,
          offset: const Offset(0, 18),
        ),
      ];

  static List<BoxShadow> get gold => [
        BoxShadow(
          color: const Color(0xFFC9A646).withValues(alpha: 0.28),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.notoSansKrTextTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.card,
        surfaceTint: Colors.transparent,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.notoSerifKr(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
          letterSpacing: 1,
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
    );
  }

  static TextStyle serif({
    double size = 20,
    FontWeight weight = FontWeight.w700,
    Color? color,
    double height = 1.4,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.notoSerifKr(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.primary,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle sans({
    double size = 15,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double height = 1.6,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.notoSansKr(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.ink70,
        height: height,
        letterSpacing: letterSpacing,
      );
}
