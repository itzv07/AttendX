import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/models/user_model.dart';

class UserCredentialRecord {
  final UserModel user;
  final String password;

  const UserCredentialRecord({
    required this.user,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'user': user.toFirestore(),
        'password': password,
      };
}

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();

  AppDatabase._internal() {
    _initializeDatabase();
  }

  // In-memory credential and profile registry
  final Map<String, UserCredentialRecord> _usersByIdentifier = {};

  // All student roll numbers cache
  final List<String> studentRollNumbers = [];

  void _initializeDatabase() {
    // 1. Seed Administrator
    final adminUser = UserModel(
      uid: 'admin_master_01',
      email: 'admin@attendx.edu',
      displayName: 'Chief Academic Administrator',
      role: UserRole.admin,
      departmentId: 'ADMIN_OFFICE',
      employeeId: 'ADM001',
      designation: 'Director of Academic Affairs',
      createdAt: DateTime(2024, 1, 1),
    );
    _usersByIdentifier['ADMIN'] = UserCredentialRecord(
      user: adminUser,
      password: '@Admin123',
    );

    // 2. Seed Faculty Members (dummy details)
    final facultyList = [
      {
        'id': 'FAC101',
        'name': 'Dr. Robert Vance',
        'email': 'robert.vance@attendx.edu',
        'dept': 'Artificial Intelligence & Data Science',
        'designation': 'Professor & HOD',
      },
      {
        'id': 'FAC102',
        'name': 'Prof. Elena Rostova',
        'email': 'elena.rostova@attendx.edu',
        'dept': 'Computer Science & Engineering',
        'designation': 'Associate Professor',
      },
      {
        'id': 'FAC103',
        'name': 'Dr. Alan Morales',
        'email': 'alan.morales@attendx.edu',
        'dept': 'Data Science & Analytics',
        'designation': 'Assistant Professor',
      },
      {
        'id': 'FAC104',
        'name': 'Dr. Sarah Jenkins',
        'email': 'sarah.jenkins@attendx.edu',
        'dept': 'Information Technology',
        'designation': 'Senior Lecturer',
      },
    ];

    for (final fac in facultyList) {
      final facId = fac['id']!;
      final facUser = UserModel(
        uid: 'fac_${facId.toLowerCase()}',
        email: fac['email']!,
        displayName: fac['name']!,
        role: UserRole.faculty,
        departmentId: fac['dept'],
        employeeId: facId,
        designation: fac['designation'],
        createdAt: DateTime(2024, 1, 15),
      );
      // Faculty password is same as faculty ID
      _usersByIdentifier[facId.toUpperCase()] = UserCredentialRecord(
        user: facUser,
        password: facId,
      );
    }

    // 3. Seed Students (2273A39001 to 2273A39132)
    for (int i = 1; i <= 132; i++) {
      final suffix = i.toString().padLeft(3, '0');
      final roll = '2273A39$suffix';
      studentRollNumbers.add(roll);

      final isSecA = i <= 66;
      final studentUser = UserModel(
        uid: 'std_${roll.toLowerCase()}',
        email: '$roll@attendx.edu',
        displayName: 'Student $roll',
        role: UserRole.student,
        rollNumber: roll,
        studentId: roll,
        departmentId: 'Artificial Intelligence & Data Science',
        createdAt: DateTime(2022, 9, 1),
      );

      // Student password is same as roll number
      _usersByIdentifier[roll.toUpperCase()] = UserCredentialRecord(
        user: studentUser,
        password: roll,
      );
    }

    // 4. Seed Lateral Entry Students (2273A390L1 to 2273A390L3)
    final lateralSuffixes = ['L1', 'L2', 'L3'];
    for (final lat in lateralSuffixes) {
      final roll = '2273A390$lat';
      studentRollNumbers.add(roll);

      final studentUser = UserModel(
        uid: 'std_${roll.toLowerCase()}',
        email: '$roll@attendx.edu',
        displayName: 'Lateral Student $roll',
        role: UserRole.student,
        rollNumber: roll,
        studentId: roll,
        departmentId: 'Artificial Intelligence & Data Science',
        createdAt: DateTime(2023, 9, 1),
      );

      // Password is same as roll number
      _usersByIdentifier[roll.toUpperCase()] = UserCredentialRecord(
        user: studentUser,
        password: roll,
      );
    }
  }

  /// Authenticate user by identifier (Roll Number / Faculty ID / ADMIN) and Password
  Future<UserModel> authenticate(String identifier, String password) async {
    final cleanId = identifier.trim().toUpperCase();
    final cleanPass = password.trim();

    if (!_usersByIdentifier.containsKey(cleanId)) {
      throw Exception(
        'User not found. For students, enter roll number (e.g. 2273A39001 to 2273A39132, 2273A390L1-L3). For faculty, enter Faculty ID (e.g. FAC101). For admin, enter ADMIN.',
      );
    }

    final record = _usersByIdentifier[cleanId]!;

    // Check password (case-insensitive for roll numbers & faculty IDs, exact for admin)
    final isPasswordMatch = cleanId == 'ADMIN'
        ? record.password == cleanPass
        : record.password.toUpperCase() == cleanPass.toUpperCase();

    if (!isPasswordMatch) {
      throw Exception(
        cleanId == 'ADMIN'
            ? 'Incorrect admin password. (Default is @Admin123)'
            : 'Incorrect password. Password must be the same as your ID/Roll Number ($cleanId).',
      );
    }

    // Save session in SharedPreferences
    await saveSession(record.user);
    return record.user;
  }

  /// Persist session locally
  Future<void> saveSession(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('attendx_active_user', jsonEncode({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'role': user.role.name,
        'rollNumber': user.rollNumber,
        'studentId': user.studentId,
        'employeeId': user.employeeId,
        'departmentId': user.departmentId,
        'designation': user.designation,
      }));
    } catch (_) {}
  }

  /// Retrieve persisted session
  Future<UserModel?> getSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('attendx_active_user');
      if (str == null) return null;

      final data = jsonDecode(str) as Map<String, dynamic>;
      UserRole role = UserRole.student;
      if (data['role'] == 'admin') role = UserRole.admin;
      if (data['role'] == 'faculty') role = UserRole.faculty;

      return UserModel(
        uid: data['uid'] ?? '',
        email: data['email'] ?? '',
        displayName: data['displayName'] ?? '',
        role: role,
        rollNumber: data['rollNumber'],
        studentId: data['studentId'],
        employeeId: data['employeeId'],
        departmentId: data['departmentId'],
        designation: data['designation'],
        createdAt: DateTime(2024, 1, 1),
      );
    } catch (_) {
      return null;
    }
  }

  /// Clear session
  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('attendx_active_user');
    } catch (_) {}
  }

  /// Query all registered students
  List<UserModel> getAllStudents() {
    return _usersByIdentifier.values
        .where((r) => r.user.role == UserRole.student)
        .map((r) => r.user)
        .toList();
  }

  /// Query all registered faculty
  List<UserModel> getAllFaculty() {
    return _usersByIdentifier.values
        .where((r) => r.user.role == UserRole.faculty)
        .map((r) => r.user)
        .toList();
  }
}
