import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/attendance_models.dart';
import '../../auth/providers/auth_provider.dart';

// Active sessions for student's enrolled subjects
final activeStudentSessionsProvider =
    StreamProvider.family<List<AttendanceSession>, String>((ref, studentId) {
  // First get the student's enrollments, then check active sessions for those
  // For simplicity, fetch all active sessions and filter by enrollment
  return ref.read(firestoreProvider)
      .collection(AppConstants.attendanceSessionsCollection)
      .where('status', isEqualTo: 'ACTIVE')
      .snapshots()
      .asyncMap((snap) async {
    final sessions = snap.docs.map(AttendanceSession.fromFirestore).toList();

    // Filter by enrolled subjects
    final enrollSnap = await ref.read(firestoreProvider)
        .collection(AppConstants.enrollmentsCollection)
        .where('studentId', isEqualTo: studentId)
        .where('isActive', isEqualTo: true)
        .get();

    final enrolledSectionIds = enrollSnap.docs.map((d) => d.data()['sectionId'] as String).toSet();
    return sessions.where((s) => enrolledSectionIds.contains(s.sectionId)).toList();
  });
});

// Student enrollments with attendance stats
final studentEnrollmentsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, studentId) {
  return ref.read(firestoreProvider)
      .collection(AppConstants.enrollmentsCollection)
      .where('studentId', isEqualTo: studentId)
      .where('isActive', isEqualTo: true)
      .snapshots()
      .asyncMap((snap) async {
    final results = <Map<String, dynamic>>[];

    for (final doc in snap.docs) {
      final data = doc.data();
      final courseId = data['courseId'] as String;
      final sectionId = data['sectionId'] as String;

      // Get attendance stats for this course
      final recordsSnap = await ref.read(firestoreProvider)
          .collection(AppConstants.attendanceRecordsCollection)
          .where('studentId', isEqualTo: studentId)
          .where('courseId', isEqualTo: courseId)
          .get();

      final totalRecords = recordsSnap.docs.length;
      final presentCount = recordsSnap.docs.where((r) => r.data()['status'] == 'PRESENT').length;
      final pct = totalRecords > 0 ? (presentCount / totalRecords) * 100 : 0.0;

      results.add({
        'enrollmentId': doc.id,
        'courseId': courseId,
        'sectionId': sectionId,
        'courseName': data['courseName'] ?? 'Unknown',
        'facultyName': data['facultyName'] ?? '',
        'total': totalRecords,
        'present': presentCount,
        'attendancePercentage': pct,
      });
    }

    return results;
  });
});

// Student attendance history
final studentAttendanceHistoryProvider =
    StreamProvider.family<List<AttendanceRecord>, String>((ref, studentId) {
  return ref.read(firestoreProvider)
      .collection(AppConstants.attendanceRecordsCollection)
      .where('studentId', isEqualTo: studentId)
      .orderBy('submittedAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) => snap.docs.map(AttendanceRecord.fromFirestore).toList());
});

// Student service provider
final studentServiceProvider = Provider<StudentService>((ref) {
  return StudentService(
    firestore: ref.read(firestoreProvider),
    functions: FirebaseFunctions.instance,
  );
});

class StudentService {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  StudentService({required FirebaseFirestore firestore, required FirebaseFunctions functions})
      : _firestore = firestore,
        _functions = functions;

  /// Submit attendance — all validation happens server-side
  Future<Map<String, dynamic>> submitAttendance({
    required String sessionId,
    required String otp,
  }) async {
    // Get fresh location
    final position = await _getLocation();

    final callable = _functions.httpsCallable(AppConstants.fnSubmitAttendance);
    final result = await callable.call({
      'sessionId': sessionId,
      'otp': otp,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'clientTimestamp': DateTime.now().toIso8601String(),
    });

    return Map<String, dynamic>.from(result.data);
  }

  /// Submit a correction request
  Future<void> submitCorrectionRequest({
    required String sessionId,
    required String attendanceRecordId,
    required String reason,
  }) async {
    final callable = _functions.httpsCallable('submitCorrectionRequest');
    await callable.call({
      'sessionId': sessionId,
      'attendanceRecordId': attendanceRecordId,
      'reason': reason,
    });
  }

  Future<Position> _getLocation() async {
    var status = await Permission.location.status;
    if (status.isDenied) {
      status = await Permission.location.request();
    }
    if (!status.isGranted) {
      throw Exception('Location permission is required to mark attendance.');
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Please enable location services (GPS) to mark attendance.');
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 20),
      );
    } catch (e) {
      throw Exception('Unable to get your location. Please ensure GPS is enabled and try again.');
    }
  }

  Stream<AttendanceSession?> sessionStream(String sessionId) {
    return _firestore
        .collection(AppConstants.attendanceSessionsCollection)
        .doc(sessionId)
        .snapshots()
        .map((doc) => doc.exists ? AttendanceSession.fromFirestore(doc) : null);
  }
}
