import 'package:flutter/material.dart';

abstract class AppColors {
  static const primary = Color(0xFFFFE234);
  static const black = Color(0xFF111111);
  static const white = Color(0xFFFFFFFF);
  static const background = Color(0xFFF5F5F5);
  static const surface = Color(0xFFFFFFFF);
  static const danger = Color(0xFFFF6B6B);
  static const success = Color(0xFF4ECDC4);
  static const info = Color(0xFFA8DAFF);
  static const textPrimary = Color(0xFF111111);
  static const textMuted = Color(0xFF666666);

  static const neoShadow = BoxShadow(
    color: Color(0xFF111111),
    offset: Offset(3, 3),
    blurRadius: 0,
  );

  static const neoShadowSmall = BoxShadow(
    color: Color(0xFF111111),
    offset: Offset(2, 2),
    blurRadius: 0,
  );
}
