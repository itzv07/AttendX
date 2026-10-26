import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/manage_users_screen.dart';
import '../../features/admin/screens/manage_courses_screen.dart';
import '../../features/admin/screens/manage_sections_screen.dart';
import '../../features/admin/screens/audit_logs_screen.dart';
import '../../features/admin/screens/reports_screen.dart';
import '../../features/faculty/screens/faculty_dashboard_screen.dart';
import '../../features/faculty/screens/start_session_screen.dart';
import '../../features/faculty/screens/otp_display_screen.dart';
import '../../features/faculty/screens/live_attendance_screen.dart';
import '../../features/faculty/screens/faculty_history_screen.dart';
import '../../features/student/screens/student_dashboard_screen.dart';
import '../../features/student/screens/submit_attendance_screen.dart';
import '../../features/student/screens/otp_entry_screen.dart';
import '../../features/student/screens/student_history_screen.dart';
import '../../features/student/screens/subject_analytics_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isOnAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/splash';

      if (!isLoggedIn && !isOnAuth) return '/login';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Admin routes
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'users',
            builder: (context, state) => const ManageUsersScreen(),
          ),
          GoRoute(
            path: 'courses',
            builder: (context, state) => const ManageCoursesScreen(),
          ),
          GoRoute(
            path: 'sections',
            builder: (context, state) => const ManageSectionsScreen(),
          ),
          GoRoute(
            path: 'audit-logs',
            builder: (context, state) => const AuditLogsScreen(),
          ),
          GoRoute(
            path: 'reports',
            builder: (context, state) => const ReportsScreen(),
          ),
        ],
      ),

      // Faculty routes
      GoRoute(
        path: '/faculty',
        builder: (context, state) => const FacultyDashboardScreen(),
        routes: [
          GoRoute(
            path: 'start-session',
            builder: (context, state) => const StartSessionScreen(),
          ),
          GoRoute(
            path: 'otp/:sessionId',
            builder: (context, state) => OtpDisplayScreen(
              sessionId: state.pathParameters['sessionId']!,
            ),
          ),
          GoRoute(
            path: 'live/:sessionId',
            builder: (context, state) => LiveAttendanceScreen(
              sessionId: state.pathParameters['sessionId']!,
            ),
          ),
          GoRoute(
            path: 'history',
            builder: (context, state) => const FacultyHistoryScreen(),
          ),
        ],
      ),

      // Student routes
      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentDashboardScreen(),
        routes: [
          GoRoute(
            path: 'submit/:sessionId',
            builder: (context, state) => SubmitAttendanceScreen(
              sessionId: state.pathParameters['sessionId']!,
            ),
          ),
          GoRoute(
            path: 'otp/:sessionId',
            builder: (context, state) => OtpEntryScreen(
              sessionId: state.pathParameters['sessionId']!,
            ),
          ),
          GoRoute(
            path: 'history',
            builder: (context, state) => const StudentHistoryScreen(),
          ),
          GoRoute(
            path: 'analytics/:subjectId',
            builder: (context, state) => SubjectAnalyticsScreen(
              subjectId: state.pathParameters['subjectId']!,
            ),
          ),
        ],
      ),
    ],
  );
});
