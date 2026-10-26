import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../auth/providers/auth_provider.dart';

class StudentHistoryScreen extends ConsumerStatefulWidget {
  const StudentHistoryScreen({super.key});

  @override
  ConsumerState<StudentHistoryScreen> createState() => _StudentHistoryScreenState();
}

class _StudentHistoryScreenState extends ConsumerState<StudentHistoryScreen> {
  String _selectedStatusFilter = 'ALL';
  String _selectedCourse = 'ALL';

  final List<Map<String, dynamic>> _mockRecords = [
    {
      'id': 'rec_01',
      'courseId': 'CS401',
      'courseName': 'Distributed Cloud Systems',
      'facultyName': 'Dr. Robert Vance',
      'timestamp': DateTime.now().subtract(const Duration(hours: 4)),
      'status': 'PRESENT',
      'distance': 6.4,
      'isManuallyMarked': false,
    },
    {
      'id': 'rec_02',
      'courseId': 'CS405',
      'courseName': 'Machine Learning & Neural Networks',
      'facultyName': 'Prof. Elena Rostova',
      'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      'status': 'PRESENT',
      'distance': 11.2,
      'isManuallyMarked': false,
    },
    {
      'id': 'rec_03',
      'courseId': 'CS302',
      'courseName': 'Database Engineering & Scaling',
      'facultyName': 'Dr. Alan Morales',
      'timestamp': DateTime.now().subtract(const Duration(days: 2, hours: 5)),
      'status': 'ABSENT',
      'distance': null,
      'isManuallyMarked': false,
    },
    {
      'id': 'rec_04',
      'courseId': 'CS401',
      'courseName': 'Distributed Cloud Systems',
      'facultyName': 'Dr. Robert Vance',
      'timestamp': DateTime.now().subtract(const Duration(days: 3, hours: 2)),
      'status': 'PRESENT',
      'distance': 4.1,
      'isManuallyMarked': false,
    },
    {
      'id': 'rec_05',
      'courseId': 'CS405',
      'courseName': 'Machine Learning & Neural Networks',
      'facultyName': 'Prof. Elena Rostova',
      'timestamp': DateTime.now().subtract(const Duration(days: 4, hours: 6)),
      'status': 'EXCUSED',
      'distance': null,
      'isManuallyMarked': true,
      'reason': 'Medical leave approved by Dean',
    },
    {
      'id': 'rec_06',
      'courseId': 'CS302',
      'courseName': 'Database Engineering & Scaling',
      'facultyName': 'Dr. Alan Morales',
      'timestamp': DateTime.now().subtract(const Duration(days: 5, hours: 1)),
      'status': 'PRESENT',
      'distance': 14.8,
      'isManuallyMarked': false,
    },
  ];

  void _showCorrectionDialog(Map<String, dynamic> record) {
    final reasonController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Request Attendance Correction',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Submit an audit appeal to instructor ${record['facultyName']} for ${record['courseId']}.',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Explain reason (e.g. GPS drift, verified in lecture hall)...',
                  hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.6)),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GradientButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Correction dispute submitted for faculty review.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                child: const Text('SUBMIT APPEAL'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _mockRecords.where((r) {
      if (_selectedStatusFilter != 'ALL' && r['status'] != _selectedStatusFilter) {
        return false;
      }
      if (_selectedCourse != 'ALL' && r['courseId'] != _selectedCourse) {
        return false;
      }
      return true;
    }).toList();

    final totalClasses = _mockRecords.length;
    final attendedClasses = _mockRecords.where((r) => r['status'] == 'PRESENT' || r['status'] == 'EXCUSED').length;
    final overallPct = totalClasses > 0 ? (attendedClasses / totalClasses) * 100 : 0.0;

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Attendance Ledger',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Summary banner card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: GlassCard(
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: CircularProgressIndicator(
                          value: overallPct / 100,
                          strokeWidth: 6,
                          backgroundColor: AppColors.surface,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            overallPct >= 75 ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ),
                      Text(
                        '${overallPct.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          overallPct >= 75 ? 'ELIGIBLE FOR EXAMS' : 'ATTENDANCE SHORTAGE WARNING',
                          style: TextStyle(
                            color: overallPct >= 75 ? AppColors.success : AppColors.error,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$attendedClasses of $totalClasses total sessions attended',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Minimum mandatory university requirement: 75%',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Filters row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusChip('ALL', 'All Sessions'),
                  const SizedBox(width: 8),
                  _buildStatusChip('PRESENT', 'Present'),
                  const SizedBox(width: 8),
                  _buildStatusChip('ABSENT', 'Absent'),
                  const SizedBox(width: 8),
                  _buildStatusChip('EXCUSED', 'Excused'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Records list
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No matching attendance records',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final rec = filtered[index];
                      return _buildRecordTile(rec, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, String label) {
    final isSelected = _selectedStatusFilter == status;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatusFilter = status),
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

  Widget _buildRecordTile(Map<String, dynamic> rec, int index) {
    final status = rec['status'] as String;
    final isPresent = status == 'PRESENT';
    final isExcused = status == 'EXCUSED';
    final date = rec['timestamp'] as DateTime;
    final formattedTime = DateFormat('EEE, MMM d • h:mm a').format(date);

    Color statusColor = AppColors.error;
    if (isPresent) statusColor = AppColors.success;
    if (isExcused) statusColor = AppColors.warning;

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
                      rec['courseId'] as String,
                      style: const TextStyle(
                        color: AppColors.glowBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    rec['facultyName'] as String,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPresent ? Icons.check_circle : (isExcused ? Icons.info : Icons.cancel),
                      size: 12,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            rec['courseName'] as String,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formattedTime,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              if (isPresent && rec['distance'] != null)
                Text(
                  'Verified: ${(rec['distance'] as double).toStringAsFixed(1)}m away',
                  style: const TextStyle(
                    color: AppColors.glowBlue,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              if (!isPresent && !isExcused)
                InkWell(
                  onTap: () => _showCorrectionDialog(rec),
                  child: const Text(
                    'Dispute / Appeal',
                    style: TextStyle(
                      color: AppColors.accentBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.05);
  }
}
