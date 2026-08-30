import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/channel_provider.dart';
import '../common/solid_heavy_button.dart';

/// Clean, Minimal, and Editorial Tactile Authentication Modal Sheet for Prevue
class AuthModalSheet extends StatefulWidget {
  final VoidCallback? onAuthenticated;

  const AuthModalSheet({super.key, this.onAuthenticated});

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onAuthenticated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AuthModalSheet(onAuthenticated: onAuthenticated),
    );
  }

  @override
  State<AuthModalSheet> createState() => _AuthModalSheetState();
}

class _AuthModalSheetState extends State<AuthModalSheet> {
  bool _isSignUp = false;
  bool _obscurePassword = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _handleController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _handleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final channelProvider = context.read<ChannelProvider>();

    return Container(
      constraints: BoxConstraints(maxHeight: 740.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Container(
              margin: EdgeInsets.only(top: 10.h, bottom: 6.h),
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),

            // Top Header Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 16.sp,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'CREATOR STUDIO ACCOUNT',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textInk,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20.sp,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Segmented Control (Sign In vs Create Account)
                    _buildSegmentedSwitcher(authProvider),
                    SizedBox(height: 14.h),

                    // Error Message Banner
                    if (authProvider.errorMessage != null) ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 10.h,
                        ),
                        margin: EdgeInsets.only(bottom: 12.h),
                        decoration: BoxDecoration(
                          color: AppColors.hazardRubySubtle,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppColors.hazardRubyBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 16.sp,
                              color: AppColors.hazardRuby,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                authProvider.errorMessage!,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.hazardRuby,
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // 1-Tap Google Sign-In
                    SolidHeavyButton(
                      label: 'Continue with Google',
                      icon: Icons.g_mobiledata_rounded,
                      height: 48.h,
                      fontSize: 14.5.sp,
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textInk,
                      borderColor: const Color(0xFFD1D5DB),
                      shadowColor: const Color(0xFFCBD5E1),
                      isLoading: authProvider.isLoading,
                      onPressed: () async {
                        final success = await authProvider.signInWithGoogle(
                          preferredHandle: channelProvider.channel.handle,
                        );
                        if (context.mounted && success) {
                          await channelProvider.syncChannel(
                            authProvider.activeHandle,
                          );
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          widget.onAuthenticated?.call();
                        }
                      },
                    ),
                    SizedBox(height: 14.h),

                    // Section Divider
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Flexible(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.w),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _isSignUp
                                    ? 'OR EMAIL SIGN UP'
                                    : 'OR EMAIL LOGIN',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 9.5.sp,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    // Form Inputs
                    if (_isSignUp) ...[
                      _buildTextField(
                        controller: _nameController,
                        hintText: 'Creator / Channel Name',
                        icon: Icons.person_outline_rounded,
                        onChanged: (_) {
                          if (authProvider.errorMessage != null) {
                            authProvider.clearError();
                          }
                        },
                      ),
                      SizedBox(height: 10.h),
                      _buildTextField(
                        controller: _handleController,
                        hintText: 'Primary YouTube Handle (e.g. @Telusko)',
                        icon: Icons.alternate_email_rounded,
                        onChanged: (_) {
                          if (authProvider.errorMessage != null) {
                            authProvider.clearError();
                          }
                        },
                      ),
                      SizedBox(height: 10.h),
                    ],

                    _buildTextField(
                      controller: _emailController,
                      hintText: 'Email address',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) {
                        if (authProvider.errorMessage != null) {
                          authProvider.clearError();
                        }
                      },
                    ),
                    SizedBox(height: 10.h),

                    _buildTextField(
                      controller: _passwordController,
                      hintText: 'Password (min 6 characters)',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      onChanged: (_) {
                        if (authProvider.errorMessage != null) {
                          authProvider.clearError();
                        }
                      },
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18.sp,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 14.h),

                    // Action Button
                    SolidHeavyButton(
                      label: _isSignUp ? 'Create Account' : 'Sign In',
                      height: 48.h,
                      fontSize: 14.5.sp,
                      isLoading: authProvider.isLoading,
                      onPressed: () async {
                        bool success;
                        if (_isSignUp) {
                          success = await authProvider.signUpWithEmail(
                            email: _emailController.text,
                            password: _passwordController.text,
                            displayName: _nameController.text,
                            initialHandle: _handleController.text.isNotEmpty
                                ? _handleController.text
                                : channelProvider.channel.handle,
                          );
                        } else {
                          success = await authProvider.signInWithEmail(
                            email: _emailController.text,
                            password: _passwordController.text,
                          );
                        }

                        if (context.mounted && success) {
                          await channelProvider.syncChannel(
                            authProvider.activeHandle,
                          );
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          widget.onAuthenticated?.call();
                        }
                      },
                    ),
                    SizedBox(height: 12.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedSwitcher(AuthProvider authProvider) {
    return Container(
      height: 40.h,
      padding: EdgeInsets.all(3.r),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF2F6),
        borderRadius: BorderRadius.circular(100.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_isSignUp) {
                  setState(() => _isSignUp = false);
                  authProvider.clearError();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: !_isSignUp ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(100.r),
                  boxShadow: !_isSignUp
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Sign In',
                    style: AppTypography.labelSmall.copyWith(
                      color: !_isSignUp
                          ? AppColors.textInk
                          : AppColors.textSecondary,
                      fontWeight: !_isSignUp
                          ? FontWeight.w800
                          : FontWeight.w600,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_isSignUp) {
                  setState(() => _isSignUp = true);
                  authProvider.clearError();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: _isSignUp ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(100.r),
                  boxShadow: _isSignUp
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Create Account',
                    style: AppTypography.labelSmall.copyWith(
                      color: _isSignUp
                          ? AppColors.textInk
                          : AppColors.textSecondary,
                      fontWeight: _isSignUp
                          ? FontWeight.w800
                          : FontWeight.w600,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.textInk,
        fontSize: 13.5.sp,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, size: 18.sp, color: AppColors.textMuted),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.surfaceSubtle,
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

