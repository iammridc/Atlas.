import 'package:atlas/core/errors/auth_exception.dart';
import 'package:atlas/features/auth/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRemoteDatasource {
  Future<UserModel> signIn({required String email, required String password});
  Future<UserModel> signUp({required String email, required String password});
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final FirebaseAuth _firebaseAuth;

  AuthRemoteDatasourceImpl({required FirebaseAuth firebaseAuth})
    : _firebaseAuth = firebaseAuth;

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userMap = {
        'id': credential.user!.uid,
        'email': credential.user!.email ?? '',
        'username': credential.user!.displayName ?? email.split('@')[0],
        'name': null,
        'bio': null,
        'avatarUrl': credential.user!.photoURL,
        'likedPlaces': [],
        'createdRoutes': [],
        'preferences': [],
        'settings': {
          'theme': 'system',
          'biometricsEnabled': false,
          'language': 'en',
          'currency': 'USD',
        },
        'createdAt': DateTime.now().toIso8601String(),
      };

      return UserModel.fromJson(userMap);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseException(e);
    } catch (e) {
      throw AuthException(
        code: 'unknown',
        message: 'An unexpected error occurred.',
      );
    }
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userMap = {
        'id': credential.user!.uid,
        'email': credential.user!.email ?? '',
        'username': email.split('@')[0],
        'name': null,
        'bio': null,
        'avatarUrl': credential.user!.photoURL,
        'likedPlaces': [],
        'createdRoutes': [],
        'preferences': [],
        'settings': {
          'theme': 'system',
          'biometricsEnabled': false,
          'language': 'en',
          'currency': 'USD',
        },
        'createdAt': DateTime.now().toIso8601String(),
      };

      return UserModel.fromJson(userMap);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseException(e);
    } catch (e) {
      throw AuthException(
        code: 'unknown',
        message: 'An unexpected error occurred.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseException(e);
    } catch (e) {
      throw AuthException(
        code: 'unknown',
        message: 'An unexpected error occurred.',
      );
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) return null;

      final userMap = {
        'id': firebaseUser.uid,
        'email': firebaseUser.email ?? '',
        'username':
            firebaseUser.displayName ?? firebaseUser.email!.split('@')[0],
        'name': null,
        'bio': null,
        'avatarUrl': firebaseUser.photoURL,
        'likedPlaces': [],
        'createdRoutes': [],
        'preferences': [],
        'settings': {
          'theme': 'system',
          'biometricsEnabled': false,
          'language': 'en',
          'currency': 'USD',
        },
        'createdAt': DateTime.now().toIso8601String(),
      };

      return UserModel.fromJson(userMap);
    } catch (e) {
      throw AuthException(
        code: 'unknown',
        message: 'An unexpected error occurred.',
      );
    }
  }

  AuthException _handleFirebaseException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AuthException(
          code: 'user-not-found',
          message: 'No account found with this email.',
        );
      case 'wrong-password':
        return AuthException(
          code: 'wrong-password',
          message: 'Incorrect password. Please try again.',
        );
      case 'invalid-credential':
        return AuthException(
          code: 'invalid-credential',
          message: 'Invalid email or password.',
        );
      case 'email-already-in-use':
        return AuthException(
          code: 'email-already-in-use',
          message: 'This email is already registered.',
        );
      case 'invalid-email':
        return AuthException(
          code: 'invalid-email',
          message: 'Please enter a valid email address.',
        );
      case 'weak-password':
        return AuthException(
          code: 'weak-password',
          message: 'Password must be at least 6 characters.',
        );
      case 'too-many-requests':
        return AuthException(
          code: 'too-many-requests',
          message: 'Too many attempts. Please try again later.',
        );
      case 'network-request-failed':
        return AuthException(
          code: 'network-request-failed',
          message: 'No internet connection.',
        );
      case 'user-disabled':
        return AuthException(
          code: 'user-disabled',
          message: 'This account has been disabled.',
        );
      default:
        return AuthException(
          code: e.code,
          message: e.message ?? 'An unexpected error occurred.',
        );
    }
  }
}
