import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceSession {
  final String id;
  final String facultyId;
  final String courseId;
  final String courseName;
  final String sectionId;
  final String sectionName;
  final String departmentId;
  final double facultyLatitude;
  final double facultyLongitude;
  final double facultyLocationAccuracy;
  final DateTime startTime;
  final DateTime? endTime;
  final String status; // ACTIVE, CLOSED, EXPIRED
  final int durationMinutes;
  final int otpExpirySeconds;
  final double maxDistanceMeters;
  final int totalEnrolled;
  final int totalPresent;
  final String? closureReason;
  final String? activeOtpId;

  const AttendanceSession({
    required this.id,
    required this.facultyId,
    required this.courseId,
    required this.courseName,
    required this.sectionId,
    required this.sectionName,
    required this.departmentId,
    required this.facultyLatitude,
    required this.facultyLongitude,
    required this.facultyLocationAccuracy,
    required this.startTime,
    this.endTime,
    required this.status,
    this.durationMinutes = 30,
    this.otpExpirySeconds = 120,
    this.maxDistanceMeters = 20.0,
    this.totalEnrolled = 0,
    this.totalPresent = 0,
    this.closureReason,
    this.activeOtpId,
  });

  bool get isActive => status == 'ACTIVE';
  bool get isClosed => status == 'CLOSED' || status == 'EXPIRED';

  double get attendancePercentage =>
      totalEnrolled > 0 ? (totalPresent / totalEnrolled) * 100 : 0;

  factory AttendanceSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceSession(
      id: doc.id,
      facultyId: data['facultyId'] ?? '',
      courseId: data['courseId'] ?? '',
      courseName: data['courseName'] ?? '',
      sectionId: data['sectionId'] ?? '',
      sectionName: data['sectionName'] ?? '',
      departmentId: data['departmentId'] ?? '',
      facultyLatitude: (data['facultyLatitude'] ?? 0.0).toDouble(),
      facultyLongitude: (data['facultyLongitude'] ?? 0.0).toDouble(),
      facultyLocationAccuracy: (data['facultyLocationAccuracy'] ?? 0.0).toDouble(),
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'ACTIVE',
      durationMinutes: data['durationMinutes'] ?? 30,
      otpExpirySeconds: data['otpExpirySeconds'] ?? 120,
      maxDistanceMeters: (data['maxDistanceMeters'] ?? 20.0).toDouble(),
      totalEnrolled: data['totalEnrolled'] ?? 0,
      totalPresent: data['totalPresent'] ?? 0,
      closureReason: data['closureReason'],
      activeOtpId: data['activeOtpId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'facultyId': facultyId,
      'courseId': courseId,
      'courseName': courseName,
      'sectionId': sectionId,
      'sectionName': sectionName,
      'departmentId': departmentId,
      'facultyLatitude': facultyLatitude,
      'facultyLongitude': facultyLongitude,
      'facultyLocationAccuracy': facultyLocationAccuracy,
      'startTime': Timestamp.fromDate(startTime),
      if (endTime != null) 'endTime': Timestamp.fromDate(endTime!),
      'status': status,
      'durationMinutes': durationMinutes,
      'otpExpirySeconds': otpExpirySeconds,
      'maxDistanceMeters': maxDistanceMeters,
      'totalEnrolled': totalEnrolled,
      'totalPresent': totalPresent,
      if (closureReason != null) 'closureReason': closureReason,
      if (activeOtpId != null) 'activeOtpId': activeOtpId,
    };
  }
}

class AttendanceRecord {
  final String id;
  final String sessionId;
  final String studentId;
  final String studentName;
  final String rollNumber;
  final String status; // PRESENT, ABSENT, EXCUSED
  final double? studentLatitude;
  final double? studentLongitude;
  final double? distanceFromFaculty;
  final DateTime submittedAt;
  final String? deviceId;
  final bool isManuallyMarked;
  final String? remarks;

  const AttendanceRecord({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required this.status,
    this.studentLatitude,
    this.studentLongitude,
    this.distanceFromFaculty,
    required this.submittedAt,
    this.deviceId,
    this.isManuallyMarked = false,
    this.remarks,
  });

  bool get isPresent => status == 'PRESENT';

  factory AttendanceRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceRecord(
      id: doc.id,
      sessionId: data['sessionId'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      rollNumber: data['rollNumber'] ?? '',
      status: data['status'] ?? 'ABSENT',
      studentLatitude: data['studentLatitude']?.toDouble(),
      studentLongitude: data['studentLongitude']?.toDouble(),
      distanceFromFaculty: data['distanceFromFaculty']?.toDouble(),
      submittedAt: (data['submittedAt'] as Timestamp).toDate(),
      deviceId: data['deviceId'],
      isManuallyMarked: data['isManuallyMarked'] ?? false,
      remarks: data['remarks'],
    );
  }
}
