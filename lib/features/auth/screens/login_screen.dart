import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController(text: '2273A39001');
  final _passwordController = TextEditingController(text: '2273A39001');

  // Selected role tab: 0: Student, 1: Faculty, 2: Admin
  int _selectedRoleIndex = 0;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRoleSelected(int index) {
    setState(() {
      _selectedRoleIndex = index;
      _errorMessage = null;

      if (index == 0) {
        // Student default
        _identifierController.text = '2273A39001';
        _passwordController.text = '2273A39001';
      } else if (index == 1) {
        // Faculty default
        _identifierController.text = 'FAC101';
        _passwordController.text = 'FAC101';
      } else {
        // Admin default
        _identifierController.text = 'ADMIN';
        _passwordController.text = '@Admin123';
      }
    });
  }

  void _fillSample(String id, String pass, int roleIdx) {
    setState(() {
      _selectedRoleIndex = roleIdx;
      _identifierController.text = id;
      _passwordController.text = pass;
      _errorMessage = null;
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.signIn(
        _identifierController.text,
        _passwordController.text,
      );

      if (!mounted) return;

      // Navigate based on role
      switch (user.role) {
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
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background ambient gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.4),
                radius: 1.1,
                colors: [
                  Color(0xFF1E3A5F),
                  Color(0xFF0A0E1A),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Branding & Logo
                      _buildLogo(),
                      const SizedBox(height: 12),
                      const Text(
                        'AttendX',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Smart Attendance & Proximity Verification',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary.withOpacity(0.9),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Role Switcher Tabs
                      _buildRoleTabs(),

                      const SizedBox(height: 18),

                      // Login Card
                      GlassCard(
                        padding: const EdgeInsets.all(22),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getCardTitle(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getCardSubtitle(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary.withOpacity(0.8),
                                ),
                              ),

                              const SizedBox(height: 18),

                              // Error alert
                              if (_errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.error.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: AppColors.error, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: const TextStyle(
                                            color: AppColors.error,
                                            fontSize: 12,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Identifier Field (Roll number / Faculty ID / ADMIN)
                              Text(
                                _getFieldLabel(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _identifierController,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                                textCapitalization: TextCapitalization.characters,
                                decoration: InputDecoration(
                                  hintText: _getFieldHint(),
                                  hintStyle: TextStyle(
                                    color: AppColors.textSecondary.withOpacity(0.5),
                                    letterSpacing: 0,
                                  ),
                                  prefixIcon: Icon(
                                    _getFieldIcon(),
                                    color: AppColors.accentBlue,
                                    size: 20,
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter your ${_getFieldLabel()}';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              // Password Field
                              Text(
                                _getPasswordLabel(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Enter password',
                                  hintStyle: TextStyle(
                                    color: AppColors.textSecondary.withOpacity(0.5),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    color: AppColors.accentBlue,
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.textSecondary,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Password is required';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 22),

                              // Sign In Button
                              GradientButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                isLoading: _isLoading,
                                child: Text(
                                  'SIGN IN AS ${_getRoleName().toUpperCase()}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Quick Sample Logins
                      _buildQuickPills(),

                      const SizedBox(height: 16),

                      Text(
                        'AttendX Enterprise v1.0.0 • Verified by Technology',
                        style: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 64,
      height: 64,
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
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: const Icon(
        Icons.school_rounded,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  Widget _buildRoleTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceLight.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          _buildRoleTabItem(0, 'Student', Icons.school_outlined),
          _buildRoleTabItem(1, 'Instructor', Icons.badge_outlined),
          _buildRoleTabItem(2, 'Admin', Icons.security_outlined),
        ],
      ),
    );
  }

  Widget _buildRoleTabItem(int index, String label, IconData icon) {
    final isSelected = _selectedRoleIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onRoleSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.accentBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickPills() {
    return Column(
      children: [
        Text(
          'Quick Fill Credentials',
          style: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.7),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            _buildSampleChip('2273A39001 (Std)', '2273A39001', '2273A39001', 0),
            _buildSampleChip('2273A39050 (Std)', '2273A39050', '2273A39050', 0),
            _buildSampleChip('2273A390L1 (Lateral)', '2273A390L1', '2273A390L1', 0),
            _buildSampleChip('FAC101 (Faculty)', 'FAC101', 'FAC101', 1),
            _buildSampleChip('ADMIN (@Admin123)', 'ADMIN', '@Admin123', 2),
          ],
        ),
      ],
    );
  }

  Widget _buildSampleChip(String label, String id, String pass, int roleIdx) {
    return ActionChip(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      backgroundColor: AppColors.card,
      side: BorderSide(color: AppColors.surfaceLight.withOpacity(0.6)),
      label: Text(
        label,
        style: const TextStyle(
          color: AppColors.glowBlue,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: () => _fillSample(id, pass, roleIdx),
    );
  }

  String _getRoleName() {
    switch (_selectedRoleIndex) {
      case 1:
        return 'Instructor';
      case 2:
        return 'Administrator';
      default:
        return 'Student';
    }
  }

  String _getCardTitle() {
    switch (_selectedRoleIndex) {
      case 1:
        return 'Instructor Faculty Portal';
      case 2:
        return 'University Administration';
      default:
        return 'Student Attendance Portal';
    }
  }

  String _getCardSubtitle() {
    switch (_selectedRoleIndex) {
      case 1:
        return 'Login with your Faculty Identification ID';
      case 2:
        return 'Authenticate with University Admin Master Key';
      default:
        return 'Login with your Roll Number (2273A39001 - 2273A39132, 2273A390L1-L3)';
    }
  }

  String _getFieldLabel() {
    switch (_selectedRoleIndex) {
      case 1:
        return 'FACULTY ID';
      case 2:
        return 'ADMIN IDENTIFIER';
      default:
        return 'ROLL NUMBER';
    }
  }

  String _getFieldHint() {
    switch (_selectedRoleIndex) {
      case 1:
        return 'e.g. FAC101';
      case 2:
        return 'ADMIN';
      default:
        return 'e.g. 2273A39001';
    }
  }

  IconData _getFieldIcon() {
    switch (_selectedRoleIndex) {
      case 1:
        return Icons.badge_outlined;
      case 2:
        return Icons.admin_panel_settings_outlined;
      default:
        return Icons.person_outline;
    }
  }

  String _getPasswordLabel() {
    switch (_selectedRoleIndex) {
      case 1:
        return 'PASSWORD (SAME AS FACULTY ID)';
      case 2:
        return 'PASSWORD (@Admin123)';
      default:
        return 'PASSWORD (SAME AS ROLL NUMBER)';
    }
  }
}
