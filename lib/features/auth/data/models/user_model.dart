import 'package:atlas/features/auth/domain/entities/user_entity.dart';
import 'package:atlas/features/auth/data/models/user_settings_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.username,
    super.name,
    super.bio,
    super.avatarUrl,
    super.likedPlaces,
    super.createdRoutes,
    super.preferences,
    required super.settings,
    required super.createdAt,
  });

  factory UserModel.fromFirebase(User user) {
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      username: user.displayName ?? '',
      avatarUrl: user.photoURL,
      settings: UserSettingsModel.defaults(),
      createdAt: DateTime.now(),
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      name: json['name'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      likedPlaces: List<String>.from(json['likedPlaces'] ?? []),
      createdRoutes: List<String>.from(json['createdRoutes'] ?? []),
      preferences: List<String>.from(json['preferences'] ?? []),
      settings: UserSettingsModel.fromJson(
        json['settings'] as Map<String, dynamic>? ?? {},
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'name': name,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'likedPlaces': likedPlaces,
      'createdRoutes': createdRoutes,
      'preferences': preferences,
      'settings': (settings as UserSettingsModel).toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
