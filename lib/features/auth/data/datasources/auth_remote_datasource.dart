// auth_remote_datasource.dart — fetch preferences from Firestore

import 'package:atlas/core/errors/auth_exception.dart';
import 'package:atlas/features/auth/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRemoteDatasource {
  Future<UserModel> signIn({required String email, required String password});
  Future<UserModel> signUp({required String email, required String password});
  Future<void> signOut();
  Future<void> deleteAccount();
  Future<UserModel?> getCurrentUser();
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRemoteDatasourceImpl({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  }) : _firebaseAuth = firebaseAuth,
       _firestore = firestore;

  Future<Map<String, dynamic>> _fetchUserDoc(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data() ?? {};
  }

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

      final uid = credential.user!.uid;
      final userData = await _fetchUserDoc(uid);
      final userMap = {
        'id': uid,
        'email': credential.user!.email ?? '',
        'username':
            userData['username'] ??
            credential.user!.displayName ??
            email.split('@')[0],
        'name': userData['name'],
        'bio': userData['bio'],
        'avatarUrl': userData['avatarUrl'] ?? credential.user!.photoURL,
        'likedPlaces': userData['likedPlaces'] ?? [],
        'createdRoutes': userData['createdRoutes'] ?? [],
        'preferences': userData['preferences'] ?? [],
        'settings':
            userData['settings'] ??
            {
              'theme': 'system',
              'biometricsEnabled': false,
              'language': 'en',
              'currency': 'USD',
            },
        'createdAt': userData['createdAt'] ?? DateTime.now().toIso8601String(),
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

      final uid = credential.user!.uid;

      final userMap = {
        'id': uid,
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

      await _firestore.collection('users').doc(uid).set(userMap);

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
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException(
          code: 'no-current-user',
          message: 'Please sign in again.',
        );
      }

      final userDoc = _firestore.collection('users').doc(user.uid);
      final reviewsSnapshot = await userDoc.collection('reviews').get();

      final batch = _firestore.batch();
      for (final reviewDoc in reviewsSnapshot.docs) {
        final placeId = (reviewDoc.data()['placeId'] as String?)?.trim();
        if (placeId != null && placeId.isNotEmpty) {
          batch.delete(
            _firestore
                .collection('places')
                .doc(placeId)
                .collection('reviews')
                .doc(user.uid),
          );
        }
        batch.delete(reviewDoc.reference);
      }

      final favoritePlacesSnapshot = await userDoc
          .collection('favorite_places')
          .get();
      for (final doc in favoritePlacesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      final plannedTripsSnapshot = await userDoc
          .collection('planned_trips')
          .get();
      for (final doc in plannedTripsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      batch.delete(userDoc);
      await batch.commit();
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw AuthException(
          code: e.code,
          message: 'Please sign in again before deleting your account.',
        );
      }
      throw _handleFirebaseException(e);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(
        code: 'unknown',
        message: 'Failed to delete account.',
      );
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) return null;

      final uid = firebaseUser.uid;
      final userData = await _fetchUserDoc(uid);

      final userMap = {
        'id': uid,
        'email': firebaseUser.email ?? '',
        'username':
            userData['username'] ??
            firebaseUser.displayName ??
            firebaseUser.email!.split('@')[0],
        'name': userData['name'],
        'bio': userData['bio'],
        'avatarUrl': userData['avatarUrl'] ?? firebaseUser.photoURL,
        'likedPlaces': userData['likedPlaces'] ?? [],
        'createdRoutes': userData['createdRoutes'] ?? [],
        'preferences': userData['preferences'] ?? [],
        'settings':
            userData['settings'] ??
            {
              'theme': 'system',
              'biometricsEnabled': false,
              'language': 'en',
              'currency': 'USD',
            },
        'createdAt': userData['createdAt'] ?? DateTime.now().toIso8601String(),
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
