import 'package:flutter/material.dart';

class AppDimensions {
  // Spacing
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space28 = 28.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;

  // Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 14.0;
  static const double radiusLarge = 20.0;
  static const double radiusXLarge = 28.0;
  static const double radiusFull = 999.0;

  // Shadows
  static const List<BoxShadow> cardShadowLight = [
    BoxShadow(color: Color(0x0A262A4E), blurRadius: 16, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> cardShadowDark = [
    BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 4)),
  ];
}
