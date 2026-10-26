import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/student_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/models/attendance_models.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.accentBlue)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('$e', style: const TextStyle(color: AppColors.error))),
      ),
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        final activeSessionsAsync = ref.watch(activeStudentSessionsProvider(user.uid));
        final enrollmentsAsync = ref.watch(studentEnrollmentsProvider(user.uid));

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              _buildBackground(),
              SafeArea(
                child: Column(
                  children: [
                    _buildAppBar(context, ref, user.displayName),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildGreeting(context, user.displayName),
                            const SizedBox(height: 20),

                            // Active session banner
                            activeSessionsAsync.when(
                              data: (sessions) => sessions.isNotEmpty
                                  ? _buildActiveSessionBanner(context, sessions.first)
                                  : const SizedBox.shrink(),
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 20),

                            // Quick stats row
                            enrollmentsAsync.when(
                              data: (enrollments) => _buildStats(context, enrollments),
                              loading: () => _buildStatsLoading(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 24),

                            // Subject cards
                            Text('My Subjects',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
                            const SizedBox(height: 12),
                            enrollmentsAsync.when(
                              data: (enrollments) => enrollments.isEmpty
                                  ? _buildEmptyState(context)
                                  : Column(
                                      children: enrollments
                                          .asMap()
                                          .entries
                                          .map((e) => _buildSubjectCard(context, e.value, e.key, ref, user.uid))
                                          .toList(),
                                    ),
                              loading: () => Column(
                                children: List.generate(3, (i) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildSkeletonCard(height: 90),
                                )),
                              ),
                              error: (e, _) => Text('$e'),
                            ),

                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(context),
        );
      },
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.5, -0.5),
          radius: 1.2,
          colors: [
            AppColors.accentBlue.withOpacity(0.06),
            AppColors.background,
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref, String name) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(colors: [AppColors.accentBlue, Color(0xFF1E3A8A)]),
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Text('AttendX',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
            onPressed: () {},
          ),
          GestureDetector(
            onTap: () => _showProfileMenu(context, ref),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.accentBlue,
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'S',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting(BuildContext context, String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hi, ${name.split(' ').first}! 👋',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white, fontWeight: FontWeight.w700),
        ).animate().fadeIn().slideX(begin: -0.2, end: 0),
        Text(
          'Keep track of your attendance',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ).animate().fadeIn(delay: 100.ms),
      ],
    );
  }

  Widget _buildActiveSessionBanner(BuildContext context, AttendanceSession session) {
    return GlowCard(
      glowColor: AppColors.success,
      padding: const EdgeInsets.all(16),
      onTap: () => context.go('/student/otp/${session.id}'),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
          ).animate(onPlay: (c) => c.repeat())
              .scaleXY(begin: 1, end: 1.5, duration: 800.ms)
              .then().scaleXY(begin: 1.5, end: 1, duration: 800.ms),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ACTIVE SESSION',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.success, fontWeight: FontWeight.w700, letterSpacing: 1)),
                Text('${session.courseName} is live — Check in now!',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.success),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildStats(BuildContext context, List<Map<String, dynamic>> enrollments) {
    final total = enrollments.length;
    final lowAttendance = enrollments.where((e) => (e['attendancePercentage'] ?? 0) < 75).length;
    final avgPct = total > 0
        ? enrollments.fold<double>(0, (sum, e) => sum + (e['attendancePercentage'] ?? 0)) / total
        : 0.0;

    return Row(
      children: [
        _buildStatCard(context, 'Subjects', '$total', Icons.book_outlined, AppColors.accentBlue),
        const SizedBox(width: 12),
        _buildStatCard(context, 'Avg. Attendance', '${avgPct.toStringAsFixed(0)}%', Icons.bar_chart_rounded, AppColors.success),
        const SizedBox(width: 12),
        _buildStatCard(context, 'Low Attendance', '$lowAttendance', Icons.warning_amber_rounded, lowAttendance > 0 ? AppColors.warning : AppColors.success),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            Text(label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
                maxLines: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsLoading() {
    return Row(
      children: List.generate(3, (i) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: i < 2 ? 12 : 0),
          child: _buildSkeletonCard(height: 80),
        ),
      )),
    );
  }

  Widget _buildSubjectCard(BuildContext context, Map<String, dynamic> enrollment, int index, WidgetRef ref, String studentId) {
    final pct = (enrollment['attendancePercentage'] ?? 0.0).toDouble();
    final isLow = pct < 75;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: () => context.go('/student/analytics/${enrollment['courseId']}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Subject icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.chartColors[index % AppColors.chartColors.length].withOpacity(0.15),
                ),
                child: Icon(Icons.book_outlined,
                    color: AppColors.chartColors[index % AppColors.chartColors.length], size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(enrollment['courseName'] ?? 'Subject',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white)),
                    Text('${enrollment['present'] ?? 0} / ${enrollment['total'] ?? 0} classes',
                        style: Theme.of(context).textTheme.bodySmall),
                    if (isLow)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 12, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Text('Below 75% threshold',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppColors.warning, fontSize: 10)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Circular progress
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: pct / 100,
                      strokeWidth: 4,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isLow ? AppColors.warning : AppColors.success,
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                    Text(
                      '${pct.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isLow ? AppColors.warning : AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: (index * 100 + 300).ms).slideX(begin: 0.1, end: 0),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.school_outlined, size: 48, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text('No subjects enrolled', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text('Contact your administrator to enroll in courses.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
    ).animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1200.ms, color: AppColors.accentBlue.withOpacity(0.05));
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navBar,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard_rounded), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history_rounded), label: 'History'),
          BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics_rounded), label: 'Analytics'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
        onTap: (index) {
          switch (index) {
            case 1: context.go('/student/history'); break;
          }
        },
      ),
    );
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
