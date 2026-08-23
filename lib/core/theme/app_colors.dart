import 'package:flutter/material.dart';

/// Curated Studio Light Color System for TubeSimul8
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
  static const Color borderLight = Color(0xFFE5E9F0);
  static const Color borderSubtle = Color(0xFFEEF1F6);
  static const Color borderFocused = Color(0xFF2563EB);

  // Brand / Editorial Primary
  static const Color primaryDark = Color(0xFF1E3A8A);    // Deep Editorial Cobalt
  static const Color primary = Color(0xFF2563EB);        // Electric Royal Blue
  static const Color primaryLight = Color(0xFF3B82F6);   // Glow / Active
  static const Color primarySubtle = Color(0xFFEFF6FF);  // Background tint
  static const Color indigoAccent = Color(0xFF4F46E5);

  // YouTube / Studio Accent
  static const Color youtubeRed = Color(0xFFFF0033);
  static const Color studioCrimson = Color(0xFFFF2D55);
  static const Color studioCrimsonSubtle = Color(0xFFFFF1F4);

  // Semantic Signals: Outlier & Conviction (Jade / Emerald)
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
    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
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
    colors: [Color(0xFFEFF6FF), Color(0xFFFAFAFC), Color(0xFFFFF1F4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Layered Tactile Shadows
  static List<BoxShadow> get cardElevation => [
    const BoxShadow(
      color: Color(0x080F172A),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
    const BoxShadow(
      color: Color(0x040F172A),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get cardElevationPressed => [
    const BoxShadow(
      color: Color(0x050F172A),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get proGlow => [
    BoxShadow(
      color: const Color(0xFF2563EB).withValues(alpha: 0.25),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}
