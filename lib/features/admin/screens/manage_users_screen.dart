import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../providers/admin_provider.dart';

class ManageUsersScreen extends ConsumerStatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  ConsumerState<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends ConsumerState<ManageUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _mockStudents = [
    {
      'id': 'std_1',
      'name': 'Aarav Sharma',
      'email': 'aarav.sharma@attendx.edu',
      'roll': '21BCSE101',
      'dept': 'CSE',
      'deviceLocked': true,
      'deviceModel': 'Samsung Galaxy S23 (SHA-256)',
    },
    {
      'id': 'std_2',
      'name': 'Priya Patel',
      'email': 'priya.patel@attendx.edu',
      'roll': '21BCSE102',
      'dept': 'CSE',
      'deviceLocked': true,
      'deviceModel': 'iPhone 15 Pro (Apple Secure Enclave)',
    },
    {
      'id': 'std_3',
      'name': 'Rohan Iyer',
      'email': 'rohan.iyer@attendx.edu',
      'roll': '21BCSE103',
      'dept': 'CSE',
      'deviceLocked': false,
      'deviceModel': 'Unbound (Pending First Verification)',
    },
    {
      'id': 'std_4',
      'name': 'Ananya Deshmukh',
      'email': 'ananya.d@attendx.edu',
      'roll': '21BCSE104',
      'dept': 'CSE',
      'deviceLocked': true,
      'deviceModel': 'Google Pixel 8 (Titan M2)',
    },
  ];

  final List<Map<String, dynamic>> _mockFaculty = [
    {
      'id': 'fac_1',
      'name': 'Dr. Robert Vance',
      'email': 'robert.vance@attendx.edu',
      'dept': 'Computer Science & Engineering',
      'designation': 'Professor & HOD',
      'courses': 'CS401, CS502',
    },
    {
      'id': 'fac_2',
      'name': 'Prof. Elena Rostova',
      'email': 'elena.rostova@attendx.edu',
      'dept': 'Artificial Intelligence',
      'designation': 'Associate Professor',
      'courses': 'CS405, AI301',
    },
    {
      'id': 'fac_3',
      'name': 'Dr. Alan Morales',
      'email': 'alan.morales@attendx.edu',
      'dept': 'Information Technology',
      'designation': 'Assistant Professor',
      'courses': 'CS302, DB201',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showAddUserDialog(bool isFaculty) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final idCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isFaculty ? 'Add Faculty Instructor' : 'Enroll New Student',
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Full Name', labelStyle: TextStyle(color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'University Email', labelStyle: TextStyle(color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: idCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: isFaculty ? 'Employee ID' : 'Roll Number',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
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
                  content: Text('${nameCtrl.text.isNotEmpty ? nameCtrl.text : "User"} added to directory.'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Add User'),
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
          'User Directory & Devices',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, color: AppColors.glowBlue),
            onPressed: () => _showAddUserDialog(_tabController.index == 1),
            tooltip: 'Add User',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentBlue,
          indicatorWeight: 3,
          labelColor: AppColors.glowBlue,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Students (1,420)'),
            Tab(text: 'Faculty Staff (86)'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Container(
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
                  hintText: 'Search by name, roll, or email...',
                  hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.6)),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStudentsTab(),
                _buildFacultyTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsTab() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _mockStudents.length,
      itemBuilder: (context, index) {
        final std = _mockStudents[index];
        final isLocked = std['deviceLocked'] as bool;

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
                          std['roll']!,
                          style: const TextStyle(
                            color: AppColors.glowBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        std['dept']!,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (isLocked ? AppColors.success : AppColors.warning).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (isLocked ? AppColors.success : AppColors.warning).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      isLocked ? 'Hardware Bound' : 'No Lock',
                      style: TextStyle(
                        color: isLocked ? AppColors.success : AppColors.warning,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                std['name']!,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                std['email']!,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const Divider(color: AppColors.surface, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.smartphone, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            std['deviceModel']!,
                            style: TextStyle(
                              color: isLocked ? AppColors.textSecondary : AppColors.warning,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isLocked)
                    InkWell(
                      onTap: () {
                        setState(() {
                          std['deviceLocked'] = false;
                          std['deviceModel'] = 'Unbound (Reset by Administrator)';
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Device binding reset for ${std['name']}.'),
                            backgroundColor: AppColors.accentBlue,
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          'Reset Device Lock',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: (index * 50).ms);
      },
    );
  }

  Widget _buildFacultyTab() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _mockFaculty.length,
      itemBuilder: (context, index) {
        final fac = _mockFaculty[index];
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
                      color: Colors.purpleAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      fac['designation']!,
                      style: const TextStyle(
                        color: Colors.purpleAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const Text(
                    'Active Faculty',
                    style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                fac['name']!,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                fac['email']!,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const Divider(color: AppColors.surface, height: 20),
              Row(
                children: [
                  Icon(Icons.class_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Assigned Courses: ${fac['courses']}',
                    style: const TextStyle(color: AppColors.glowBlue, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: (index * 50).ms);
      },
    );
  }
}
