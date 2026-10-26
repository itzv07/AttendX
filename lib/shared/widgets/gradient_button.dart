import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// A gradient-filled primary action button with optional loading state
class GradientButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool isLoading;
  final List<Color>? gradientColors;
  final double borderRadius;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;

  const GradientButton({
    super.key,
    required this.child,
    this.onPressed,
    this.isLoading = false,
    this.gradientColors,
    this.borderRadius = 12,
    this.width,
    this.height = 52,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ??
        [
          AppColors.accentBlue,
          const Color(0xFF1E3A8A),
        ];

    return GestureDetector(
      onTap: (onPressed == null || isLoading) ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width ?? double.infinity,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          gradient: onPressed == null || isLoading
              ? LinearGradient(
                  colors: colors.map((c) => c.withOpacity(0.5)).toList(),
                )
              : LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: colors,
                ),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: onPressed != null && !isLoading
              ? [
                  BoxShadow(
                    color: AppColors.accentBlue.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : DefaultTextStyle(
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  child: child,
                ),
        ),
      ),
    );
  }
}

/// A danger/destructive action button with red gradient
class DangerButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool isLoading;

  const DangerButton({
    super.key,
    required this.child,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GradientButton(
      onPressed: onPressed,
      isLoading: isLoading,
      gradientColors: [AppColors.error, const Color(0xFFDC2626)],
      child: child,
    );
  }
}

/// A success/confirm action button with green gradient
class SuccessButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool isLoading;

  const SuccessButton({
    super.key,
    required this.child,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GradientButton(
      onPressed: onPressed,
      isLoading: isLoading,
      gradientColors: [AppColors.success, const Color(0xFF059669)],
      child: child,
    );
  }
}
