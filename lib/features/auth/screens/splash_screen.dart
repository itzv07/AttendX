import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../../../core/theme/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();

    // Navigate after animation
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      _checkAuthAndNavigate();
    });
  }

  void _checkAuthAndNavigate() async {
    final userModel = await ref.read(currentUserProvider.future);
    if (!mounted) return;

    if (userModel == null) {
      context.go('/login');
    } else {
      switch (userModel.role) {
        case UserRole.admin:
          context.go('/admin');
          break;
        case UserRole.faculty:
          context.go('/faculty');
          break;
        case UserRole.student:
          context.go('/student');
          break;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background radial gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.2,
                colors: [
                  Color(0xFF1A2A4A),
                  Color(0xFF0A0E1A),
                ],
              ),
            ),
          ),

          // Animated particles (stars)
          ...List.generate(20, (i) => _buildStar(i)),

          // Center content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                _buildLogo(),
                const SizedBox(height: 24),
                // App name
                Text(
                  'AttendX',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                )
                    .animate(controller: _controller)
                    .fadeIn(delay: 400.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),
                const SizedBox(height: 8),
                Text(
                  'Present in Person. Verified by Technology.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 0.3,
                      ),
                  textAlign: TextAlign.center,
                )
                    .animate(controller: _controller)
                    .fadeIn(delay: 600.ms, duration: 600.ms),
                const SizedBox(height: 60),

                // Loading indicator
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.accentBlue,
                    backgroundColor: AppColors.accentBlue.withOpacity(0.2),
                  ),
                )
                    .animate(controller: _controller)
                    .fadeIn(delay: 1000.ms, duration: 400.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3563E9), Color(0xFF1E3A5F)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentBlue.withOpacity(0.4),
            blurRadius: 40,
            spreadRadius: 8,
          ),
        ],
      ),
      child: const Icon(
        Icons.school_rounded,
        color: Colors.white,
        size: 48,
      ),
    )
        .animate(controller: _controller)
        .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 600.ms, curve: Curves.elasticOut)
        .fadeIn(duration: 400.ms);
  }

  Widget _buildStar(int index) {
    final positions = [
      const Offset(0.1, 0.1),
      const Offset(0.9, 0.1),
      const Offset(0.15, 0.9),
      const Offset(0.85, 0.85),
      const Offset(0.5, 0.05),
      const Offset(0.05, 0.5),
      const Offset(0.95, 0.5),
      const Offset(0.3, 0.2),
      const Offset(0.7, 0.15),
      const Offset(0.2, 0.7),
      const Offset(0.8, 0.7),
      const Offset(0.4, 0.8),
      const Offset(0.6, 0.8),
      const Offset(0.25, 0.45),
      const Offset(0.75, 0.4),
      const Offset(0.1, 0.6),
      const Offset(0.9, 0.65),
      const Offset(0.45, 0.15),
      const Offset(0.55, 0.9),
      const Offset(0.35, 0.55),
    ];

    final pos = index < positions.length
        ? positions[index]
        : Offset(index * 0.05, index * 0.07);

    return Align(
      alignment: Alignment(pos.dx * 2 - 1, pos.dy * 2 - 1),
      child: Container(
        width: 3,
        height: 3,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .fadeIn(delay: (index * 100).ms, duration: 1000.ms)
          .then()
          .fadeOut(duration: 1000.ms),
    );
  }
}
