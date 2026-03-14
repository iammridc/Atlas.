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
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
  }) async {
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
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    final userMap = {
      'id': firebaseUser.uid,
      'email': firebaseUser.email ?? '',
      'username': firebaseUser.displayName ?? firebaseUser.email!.split('@')[0],
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
  }
}
