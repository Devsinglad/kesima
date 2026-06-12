import 'package:flutter/material.dart';

abstract class AppColors {
  // Background gradient
  static const bgTop    = Color(0xFFB87828);
  static const bgBottom = Color(0xFF3A1406);

  // Board surface
  static const parchment  = Color(0xFFF7EFD8);
  static const parchment2 = Color(0xFFEBE0C0);
  static const darkBrown  = Color(0xFF2E1004);
  static const midBrown   = Color(0xFF7D5234);
  static const lightBrown = Color(0xFFB89060);

  // Gold accents
  static const gold      = Color(0xFFC8921A);
  static const goldLight = Color(0xFFE8BF58);
  static const goldPale  = Color(0xFFBF9848);
  static const cream     = Color(0xFFFFF8EE);

  // Blue player
  static const blue      = Color(0xFF1565C0);
  static const blueDark  = Color(0xFF001060);
  static const blueLight = Color(0xFF78A8F8);

  // Red player
  static const red       = Color(0xFFC02020);
  static const redDark   = Color(0xFF5A0000);
  static const redLight  = Color(0xFFF08070);

  // Interaction states
  static const selectionGreen = Color(0xFF4CAF50);
  static const validMoveAmber = Color(0xFFFF9800);
  static const validMoveLight = Color(0xFFFFCC80);

  /// Returns the base, light, and dark shades for a given player.
  static (Color base, Color light, Color dark) pieceColors(bool isBlue) =>
      isBlue
          ? (blue, blueLight, blueDark)
          : (red, redLight, redDark);
}
