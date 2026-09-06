import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../core/services/backend_api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/simulation_result.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/tactile_card.dart';

/// History Screen — past Daily Briefings & Pre-Flight Simulations, sourced
/// directly from the Prevue backend (PostgreSQL), the same source of truth a
/// future web client would read from.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: CustomAppBar(
          title: 'History',
          subtitle: 'Past briefings & simulations',
          actions: [
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: AppColors.textInk,
                size: 22.sp,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              margin: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 8.h),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(100.r),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(100.r),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: EdgeInsets.all(3.w),
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.sp,
                ),
                unselectedLabelStyle: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.sp,
                ),
                tabs: const [
                  Tab(text: 'Briefings'),
                  Tab(text: 'Simulations'),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _BriefingHistoryTab(),
                  _SimulationHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared empty-state used by both tabs
class _EmptyHistoryState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyHistoryState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40.sp, color: AppColors.textMuted),
            SizedBox(height: 12.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textInk,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BriefingHistoryTab extends StatefulWidget {
  const _BriefingHistoryTab();

  @override
  State<_BriefingHistoryTab> createState() => _BriefingHistoryTabState();
}

class _BriefingHistoryTabState extends State<_BriefingHistoryTab> {
  final BackendApiService _backendApiService = BackendApiService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _backendApiService.getBriefingHistory();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _backendApiService.getBriefingHistory();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final briefings = snapshot.data ?? [];
        if (briefings.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.primary,
            child: ListView(
              children: [
                SizedBox(height: 120.h),
                const _EmptyHistoryState(
                  icon: Icons.lightbulb_outline_rounded,
                  title: 'No Briefings Yet',
                  message:
                      'Generate a Daily Briefing from the Ideas tab and it will be saved here automatically.',
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primary,
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
            itemCount: briefings.length,
            itemBuilder: (context, index) =>
                _BriefingHistoryCard(record: briefings[index]),
          ),
        );
      },
    );
  }
}

class _BriefingHistoryCard extends StatelessWidget {
  final Map<String, dynamic> record;

  const _BriefingHistoryCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final channelHandle = record['channel_handle']?.toString() ?? 'Unknown';
    final source = record['source']?.toString() ?? 'algorithmic';
    final isGemini = source == 'gemini';
    final createdAt = DateTime.tryParse(record['created_at']?.toString() ?? '');
    final blueprints = (record['blueprints'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: TactileCard(
        padding: EdgeInsets.all(14.w),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.only(top: 6.h),
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        channelHandle,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        createdAt != null
                            ? DateFormat('MMM d, y • h:mm a').format(createdAt)
                            : 'Unknown date',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: isGemini
                        ? AppColors.outlierJadeSubtle
                        : AppColors.warningAmberSubtle,
                    borderRadius: BorderRadius.circular(100.r),
                    border: Border.all(
                      color: isGemini
                          ? AppColors.outlierJadeBorder
                          : AppColors.warningAmberBorder,
                    ),
                  ),
                  child: Text(
                    isGemini ? 'AI GENERATED' : 'ALGORITHMIC',
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w800,
                      color: isGemini
                          ? AppColors.outlierJade
                          : AppColors.warningAmber,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: Text(
                '${blueprints.length} blueprint${blueprints.length == 1 ? '' : 's'} generated',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11.sp,
                ),
              ),
            ),
            children: blueprints.map((bp) {
              return Container(
                margin: EdgeInsets.only(bottom: 6.h),
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bp['title']?.toString() ?? 'Untitled Blueprint',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textInk,
                      ),
                    ),
                    if ((bp['dataProofReason']?.toString() ?? '').isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        bp['dataProofReason'].toString(),
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10.5.sp,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _SimulationHistoryTab extends StatefulWidget {
  const _SimulationHistoryTab();

  @override
  State<_SimulationHistoryTab> createState() => _SimulationHistoryTabState();
}

class _SimulationHistoryTabState extends State<_SimulationHistoryTab> {
  final BackendApiService _backendApiService = BackendApiService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _backendApiService.getSimulationHistory();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _backendApiService.getSimulationHistory();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final simulations = snapshot.data ?? [];
        if (simulations.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.primary,
            child: ListView(
              children: [
                SizedBox(height: 120.h),
                const _EmptyHistoryState(
                  icon: Icons.speed_rounded,
                  title: 'No Simulations Yet',
                  message:
                      'Run a Pre-Flight Simulation from the Simulator tab and it will be saved here automatically.',
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primary,
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
            itemCount: simulations.length,
            itemBuilder: (context, index) =>
                _SimulationHistoryCard(record: simulations[index]),
          ),
        );
      },
    );
  }
}

class _SimulationHistoryCard extends StatelessWidget {
  final Map<String, dynamic> record;

  const _SimulationHistoryCard({required this.record});

  double _asDouble(dynamic value, [double fallback = 0.0]) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final title = record['title']?.toString() ?? 'Untitled Draft';
    final format = record['format']?.toString() ?? 'longForm';
    final hookScore = _asDouble(record['hook_score']);
    final tierStr = record['performance_tier']?.toString() ?? 'averageBaseline';
    final tier = PerformanceTier.values.firstWhere(
      (t) => t.name == tierStr,
      orElse: () => PerformanceTier.averageBaseline,
    );
    final createdAt = DateTime.tryParse(record['created_at']?.toString() ?? '');

    Color tierColor;
    switch (tier) {
      case PerformanceTier.topOutlier:
        tierColor = AppColors.outlierJade;
        break;
      case PerformanceTier.aboveMedian:
        tierColor = AppColors.primary;
        break;
      case PerformanceTier.averageBaseline:
        tierColor = AppColors.warningAmber;
        break;
      case PerformanceTier.highFlopRisk:
        tierColor = AppColors.hazardRuby;
        break;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: TactileCard(
        padding: EdgeInsets.all(14.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46.w,
              height: 46.w,
              decoration: BoxDecoration(
                color: tierColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: tierColor.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(
                  hookScore.toStringAsFixed(1),
                  style: AppTypography.monoScoreMedium.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w900,
                    color: tierColor,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textInk,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 4.h,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: tierColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(100.r),
                        ),
                        child: Text(
                          tier.title,
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 8.5.sp,
                            fontWeight: FontWeight.w800,
                            color: tierColor,
                          ),
                        ),
                      ),
                      Text(
                        format == 'short' ? 'Short' : 'Long-Form',
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 10.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (createdAt != null)
                        Text(
                          '• ${DateFormat('MMM d, h:mm a').format(createdAt)}',
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 10.sp,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
