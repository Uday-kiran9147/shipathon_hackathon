import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Ultra-Craft Vector Illustration: Audience Demand Intelligence & Comment Mining
/// Interactive topic cluster selection showing how mined audience comments synthesize into blueprints.
class AudienceDemandIllustration extends StatefulWidget {
  const AudienceDemandIllustration({super.key});

  @override
  State<AudienceDemandIllustration> createState() =>
      _AudienceDemandIllustrationState();
}

class _AudienceDemandIllustrationState extends State<AudienceDemandIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  int _selectedTopicIndex = 0;

  final List<Map<String, dynamic>> _topics = [
    {
      'title': '"Why Senior Devs Hate Microservices"',
      'velocity': '3.4x Velocity',
      'requests': '48 Audience Demands',
      'c1': {'name': 'Alex R.', 'text': 'How do you handle distributed trace lag?', 'likes': 142},
      'c2': {'name': 'Sarah K.', 'text': 'Our team reverted to a monolith last month!', 'likes': 89},
    },
    {
      'title': '"6-Second Resume Filter Teardown"',
      'velocity': '4.1x Velocity',
      'requests': '76 Audience Demands',
      'c1': {'name': 'Marcus D.', 'text': 'Why do ATS parsers reject PDF portfolios?', 'likes': 210},
      'c2': {'name': 'Elena P.', 'text': 'Please review real junior github links!', 'likes': 135},
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTopic = _topics[_selectedTopicIndex];

    return Container(
      width: double.infinity,
      height: 240.h,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppColors.cardElevation,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.r),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Network connection canvas
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _NetworkPulsePainter(
                      pulse: _pulseController.value,
                    ),
                  );
                },
              ),
            ),

            // Central High-Conviction Core Card
            Positioned(
              top: 50.h,
              left: 30.w,
              right: 30.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome_rounded,
                                color: Colors.amberAccent, size: 14.sp),
                            SizedBox(width: 5.w),
                            Text(
                              'VERIFIED AUDIENCE DEMAND',
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white,
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            currentTopic['velocity'],
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      currentTopic['title'],
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.sp,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      '${currentTopic['requests']} • High Save Intent',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white70,
                        fontSize: 9.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Top Left Mined Comment Card
            Positioned(
              left: 12.w,
              top: 10.h,
              child: _buildCommentBubble(
                name: currentTopic['c1']['name'],
                text: currentTopic['c1']['text'],
                likes: currentTopic['c1']['likes'],
                color: AppColors.primary,
              ),
            ),

            // Bottom Right Mined Comment Card
            Positioned(
              right: 12.w,
              bottom: 12.h,
              child: _buildCommentBubble(
                name: currentTopic['c2']['name'],
                text: currentTopic['c2']['text'],
                likes: currentTopic['c2']['likes'],
                color: AppColors.outlierJade,
              ),
            ),

            // Interactive Topic Cluster Switcher Pill (Bottom Left)
            Positioned(
              left: 14.w,
              bottom: 12.h,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTopicIndex =
                        (_selectedTopicIndex + 1) % _topics.length;
                  });
                },
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: AppColors.primary, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_horiz_rounded,
                          size: 13.sp, color: AppColors.primary),
                      SizedBox(width: 4.w),
                      Text(
                        'Tap to switch topic cluster',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 9.5.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentBubble({
    required String name,
    required String text,
    required int likes,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      constraints: BoxConstraints(maxWidth: 180.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
              CircleAvatar(
                radius: 8.r,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Text(
                  name[0],
                  style: TextStyle(
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
              SizedBox(width: 5.w),
              Text(
                name,
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 9.sp,
                  color: AppColors.textInk,
                ),
              ),
              const Spacer(),
              Text(
                '👍 $likes',
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 8.5.sp,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 9.sp,
              color: AppColors.textSecondary,
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _NetworkPulsePainter extends CustomPainter {
  final double pulse;

  _NetworkPulsePainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.45);

    // Glowing orbital circles
    final ringPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.04 + 0.04 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(center, 65.r + (pulse * 12), ringPaint);
    canvas.drawCircle(center, 105.r + (pulse * 18), ringPaint);

    // Dynamic spoke connections
    final spokePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.15)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final node1 = Offset(size.width * 0.25, size.height * 0.15);
    final node2 = Offset(size.width * 0.75, size.height * 0.85);

    canvas.drawLine(center, node1, spokePaint);
    canvas.drawLine(center, node2, spokePaint);
  }

  @override
  bool shouldRepaint(covariant _NetworkPulsePainter oldDelegate) =>
      oldDelegate.pulse != pulse;
}
