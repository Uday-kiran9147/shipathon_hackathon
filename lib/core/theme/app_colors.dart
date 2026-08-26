import 'package:flutter/material.dart';

/// Curated Studio Light Color System for Prevue
/// Designed with international hackathon craft standards in mind:
/// warm off-white canvas, pure elevated card layers, crisp ink typography,
/// and purposeful semantic indicators for creator intelligence.
class AppColors {
  // Canvas & Surfaces
  static const Color canvas = Color(0xFFFAFAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF1F4F9);
  static const Color surfaceHighlight = Color(0xFFE8EDF5);
  
  // Borders & Dividers
  // Borders & Dividers
  static const Color borderLight = Color(0xFFE5E9F0);
  static const Color borderSubtle = Color(0xFFEEF1F6);
  static const Color borderFocused = Color(0xFFFF0022);

  // Brand / Editorial Primary (Aligned with Logo Red & Ink Black)
  static const Color primaryDark = Color(0xFF181A24);    // Deep Ink / Charcoal Black
  static const Color primary = Color(0xFFFF0022);        // Vibrant Prevue Red (from logo)
  static const Color primaryLight = Color(0xFFFF334B);   // Bright Red Glow / Active
  static const Color primarySubtle = Color(0xFFFFF1F2);  // Soft Red background tint
  static const Color primaryBorder = Color(0xFFFECDD3);  // Soft Red border
  static const Color brandBlack = Color(0xFF181A24);     // Deep Black
  static const Color indigoAccent = Color(0xFF181A24);

  // YouTube / Studio Accent
  static const Color youtubeRed = Color(0xFFFF0022);
  static const Color studioCrimson = Color(0xFFFF2D55);
  static const Color studioCrimsonSubtle = Color(0xFFFFF1F4);

  // Semantic Signals: Outlier & Conviction (Jade / Mint Green from Logo Arrow)
  static const Color outlierJade = Color(0xFF059669);
  static const Color outlierJadeLight = Color(0xFF10B981);
  static const Color outlierJadeSubtle = Color(0xFFECFDF5);
  static const Color outlierJadeBorder = Color(0xFFA7F3D0);

  // Semantic Signals: Drop-Off & Retention Hazard (Ruby Red)
  static const Color hazardRuby = Color(0xFFE11D48);
  static const Color hazardRubyLight = Color(0xFFF43F5E);
  static const Color hazardRubySubtle = Color(0xFFFFF1F2);
  static const Color hazardRubyBorder = Color(0xFFFECDD3);

  // Semantic Signals: Warning & Attention (Amber / Gold)
  static const Color warningAmber = Color(0xFFD97706);
  static const Color warningAmberLight = Color(0xFFF59E0B);
  static const Color warningAmberSubtle = Color(0xFFFFFBEB);
  static const Color warningAmberBorder = Color(0xFFFDE68A);

  // Pro & Premium Accents
  static const Color proGold = Color(0xFFB45309);
  static const Color proGoldAccent = Color(0xFFF59E0B);
  static const Color proGoldSubtle = Color(0xFFFEF3C7);

  // Text / Ink Hierarchy
  static const Color textInk = Color(0xFF0A0D14);        // Razor-sharp headlines
  static const Color textPrimary = Color(0xFF0F172A);    // Primary reading
  static const Color textSecondary = Color(0xFF475569);  // Supporting descriptions
  static const Color textMuted = Color(0xFF8592A6);      // Timestamps & metadata
  static const Color textDisabled = Color(0xFFCBD5E1);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE50914), Color(0xFFFF2D55)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient proShimmerGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706), Color(0xFFB45309)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient outlierGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient hazardGradient = LinearGradient(
    colors: [Color(0xFFE11D48), Color(0xFFF43F5E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroMeshGradient = LinearGradient(
    colors: [Color(0xFFFFF1F2), Color(0xFFFAFAFC), Color(0xFFECFDF5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Layered Heavy Tactile Shadows for Solid Visual Weight
  static List<BoxShadow> get cardElevation => [
    const BoxShadow(
      color: Color(0x140F172A), // 8% alpha deep ink shadow
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
    const BoxShadow(
      color: Color(0x0A0F172A), // 4% alpha crisp ground shadow
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get cardElevationPressed => [
    const BoxShadow(
      color: Color(0x0F0F172A),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get solidButtonGlow => [
    BoxShadow(
      color: const Color(0xFFFF0022).withValues(alpha: 0.35),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get proGlow => [
    BoxShadow(
      color: const Color(0xFFFF0022).withValues(alpha: 0.28),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}
