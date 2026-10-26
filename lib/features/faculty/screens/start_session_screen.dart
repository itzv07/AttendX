import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/faculty_provider.dart';

class StartSessionScreen extends ConsumerStatefulWidget {
  const StartSessionScreen({super.key});

  @override
  ConsumerState<StartSessionScreen> createState() => _StartSessionScreenState();
}

class _StartSessionScreenState extends ConsumerState<StartSessionScreen> {
  // Selection
  String? _selectedCourseId;
  String? _selectedCourseName;
  String? _selectedSectionId;
  String? _selectedSectionName;
  String? _selectedDepartmentId;

  // Session options
  int _durationMinutes = 30;
  int _otpExpirySeconds = 120;
  double _maxDistanceMeters = 20.0;

  // GPS state
  Position? _currentPosition;
  bool _isGettingLocation = false;
  String? _locationError;

  // Launch state
  bool _isCreatingSession = false;

  // Mock / Assigned classes
  final List<Map<String, String>> _mockClasses = [
    {
      'courseId': 'CS401',
      'courseName': 'Distributed Cloud Systems',
      'sectionId': 'SEC-A',
      'sectionName': 'Section A (Batch 2023)',
      'departmentId': 'CSE',
      'room': 'Lab 402 - Block C',
      'enrolled': '48 Students',
    },
    {
      'courseId': 'CS405',
      'courseName': 'Machine Learning & Neural Networks',
      'sectionId': 'SEC-B',
      'sectionName': 'Section B (Batch 2023)',
      'departmentId': 'CSE',
      'room': 'Seminar Hall 2',
      'enrolled': '52 Students',
    },
    {
      'courseId': 'CS302',
      'courseName': 'Database Engineering & Scaling',
      'sectionId': 'SEC-A',
      'sectionName': 'Section A (Batch 2024)',
      'departmentId': 'CSE',
      'room': 'LH 101 - Main Wing',
      'enrolled': '45 Students',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Default select first class
    if (_mockClasses.isNotEmpty) {
      _selectClass(_mockClasses.first);
    }
    _captureCurrentLocation();
  }

  void _selectClass(Map<String, String> cls) {
    setState(() {
      _selectedCourseId = cls['courseId'];
      _selectedCourseName = cls['courseName'];
      _selectedSectionId = cls['sectionId'];
      _selectedSectionName = cls['sectionName'];
      _selectedDepartmentId = cls['departmentId'];
    });
  }

  Future<void> _captureCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
      _locationError = null;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          _locationError = 'Location permission is denied. GPS is required to verify student proximity.';
          _isGettingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 15),
      );

      setState(() {
        _currentPosition = position;
        _isGettingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationError = 'Unable to acquire GPS lock: $e';
        _isGettingLocation = false;
      });
    }
  }

  Future<void> _handleStartSession() async {
    if (_selectedCourseId == null || _selectedSectionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a course and section.')),
      );
      return;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS coordinates are required to start the session.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isCreatingSession = true);

    try {
      final facultyService = ref.read(facultyServiceProvider);
      final result = await facultyService.createSession(
        courseId: _selectedCourseId!,
        courseName: _selectedCourseName!,
        sectionId: _selectedSectionId!,
        sectionName: _selectedSectionName!,
        departmentId: _selectedDepartmentId ?? 'CSE',
        durationMinutes: _durationMinutes,
      );

      final sessionId = result['sessionId'] as String? ?? 'session_${DateTime.now().millisecondsSinceEpoch}';

      if (mounted) {
        context.push('/faculty/otp/$sessionId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start session: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingSession = false);
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
          'Start Attendance Session',
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
            // Header explanation
            Text(
              'Select Classroom & Verify GPS',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
            const SizedBox(height: 4),
            Text(
              'Your GPS location will form the ground truth anchor for student verification (20m radius).',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 24),

            // Class selection section
            _buildSectionHeader('ASSIGNED CLASS', Icons.school_outlined),
            const SizedBox(height: 12),
            ..._mockClasses.map((cls) => _buildClassCard(cls)).toList(),

            const SizedBox(height: 24),

            // GPS Lock Section
            _buildSectionHeader('LOCATION ANCHOR', Icons.my_location),
            const SizedBox(height: 12),
            _buildGpsStatusCard(),

            const SizedBox(height: 24),

            // Session Configuration
            _buildSectionHeader('SESSION PARAMETERS', Icons.tune),
            const SizedBox(height: 12),
            _buildParametersCard(),

            const SizedBox(height: 32),

            // Start Session Button
            GradientButton(
              onPressed: _isCreatingSession ? null : _handleStartSession,
              isLoading: _isCreatingSession,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bolt, color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'GENERATE OTP & START SESSION',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.accentBlue),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppColors.accentBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildClassCard(Map<String, String> cls) {
    final isSelected = _selectedCourseId == cls['courseId'] && _selectedSectionId == cls['sectionId'];

    return GestureDetector(
      onTap: () => _selectClass(cls),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentBlue.withOpacity(0.12) : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accentBlue : AppColors.surface,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accentBlue.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentBlue : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  cls['courseId']?.substring(0, 2) ?? 'CS',
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          cls['courseId']!,
                          style: const TextStyle(
                            color: AppColors.glowBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        cls['sectionName']!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cls['courseName']!,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        cls['room']!,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.group_outlined, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        cls['enrolled']!,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? AppColors.accentBlue : AppColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGpsStatusCard() {
    final hasLock = _currentPosition != null;
    final accuracy = _currentPosition?.accuracy ?? 999.0;
    final isGoodAccuracy = accuracy <= 20.0;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasLock
                          ? (isGoodAccuracy ? AppColors.success : AppColors.warning)
                          : AppColors.error,
                      boxShadow: [
                        BoxShadow(
                          color: (hasLock ? (isGoodAccuracy ? AppColors.success : AppColors.warning) : AppColors.error)
                              .withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasLock
                        ? (isGoodAccuracy ? 'GPS Lock Acquired (High Precision)' : 'GPS Lock Acquired (Moderate)')
                        : 'GPS Lock Pending',
                    style: TextStyle(
                      color: hasLock
                          ? (isGoodAccuracy ? AppColors.success : AppColors.warning)
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: _isGettingLocation ? null : _captureCurrentLocation,
                icon: _isGettingLocation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentBlue),
                      )
                    : const Icon(Icons.refresh, size: 20, color: AppColors.accentBlue),
                tooltip: 'Refresh Location',
              ),
            ],
          ),
          const Divider(color: AppColors.surface, height: 20),
          if (hasLock) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LATITUDE',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentPosition!.latitude.toStringAsFixed(6),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LONGITUDE',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentPosition!.longitude.toStringAsFixed(6),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ACCURACY',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '±${accuracy.toStringAsFixed(1)}m',
                        style: TextStyle(
                          color: isGoodAccuracy ? AppColors.success : AppColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else if (_locationError != null) ...[
            Text(
              _locationError!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ] else ...[
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentBlue),
                ),
                SizedBox(width: 12),
                Text(
                  'Querying satellite telemetry...',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParametersCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Proximity radius
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Proximity Radius',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_maxDistanceMeters.toInt()} Metres',
                  style: const TextStyle(
                    color: AppColors.glowBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Students beyond ${_maxDistanceMeters.toInt()}m from your location are automatically rejected.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),

          // Duration Chips
          const Text(
            'Session Active Duration',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            children: [15, 30, 45, 60].map((mins) {
              final isSel = _durationMinutes == mins;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _durationMinutes = mins),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.accentBlue : AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSel ? AppColors.accentBlue : Colors.transparent,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$mins m',
                        style: TextStyle(
                          color: isSel ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // OTP Expiry
          const Text(
            'OTP Refresh Cycle',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            children: [60, 120, 180].map((secs) {
              final isSel = _otpExpirySeconds == secs;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _otpExpirySeconds = secs),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.accentBlue : AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSel ? AppColors.accentBlue : Colors.transparent,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${secs ~/ 60} min${secs == 60 ? '' : 's'}',
                        style: TextStyle(
                          color: isSel ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
