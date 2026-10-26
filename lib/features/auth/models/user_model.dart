import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, faculty, student }

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final String? photoUrl;
  final String? phone;
  final String? departmentId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;

  // Student-specific
  final String? studentId;
  final String? rollNumber;

  // Faculty-specific
  final String? employeeId;
  final String? designation;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.photoUrl,
    this.phone,
    this.departmentId,
    this.isActive = true,
    required this.createdAt,
    this.lastLogin,
    this.studentId,
    this.rollNumber,
    this.employeeId,
    this.designation,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      role: _parseRole(data['role']),
      photoUrl: data['photoUrl'],
      phone: data['phone'],
      departmentId: data['departmentId'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
      studentId: data['studentId'],
      rollNumber: data['rollNumber'],
      employeeId: data['employeeId'],
      designation: data['designation'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role.name,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (phone != null) 'phone': phone,
      if (departmentId != null) 'departmentId': departmentId,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      if (lastLogin != null) 'lastLogin': Timestamp.fromDate(lastLogin!),
      if (studentId != null) 'studentId': studentId,
      if (rollNumber != null) 'rollNumber': rollNumber,
      if (employeeId != null) 'employeeId': employeeId,
      if (designation != null) 'designation': designation,
    };
  }

  static UserRole _parseRole(String? role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'faculty':
        return UserRole.faculty;
      default:
        return UserRole.student;
    }
  }

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    String? phone,
    bool? isActive,
    DateTime? lastLogin,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      role: role,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      departmentId: departmentId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      studentId: studentId,
      rollNumber: rollNumber,
      employeeId: employeeId,
      designation: designation,
    );
  }

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isFaculty => role == UserRole.faculty;
  bool get isStudent => role == UserRole.student;
}
