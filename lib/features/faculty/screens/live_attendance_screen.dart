import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/faculty_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/models/attendance_models.dart';
import 'otp_display_screen.dart';

class LiveAttendanceScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const LiveAttendanceScreen({super.key, required this.sessionId});

  @override
  ConsumerState<LiveAttendanceScreen> createState() => _LiveAttendanceScreenState();
}

class _LiveAttendanceScreenState extends ConsumerState<LiveAttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(
      StreamProvider.autoDispose.family<AttendanceSession?, String>(
        (ref, id) => ref.read(facultyServiceProvider).sessionStream(id),
      )(widget.sessionId),
    );
    final recordsAsync = ref.watch(sessionRecordsProvider(widget.sessionId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textSecondary),
                    onPressed: () => context.pop(),
                  ),
                  Text('Live Attendance',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
                  const Spacer(),
                  sessionAsync.when(
                    data: (s) => s != null
                        ? IconButton(
                            onPressed: () => context.go('/faculty/otp/${widget.sessionId}'),
                            icon: const Icon(Icons.dialpad_rounded, color: AppColors.accentBlue),
                            tooltip: 'Show OTP',
                          )
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            // Session header + progress
            recordsAsync.when(
              data: (records) {
                final present = records.where((r) => r.isPresent).length;
                return sessionAsync.when(
                  data: (session) => session != null
                      ? _buildHeader(context, session, present, records.length)
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Filter tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                onTap: (i) {
                  setState(() {
                    _filter = ['All', 'Present', 'Absent'][i];
                  });
                },
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.accentBlue,
                ),
                indicatorPadding: const EdgeInsets.all(4),
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                dividerColor: Colors.transparent,
                tabs: const [Tab(text: 'All'), Tab(text: 'Present'), Tab(text: 'Absent')],
              ),
            ),

            // Student list
            Expanded(
              child: recordsAsync.when(
                data: (records) {
                  final filtered = _filter == 'All'
                      ? records
                      : _filter == 'Present'
                          ? records.where((r) => r.isPresent).toList()
                          : records.where((r) => !r.isPresent).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _filter == 'Present' ? Icons.check_circle_outline : Icons.people_outline,
                            size: 56,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _filter == 'All'
                                ? 'Waiting for students to check in...'
                                : 'No ${_filter.toLowerCase()} students yet',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      return _buildStudentTile(context, filtered[i], i)
                          .animate()
                          .fadeIn(delay: (i * 50).ms)
                          .slideX(begin: 0.1, end: 0);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.accentBlue),
                ),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),

            // Close session button
            Padding(
              padding: const EdgeInsets.all(20),
              child: DangerButtonWidget(
                onPressed: () => _showCloseDialog(context),
                label: 'Close Session',
                icon: Icons.stop_circle_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, AttendanceSession session, int present, int total) {
    final percentage = session.totalEnrolled > 0
        ? (present / session.totalEnrolled)
        : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: GlowCard(
        glowColor: AppColors.accentBlue,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.courseName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white)),
                    Text(session.sectionName, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$present / ${session.totalEnrolled}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppColors.accentBlue,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text('Present', style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: percentage),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOut,
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${(percentage * 100).toStringAsFixed(1)}% attended',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.glowBlue)),
                Text('${session.totalEnrolled - present} pending',
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentTile(BuildContext context, AttendanceRecord record, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: record.isPresent
                  ? AppColors.success.withOpacity(0.2)
                  : AppColors.card,
              child: Text(
                record.studentName.isNotEmpty ? record.studentName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: record.isPresent ? AppColors.success : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.studentName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white)),
                  Text(record.rollNumber, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: record.isPresent
                        ? AppColors.success.withOpacity(0.15)
                        : AppColors.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        record.isPresent ? Icons.check_circle_outline : Icons.schedule_rounded,
                        size: 12,
                        color: record.isPresent ? AppColors.success : AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        record.isPresent ? 'Present' : 'Pending',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: record.isPresent ? AppColors.success : AppColors.warning,
                            ),
                      ),
                    ],
                  ),
                ),
                if (record.isPresent)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat('hh:mm a').format(record.submittedAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCloseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Close Session', style: TextStyle(color: Colors.white)),
        content: Text(
          'Close this attendance session? No more submissions will be accepted.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              try {
                final service = ref.read(facultyServiceProvider);
                await service.closeSession(widget.sessionId, reason: 'Manually closed from live view');
                if (context.mounted) context.go('/faculty');
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
