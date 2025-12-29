import 'package:flutter/material.dart';
import '../theme/tokens/colors.dart';

abstract class ProgressColorHelper {
  static Color getColorForPercentage(double percentage) {
    if (percentage < 40) return EvioLightColors.progressLow;
    if (percentage < 70) return EvioLightColors.progressMedium;
    if (percentage < 90) return EvioLightColors.progressHigh;
    return EvioLightColors.progressFull;
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
      case 'próximo':
        return EvioLightColors.statusUpcoming;
      case 'ongoing':
      case 'en curso':
        return EvioLightColors.statusOngoing;
      case 'completed':
      case 'finalizado':
        return EvioLightColors.statusCompleted;
      case 'cancelled':
      case 'cancelado':
        return EvioLightColors.statusCancelled;
      default:
        return EvioLightColors.statusUpcoming;
    }
  }
}
