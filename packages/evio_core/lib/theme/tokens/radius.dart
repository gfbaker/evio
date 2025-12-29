import 'package:flutter/material.dart';

// Bordes redondeados de Evio Club
abstract class EvioRadius {
  // Base (10px como en el mockup)
  static const double base = 10;

  // Scale
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 10;
  static const double xl = 14;
  static const double xxl = 20;
  static const double full = 999;

  // Components
  static const double button = 8;
  static const double input = 10;
  static const double card = 12;
  static const double cardLarge = 16;
  static const double badge = 6;
  static const double bottomSheet = 24;

  // BorderRadius helpers
  static BorderRadius get buttonRadius => BorderRadius.circular(button);
  static BorderRadius get inputRadius => BorderRadius.circular(input);
  static BorderRadius get cardRadius => BorderRadius.circular(card);
  static BorderRadius get cardLargeRadius => BorderRadius.circular(cardLarge);
  static BorderRadius get badgeRadius => BorderRadius.circular(badge);
  static BorderRadius get bottomSheetRadius =>
      BorderRadius.vertical(top: Radius.circular(bottomSheet));

  // Admin specific
  static const double sidebar = 8;
  static const double stats = 12;
}
