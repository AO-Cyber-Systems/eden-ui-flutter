import 'package:flutter/material.dart';

/// Eden UI color palette — ported from eden_ui/tokens.css and brand_presets.rb.
///
/// Each brand preset is a [MaterialColor] with 11 shades (50–950).
/// Use [EdenColors.primary] for the current brand color (defaults to gold).
class EdenColors {
  EdenColors._();

  // ---------------------------------------------------------------------------
  // Brand presets
  // ---------------------------------------------------------------------------

  static const MaterialColor gold = MaterialColor(0xFFD4A853, <int, Color>{
    50: Color(0xFFFDF8EF),
    100: Color(0xFFFAECD5),
    200: Color(0xFFF4D5AA),
    300: Color(0xFFEDB974),
    400: Color(0xFFE59A3C),
    500: Color(0xFFD4A853),
    600: Color(0xFFC49545),
    700: Color(0xFFA67A38),
    800: Color(0xFF856131),
    900: Color(0xFF6C5029),
    950: Color(0xFF3D2A14),
  });

  static const MaterialColor blue = MaterialColor(0xFF3B82F6, <int, Color>{
    50: Color(0xFFEFF6FF),
    100: Color(0xFFDBEAFE),
    200: Color(0xFFBFDBFE),
    300: Color(0xFF93C5FD),
    400: Color(0xFF60A5FA),
    500: Color(0xFF3B82F6),
    600: Color(0xFF2563EB),
    700: Color(0xFF1D4ED8),
    800: Color(0xFF1E40AF),
    900: Color(0xFF1E3A8A),
    950: Color(0xFF172554),
  });

  static const MaterialColor emerald = MaterialColor(0xFF10B981, <int, Color>{
    50: Color(0xFFECFDF5),
    100: Color(0xFFD1FAE5),
    200: Color(0xFFA7F3D0),
    300: Color(0xFF6EE7B7),
    400: Color(0xFF34D399),
    500: Color(0xFF10B981),
    600: Color(0xFF059669),
    700: Color(0xFF047857),
    800: Color(0xFF065F46),
    900: Color(0xFF064E3B),
    950: Color(0xFF022C22),
  });

  static const MaterialColor purple = MaterialColor(0xFFA855F7, <int, Color>{
    50: Color(0xFFFAF5FF),
    100: Color(0xFFF3E8FF),
    200: Color(0xFFE9D5FF),
    300: Color(0xFFD8B4FE),
    400: Color(0xFFC084FC),
    500: Color(0xFFA855F7),
    600: Color(0xFF9333EA),
    700: Color(0xFF7E22CE),
    800: Color(0xFF6B21A8),
    900: Color(0xFF581C87),
    950: Color(0xFF3B0764),
  });

  static const MaterialColor red = MaterialColor(0xFFEF4444, <int, Color>{
    50: Color(0xFFFEF2F2),
    100: Color(0xFFFEE2E2),
    200: Color(0xFFFECACA),
    300: Color(0xFFFCA5A5),
    400: Color(0xFFF87171),
    500: Color(0xFFEF4444),
    600: Color(0xFFDC2626),
    700: Color(0xFFB91C1C),
    800: Color(0xFF991B1B),
    900: Color(0xFF7F1D1D),
    950: Color(0xFF450A0A),
  });

  static const MaterialColor slate = MaterialColor(0xFF64748B, <int, Color>{
    50: Color(0xFFF8FAFC),
    100: Color(0xFFF1F5F9),
    200: Color(0xFFE2E8F0),
    300: Color(0xFFCBD5E1),
    400: Color(0xFF94A3B8),
    500: Color(0xFF64748B),
    600: Color(0xFF475569),
    700: Color(0xFF334155),
    800: Color(0xFF1E293B),
    900: Color(0xFF0F172A),
    950: Color(0xFF020617),
  });

  // ---------------------------------------------------------------------------
  // Neutral (Zinc)
  // ---------------------------------------------------------------------------

