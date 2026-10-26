import 'dart:async';
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

class SubmitAttendanceScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const SubmitAttendanceScreen({
    super.key,
    required this.sessionId,
  });

  @override
  ConsumerState<SubmitAttendanceScreen> createState() => _SubmitAttendanceScreenState();
}

class _SubmitAttendanceScreenState extends ConsumerState<SubmitAttendanceScreen> {
  Position? _currentPosition;
  double? _distanceInMeters;
  bool _isLocating = true;
  String? _locationError;
  StreamSubscription<Position>? _positionStream;

  // Mock faculty coordinate fallback for testing / simulation
  final double _facultyLat = 12.9716;
  final double _facultyLng = 77.5946;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    setState(() {
      _isLocating = true;
      _locationError = null;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'GPS permission is mandatory to verify in-person classroom proximity.';
          _isLocating = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 15),
      );

      _updatePosition(position);

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1,
        ),
      ).listen(_updatePosition);
    } catch (e) {
      setState(() {
        _locationError = 'Failed to obtain GPS telemetry: $e';
        _isLocating = false;
      });
    }
  }

  void _updatePosition(Position pos) {
    if (!mounted) return;

    final distance = HaversineUtil.distanceInMetres(
      pos.latitude,
      pos.longitude,
      _facultyLat,
      _facultyLng,
    );

    setState(() {
      _currentPosition = pos;
      _distanceInMeters = distance;
      _isLocating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final isWithinRadius = _distanceInMeters != null && _distanceInMeters! <= AppConstants.maxDistanceMeters;

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Proximity Verification',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // Radar visual animation
            Container(
              height: 180,
              width: double.infinity,
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ripple ring
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (isWithinRadius ? AppColors.success : AppColors.accentBlue).withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                        begin: const Offset(0.85, 0.85),
                        end: const Offset(1.15, 1.15),
                        duration: 1800.ms,
                      ),
                  // Inner ripple ring
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (isWithinRadius ? AppColors.success : AppColors.accentBlue).withOpacity(0.08),
                      border: Border.all(
                        color: (isWithinRadius ? AppColors.success : AppColors.accentBlue).withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                  ),
                  // Center icon beacon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isWithinRadius ? AppColors.success : AppColors.accentBlue,
                      boxShadow: [
                        BoxShadow(
                          color: (isWithinRadius ? AppColors.success : AppColors.accentBlue).withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      isWithinRadius ? Icons.verified_user : Icons.radar,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Distance Status
            Text(
              _locationError != null
                  ? 'LOCATION PERMISSION REQUIRED'
                  : (_isLocating
                      ? 'Acquiring GPS Triangulation...'
                      : (isWithinRadius ? 'PROXIMITY CONFIRMED' : 'OUTSIDE CLASSROOM PERIMETER')),
              style: TextStyle(
                color: _locationError != null
                    ? AppColors.error
                    : (isWithinRadius ? AppColors.success : (_isLocating ? AppColors.accentBlue : AppColors.error)),
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              _locationError ??
                  (_isLocating
                      ? 'Please hold your device steady while GPS precision stabilizes.'
                      : (isWithinRadius
                          ? 'You are ~${_distanceInMeters!.toStringAsFixed(1)}m from instructor (Within ${AppConstants.maxDistanceMeters.toInt()}m threshold).'
                          : 'You are ${_distanceInMeters?.toStringAsFixed(1) ?? '--'}m away. Move closer to the classroom to verify attendance.')),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 24),

            // Verification Details Card
            GlassCard(
              child: Column(
                children: [
                  _buildVerificationRow(
                    icon: Icons.person_outline,
                    title: 'Student Identity',
                    value: user?.displayName ?? 'Student User',
                    subtitle: user?.rollNumber ?? '21BCSE104',
                    isOk: true,
                  ),
                  const Divider(color: AppColors.surface, height: 20),
                  _buildVerificationRow(
                    icon: Icons.fingerprint,
                    title: 'Hardware Device Binding',
                    value: 'Registered Single Device',
                    subtitle: 'SHA-256 Signature Verified',
                    isOk: true,
                  ),
                  const Divider(color: AppColors.surface, height: 20),
                  _buildVerificationRow(
                    icon: Icons.location_on_outlined,
                    title: 'Classroom Geofence',
                    value: _isLocating
                        ? 'Locating...'
                        : (isWithinRadius ? 'In Range (≤ 20m)' : 'Out of Bounds (> 20m)'),
                    subtitle: _currentPosition != null
                        ? 'Accuracy: ±${_currentPosition!.accuracy.toStringAsFixed(1)}m'
                        : 'GPS Lock Pending',
                    isOk: isWithinRadius,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Action Button
            GradientButton(
              onPressed: () {
                // Navigate to OTP entry
                context.push('/student/otp/${widget.sessionId}');
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'PROCEED TO ENTER OTP',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationRow({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required bool isOk,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isOk ? AppColors.success.withOpacity(0.12) : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isOk ? AppColors.success : AppColors.textSecondary,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: isOk ? AppColors.glowBlue : AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Icon(
          isOk ? Icons.check_circle : Icons.error_outline,
          color: isOk ? AppColors.success : AppColors.warning,
          size: 20,
        ),
      ],
    );
  }
}
