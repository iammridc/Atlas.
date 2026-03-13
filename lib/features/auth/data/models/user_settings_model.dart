import 'package:atlas/features/auth/domain/entities/user_settings_entity.dart';

class UserSettingsModel extends UserSettingsEntity {
  const UserSettingsModel({
    super.theme,
    super.biometricsEnabled,
    super.language,
    super.currency,
  });

  factory UserSettingsModel.defaults() {
    return const UserSettingsModel(
      theme: 'system',
      biometricsEnabled: false,
      language: 'en',
      currency: 'USD',
    );
  }

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      theme: json['theme'] as String? ?? 'system',
      biometricsEnabled: json['biometricsEnabled'] as bool? ?? false,
      language: json['language'] as String? ?? 'en',
      currency: json['currency'] as String? ?? 'USD',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'biometricsEnabled': biometricsEnabled,
      'language': language,
      'currency': currency,
    };
  }
}
