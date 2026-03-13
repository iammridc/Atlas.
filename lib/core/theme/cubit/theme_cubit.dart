import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, system }

class ThemeCubit extends Cubit<AppThemeMode> {
  ThemeCubit() : super(AppThemeMode.system);

  static String _key(String userId) => 'app_theme_$userId';
  static const _guestKey = 'app_theme_guest';

  // Called on app start (no user yet)
  Future<void> loadGuestTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_guestKey);
    if (saved != null) {
      emit(AppThemeMode.values.firstWhere((e) => e.name == saved));
    } else {
      emit(AppThemeMode.system);
    }
  }

  // Called after login — loads that user's saved theme
  Future<void> loadUserTheme(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key(userId));
    if (saved != null) {
      emit(AppThemeMode.values.firstWhere((e) => e.name == saved));
    } else {
      emit(AppThemeMode.system); // first time this user logs in
    }
  }

  // Called from settings — saves under current user's key
  Future<void> setTheme(AppThemeMode theme, {String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = userId != null ? _key(userId) : _guestKey;
    await prefs.setString(key, theme.name);
    emit(theme);
  }

  // Called on logout — reset to system
  void resetTheme() {
    emit(AppThemeMode.system);
  }
}
