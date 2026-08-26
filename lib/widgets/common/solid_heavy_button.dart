import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Visually heavy, solid tactile physical button with 3D slab depth and press feedback.
class SolidHeavyButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final Color? shadowColor;
  final double? height;
  final double? fontSize;
  final bool isLoading;
  final String? loadingText;
  final bool isSecondary;

  const SolidHeavyButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.shadowColor,
    this.height,
    this.fontSize,
    this.isLoading = false,
    this.loadingText,
    this.isSecondary = false,
  });

  @override
  State<SolidHeavyButton> createState() => _SolidHeavyButtonState();
}

class _SolidHeavyButtonState extends State<SolidHeavyButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    final bg = widget.backgroundColor ??
        (widget.isSecondary
            ? const Color(0xFF181A24) // Solid Dark Ink
            : AppColors.primary);     // Solid Vibrant Red

    final fg = widget.foregroundColor ?? Colors.white;

    // Calculate physical bottom ledge color
    final bottomLedgeColor = widget.shadowColor ??
        (widget.isSecondary
            ? const Color(0xFF000000)
            : const Color(0xFF990014));

    final outlineColor = widget.borderColor ??
        (widget.isSecondary
            ? const Color(0xFF0A0D14)
            : const Color(0xFFCC0018));

    final effectiveHeight = widget.height ?? 52.h;

    return GestureDetector(
      onTapDown: isEnabled
          ? (_) {
              HapticFeedback.lightImpact();
              setState(() => _isPressed = true);
            }
          : null,
      onTapUp: isEnabled
          ? (_) {
              setState(() => _isPressed = false);
            }
          : null,
      onTapCancel: isEnabled
          ? () {
              setState(() => _isPressed = false);
            }
          : null,
      onTap: isEnabled ? widget.onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeInOut,
        height: effectiveHeight,
        margin: EdgeInsets.only(
          top: _isPressed ? 3.h : 0,
          bottom: _isPressed ? 0 : 3.h,
        ),
        decoration: BoxDecoration(
          color: isEnabled ? bg : bg.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(100.r), // Solid Stadium Capsule
          border: Border.all(
            color: isEnabled ? outlineColor : outlineColor.withValues(alpha: 0.5),
            width: 1.8,
          ),
          boxShadow: isEnabled && !_isPressed
              ? [
                  // Crisp 3D physical ledge depth
                  BoxShadow(
                    color: bottomLedgeColor,
                    offset: const Offset(0, 3.5),
                    blurRadius: 0,
                  ),
                  // Ambient glow dispersion
                  BoxShadow(
                    color: bg.withValues(alpha: 0.35),
                    offset: const Offset(0, 6),
                    blurRadius: 14,
                  ),
                ]
              : [
                  // Pressed or disabled state: subtle minimal contact shadow
                  BoxShadow(
                    color: bottomLedgeColor.withValues(alpha: 0.4),
                    offset: const Offset(0, 1),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Center(
          child: widget.isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(fg),
                      ),
                    ),
                    if (widget.loadingText != null) ...[
                      SizedBox(width: 10.w),
                      Text(
                        widget.loadingText!,
                        style: AppTypography.labelLarge.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w900,
                          fontSize: widget.fontSize ?? 14.5.sp,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 20.sp, color: fg),
                      SizedBox(width: 8.w),
                    ],
                    Flexible(
                      child: Text(
                        widget.label,
                        style: AppTypography.labelLarge.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w900, // Heavy solid weight
                          fontSize: widget.fontSize ?? 14.5.sp,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
