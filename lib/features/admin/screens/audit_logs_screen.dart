import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';

class AuditLogsScreen extends ConsumerStatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  ConsumerState<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends ConsumerState<AuditLogsScreen> {
  String _selectedSeverity = 'ALL';

  final List<Map<String, dynamic>> _mockLogs = [
    {
      'id': 'log_01',
      'type': 'LOCATION_BREACH_REJECT',
      'severity': 'HIGH',
      'title': 'Proximity Geofence Violation Rejected',
      'details': 'Student 21BCSE089 submitted OTP from 43.8m away (Threshold: 20m). Verification denied by server.',
      'user': 'Vikram Mehta (21BCSE089)',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 12)),
      'ip': '172.16.42.11',
    },
    {
      'id': 'log_02',
      'type': 'EXPIRED_OTP_ATTEMPT',
      'severity': 'MEDIUM',
      'title': 'Submission with Stale OTP Token',
      'details': 'Submission attempted 14 seconds after OTP expiration window. Submission rejected.',
      'user': 'Aditi Rao (21BCSE114)',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 48)),
      'ip': '172.16.42.88',
    },
    {
      'id': 'log_03',
      'type': 'DUPLICATE_SUBMISSION_BLOCKED',
      'severity': 'MEDIUM',
      'title': 'Duplicate Attendance Record Prevented',
      'details': 'Atomic Firestore transaction rejected second submission attempt for same session.',
      'user': 'Rohan Iyer (21BCSE103)',
      'timestamp': DateTime.now().subtract(const Duration(hours: 1, minutes: 22)),
      'ip': '172.16.42.94',
    },
    {
      'id': 'log_04',
      'type': 'DEVICE_BINDING_RESET',
      'severity': 'LOW',
      'title': 'Admin Reset Device Binding Lock',
      'details': 'Hardware fingerprint lock unbound by System Administrator for device upgrade.',
      'user': 'Admin (admin@attendx.edu)',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
      'ip': '192.168.1.10',
    },
    {
      'id': 'log_05',
      'type': 'SESSION_COMPLETED_NORMAL',
      'severity': 'LOW',
      'title': 'Session CS401 Closed with 94% Turnout',
      'details': 'Session closed with 44 present, 4 absent out of 48 enrolled students.',
      'user': 'Dr. Robert Vance',
      'timestamp': DateTime.now().subtract(const Duration(hours: 3)),
      'ip': '172.16.10.5',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _mockLogs.where((l) {
      if (_selectedSeverity != 'ALL' && l['severity'] != _selectedSeverity) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Security & Audit Telemetry',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Filter pills
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                _buildSeverityChip('ALL', 'All Events'),
                const SizedBox(width: 8),
                _buildSeverityChip('HIGH', 'Security Breaches', color: AppColors.error),
                const SizedBox(width: 8),
                _buildSeverityChip('MEDIUM', 'Suspicious', color: AppColors.warning),
                const SizedBox(width: 8),
                _buildSeverityChip('LOW', 'Normal Audits', color: AppColors.success),
              ],
            ),
          ),

          // Log list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final log = filtered[index];
                final sev = log['severity'] as String;
                final date = log['timestamp'] as DateTime;
                final formatted = DateFormat('h:mm:ss a • MMM d').format(date);

                Color badgeColor = AppColors.success;
                if (sev == 'HIGH') badgeColor = AppColors.error;
                if (sev == 'MEDIUM') badgeColor = AppColors.warning;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: sev == 'HIGH' ? AppColors.error.withOpacity(0.4) : AppColors.surface,
                    ),
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
                              color: badgeColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              log['type'] as String,
                              style: TextStyle(
                                color: badgeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Text(
                            formatted,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        log['title'] as String,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        log['details'] as String,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.3),
                      ),
                      const Divider(color: AppColors.surface, height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            log['user'] as String,
                            style: const TextStyle(color: AppColors.glowBlue, fontSize: 11),
                          ),
                          Text(
                            'IP: ${log['ip']}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: (index * 40).ms);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityChip(String sev, String label, {Color? color}) {
    final isSelected = _selectedSeverity == sev;
    final activeColor = color ?? AppColors.accentBlue;

    return GestureDetector(
      onTap: () => setState(() => _selectedSeverity = sev),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.2) : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.surface,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
