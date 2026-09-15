import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/channel_provider.dart';
import '../../widgets/common/solid_heavy_button.dart';

/// Auth Gate Screen matching Prevue Studio design
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
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 28.h),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 440.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Brand Logo — gradient red container with chart icon
                  Center(
                    child: Image.asset(
                      'assets/images/prevue_logo_v6.png',
                      width: 84.w,
                      height: 84.w,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Brand Title
                  Text(
                    'Prevue Studio',
                    textAlign: TextAlign.center,
                    style: AppTypography.displayMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 28.sp,
                      letterSpacing: -0.3,
                      color: const Color(0xFF111214),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'YouTube Pre-Flight Intelligence & Retention Simulator',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: const Color(0xFF6B7280),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Segmented Switcher
                  _buildSegmentedSwitcher(authProvider),
                  SizedBox(height: 20.h),

                  // Auth Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(22.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Google Sign-In Button (white border, Google logo)
                        _buildGoogleButton(authProvider, channelProvider),
                        SizedBox(height: 20.h),

                        // Divider
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(color: Color(0xFFE5E7EB)),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10.w),
                              child: Text(
                                _isSignUp
                                    ? 'OR EMAIL SIGN UP'
                                    : 'OR EMAIL LOGIN',
                                style: AppTypography.labelSmall.copyWith(
                                  color: const Color(0xFF9CA3AF),
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(color: Color(0xFFE5E7EB)),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),

                        // Error Message
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
                              border: Border.all(
                                color: AppColors.hazardRubyBorder,
                              ),
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

                        // Sign Up extra fields
                        if (_isSignUp) ...[
                          _buildTextField(
                            controller: _nameController,
                            hintText: 'Creator / Channel Name',
                            icon: Icons.person_outline_rounded,
                            onChanged: (_) => authProvider.errorMessage != null
                                ? authProvider.clearError()
                                : null,
                          ),
                          SizedBox(height: 12.h),
                          _buildTextField(
                            controller: _handleController,
                            hintText: 'Primary YouTube Handle (e.g. @Telusko)',
                            icon: Icons.alternate_email_rounded,
                            onChanged: (_) => authProvider.errorMessage != null
                                ? authProvider.clearError()
                                : null,
                          ),
                          SizedBox(height: 12.h),
                        ],

                        _buildTextField(
                          controller: _emailController,
                          hintText: 'Email address',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (_) => authProvider.errorMessage != null
                              ? authProvider.clearError()
                              : null,
                        ),
                        SizedBox(height: 12.h),

                        _buildTextField(
                          controller: _passwordController,
                          hintText: 'Password (min 6 characters)',
                          icon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          onChanged: (_) => authProvider.errorMessage != null
                              ? authProvider.clearError()
                              : null,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18.sp,
                              color: const Color(0xFF9CA3AF),
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),

                        // Primary CTA (Red custom button — uses existing SolidHeavyButton)
                        SolidHeavyButton(
                          label: _isSignUp
                              ? 'Create Studio Account'
                              : 'Sign In',
                          height: 52.h,
                          fontSize: 16.sp,
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
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton(
    AuthProvider authProvider,
    ChannelProvider channelProvider,
  ) {
    return GestureDetector(
      onTap: authProvider.isLoading
          ? null
          : () async {
              final success = await authProvider.signInWithGoogle(
                preferredHandle: channelProvider.channel.handle,
              );
              if (context.mounted && success) {
                await channelProvider.syncChannel(authProvider.activeHandle);
              }
            },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(15.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google 4-color logo
            SizedBox(
              width: 18.w,
              height: 18.w,
              child: Image.network(
                'https://developers.google.com/identity/images/g-logo.png',
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              'Continue with Google',
              style: AppTypography.labelLarge.copyWith(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111214),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedSwitcher(AuthProvider authProvider) {
    return Container(
      width: double.infinity,
      height: 48.h,
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EAED),
        borderRadius: BorderRadius.circular(999.r),
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
                  borderRadius: BorderRadius.circular(999.r),
                  boxShadow: !_isSignUp
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Sign In',
                    style: AppTypography.labelMedium.copyWith(
                      color: !_isSignUp
                          ? const Color(0xFF111214)
                          : const Color(0xFF6B7280),
                      fontWeight: !_isSignUp
                          ? FontWeight.w700
                          : FontWeight.w700,
                      fontSize: 14.5.sp,
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
                  borderRadius: BorderRadius.circular(999.r),
                  boxShadow: _isSignUp
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Create Account',
                    style: AppTypography.labelMedium.copyWith(
                      color: _isSignUp
                          ? const Color(0xFF111214)
                          : const Color(0xFF6B7280),
                      fontWeight: _isSignUp ? FontWeight.w700 : FontWeight.w700,
                      fontSize: 14.5.sp,
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: AppTypography.bodyMedium.copyWith(
          color: const Color(0xFF111214),
          fontSize: 14.5.sp,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: const Color(0xFF9CA3AF),
            fontSize: 14.5.sp,
          ),
          prefixIcon: Icon(icon, size: 17.sp, color: const Color(0xFF6B7280)),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: const Color(0xFFF3F4F6),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 14.h,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: const BorderSide(color: Color(0xFFE31414), width: 1.5),
          ),
        ),
      ),
    );
  }
}

/// Draws the Prevue chart icon (screen outline + line graph + arrow)
class _PrevueChartIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Screen rectangle
    final rect = RRect.fromLTRBR(
      2.5 * s,
      4.5 * s,
      21.5 * s,
      18.5 * s,
      Radius.circular(2.5 * s),
    );
    canvas.drawRRect(rect, paint);

    // Line graph: M5 15 L9.5 10.5 L12.5 13 L18.5 7
    final graphPath = Path()
      ..moveTo(5 * s, 15 * s)
      ..lineTo(9.5 * s, 10.5 * s)
      ..lineTo(12.5 * s, 13 * s)
      ..lineTo(18.5 * s, 7 * s);
    canvas.drawPath(graphPath, paint);

    // Arrow head: M15.5 7H18.5V10
    final arrowPath = Path()
      ..moveTo(15.5 * s, 7 * s)
      ..lineTo(18.5 * s, 7 * s)
      ..lineTo(18.5 * s, 10 * s);
    canvas.drawPath(arrowPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Draws the 4-color Google "G" logo
