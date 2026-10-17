import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Border? border;
  final double? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDimensions.space16),
    this.onTap,
    this.color,
    this.border,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = borderRadius ?? AppDimensions.radiusMedium;

    final cardColor =
        color ?? (isDark ? AppColors.cardDark : AppColors.cardLight);
    final cardBorder =
        border ??
        Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        );

    final content = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        border: cardBorder,
      ),
      padding: padding,
      child: child,
    );

    final shadows = isDark
        ? AppDimensions.cardShadowDark
        : AppDimensions.cardShadowLight;

    if (onTap != null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(r),
          boxShadow: shadows,
        ),
        child: Material(
          color: cardColor,
          borderRadius: BorderRadius.circular(r),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: BorderRadius.circular(r),
            onTap: onTap,
            child: content,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        boxShadow: shadows,
      ),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(r),
        clipBehavior: Clip.antiAlias,
        child: content,
      ),
    );
  }
}
