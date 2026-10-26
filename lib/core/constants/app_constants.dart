import 'dart:math';

class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'AttendX';
  static const String appTagline = 'Present in Person. Verified by Technology.';
  static const String appVersion = '1.0.0';

  // Attendance rules
  static const int otpValiditySeconds = 120; // 2 minutes
  static const int otpLength = 6;
  static const double maxDistanceMeters = 20.0; // 20 metres
  static const double maxLocationAccuracyMeters = 50.0;
  static const int deviceCooldownMinutes = 30;
  static const int maxOtpAttempts = 5;

  // Session status
  static const String sessionStatusActive = 'ACTIVE';
  static const String sessionStatusClosed = 'CLOSED';
  static const String sessionStatusExpired = 'EXPIRED';

  // Attendance record status
  static const String attendancePresent = 'PRESENT';
  static const String attendanceAbsent = 'ABSENT';
  static const String attendancePending = 'PENDING';

  // Correction request status
  static const String correctionPending = 'PENDING';
  static const String correctionApproved = 'APPROVED';
  static const String correctionRejected = 'REJECTED';

  // User roles
  static const String roleAdmin = 'admin';
  static const String roleFaculty = 'faculty';
  static const String roleStudent = 'student';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String departmentsCollection = 'departments';
  static const String coursesCollection = 'courses';
  static const String sectionsCollection = 'sections';
  static const String enrollmentsCollection = 'enrollments';
  static const String facultyAssignmentsCollection = 'faculty_assignments';
  static const String attendanceSessionsCollection = 'attendance_sessions';
  static const String attendanceRecordsCollection = 'attendance_records';
  static const String devicesCollection = 'devices';
  static const String correctionRequestsCollection = 'correction_requests';
  static const String auditLogsCollection = 'audit_logs';

  // Cloud Functions
  static const String fnCreateSession = 'createAttendanceSession';
  static const String fnGenerateOtp = 'generateOtp';
  static const String fnSubmitAttendance = 'submitAttendance';
  static const String fnCloseSession = 'closeSession';
  static const String fnImportStudents = 'importStudents';
  static const String fnGenerateReport = 'generateReport';

  // Pagination
  static const int defaultPageSize = 20;

  // Low attendance threshold
  static const double lowAttendanceThreshold = 0.75; // 75%

  // UI constants
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 12.0;
  static const double screenPadding = 20.0;

  // Earth radius for Haversine
  static const double earthRadiusKm = 6371.0;
}

class HaversineUtil {
  HaversineUtil._();

  /// Calculate distance between two GPS points in metres
  static double distanceInMetres(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double r = AppConstants.earthRadiusKm * 1000; // Convert to metres

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _toRadians(double degrees) {
    return degrees * (pi / 180.0);
  }

  /// Returns true if distance is within maxMeters
  static bool isWithinRadius(
    double lat1,
    double lon1,
    double lat2,
    double lon2, {
    double maxMeters = AppConstants.maxDistanceMeters,
  }) {
    return distanceInMetres(lat1, lon1, lat2, lon2) <= maxMeters;
  }
}
