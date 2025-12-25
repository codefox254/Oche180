import 'package:flutter/material.dart';

class AppColors {
  // Core brand colors - Futuristic dark theme
  static const primary = Color(0xFF00FF94); // Neon green
  static const primaryDark = Color(0xFF00CC77);
  static const secondary = Color(0xFF00D9FF); // Cyan
  static const accent = Color(0xFFFF006E); // Hot pink
 
  // Background colors - Dark futuristic
  static const bgDark = Color(0xFF0A0E27);
  static const bgMedium = Color(0xFF151932);
  static const bgLight = Color(0xFF1E2442);
  static const bgCard = Color(0xFF252B4F);
  
  // Text colors
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB4B8D4);
  static const textTertiary = Color(0xFF7B82A3);
  
  // Semantic colors
  static const success = Color(0xFF00FF94);
  static const warning = Color(0xFFFFC107);
  static const error = Color(0xFFFF006E);
  static const info = Color(0xFF00D9FF);
  
  // Gradient colors
  static const List<Color> primaryGradient = [
    Color(0xFF00FF94),
    Color(0xFF00D9FF),
  ];
  
  static const List<Color> secondaryGradient = [
    Color(0xFF00D9FF),
    Color(0xFF0099FF),
  ];
  
  static const List<Color> accentGradient = [
    Color(0xFFFF006E),
    Color(0xFFFFAA00),
  ];
  
  static const List<Color> darkGradient = [
    Color(0xFF0A0E27),
    Color(0xFF151932),
  ];
}

class AppTextStyles {
  static const String fontFamily = 'Inter';
  
  static const displayLarge = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    letterSpacing: -1.5,
    color: AppColors.textPrimary,
  );
  
  static const displayMedium = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    letterSpacing: -1,
    color: AppColors.textPrimary,
  );
  
  static const headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );
  
  static const headlineMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );
  
  static const titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    color: AppColors.textPrimary,
  );
  
  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
  );
  
  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.25,
    color: AppColors.textSecondary,
  );
  
  static const labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.25,
    color: AppColors.textPrimary,
  );

  static const labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
  );
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppBorderRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double full = 999;
}
