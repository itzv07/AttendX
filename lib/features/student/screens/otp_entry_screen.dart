import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../providers/student_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/models/attendance_models.dart';

enum _SubmissionState { idle, gettingLocation, submitting, success, failed }

class OtpEntryScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const OtpEntryScreen({super.key, required this.sessionId});

  @override
  ConsumerState<OtpEntryScreen> createState() => _OtpEntryScreenState();
}

class _OtpEntryScreenState extends ConsumerState<OtpEntryScreen>
    with TickerProviderStateMixin {
  final _otpController = TextEditingController();
  final _focusNode = FocusNode();
  late AnimationController _successController;
  late AnimationController _shakeController;

  _SubmissionState _state = _SubmissionState.idle;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    _successController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _submitAttendance() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit OTP');
      return;
    }

    setState(() {
      _state = _SubmissionState.gettingLocation;
      _errorMessage = null;
    });

    try {
      final service = ref.read(studentServiceProvider);

      setState(() => _state = _SubmissionState.submitting);

      final result = await service.submitAttendance(
        sessionId: widget.sessionId,
        otp: otp,
      );

      final success = result['success'] as bool? ?? false;
      if (success) {
        setState(() {
          _state = _SubmissionState.success;
          _successMessage = result['message'] as String? ?? 'Attendance marked successfully!';
        });
        await _successController.forward();
        HapticFeedback.heavyImpact();
      } else {
        setState(() {
          _state = _SubmissionState.failed;
          _errorMessage = result['message'] as String? ?? 'Attendance submission failed.';
        });
        _shakeController.forward(from: 0);
        HapticFeedback.vibrate();
      }
    } catch (e) {
      setState(() {
        _state = _SubmissionState.failed;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      _shakeController.forward(from: 0);
    }
  }

  void _retry() {
    setState(() {
      _state = _SubmissionState.idle;
      _errorMessage = null;
      _otpController.clear();
    });
    _shakeController.reset();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(
      StreamProvider.autoDispose.family<AttendanceSession?, String>(
        (ref, id) => ref.read(studentServiceProvider).sessionStream(id),
      )(widget.sessionId),
    );

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
                  child: _state == _SubmissionState.success
                      ? _buildSuccessState(context)
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              sessionAsync.when(
                                data: (s) => s != null ? _buildSessionBanner(context, s) : const SizedBox.shrink(),
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              ),
                              const SizedBox(height: 40),
                              _buildOtpTitle(context),
                              const SizedBox(height: 32),
                              _buildOtpInput(context),
                              const SizedBox(height: 24),
                              _buildLocationStatus(context),
                              const SizedBox(height: 32),
                              _buildSubmitButton(context),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 16),
                                _buildErrorCard(context),
                              ],
                              const SizedBox(height: 24),
                              _buildPrivacyNote(context),
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
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.3),
          radius: 1.5,
          colors: [
            _state == _SubmissionState.success
                ? AppColors.success.withOpacity(0.08)
                : AppColors.accentBlue.withOpacity(0.06),
            AppColors.background,
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 20, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textSecondary),
            onPressed: () => context.go('/student'),
          ),
          Text('Verify Attendance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildSessionBanner(BuildContext context, AttendanceSession session) {
    return GlassCard(
      borderColor: AppColors.success.withOpacity(0.4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
          ).animate(onPlay: (c) => c.repeat())
            .scaleXY(begin: 1, end: 1.5, duration: 800.ms).then()
            .scaleXY(begin: 1.5, end: 1, duration: 800.ms),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.courseName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white)),
                Text(session.sectionName, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('LIVE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.success, fontWeight: FontWeight.w700, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpTitle(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentBlue.withOpacity(0.15),
            border: Border.all(color: AppColors.accentBlue.withOpacity(0.4)),
          ),
          child: const Icon(Icons.dialpad_rounded, color: AppColors.accentBlue, size: 30),
        ).animate().scaleXY(begin: 0.5, end: 1, duration: 500.ms, curve: Curves.elasticOut),
        const SizedBox(height: 16),
        Text('Enter OTP',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Enter the 6-digit code announced by your faculty',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildOtpInput(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 58,
      textStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        shadows: [Shadow(color: AppColors.accentBlue.withOpacity(0.8), blurRadius: 10)],
      ),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: AppColors.accentBlue, width: 2),
      boxShadow: [BoxShadow(color: AppColors.accentBlue.withOpacity(0.3), blurRadius: 12)],
    );

    final filledPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: AppColors.accentBlue.withOpacity(0.6)),
      color: AppColors.accentBlue.withOpacity(0.1),
    );

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final shake = _shakeController.value;
        final offset = shake < 0.5
            ? Offset(8 * shake * 4, 0)
            : Offset(8 * (1 - shake) * 4, 0);
        return Transform.translate(offset: offset, child: child);
      },
      child: Pinput(
        controller: _otpController,
        focusNode: _focusNode,
        length: 6,
        defaultPinTheme: defaultPinTheme,
        focusedPinTheme: focusedPinTheme,
        submittedPinTheme: filledPinTheme,
        enabled: _state == _SubmissionState.idle || _state == _SubmissionState.failed,
        autofocus: true,
        keyboardType: TextInputType.number,
        separatorBuilder: (_) => const SizedBox(width: 4),
        onCompleted: (_) => _submitAttendance(),
      ),
    );
  }

  Widget _buildLocationStatus(BuildContext context) {
    final isActive = _state == _SubmissionState.gettingLocation;
    return GlassCard(
      borderColor: AppColors.info.withOpacity(0.3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: isActive
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.info),
                  )
                : const Icon(Icons.location_on_outlined, color: AppColors.info, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? 'Getting your location...' : 'Location Verification',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                ),
                Text(
                  isActive
                      ? 'Please wait, acquiring GPS signal'
                      : 'Your location will be verified when you submit',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    final isLoading = _state == _SubmissionState.gettingLocation ||
        _state == _SubmissionState.submitting;
    final label = _state == _SubmissionState.gettingLocation
        ? 'Getting Location...'
        : _state == _SubmissionState.submitting
            ? 'Verifying...'
            : 'Mark Attendance';

    return GradientButton(
      onPressed: isLoading ? null : _submitAttendance,
      isLoading: isLoading,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isLoading) ...[
            const Icon(Icons.check_circle_outline, size: 18),
            const SizedBox(width: 8),
          ],
          Text(label),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    return GlassCard(
      borderColor: AppColors.error.withOpacity(0.4),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(_errorMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.errorLight)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _retry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Try Again'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accentBlue,
              side: const BorderSide(color: AppColors.accentBlue),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildPrivacyNote(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.lock_outline, size: 13, color: AppColors.textHint),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Your location is only used to verify proximity to the classroom and is not stored permanently.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textHint),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withOpacity(0.15),
                border: Border.all(color: AppColors.success.withOpacity(0.5), width: 2),
                boxShadow: [
                  BoxShadow(color: AppColors.success.withOpacity(0.3), blurRadius: 40, spreadRadius: 10),
                ],
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.success, size: 56),
            )
                .animate(controller: _successController)
                .scaleXY(begin: 0.3, end: 1, duration: 500.ms, curve: Curves.elasticOut)
                .fadeIn(duration: 300.ms),
            const SizedBox(height: 24),
            Text('Attendance Marked!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700))
                .animate(controller: _successController)
                .fadeIn(delay: 300.ms, duration: 400.ms)
                .slideY(begin: 0.3, end: 0),
            const SizedBox(height: 8),
            Text(_successMessage ?? 'Your attendance has been successfully recorded.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center)
                .animate(controller: _successController)
                .fadeIn(delay: 400.ms, duration: 400.ms),
            const SizedBox(height: 40),
            GradientButton(
              onPressed: () => context.go('/student'),
              width: 200,
              child: const Text('Back to Dashboard'),
            ).animate(controller: _successController).fadeIn(delay: 600.ms),
          ],
        ),
      ),
    );
  }
}
