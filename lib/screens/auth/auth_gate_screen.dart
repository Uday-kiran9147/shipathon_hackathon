import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/channel_provider.dart';
import '../../widgets/common/solid_heavy_button.dart';
import '../../widgets/common/tactile_card.dart';

/// Clean, Minimal, and Editorial Mandatory Authentication Gate for Prevue
class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
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

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 440.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Minimalist Studio Brand Header
                  Center(
                    child: Container(
                      width: 50.w,
                      height: 50.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF0022).withValues(alpha: 0.25),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14.r),
                        child: Image.asset(
                          'assets/images/prevue_logo_v6.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: const Color(0xFFFF0022),
                            child: Center(
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 28.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Brand Title & Subtitle
                  Text(
                    'Prevue Studio',
                    textAlign: TextAlign.center,
                    style: AppTypography.displayMedium.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 22.sp,
                      letterSpacing: -0.6,
                      color: AppColors.textInk,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'YouTube Pre-Flight Intelligence & Retention Simulator',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12.sp,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 18.h),

                  // Tactile Segmented Switcher (Sign In vs Create Account)
                  _buildSegmentedSwitcher(authProvider),
                  SizedBox(height: 14.h),

                  // Error Message Tile (if any)
                  if (authProvider.errorMessage != null) ...[
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
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

                  // Main Auth Card Container
                  TactileCard(
                    padding: EdgeInsets.all(16.w),
                    borderRadius: 18.r,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Fast 1-Tap Google Sign-In CTA
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
                            }
                          },
                        ),
                        SizedBox(height: 14.h),

                        // Section Divider with subtle text
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
                        SizedBox(height: 14.h),

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
                        SizedBox(height: 16.h),

                        // Primary Action Button
                        SolidHeavyButton(
                          label: _isSignUp ? 'Create Studio Account' : 'Sign In',
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
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 14.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedSwitcher(AuthProvider authProvider) {
    return Container(
      height: 42.h,
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
                      color: !_isSignUp ? AppColors.textInk : AppColors.textSecondary,
                      fontWeight: !_isSignUp ? FontWeight.w800 : FontWeight.w600,
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
                      color: _isSignUp ? AppColors.textInk : AppColors.textSecondary,
                      fontWeight: _isSignUp ? FontWeight.w800 : FontWeight.w600,
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

