import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../models/user_model.dart';

// Firebase auth instance provider
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// Firestore instance provider
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// StateNotifier for active user profile with local DB persistence
class ActiveUserNotifier extends StateNotifier<UserModel?> {
  ActiveUserNotifier() : super(null) {
    _loadInitialSession();
  }

  Future<void> _loadInitialSession() async {
    final saved = await AppDatabase.instance.getSavedSession();
    if (saved != null) {
      state = saved;
    }
  }

  void setUser(UserModel? user) {
    state = user;
  }
}

final activeUserProvider = StateNotifierProvider<ActiveUserNotifier, UserModel?>((ref) {
  return ActiveUserNotifier();
});

// Auth state stream provider for router guards
final authStateProvider = StreamProvider<dynamic>((ref) {
  final user = ref.watch(activeUserProvider);
  return Stream.value(user);
});

// Current user model provider
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final user = ref.watch(activeUserProvider);
  if (user != null) return user;
  return await AppDatabase.instance.getSavedSession();
});

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref: ref,
    auth: ref.read(firebaseAuthProvider),
    firestore: ref.read(firestoreProvider),
  );
});

class AuthService {
  final Ref _ref;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({
    required Ref ref,
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _ref = ref,
        _auth = auth,
        _firestore = firestore;

  /// Sign in using Roll Number (Students), Faculty ID (Faculty), or ADMIN
  Future<UserModel> signIn(String identifier, String password) async {
    try {
      // Authenticate via database
      final user = await AppDatabase.instance.authenticate(identifier, password);

      // Update state notifier
      _ref.read(activeUserProvider.notifier).setUser(user);

      // Try background Firebase Auth sign-in if online
      try {
        if (_auth.currentUser == null) {
          await _auth.signInWithEmailAndPassword(
            email: user.email,
            password: password,
          );
        }
      } catch (_) {
        // Fallback to local DB authentication is completely valid
      }

      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await AppDatabase.instance.clearSession();
    _ref.read(activeUserProvider.notifier).setUser(null);
    try {
      await _auth.signOut();
    } catch (_) {}
  }
}
