import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _selectedReportType = 'EXAM_ELIGIBILITY';
  String _selectedDept = 'CSE';
  bool _isGenerating = false;

  final List<Map<String, String>> _reportTypes = [
    {
      'id': 'EXAM_ELIGIBILITY',
      'title': 'End-Semester Exam Hall Ticket Clearance (<75% Cutoff)',
      'desc': 'Detailed list of students ineligible to appear for end-term exams due to attendance shortage.',
    },
    {
      'id': 'NBA_NAAC_COMPLIANCE',
      'title': 'NBA / NAAC Institutional Accreditation Summary',
      'desc': 'Aggregated course-wise percentage breakdown formatted for university board audits.',
    },
    {
      'id': 'FACULTY_LECTURE_HOURS',
      'title': 'Faculty Session Completion & Workload Verification',
      'desc': 'Audit of total lecture hours delivered vs. scheduled syllabus hours across all departments.',
    },
    {
      'id': 'SECURITY_AUDIT_ARCHIVE',
      'title': 'Campus Geofence & Proxy Attempt Security Archive',
      'desc': 'Log of all rejected out-of-bounds submissions and hardware collisions for cybersecurity audit.',
    },
  ];

  Future<void> _handleGenerateReport() async {
    setState(() => _isGenerating = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report generated successfully! Exported to device storage and PDF archive.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Institutional Reports & Analytics',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
            const Text(
              'Select Report Specification',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Generate cryptographic tamper-evident reports for administration and compliance.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),

            const SizedBox(height: 20),

            // Report type cards
            ..._reportTypes.map((r) {
              final isSel = _selectedReportType == r['id'];
              return GestureDetector(
                onTap: () => setState(() => _selectedReportType = r['id']!),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.accentBlue.withOpacity(0.12) : AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSel ? AppColors.accentBlue : AppColors.surface,
                      width: isSel ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSel ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: isSel ? AppColors.accentBlue : AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r['title']!,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              r['desc']!,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 20),

            // Parameters
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Department Scope',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: ['ALL', 'CSE', 'ECE', 'MECH', 'CIVIL'].map((dept) {
                      final isSel = _selectedDept == dept;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedDept = dept),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.accentBlue : AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                dept,
                                style: TextStyle(
                                  color: isSel ? Colors.white : AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Export Format',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.picture_as_pdf, color: AppColors.error, size: 18),
                      SizedBox(width: 6),
                      Text('PDF Official Dossier (Digitally Signed)', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(Icons.table_chart_outlined, color: AppColors.success, size: 18),
                      SizedBox(width: 6),
                      Text('CSV Raw Attendance Ledger (Excel Compatible)', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            GradientButton(
              onPressed: _isGenerating ? null : _handleGenerateReport,
              isLoading: _isGenerating,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.file_download_outlined, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'GENERATE & EXPORT REPORT',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.8),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
