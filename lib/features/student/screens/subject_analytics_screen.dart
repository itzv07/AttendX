import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';

class SubjectAnalyticsScreen extends ConsumerWidget {
  final String subjectId;

  const SubjectAnalyticsScreen({
    super.key,
    required this.subjectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Subject specific data
    final isCloudSystems = subjectId.contains('401') || subjectId == 'CS401';
    final courseName = isCloudSystems
        ? 'Distributed Cloud Systems'
        : 'Machine Learning & Neural Networks';
    final courseCode = isCloudSystems ? 'CS401' : 'CS405';
    final instructor = isCloudSystems ? 'Dr. Robert Vance' : 'Prof. Elena Rostova';
    final totalClasses = isCloudSystems ? 28 : 32;
    final attended = isCloudSystems ? 25 : 29;
    final missed = totalClasses - attended;
    final pct = (attended / totalClasses) * 100;

    // Simulation calculation: how many can miss or need to attend
    // Target: 75%
    // attended / (total + X) >= 0.75  => can miss floor((attended - 0.75*total)/0.75)
    final canMiss = ((attended - 0.75 * totalClasses) / 0.75).floor();

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '$courseCode Analytics',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course header
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accentBlue.withOpacity(0.25),
                    AppColors.card,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accentBlue.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          courseCode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        '${pct.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: pct >= 75 ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    courseName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Instructor: $instructor',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

            const SizedBox(height: 20),

            // Stat counters grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'TOTAL SESSIONS',
                    value: '$totalClasses',
                    subtitle: 'Held to date',
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'ATTENDED',
                    value: '$attended',
                    subtitle: 'Verified present',
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'ABSENT',
                    value: '$missed',
                    subtitle: 'Unexcused',
                    color: AppColors.error,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Attendance margin forecast
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.insights, size: 20, color: AppColors.accentBlue),
                      const SizedBox(width: 8),
                      const Text(
                        'Attendance Margin Forecast',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: canMiss >= 0
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: canMiss >= 0
                            ? AppColors.success.withOpacity(0.3)
                            : AppColors.error.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          canMiss >= 0 ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                          color: canMiss >= 0 ? AppColors.success : AppColors.error,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            canMiss >= 0
                                ? 'Safe Zone: You can afford to miss up to $canMiss more class${canMiss == 1 ? '' : 'es'} without dropping below the 75% cutoff.'
                                : 'Critical shortage! You must attend the next ${canMiss.abs()} consecutive classes to reach 75%.',
                            style: TextStyle(
                              color: canMiss >= 0 ? AppColors.success : AppColors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Weekly attendance pattern
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weekly Attendance Distribution',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDayProgress('Monday', 0.95, '95% (19/20)'),
                  const SizedBox(height: 10),
                  _buildDayProgress('Wednesday', 0.88, '88% (14/16)'),
                  const SizedBox(height: 10),
                  _buildDayProgress('Friday', 0.75, '75% (9/12)'),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(color: AppColors.textSecondary.withOpacity(0.8), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildDayProgress(String day, double ratio, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(day, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: AppColors.surface,
            valueColor: AlwaysStoppedAnimation<Color>(
              ratio >= 0.85 ? AppColors.success : (ratio >= 0.75 ? AppColors.warning : AppColors.error),
            ),
          ),
        ),
      ],
    );
  }
}
