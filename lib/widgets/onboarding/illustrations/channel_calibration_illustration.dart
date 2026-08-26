import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Senior-Craft Vector Illustration: Creator DNA & Channel Graph Calibration
/// Illustrates channel baseline graph, subscriber resonance, and daily blueprint ready state.
class ChannelCalibrationIllustration extends StatelessWidget {
  final String channelHandle;
  final String niche;

  const ChannelCalibrationIllustration({
    super.key,
    this.channelHandle = '@RevenueCat',
    this.niche = 'Tech & SaaS',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220.h,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppColors.cardElevation,
      ),
      child: Stack(
        children: [
          // Background Gradient Mesh
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                gradient: LinearGradient(
                  colors: [
                    AppColors.primarySubtle.withValues(alpha: 0.6),
                    AppColors.surface,
                    AppColors.outlierJadeSubtle.withValues(alpha: 0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Central Profile Hub
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.auto_graph_rounded,
                    color: AppColors.primary,
                    size: 32.sp,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  channelHandle.isNotEmpty ? channelHandle : '@YourChannel',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textInk,
                  ),
                ),
                SizedBox(height: 3.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    'Niche: $niche',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 10.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Top Left Satellite Badge: CTR Baseline
          Positioned(
            left: 16.w,
            top: 18.h,
            child: _buildSatelliteBadge(
              icon: Icons.ads_click_rounded,
              title: 'Median CTR',
              value: '5.4%',
              color: AppColors.primaryDark,
            ),
          ),

          // Top Right Satellite Badge: Demand Clusters
          Positioned(
            right: 16.w,
            top: 18.h,
            child: _buildSatelliteBadge(
              icon: Icons.psychology_rounded,
              title: 'Audience Clusters',
              value: '12 Mined',
              color: AppColors.outlierJade,
            ),
          ),

          // Bottom Left Satellite Badge: Benchmark Views
          Positioned(
            left: 16.w,
            bottom: 18.h,
            child: _buildSatelliteBadge(
              icon: Icons.remove_red_eye_rounded,
              title: 'Median Views',
              value: '14.2K',
              color: AppColors.textPrimary,
            ),
          ),

          // Bottom Right Satellite Badge: Outlier Multiplier
          Positioned(
            right: 16.w,
            bottom: 18.h,
            child: _buildSatelliteBadge(
              icon: Icons.rocket_launch_rounded,
              title: 'Outlier Target',
              value: '3.4x Velocity',
              color: AppColors.outlierJade,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSatelliteBadge({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 11.sp, color: color),
              SizedBox(width: 4.w),
              Text(
                title,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 9.sp,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: AppTypography.labelSmall.copyWith(
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
