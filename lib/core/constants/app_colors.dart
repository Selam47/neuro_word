import 'dart:ui';

class AppColors {
  AppColors._();

  static const Color deepSpace = Color(0xFF0B0E14);
  static const Color surfaceDark = Color(0xFF101520);
  static const Color surfaceMedium = Color(0xFF151B28);
  static const Color cardDark = Color(0xFF121826);
  static const Color cardBorder = Color(0xFF1E2A3A);

  static const Color backgroundDark = deepSpace;

  static const Color electricBlue = Color(0xFF00D2FF);
  static const Color cyberPurple = Color(0xFF9D50BB);
  static const Color neonGreen = Color(0xFF00E676);
  static const Color accentOrange = Color(0xFFFF6D00);
  static const Color warningRed = Color(0xFFFF3D71);

  static const Color textPrimary = Color(0xFFE8EAED);
  static const Color textSecondary = Color(0xFF8899AA);
  static const Color textMuted = Color(0xFF556677);

  static const Color glassWhite = Color(0x12FFFFFF);
  static const Color glassBorder = Color(0x22FFFFFF);
  static const Color glassHighlight = Color(0x08FFFFFF);

  static const Color neonPink = Color(0xFFFF00FF);
  static const Color surfaceLight = Color(0xFF202A3C);
  static const Color masteredGold = Color(0xFFFFD700);

  static Color? get error => null;

  static Color forLevel(String level) {
    switch (level) {
      case 'A1':
        return const Color(0xFF4CAF50);
      case 'A2':
        return const Color(0xFF8BC34A);
      case 'B1':
        return const Color(0xFFFFEB3B);
      case 'B2':
        return const Color(0xFFFF9800);
      case 'C1':
        return const Color(0xFFFF5722);
      case 'C2':
        return const Color(0xFFF44336);
      default:
        return electricBlue;
    }
  }
}
