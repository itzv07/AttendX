import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/attendance_models.dart';
import '../../auth/providers/auth_provider.dart';

final facultyServiceProvider = Provider<FacultyService>((ref) {
  return FacultyService(
    firestore: ref.read(firestoreProvider),
    functions: FirebaseFunctions.instance,
  );
});

// Active session stream
final activeSessionStreamProvider = StreamProvider.family<AttendanceSession?, String>((ref, facultyId) {
  return ref.read(firestoreProvider)
      .collection(AppConstants.attendanceSessionsCollection)
      .where('facultyId', isEqualTo: facultyId)
      .where('status', isEqualTo: 'ACTIVE')
      .limit(1)
      .snapshots()
      .map((snap) {
    if (snap.docs.isEmpty) return null;
    return AttendanceSession.fromFirestore(snap.docs.first);
  });
});

// Session records stream
final sessionRecordsProvider = StreamProvider.family<List<AttendanceRecord>, String>((ref, sessionId) {
  return ref.read(firestoreProvider)
      .collection(AppConstants.attendanceRecordsCollection)
      .where('sessionId', isEqualTo: sessionId)
      .orderBy('submittedAt', descending: false)
      .snapshots()
      .map((snap) => snap.docs.map(AttendanceRecord.fromFirestore).toList());
});

// OTP countdown state
class OtpState {
  final String otp;
  final DateTime expiresAt;
  final int secondsRemaining;

  const OtpState({
    required this.otp,
    required this.expiresAt,
    required this.secondsRemaining,
  });

  bool get isExpired => secondsRemaining <= 0;
}

class FacultyService {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  FacultyService({
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
  })  : _firestore = firestore,
        _functions = functions;

  /// Create a new attendance session with server-side validation
  Future<Map<String, dynamic>> createSession({
    required String courseId,
    required String courseName,
    required String sectionId,
    required String sectionName,
    required String departmentId,
    required int durationMinutes,
  }) async {
    // Get location first
    final position = await _getLocation();

    final callable = _functions.httpsCallable(AppConstants.fnCreateSession);
    final result = await callable.call({
      'courseId': courseId,
      'courseName': courseName,
      'sectionId': sectionId,
      'sectionName': sectionName,
      'departmentId': departmentId,
      'durationMinutes': durationMinutes,
      'facultyLatitude': position.latitude,
      'facultyLongitude': position.longitude,
      'facultyLocationAccuracy': position.accuracy,
    });

    return Map<String, dynamic>.from(result.data);
  }

  /// Generate OTP for an active session
  Future<Map<String, dynamic>> generateOtp(String sessionId) async {
    final callable = _functions.httpsCallable(AppConstants.fnGenerateOtp);
    final result = await callable.call({'sessionId': sessionId});
    return Map<String, dynamic>.from(result.data);
  }

  /// Close an attendance session
  Future<void> closeSession(String sessionId, {String? reason}) async {
    final callable = _functions.httpsCallable(AppConstants.fnCloseSession);
    await callable.call({
      'sessionId': sessionId,
      if (reason != null) 'reason': reason,
    });
  }

  /// Get location with permission handling
  Future<Position> _getLocation() async {
    var status = await Permission.location.status;
    if (status.isDenied) {
      status = await Permission.location.request();
    }
    if (!status.isGranted) {
      throw Exception('Location permission is required to start an attendance session.');
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable GPS.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 30),
    );
  }

  /// Stream session by ID
  Stream<AttendanceSession?> sessionStream(String sessionId) {
    return _firestore
        .collection(AppConstants.attendanceSessionsCollection)
        .doc(sessionId)
        .snapshots()
        .map((doc) => doc.exists ? AttendanceSession.fromFirestore(doc) : null);
  }

  /// Get faculty's session history
  Future<List<AttendanceSession>> getSessionHistory(String facultyId, {int limit = 20}) async {
    final snap = await _firestore
        .collection(AppConstants.attendanceSessionsCollection)
        .where('facultyId', isEqualTo: facultyId)
        .orderBy('startTime', descending: true)
        .limit(limit)
        .get();

    return snap.docs.map(AttendanceSession.fromFirestore).toList();
  }

  /// Get faculty's assigned courses/sections
  Future<List<Map<String, dynamic>>> getAssignedClasses(String facultyId) async {
    final snap = await _firestore
        .collection(AppConstants.facultyAssignmentsCollection)
        .where('facultyId', isEqualTo: facultyId)
        .where('isActive', isEqualTo: true)
        .get();

    return snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }
}
