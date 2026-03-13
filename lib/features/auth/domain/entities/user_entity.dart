import 'user_settings_entity.dart';

class UserEntity {
  final String id;
  final String email;
  final String username;
  final String? name;
  final String? bio;
  final String? avatarUrl;
  final List<String> likedPlaces;
  final List<String> createdRoutes;
  final List<String> preferences;
  final UserSettingsEntity settings;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.username,
    this.name,
    this.bio,
    this.avatarUrl,
    this.likedPlaces = const [],
    this.createdRoutes = const [],
    this.preferences = const [],
    required this.settings,
    required this.createdAt,
  });
}
