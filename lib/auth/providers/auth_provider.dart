import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../../shared/constants/firestore_constants.dart';
import '../../shared/providers/locale_provider.dart';

/// Firebase Auth instance provider
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Auth state provider - streams the current user
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Current user ID provider
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).value?.uid;
});

/// App user data provider - listening to real-time updates for access control
final appUserProvider = StreamProvider<AppUser?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection(FirestoreConstants.users)
      .doc(userId)
      .snapshots()
      .map((doc) {
        if (doc.exists) return AppUser.fromFirestore(doc);
        return null;
      });
});

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(firebaseAuthProvider),
    FirebaseFirestore.instance,
    ref.watch(sharedPreferencesProvider),
  );
});

/// Auth state notifier
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService, ref);
});

/// Auth state class
class AuthState {
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  final AppUser? user;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    AppUser? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
    );
  }
}

/// Auth notifier for managing auth state
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final Ref _ref;

  AuthNotifier(this._authService, this._ref) : super(const AuthState());

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      if (result != null) {
        // Update locale
        _ref.read(localeProvider.notifier).setLocale(result.language);

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: result,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid email or password',
        );
        return false;
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login failed';
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Please try later';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid email or password';
          break;
        default:
          errorMessage = e.message ?? 'Login failed';
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String businessName,
    required String language,
    String role = 'user',
    String? adminCode,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.createAccount(
        email: email,
        password: password,
        businessName: businessName,
        language: language,
        role: role,
        adminCode: adminCode,
      );

      if (result != null) {
        // Update locale
        _ref.read(localeProvider.notifier).setLocale(language);

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: result,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to create account',
        );
        return false;
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Registration failed';
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Email is already registered';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format';
          break;
        default:
          errorMessage = e.message ?? 'Registration failed';
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    state = const AuthState();
  }

  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.sendPasswordResetEmail(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to send reset email',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Auth service for authentication operations
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final SharedPreferences _prefs;

  static const String _savedEmailKey = 'saved_email';

  AuthService(this._auth, this._firestore, this._prefs);

  /// Sign in with email and password
  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final userId = userCredential.user!.uid;

      // Fetch user data from Firestore
      final userDoc = await _firestore
          .collection(FirestoreConstants.users)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        // Automatically recreate user profile document with default admin levels on fresh start/database wipe
        final now = DateTime.now();
        final newUser = AppUser(
          id: userId,
          userId: userId,
          email: email.trim(),
          businessName: 'I-buzz User',
          language: 'en',
          role: 'admin',
          accessLevel: 'edit',
          createdAt: now,
          updatedAt: now,
        );
        await _firestore
            .collection(FirestoreConstants.users)
            .doc(userId)
            .set(newUser.toMap());

        // Save email for convenience
        await _prefs.setString(_savedEmailKey, email);
        return newUser;
      }

      // Save email for convenience
      await _prefs.setString(_savedEmailKey, email);

      return AppUser.fromFirestore(userDoc);
    } catch (e) {
      rethrow;
    }
  }

  /// Automatically recreate profile if session is active but profile is missing (e.g. database wipe)
  Future<void> checkAndRecreateUserProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore
          .collection(FirestoreConstants.users)
          .doc(user.uid)
          .get();
      if (!doc.exists) {
        final now = DateTime.now();
        final newUser = AppUser(
          id: user.uid,
          userId: user.uid,
          email: user.email ?? '',
          businessName: 'I-buzz User',
          language: 'en',
          role: 'admin',
          accessLevel: 'edit',
          createdAt: now,
          updatedAt: now,
        );
        await _firestore
            .collection(FirestoreConstants.users)
            .doc(user.uid)
            .set(newUser.toMap());
      }
    }
  }

  Future<AppUser?> createAccount({
    required String email,
    required String password,
    required String businessName,
    required String language,
    String role = 'user',
    String? adminCode,
  }) async {
    try {
      if (role == 'admin' && adminCode != 'SmartBuy001') {
        throw Exception('Invalid admin verification code');
      }
      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final userId = userCredential.user!.uid;

      final now = DateTime.now();
      final user = AppUser(
        id: userId,
        userId: userId,
        email: email.trim(),
        businessName: businessName,
        language: language,
        role: role,
        accessLevel: role == 'admin' ? 'edit' : 'view',
        createdAt: now,
        updatedAt: now,
      );

      // Save to Firestore
      await _firestore
          .collection(FirestoreConstants.users)
          .doc(userId)
          .set(user.toMap());

      // Save email for convenience
      await _prefs.setString(_savedEmailKey, email);

      return user;
    } catch (e) {
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Sign out
  Future<void> signOut() async {
    await _prefs.remove(_savedEmailKey);
    await _auth.signOut();
  }

  /// Get saved email
  String? getSavedEmail() {
    return _prefs.getString(_savedEmailKey);
  }

  /// Get current user
  User? get currentUser => _auth.currentUser;
}
