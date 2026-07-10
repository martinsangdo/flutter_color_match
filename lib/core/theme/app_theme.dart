import 'package:flutter/material.dart';

/// Shared palette + theme so every screen (splash, how-to-play, level select,
/// gameplay, results) reads as one consistent visual style.
class AppColors {
  static const bg = Color(0xFF0D1B2A);
  static const bgDeep = Color(0xFF091320);
  static const panel = Color(0xFF1A2A3A);
  static const panelLight = Color(0xFF243447);
  static const grid = Color(0xFF0D1B29);
  static const accent = Color(0xFF3498DB);
  static const accent2 = Color(0xFF1ABC9C);
  static const star = Color(0xFFF39C12);
  static const danger = Color(0xFFE74C3C);
  static const textPrimary = Color(0xFFECF3FA);
  static const textMuted = Color(0xFF8AA0B4);
  static const locked = Color(0xFF33465A);
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AppColors.bg,
      useMaterial3: true,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
    );
  }

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.bg, AppColors.bgDeep],
  );

  static TextStyle title(double size) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: 0.5,
      );
}
