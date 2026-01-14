import 'package:flutter/material.dart';

// Colores para tema oscuro (evio_fan default, evio_admin opcional)
abstract class EvioDarkColors {
  // Backgrounds
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF1C1C1E);
  static const Color surfaceVariant = Color(0xFF2C2C2E);

  // Primary
  static const Color primary = Color(0xFFFFFFFF);
  static const Color primaryForeground = Color(0xFF000000);

  // Secondary
  static const Color secondary = Color(0xFF2C2C2E);
  static const Color secondaryForeground = Color(0xFFFFFFFF);

  // Muted
  static const Color muted = Color(0xFF2C2C2E);
  static const Color mutedForeground = Color(0xFF8E8E93);

  // Accent
  static const Color accent = Color(0xFF2C2C2E);
  static const Color accentForeground = Color(0xFFFFFFFF);

  // Text
  static const Color foreground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFF4C4C4E);

  // Borders
  static const Color border = Color(0xFF3A3A3C);
  static const Color borderSubtle = Color(0xFF2C2C2E);
  static const Color input = Color(0xFF2C2C2E);
  static const Color inputBackground = Color(0xFF1C1C1E);

  // Semantic
  static const Color success = Color(0xFF32D74B);
  static const Color warning = Color(0xFFFFD60A);
  static const Color error = Color(0xFFFF453A);
  static const Color destructive = Color(0xFFFF453A);
  static const Color destructiveForeground = Color(0xFFFFFFFF);
  static const Color info = Color(0xFF0A84FF);

  // Card
  static const Color card = Color(0xFF1C1C1E);
  static const Color cardForeground = Color(0xFFFFFFFF);

  // Sidebar (admin)
  static const Color sidebar = Color(0xFF1C1C1E);
  static const Color sidebarForeground = Color(0xFFFFFFFF);
  static const Color sidebarAccent = Color(0xFF2C2C2E);

  // Ring (focus)
  static const Color ring = Color(0xFF636366);

  // Sidebar borders
  static const Color sidebarBorder = Color(0xFF3A3A3C);
}

// Colores para tema claro (evio_admin default)
abstract class EvioLightColors {
  // Backgrounds
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF3F3F5);
  static const Color surfaceVariant = Color(0xFFECECF0);

  // Primary
  static const Color primary = Color(0xFF030213);
  static const Color primaryForeground = Color(
    0xFFFBFBFB,
  ); // Cambiado de FFFFFF a FBFBFB (mockup)

  // Secondary
  static const Color secondary = Color(0xFFF2F2F5);
  static const Color secondaryForeground = Color(0xFF030213);

  // Muted
  static const Color muted = Color(0xFFECECF0);
  static const Color mutedForeground = Color(0xFF717182);

  // Accent - Amarillo dorado (highlight principal)
  static const Color accent = Color(0xFFF7CD04);
  static const Color accentForeground = Color(0xFF000000);
  
  // Hover state (gris claro)
  static const Color hover = Color(0xFFF8F8F8);

  // Text
  static const Color foreground = Color(0xFF030213);
  static const Color textPrimary = Color(
    0xFF252525,
  ); // Cambiado: Primary text del mockup
  static const Color textSecondary = Color(0xFF717182);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // Borders
  static const Color border = Color(
    0xFFEBEBEB,
  ); // Cambiado: Border específico del mockup
  static const Color borderSubtle = Color(0x0D000000);
  static const Color input = Color(0x00000000);
  static const Color inputBackground = Color(0xFFF3F3F5);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFD4183D);
  static const Color destructive = Color(0xFFD4183D);
  static const Color destructiveForeground = Color(0xFFFFFFFF);
  static const Color info = Color(0xFF3B82F6);

  // Card
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardForeground = Color(0xFF030213);

  // Sidebar (admin) - ACTUALIZADOS según mockup
  static const Color sidebar = Color(0xFFFBFBFB); // Ya estaba correcto
  static const Color sidebarForeground = Color(
    0xFF252525,
  ); // Cambiado a textPrimary
  static const Color sidebarAccent = Color(0xFFF8F8F8); // Cambiado: hover state

  // Ring (focus)
  static const Color ring = Color(0xFFB5B5B5);

  // Sidebar borders
  static const Color sidebarBorder = Color(0xFFEBEBEB); // Ya estaba correcto
  // Progress bar colors (dynamic based on percentage)
  static const Color progressLow = Color(0xFF10B981); // green-500 (0-39%)
  static const Color progressMedium = Color(0xFF3B82F6); // blue-500 (40-69%)
  static const Color progressHigh = Color(0xFFF59E0B); // orange-500 (70-89%)
  static const Color progressFull = Color(0xFFEF4444); // red-500 (90-100%)

  // Status badge colors (solid backgrounds)
  static const Color statusUpcoming = Color(0xFF3B82F6); // blue-500
  static const Color statusOngoing = Color(0xFF10B981); // green-500
  static const Color statusCompleted = Color(0xFF6B7280); // gray-500
  static const Color statusCancelled = Color(0xFFEF4444); // red-500

  // Tier state colors
  static const Color tierActiveBorder = Color(0xFFD1D5DB); // gray-300
  static const Color tierSoldOutBorder = Color(0xFFFECACA); // red-200
  static const Color tierSoldOutBackground = Color(0xFFFEE2E2); // red-50

  // Revenue colors
  static const Color revenuePositive = Color(0xFF16A34A); // green-600
  static const Color revenuePending = Color(0xFFEA580C); // orange-600
}

// Colores para Fan App (tema oscuro con acento amarillo dorado)
abstract class EvioFanColors {
  // Primary - Amarillo dorado (acento principal)
  static const Color primary = Color(0xFFF7CD04);
  static const Color primaryForeground = Color(0xFF000000);

  // Backgrounds
  static const Color background = Color(0xFF0A0A0A); // Negro profundo
  static const Color surface = Color(0xFF1E1E1E); // Cards/Modals
  static const Color surfaceVariant = Color(0xFF2C2C2C); // Elevated surfaces

  // Text
  static const Color foreground = Color(0xFFFFFFFF); // Texto principal
  static const Color secondary = Color(0xFFB0B0B0); // Texto secundario (más claro)
  static const Color mutedForeground = Color(0xFF9E9E9E); // Texto secundario
  static const Color textTertiary = Color(0xFF6B7280); // Texto terciario

  // Borders
  static const Color border = Color(0xFF3A3A3A); // Bordes sutiles
  static const Color borderSubtle = Color(0xFF2C2C2C);

  // Input
  static const Color inputBackground = Color(0xFF1E1E1E);

  // Muted
  static const Color muted = Color(0xFF2C2C2C);

  // Semantic
  static const Color success = Color(0xFF32D74B);
  static const Color warning = Color(0xFFFFD60A);
  static const Color error = Color(0xFFFF453A);
  static const Color destructive = Color(0xFFFF453A);
  static const Color destructiveForeground = Color(0xFFFFFFFF);
  static const Color info = Color(0xFF0A84FF);

  // Card
  static const Color card = Color(0xFF1E1E1E);
  static const Color cardForeground = Color(0xFFFFFFFF);

  // Bottom Nav (tab activo tiene fondo amarillo)
  static const Color activeTab = Color(0xFFF7CD04); // Amarillo
  static const Color activeTabForeground = Color(0xFF000000); // Negro
  static const Color inactiveTab = Color(0xFF9E9E9E); // Gris
}
