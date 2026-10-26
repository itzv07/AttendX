import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';

class ManageCoursesScreen extends ConsumerStatefulWidget {
  const ManageCoursesScreen({super.key});

  @override
  ConsumerState<ManageCoursesScreen> createState() => _ManageCoursesScreenState();
}

class _ManageCoursesScreenState extends ConsumerState<ManageCoursesScreen> {
  final List<Map<String, dynamic>> _mockCourses = [
    {
      'id': 'c_1',
      'code': 'CS401',
      'title': 'Distributed Cloud Systems',
      'dept': 'Computer Science',
      'credits': 4,
      'enrolled': 142,
      'sections': 3,
      'isActive': true,
    },
    {
      'id': 'c_2',
      'code': 'CS405',
      'title': 'Machine Learning & Neural Networks',
      'dept': 'Computer Science',
      'credits': 4,
      'enrolled': 158,
      'sections': 3,
      'isActive': true,
    },
    {
      'id': 'c_3',
      'code': 'CS302',
      'title': 'Database Engineering & Scaling',
      'dept': 'Computer Science',
      'credits': 3,
      'enrolled': 130,
      'sections': 2,
      'isActive': true,
    },
    {
      'id': 'c_4',
      'code': 'CS204',
      'title': 'Operating Systems & Kernels',
      'dept': 'Computer Science',
      'credits': 4,
      'enrolled': 160,
      'sections': 3,
      'isActive': true,
    },
  ];

  void _showAddCourseDialog() {
    final codeCtrl = TextEditingController();
    final titleCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Register New Curriculum Course',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Course Code (e.g. CS501)',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Course Title',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentBlue),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Course ${codeCtrl.text} added to catalog.'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Save Course'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Curriculum & Courses',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.glowBlue),
            onPressed: _showAddCourseDialog,
            tooltip: 'Add Course',
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: _mockCourses.length,
        itemBuilder: (context, index) {
          final c = _mockCourses[index];
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        c['code']!,
                        style: const TextStyle(
                          color: AppColors.glowBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      '${c['credits']} Academic Credits',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  c['title']!,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  c['dept']!,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const Divider(color: AppColors.surface, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.groups_outlined, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${c['enrolled']} Students Enrolled',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.dashboard_outlined, size: 14, color: AppColors.accentBlue),
                        const SizedBox(width: 4),
                        Text(
                          '${c['sections']} Sections',
                          style: const TextStyle(
                            color: AppColors.accentBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: (index * 50).ms);
        },
      ),
    );
  }
}
