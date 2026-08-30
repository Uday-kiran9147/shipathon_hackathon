import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';

/// Shimmer Border container for high-conviction daily blueprints
class ShimmerBorder extends StatefulWidget {
  final Widget child;
  final double? borderRadius;

  const ShimmerBorder({super.key, required this.child, this.borderRadius});

  @override
  State<ShimmerBorder> createState() => _ShimmerBorderState();
}

class _ShimmerBorderState extends State<ShimmerBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? 18.r;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: SweepGradient(
              center: Alignment.center,
              startAngle: 0.0,
              endAngle: 3.14 * 2,
              transform: GradientRotation(_controller.value * 3.14 * 2),
              colors: const [
                AppColors.primary,
                Color(0xFF38BDF8),
                AppColors.outlierJade,
                AppColors.primary,
              ],
            ),
          ),
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(radius - 1.5),
        ),
        child: widget.child,
      ),
    );
  }
}
