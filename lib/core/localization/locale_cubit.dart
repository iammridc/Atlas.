import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleCubit extends Cubit<Locale> {
  static const settingsLanguageKey = 'settings_language';
  static const englishLabel = 'English';
  static const russianLabel = 'Русский';

  LocaleCubit() : super(const Locale('en'));

  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    emit(_localeFromStoredValue(prefs.getString(settingsLanguageKey)));
  }

  Future<void> setLocale(Locale locale) async {
    final normalized = _normalizeLocale(locale);
    emit(normalized);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(settingsLanguageKey, labelForLocale(normalized));
  }

  Future<void> setLanguageLabel(String value) {
    return setLocale(_localeFromStoredValue(value));
  }

  static String labelForLocale(Locale locale) {
    return locale.languageCode == 'ru' ? russianLabel : englishLabel;
  }

  static Locale _localeFromStoredValue(String? value) {
    final normalized = value?.trim().toLowerCase();
    return switch (normalized) {
      'ru' || 'russian' || 'русский' => const Locale('ru'),
      _ => const Locale('en'),
    };
  }

  static Locale _normalizeLocale(Locale locale) {
    return locale.languageCode == 'ru'
        ? const Locale('ru')
        : const Locale('en');
  }
}
