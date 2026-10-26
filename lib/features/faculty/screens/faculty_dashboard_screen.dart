import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/faculty_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/models/attendance_models.dart';

class FacultyDashboardScreen extends ConsumerWidget {
  const FacultyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const _LoadingDashboard(),
      error: (e, _) => _ErrorDashboard(error: e.toString()),
      data: (user) {
        if (user == null) return const _ErrorDashboard(error: 'User not found');

        final activeSessionAsync = ref.watch(activeSessionStreamProvider(user.uid));

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
                            _buildQuickStats(context),
                            const SizedBox(height: 24),
                            activeSessionAsync.when(
                              data: (session) => session != null
                                  ? _buildActiveSessionCard(context, session)
                                  : _buildStartSessionCard(context),
                              loading: () => const _SkeletonCard(height: 120),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 24),
                            _buildTodaysSchedule(context, user.uid, ref),
                            const SizedBox(height: 24),
                            _buildRecentSessions(context, user.uid, ref),
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
    return Stack(
      children: [
        Container(color: AppColors.background),
        Positioned(
          top: -80,
          right: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppColors.accentBlue.withOpacity(0.08),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref, String name) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          // Logo
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
          Text(
            'AttendX',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const Spacer(),
          // Notifications
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.accentBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {},
          ),
          // Avatar
          GestureDetector(
            onTap: () => _showProfileMenu(context, ref),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.accentBlue,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'F',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting(BuildContext context, String name) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    final today = DateFormat('EEEE, MMM d').format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, ${name.split(' ').first}! 👋',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
        ).animate().fadeIn().slideX(begin: -0.2, end: 0),
        const SizedBox(height: 4),
        Text(
          today,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ).animate().fadeIn(delay: 100.ms),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Row(
      children: [
        _buildStatChip(context, 'Total Students', '142', Icons.people_outline),
        const SizedBox(width: 12),
        _buildStatChip(context, 'Sessions Today', '3', Icons.event_note_outlined),
        const SizedBox(width: 12),
        _buildStatChip(context, 'Avg. Attendance', '87%', Icons.bar_chart_rounded),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildStatChip(BuildContext context, String label, String value, IconData icon) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.accentBlue, size: 18),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSessionCard(BuildContext context, AttendanceSession session) {
    return GlowCard(
      glowColor: AppColors.success,
      padding: const EdgeInsets.all(16),
      onTap: () => context.go('/faculty/otp/${session.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .scaleXY(begin: 1, end: 1.5, duration: 800.ms, curve: Curves.easeInOut)
                  .then()
                  .scaleXY(begin: 1.5, end: 1, duration: 800.ms),
              const SizedBox(width: 8),
              Text(
                'SESSION ACTIVE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
              ),
              const Spacer(),
              Text(
                '${session.totalPresent}/${session.totalEnrolled} Present',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            session.courseName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          Text(
            session.sectionName,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go('/faculty/live/${session.id}'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.textSecondary),
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  child: const Text('View List'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.go('/faculty/otp/${session.id}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  child: const Text('Show OTP'),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildStartSessionCard(BuildContext context) {
    return GlassCard(
      onTap: () => context.go('/faculty/start-session'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [AppColors.accentBlue, Color(0xFF1E3A8A)],
                ),
              ),
              child: const Icon(Icons.play_circle_outline, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start Attendance Session',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white),
                  ),
                  Text(
                    'Tap to begin a new session for your class',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildTodaysSchedule(BuildContext context, String facultyId, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Schedule",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 12),
        // In a real app this would be fetched from Firestore timetable
        ...['CS-402 • 9:00 AM • CSE-201', 'MA-301 • 11:00 AM • LTC-105', 'EC-415 • 2:00 PM • AUDI-2']
            .asMap()
            .entries
            .map((e) => _buildScheduleItem(context, e.value, e.key)),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildScheduleItem(BuildContext context, String info, int index) {
    final parts = info.split(' • ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: index == 0 ? AppColors.success : AppColors.accentBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(parts[0], style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white)),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(parts[1], style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(width: 8),
                      const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(parts[2], style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            if (index == 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Active',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.success),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSessions(BuildContext context, String facultyId, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Sessions', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
            TextButton(
              onPressed: () => context.go('/faculty/history'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Session history will appear here',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms);
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
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history_rounded), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
        onTap: (index) {
          switch (index) {
            case 1: context.go('/faculty/history'); break;
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
              leading: const Icon(Icons.person_outline, color: AppColors.textSecondary),
              title: const Text('My Profile', style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
              title: const Text('Settings', style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),
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

class _LoadingDashboard extends StatelessWidget {
  const _LoadingDashboard();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: CircularProgressIndicator(color: AppColors.accentBlue)),
    );
  }
}

class _ErrorDashboard extends StatelessWidget {
  final String error;
  const _ErrorDashboard({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(error, style: const TextStyle(color: AppColors.error)),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final double height;
  const _SkeletonCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: 1200.ms,
          color: AppColors.accentBlue.withOpacity(0.05),
        );
  }
}
