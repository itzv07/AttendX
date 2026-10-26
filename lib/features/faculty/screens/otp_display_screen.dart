import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/faculty_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/models/attendance_models.dart';

class OtpDisplayScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const OtpDisplayScreen({super.key, required this.sessionId});

  @override
  ConsumerState<OtpDisplayScreen> createState() => _OtpDisplayScreenState();
}

class _OtpDisplayScreenState extends ConsumerState<OtpDisplayScreen>
    with TickerProviderStateMixin {
  late AnimationController _countdownController;
  late AnimationController _pulseController;
  Timer? _timer;
  Timer? _refreshTimer;

  String _otp = '------';
  int _secondsRemaining = AppConstants.otpValiditySeconds;
  bool _isLoadingOtp = false;
  bool _otpExpired = true;
  DateTime? _otpExpiresAt;

  @override
  void initState() {
    super.initState();
    _countdownController = AnimationController(
      vsync: this,
      duration: Duration(seconds: AppConstants.otpValiditySeconds),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _generateNewOtp();
  }

  Future<void> _generateNewOtp() async {
    if (_isLoadingOtp) return;
    setState(() => _isLoadingOtp = true);

    try {
      final service = ref.read(facultyServiceProvider);
      final result = await service.generateOtp(widget.sessionId);

      final otp = result['otp'] as String;
      final expiresAt = DateTime.parse(result['expiresAt'] as String);

      setState(() {
        _otp = otp;
        _otpExpiresAt = expiresAt;
        _otpExpired = false;
        _secondsRemaining = AppConstants.otpValiditySeconds;
      });

      _startCountdown(expiresAt);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate OTP: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingOtp = false);
    }
  }

  void _startCountdown(DateTime expiresAt) {
    _timer?.cancel();
    _countdownController.reset();
    _countdownController.forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final remaining = expiresAt.difference(now).inSeconds;

      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _secondsRemaining = remaining.clamp(0, AppConstants.otpValiditySeconds);
        if (_secondsRemaining <= 0) {
          _otpExpired = true;
          _otp = '------';
          timer.cancel();
        }
      });
    });
  }

  String get _countdownDisplay {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get _countdownProgress =>
      _secondsRemaining / AppConstants.otpValiditySeconds;

  Color get _countdownColor {
    if (_secondsRemaining > 60) return AppColors.success;
    if (_secondsRemaining > 30) return AppColors.warning;
    return AppColors.error;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _refreshTimer?.cancel();
    _countdownController.dispose();
    _pulseController.dispose();
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
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Session info
                        sessionAsync.when(
                          data: (s) => s != null ? _buildSessionInfo(context, s) : const SizedBox.shrink(),
                          loading: () => const SizedBox(height: 60),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 32),

                        // OTP countdown ring + digits
                        _buildOtpSection(context),

                        const SizedBox(height: 32),

                        // Live attendance counter
                        recordsAsync.when(
                          data: (records) {
                            final present = records.where((r) => r.isPresent).length;
                            return sessionAsync.when(
                              data: (s) => s != null
                                  ? _buildAttendanceCounter(context, present, s.totalEnrolled)
                                  : const SizedBox.shrink(),
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),

                        const SizedBox(height: 24),

                        // Actions
                        _buildActions(context),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Container(color: AppColors.background),
        // Central glow
        Center(
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) => Container(
              width: 400 + (_pulseController.value * 40),
              height: 400 + (_pulseController.value * 40),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentBlue.withOpacity(0.06 * _pulseController.value),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 20, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textSecondary),
            onPressed: () => context.go('/faculty'),
          ),
          Text(
            'Attendance Session',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.go('/faculty/live/${widget.sessionId}'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accentBlue.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_outline, color: AppColors.accentBlue, size: 14),
                  const SizedBox(width: 4),
                  Text('Live View', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.accentBlue)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionInfo(BuildContext context, AttendanceSession session) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.class_outlined, color: AppColors.accentBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.courseName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white)),
                Text(session.sectionName, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('LIVE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.success, fontWeight: FontWeight.w700, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpSection(BuildContext context) {
    return Column(
      children: [
        // Instruction text
        Text(
          'Announce this code to your students',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Countdown ring with OTP digits
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _countdownColor.withOpacity(0.15 + _pulseController.value * 0.1),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            ),

            // Countdown progress ring
            SizedBox(
              width: 260,
              height: 260,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 1.0, end: _countdownProgress),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, _) {
                  return CircularProgressIndicator(
                    value: value,
                    strokeWidth: 6,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(_countdownColor),
                    strokeCap: StrokeCap.round,
                  );
                },
              ),
            ),

            // OTP digits + timer
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoadingOtp)
                  const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(color: AppColors.accentBlue, strokeWidth: 2.5),
                  )
                else if (_otpExpired)
                  Icon(Icons.timer_off_outlined, color: AppColors.error, size: 48)
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(begin: 1, end: 1.05, duration: 600.ms)
                else
                  _buildOtpDigits(context),

                const SizedBox(height: 8),

                // Countdown timer display
                Text(
                  _otpExpired ? 'EXPIRED' : _countdownDisplay,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _countdownColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
                Text(
                  _otpExpired ? 'Generate a new code' : 'remaining',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 28),

        // Regenerate button (only show when expired or time is low)
        if (_otpExpired || _secondsRemaining < 30)
          GradientButton(
            onPressed: _generateNewOtp,
            isLoading: _isLoadingOtp,
            width: 200,
            height: 48,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.refresh_rounded, size: 18),
                const SizedBox(width: 8),
                Text(_otpExpired ? 'Generate New Code' : 'Regenerate'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildOtpDigits(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _otp.split('').asMap().entries.map((entry) {
        final i = entry.key;
        final digit = entry.value;
        return Padding(
          padding: EdgeInsets.only(left: i == 3 ? 12 : 0, right: i == 2 ? 12 : 4),
          child: Text(
            digit,
            style: TextStyle(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
              shadows: [
                Shadow(
                  color: AppColors.accentBlue.withOpacity(0.8),
                  blurRadius: 20,
                ),
              ],
            ),
          ).animate(key: ValueKey('$digit-$i-$_secondsRemaining'))
            .fadeIn(duration: 200.ms)
            .scaleXY(begin: 0.8, end: 1, duration: 200.ms, curve: Curves.elasticOut),
        );
      }).toList(),
    );
  }

  Widget _buildAttendanceCounter(BuildContext context, int present, int total) {
    final percentage = total > 0 ? (present / total) : 0.0;
    return GlowCard(
      glowColor: AppColors.accentBlue,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Students Present',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white),
              ),
              Text(
                '$present / $total',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.accentBlue,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: percentage),
              duration: const Duration(milliseconds: 800),
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
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        // Close session button
        DangerButtonWidget(
          onPressed: () => _showCloseSessionDialog(context),
          label: 'Close Session',
          icon: Icons.stop_circle_outlined,
        ),
      ],
    );
  }

  void _showCloseSessionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Close Session', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to close this attendance session? No further submissions will be accepted.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              _timer?.cancel();
              try {
                final service = ref.read(facultyServiceProvider);
                await service.closeSession(widget.sessionId, reason: 'Manually closed by faculty');
                if (context.mounted) context.go('/faculty');
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Close Session'),
          ),
        ],
      ),
    );
  }
}

class DangerButtonWidget extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData icon;

  const DangerButtonWidget({super.key, this.onPressed, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
