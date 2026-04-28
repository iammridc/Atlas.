import 'package:flutter/material.dart';
import 'package:atlas/core/consts/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.appPrimaryWhite,
      surface: AppColors.backgroundDark,
    ),
    iconTheme: const IconThemeData(color: AppColors.appPrimaryWhite),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.appPrimaryWhite),
      bodyMedium: TextStyle(color: AppColors.appPrimaryWhite),
      bodySmall: TextStyle(color: AppColors.appPrimaryWhite),
    ),
    elevatedButtonTheme: _elevatedButtonTheme(isDark: true),
    filledButtonTheme: _filledButtonTheme(isDark: true),
    outlinedButtonTheme: _outlinedButtonTheme(isDark: true),
    textButtonTheme: _textButtonTheme(isDark: true),
  );

  static ThemeData get light => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    colorScheme: const ColorScheme.light(
      primary: AppColors.appPrimaryBlack,
      surface: AppColors.backgroundLight,
    ),
    iconTheme: const IconThemeData(color: AppColors.appPrimaryBlack),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.appPrimaryBlack),
      bodyMedium: TextStyle(color: AppColors.appPrimaryBlack),
      bodySmall: TextStyle(color: AppColors.appPrimaryBlack),
    ),
    elevatedButtonTheme: _elevatedButtonTheme(isDark: false),
    filledButtonTheme: _filledButtonTheme(isDark: false),
    outlinedButtonTheme: _outlinedButtonTheme(isDark: false),
    textButtonTheme: _textButtonTheme(isDark: false),
  );

  static ElevatedButtonThemeData _elevatedButtonTheme({required bool isDark}) {
    return ElevatedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size.fromHeight(54)),
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08);
          }
          return isDark ? AppColors.appPrimaryBlack : AppColors.appPrimaryWhite;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return isDark ? Colors.white38 : Colors.black38;
          }
          return isDark ? AppColors.appPrimaryWhite : AppColors.appPrimaryBlack;
        }),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return BorderSide.none;
          }
          return BorderSide(color: isDark ? Colors.white24 : Colors.black26);
        }),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static FilledButtonThemeData _filledButtonTheme({required bool isDark}) {
    return FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size.fromHeight(54)),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08);
          }
          return isDark ? AppColors.appPrimaryBlack : AppColors.appPrimaryWhite;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return isDark ? Colors.white38 : Colors.black38;
          }
          return isDark ? AppColors.appPrimaryWhite : AppColors.appPrimaryBlack;
        }),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return BorderSide.none;
          }
          return BorderSide(color: isDark ? Colors.white24 : Colors.black26);
        }),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme({required bool isDark}) {
    return OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size.fromHeight(54)),
        foregroundColor: WidgetStatePropertyAll(
          isDark ? AppColors.appPrimaryWhite : AppColors.appPrimaryBlack,
        ),
        side: WidgetStatePropertyAll(
          BorderSide(color: isDark ? Colors.white24 : Colors.black26),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static TextButtonThemeData _textButtonTheme({required bool isDark}) {
    return TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(
          isDark ? AppColors.appPrimaryWhite : AppColors.appPrimaryBlack,
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
