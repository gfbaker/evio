import 'package:flutter/material.dart';
import 'colors.dart';

abstract class EvioGradients {
  // Header gradient - Subtle Grey
  // Linear gradient: white → very light gray (0xFFF9F9FB) → white
  static LinearGradient get headerGradient => LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      EvioLightColors.background, // #FFFFFF (0%)
      const Color(0xFFF9F9FB), // Gris muy muy clarito (50%)
      EvioLightColors.background, // #FFFFFF (100%)
    ],
    stops: const [0.0, 0.5, 1.0],
  );

  // Event count banner gradient
  static LinearGradient get bannerGradient => LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      EvioLightColors.muted.withValues(alpha: 0.3),
      EvioLightColors.muted.withValues(alpha: 0.2),
      EvioLightColors.muted.withValues(alpha: 0.3),
    ],
    stops: const [0.0, 0.5, 1.0],
  );
}
