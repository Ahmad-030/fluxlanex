import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Core Colors
  static const Color bgWhite = Color(0xFFF5F9FF);
  static const Color bgLightBlue = Color(0xFFDEF0FF);
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color neonCyanDark = Color(0xFF00B8D4);
  static const Color playerGlow = Color(0xFF00E5FF);
  static const Color obstacleRed = Color(0xFFFF4D6D);
  static const Color obstacleRedLight = Color(0xFFFFB3C1);
  static const Color fluxOrange = Color(0xFFFF9F1C);
  static const Color pulsePurple = Color(0xFFBD93F9);
  static const Color textDark = Color(0xFF1A202C);
  static const Color textGrey = Color(0xFF718096);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color laneLineColor = Color(0xFFCBE8FF);
  static const Color shadowCyan = Color(0x4000E5FF);

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: neonCyan,
          secondary: obstacleRed,
          surface: bgWhite,
        ),
        scaffoldBackgroundColor: bgWhite,
        textTheme: GoogleFonts.orbitronTextTheme().copyWith(
          bodyMedium: GoogleFonts.inter(color: textDark),
          bodySmall: GoogleFonts.inter(color: textGrey),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: neonCyan,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
}
