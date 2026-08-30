import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

enum BadgeVariant { primary, outlier, hazard, warning, pro, neutral }

/// Responsive Badge / Pill component
class ResponsiveBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final BadgeVariant variant;
  final VoidCallback? onTap;

  const ResponsiveBadge({
    super.key,
    required this.text,
    this.icon,
    this.variant = BadgeVariant.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color fg;

    switch (variant) {
      case BadgeVariant.primary:
        bg = const Color(0xFF181A24); // Solid Deep Black
        border = const Color(0xFF181A24);
        fg = Colors.white;
        break;
      case BadgeVariant.outlier:
        bg = AppColors.outlierJadeSubtle;
        border = AppColors.outlierJade;
        fg = const Color(0xFF047857);
        break;
      case BadgeVariant.hazard:
        bg = AppColors.hazardRubySubtle;
        border = AppColors.hazardRuby;
        fg = const Color(0xFFBE123C);
        break;
      case BadgeVariant.warning:
        bg = AppColors.warningAmberSubtle;
        border = AppColors.warningAmber;
        fg = const Color(0xFFB45309);
        break;
      case BadgeVariant.pro:
        bg = const Color(0xFF181A24);
        border = const Color(0xFFF59E0B);
        fg = const Color(0xFFF59E0B);
        break;
      case BadgeVariant.neutral:
        bg = const Color(0xFFF1F5F9);
        border = const Color(0xFFCBD5E1);
        fg = AppColors.textPrimary;
        break;
    }

    final content = Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100.r), // True Capsule geometry
        border: Border.all(color: border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12.sp, color: fg),
            SizedBox(width: 4.w),
          ],
          Flexible(
            child: Text(
              text,
              style: AppTypography.labelSmall.copyWith(
                color: fg,
                fontWeight: FontWeight.w800, // Heavy solid typography
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }
}
