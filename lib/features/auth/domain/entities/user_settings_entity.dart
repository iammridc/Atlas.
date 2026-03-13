class UserSettingsEntity {
  final String theme;
  final bool biometricsEnabled;
  final String language;
  final String currency;

  const UserSettingsEntity({
    this.theme = 'system',
    this.biometricsEnabled = false,
    this.language = 'en',
    this.currency = 'USD',
  });
}
