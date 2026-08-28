import 'package:flutter/material.dart';

/// Brand palette for VoiceCraft AI. Centralized so light/dark themes and
/// waveform/meter widgets all draw from the same source of truth.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryVariant = Color(0xFF4834D4);
  static const Color secondary = Color(0xFF00D2A0);
  static const Color accent = Color(0xFFFF7675);

  static const Color lightBackground = Color(0xFFF7F7FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color darkBackground = Color(0xFF121218);
  static const Color darkSurface = Color(0xFF1C1C25);

  static const Color waveformActive = primary;
  static const Color waveformInactive = Color(0xFFB2B2C2);

  static const Color error = Color(0xFFE74C3C);
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF39C12);

  static const Color cloudSynced = Color(0xFF2ECC71);
  static const Color localOnly = Color(0xFFB2B2C2);
}
