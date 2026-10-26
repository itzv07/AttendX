import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';

class ManageSectionsScreen extends ConsumerWidget {
  const ManageSectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mockSections = [
      {
        'id': 'sec_1',
        'code': 'CS401 - Section A',
        'course': 'Distributed Cloud Systems',
        'faculty': 'Dr. Robert Vance',
        'room': 'Lab 402, Block C',
        'students': 48,
        'schedule': 'Mon, Wed 10:00 - 11:30 AM',
      },
      {
        'id': 'sec_2',
        'code': 'CS401 - Section B',
        'course': 'Distributed Cloud Systems',
        'faculty': 'Dr. Robert Vance',
        'room': 'Lab 404, Block C',
        'students': 46,
        'schedule': 'Tue, Thu 02:00 - 03:30 PM',
      },
      {
        'id': 'sec_3',
        'code': 'CS405 - Section A',
        'course': 'Machine Learning & Neural Networks',
        'faculty': 'Prof. Elena Rostova',
        'room': 'Seminar Hall 2, Main Block',
        'students': 54,
        'schedule': 'Mon, Wed 02:00 - 03:30 PM',
      },
      {
        'id': 'sec_4',
        'code': 'CS302 - Section A',
        'course': 'Database Engineering & Scaling',
        'faculty': 'Dr. Alan Morales',
        'room': 'LH 101, Ground Floor',
        'students': 45,
        'schedule': 'Fri 09:00 - 12:00 PM',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Section & Classroom Allocations',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: mockSections.length,
        itemBuilder: (context, index) {
          final s = mockSections[index];
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
                        s['code'] as String,
                        style: const TextStyle(
                          color: AppColors.glowBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      '${s['students']} Students',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  s['course'] as String,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person_pin, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Instructor: ${s['faculty']}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                const Divider(color: AppColors.surface, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.room, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          s['room'] as String,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: AppColors.glowBlue),
                        const SizedBox(width: 4),
                        Text(
                          s['schedule'] as String,
                          style: const TextStyle(
                            color: AppColors.glowBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
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
