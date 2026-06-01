import 'package:flutter/material.dart';

/// Neutral black-and-white palette — no blue-tinted "dashboard" look.
class AppColors {
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF0A0A0A);
  static const Color surface2 = Color(0xFF141414);
  static const Color border = Color(0xFF2A2A2A);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFAAAAAA);

  /// Primary emphasis — selected tabs, focus rings, main actions.
  static const Color accent = Color(0xFFFFFFFF);
  /// Secondary data highlights (charts, secondary stats).
  static const Color accent2 = Color(0xFFD0D0D0);
  /// Tertiary / muted emphasis.
  static const Color accent3 = Color(0xFF888888);
  static const Color danger = Color(0xFFE57373);

  static const Color heatmapRed = Color(0xFFDC2626);
  static const Color heatmapBlue = Color(0xFF2563EB);
  static const Color heatmapNeutral = Color(0xFF2A2A2A);

  static const Color headVertical = Color(0xFF1C2028);
  static const Color headFocused = Color(0xFF28201C);
  static const Color headBroad = Color(0xFF1C2820);
  static const Color headPositional = Color(0xFF281C1C);

  static Color headTypeColor(String type) {
    switch (type) {
      case 'vertical':
        return headVertical;
      case 'focused':
        return headFocused;
      case 'broad':
        return headBroad;
      case 'positional':
        return headPositional;
      default:
        return surface2;
    }
  }

  static Color headTypeAccent(String type) {
    switch (type) {
      case 'vertical':
        return const Color(0xFF9EB4D0);
      case 'focused':
        return const Color(0xFFD0B49E);
      case 'broad':
        return const Color(0xFF9ED0B4);
      case 'positional':
        return const Color(0xFFD09E9E);
      default:
        return textSecondary;
    }
  }

  static const taxonomyDonutColors = {
    'broad': headBroad,
    'vertical': headVertical,
    'focused': headFocused,
    'positional': headPositional,
  };
}
