import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

enum BadgeVariant {
  primary,
  outlier,
  hazard,
  warning,
  pro,
  neutral,
}

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
        bg = AppColors.primarySubtle;
        border = const Color(0xFFBFDBFE);
        fg = AppColors.primaryDark;
        break;
      case BadgeVariant.outlier:
        bg = AppColors.outlierJadeSubtle;
        border = AppColors.outlierJadeBorder;
        fg = AppColors.outlierJade;
        break;
      case BadgeVariant.hazard:
        bg = AppColors.hazardRubySubtle;
        border = AppColors.hazardRubyBorder;
        fg = AppColors.hazardRuby;
        break;
      case BadgeVariant.warning:
        bg = AppColors.warningAmberSubtle;
        border = AppColors.warningAmberBorder;
        fg = AppColors.warningAmber;
        break;
      case BadgeVariant.pro:
        bg = AppColors.proGoldSubtle;
        border = const Color(0xFFFDE68A);
        fg = AppColors.proGold;
        break;
      case BadgeVariant.neutral:
        bg = AppColors.surfaceSubtle;
        border = AppColors.borderLight;
        fg = AppColors.textSecondary;
        break;
    }

    final content = Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12.sp, color: fg),
            SizedBox(width: 4.w),
          ],
          Text(
            text,
            style: AppTypography.labelSmall.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
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
