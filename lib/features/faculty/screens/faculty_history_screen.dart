import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/attendance_models.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/faculty_provider.dart';

class FacultyHistoryScreen extends ConsumerStatefulWidget {
  const FacultyHistoryScreen({super.key});

  @override
  ConsumerState<FacultyHistoryScreen> createState() => _FacultyHistoryScreenState();
}

class _FacultyHistoryScreenState extends ConsumerState<FacultyHistoryScreen> {
  String _selectedFilter = 'ALL';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _mockSessions = [
    {
      'id': 'sess_101',
      'courseId': 'CS401',
      'courseName': 'Distributed Cloud Systems',
      'sectionName': 'Section A',
      'date': DateTime.now().subtract(const Duration(hours: 3)),
      'totalEnrolled': 48,
      'totalPresent': 44,
      'durationMinutes': 30,
      'status': 'CLOSED',
    },
    {
      'id': 'sess_102',
      'courseId': 'CS405',
      'courseName': 'Machine Learning & Neural Networks',
      'sectionName': 'Section B',
      'date': DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      'totalEnrolled': 52,
      'totalPresent': 49,
      'durationMinutes': 45,
      'status': 'CLOSED',
    },
    {
      'id': 'sess_103',
      'courseId': 'CS302',
      'courseName': 'Database Engineering & Scaling',
      'sectionName': 'Section A',
      'date': DateTime.now().subtract(const Duration(days: 2, hours: 4)),
      'totalEnrolled': 45,
      'totalPresent': 35,
      'durationMinutes': 30,
      'status': 'CLOSED',
    },
    {
      'id': 'sess_104',
      'courseId': 'CS401',
      'courseName': 'Distributed Cloud Systems',
      'sectionName': 'Section A',
      'date': DateTime.now().subtract(const Duration(days: 3, hours: 1)),
      'totalEnrolled': 48,
      'totalPresent': 46,
      'durationMinutes': 30,
      'status': 'CLOSED',
    },
    {
      'id': 'sess_105',
      'courseId': 'CS405',
      'courseName': 'Machine Learning & Neural Networks',
      'sectionName': 'Section B',
      'date': DateTime.now().subtract(const Duration(days: 4, hours: 3)),
      'totalEnrolled': 52,
      'totalPresent': 41,
      'durationMinutes': 45,
      'status': 'CLOSED',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _mockSessions.where((s) {
      if (_selectedFilter != 'ALL' && s['courseId'] != _selectedFilter) {
        return false;
      }
      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        final name = (s['courseName'] as String).toLowerCase();
        final code = (s['courseId'] as String).toLowerCase();
        return name.contains(query) || code.contains(query);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Attendance Records History',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: AppColors.glowBlue),
            tooltip: 'Export CSV',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Exporting complete semester attendance archive...'),
                  backgroundColor: AppColors.accentBlue,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceLight.withOpacity(0.3)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() {}),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search course code or title...',
                      hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.7)),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('ALL', 'All Courses'),
                      const SizedBox(width: 8),
                      _buildFilterChip('CS401', 'CS401: Cloud Systems'),
                      const SizedBox(width: 8),
                      _buildFilterChip('CS405', 'CS405: Neural Networks'),
                      const SizedBox(width: 8),
                      _buildFilterChip('CS302', 'CS302: Databases'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Session count summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filtered.length} Sessions Logged',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Sorted by Most Recent',
                  style: TextStyle(
                    color: AppColors.accentBlue,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // List of sessions
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off, size: 48, color: AppColors.textSecondary.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        const Text(
                          'No attendance sessions found',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _buildSessionHistoryCard(item, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterId, String label) {
    final isSelected = _selectedFilter == filterId;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filterId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentBlue : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.glowBlue : AppColors.surface,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSessionHistoryCard(Map<String, dynamic> item, int index) {
    final enrolled = item['totalEnrolled'] as int;
    final present = item['totalPresent'] as int;
    final pct = enrolled > 0 ? (present / enrolled) * 100 : 0.0;
    final date = item['date'] as DateTime;
    final formattedDate = DateFormat('EEE, MMM d, yyyy • h:mm a').format(date);

    Color pctColor = AppColors.success;
    if (pct < 75) {
      pctColor = AppColors.error;
    } else if (pct < 85) {
      pctColor = AppColors.warning;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item['courseId'] as String,
                      style: const TextStyle(
                        color: AppColors.glowBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item['sectionName'] as String,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: pctColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: pctColor.withOpacity(0.3)),
                ),
                child: Text(
                  '${pct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: pctColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item['courseName'] as String,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                formattedDate,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const Divider(color: AppColors.surface, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildStatBadge(Icons.check_circle_outline, '$present Present', AppColors.success),
                  const SizedBox(width: 12),
                  _buildStatBadge(Icons.cancel_outlined, '${enrolled - present} Absent', AppColors.error),
                ],
              ),
              InkWell(
                onTap: () {
                  context.push('/faculty/live/${item['id']}');
                },
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        'View Roster',
                        style: TextStyle(
                          color: AppColors.accentBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, size: 11, color: AppColors.accentBlue),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 60).ms).slideY(begin: 0.05);
  }

  Widget _buildStatBadge(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
