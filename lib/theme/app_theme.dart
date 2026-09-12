import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF0B0E14);
  static const Color surface = Color(0xFF151924);
  static const Color cardBorder = Color(0xFF22283A);
  
  static const Color primaryNeon = Color(0xFF00E5FF);
  static const Color accentPurple = Color(0xFF7C4DFF);
  static const Color successGreen = Color(0xFF00E676);
  static const Color warningOrange = Color(0xFFFF9100);
  static const Color errorRed = Color(0xFFFF5252);
  
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF8E99AC);

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    primaryColor: primaryNeon,
    fontFamily: 'sans-serif',
    colorScheme: const ColorScheme.dark(
      background: background,
      surface: surface,
      primary: primaryNeon,
      secondary: accentPurple,
      error: errorRed,
    ),
    cardTheme: CardThemeData(
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: cardBorder, width: 1),
      ),
      elevation: 0,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryNeon;
        }
        return textMuted;
      }),
      trackColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryNeon.withOpacity(0.4);
        }
        return surface;
      }),
    ),
  );
}