  static const MaterialColor neutral = MaterialColor(0xFF71717A, <int, Color>{
    50: Color(0xFFFAFAFA),
    100: Color(0xFFF4F4F5),
    200: Color(0xFFE4E4E7),
    300: Color(0xFFD4D4D8),
    400: Color(0xFFA1A1AA),
    500: Color(0xFF71717A),
    600: Color(0xFF52525B),
    700: Color(0xFF3F3F46),
    800: Color(0xFF27272A),
    850: Color(0xFF1E1E22),
    900: Color(0xFF18181B),
    950: Color(0xFF0A0A0A),
  });

  // ---------------------------------------------------------------------------
  // Status colors
  // ---------------------------------------------------------------------------

  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0x1A10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0x1AF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0x1AEF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoBg = Color(0x1A3B82F6);

  // ---------------------------------------------------------------------------
  // Aurora gradient accents
  // ---------------------------------------------------------------------------

  static const Color auroraPurple = Color(0xFFA855F7);
  static const Color auroraBlue = Color(0xFF3B82F6);
  static const Color auroraCyan = Color(0xFF06B6D4);
  static const Color auroraEmerald = Color(0xFF10B981);

  static const MaterialColor cyan = MaterialColor(0xFF06B6D4, <int, Color>{
    50: Color(0xFFECFEFF),
    100: Color(0xFFCFFAFE),
    200: Color(0xFFA5F3FC),
    300: Color(0xFF67E8F9),
    400: Color(0xFF22D3EE),
    500: Color(0xFF06B6D4),
    600: Color(0xFF0891B2),
    700: Color(0xFF0E7490),
    800: Color(0xFF155E75),
    900: Color(0xFF164E63),
    950: Color(0xFF083344),
  });

  /// All brand presets keyed by name.
  static const Map<String, MaterialColor> presets = {
    'gold': gold,
    'blue': blue,
    'emerald': emerald,
    'purple': purple,
    'red': red,
    'slate': slate,
    'cyan': cyan,
  };
}

/// AOHealth-specific gradient definitions matching wireframe CSS.
///
/// Usage: `Container(decoration: BoxDecoration(gradient: AOHealthGradients.goldPrimary))`
class AOHealthGradients {
  AOHealthGradients._();

  /// Gold calorie ring, primary buttons: gold-400 → gold-600
  static const LinearGradient goldPrimary = LinearGradient(
    colors: [Color(0xFFE59A3C), Color(0xFFC49545)],
  );

  /// Accent cards: gold-500 → aurora-purple (135deg)
  static const LinearGradient goldAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD4A853), Color(0xFFA855F7)],
  );

  /// Blue macro bars: aurora-blue → aurora-cyan
  static const LinearGradient blueCyan = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
  );

  /// Emerald macro bars: aurora-emerald → aurora-cyan
  static const LinearGradient emeraldCyan = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
  );

  /// Purple progress: aurora-purple → aurora-blue
  static const LinearGradient purpleBlue = LinearGradient(
    colors: [Color(0xFFA855F7), Color(0xFF3B82F6)],
  );

  /// Live workout dark header: zinc-900 → zinc-800
  static const LinearGradient darkHeader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF18181B), Color(0xFF27272A)],
  );

  /// Profile gradient header: gold-500 → gold-700
  static const LinearGradient profileHeader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD4A853), Color(0xFFA67A38)],
  );
}

/// AOHealth-specific semantic colors for wireframe UI patterns.
class AOHealthColors {
  AOHealthColors._();

  /// Glass morphism background: rgba(255,255,255,0.6)
  static const Color glassBackground = Color(0x99FFFFFF);

  /// Glass morphism border: rgba(255,255,255,0.3)
  static const Color glassBorder = Color(0x4DFFFFFF);

  /// AI Insight card background: gold-50
  static const Color insightBg = Color(0xFFFDF8EF);

  /// AI Insight card border: gold-200
  static const Color insightBorder = Color(0xFFF4D5AA);

  /// Shadow glow for hover effects: rgba(212,168,83,0.15)
  static const Color shadowGlow = Color(0x26D4A853);

  /// Stat card gradient top borders (3px)
  static const List<LinearGradient> statTopBorders = [
    LinearGradient(colors: [Color(0xFFE59A3C), Color(0xFFC49545)]), // gold
    LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)]), // blue→cyan
    LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF10B981)]), // cyan→emerald
  ];
}
