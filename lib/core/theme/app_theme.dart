import 'package:flutter/material.dart';
import 'package:atlas/core/consts/app_colors.dart';

class AppTheme {
  AppTheme._();

  static const String fontFamily = 'Avenir Next';
  static const List<String> fontFamilyFallback = ['Helvetica Neue', 'Arial'];

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.appPrimaryWhite,
      surface: AppColors.backgroundDark,
    ),
    iconTheme: const IconThemeData(color: AppColors.appPrimaryWhite),
    textTheme: _textTheme(AppColors.appPrimaryWhite),
    primaryTextTheme: _textTheme(AppColors.appPrimaryWhite),
    inputDecorationTheme: _inputDecorationTheme(isDark: true),
    snackBarTheme: _snackBarTheme(isDark: true),
    elevatedButtonTheme: _elevatedButtonTheme(isDark: true),
    filledButtonTheme: _filledButtonTheme(isDark: true),
    outlinedButtonTheme: _outlinedButtonTheme(isDark: true),
    textButtonTheme: _textButtonTheme(isDark: true),
  );

  static ThemeData get light => ThemeData(
    brightness: Brightness.light,
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    colorScheme: const ColorScheme.light(
      primary: AppColors.appPrimaryBlack,
      surface: AppColors.backgroundLight,
    ),
    iconTheme: const IconThemeData(color: AppColors.appPrimaryBlack),
    textTheme: _textTheme(AppColors.appPrimaryBlack),
    primaryTextTheme: _textTheme(AppColors.appPrimaryBlack),
    inputDecorationTheme: _inputDecorationTheme(isDark: false),
    snackBarTheme: _snackBarTheme(isDark: false),
    elevatedButtonTheme: _elevatedButtonTheme(isDark: false),
    filledButtonTheme: _filledButtonTheme(isDark: false),
    outlinedButtonTheme: _outlinedButtonTheme(isDark: false),
    textButtonTheme: _textButtonTheme(isDark: false),
  );

  static TextTheme _textTheme(Color color) {
    return TextTheme(
      displayLarge: TextStyle(
        color: color,
        fontSize: 48,
        fontWeight: FontWeight.bold,
        height: 1,
      ),
      displayMedium: TextStyle(
        color: color,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        height: 1,
      ),
      headlineLarge: TextStyle(
        color: color,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        height: 1,
      ),
      headlineMedium: TextStyle(
        color: color,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        height: 1.05,
      ),
      headlineSmall: TextStyle(
        color: color,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        height: 1.1,
      ),
      titleLarge: TextStyle(
        color: color,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        height: 1.15,
      ),
      titleMedium: TextStyle(
        color: color,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        height: 1.2,
      ),
      titleSmall: TextStyle(
        color: color,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
      bodyLarge: TextStyle(
        color: color,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.35,
      ),
      bodyMedium: TextStyle(
        color: color,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.35,
      ),
      bodySmall: TextStyle(
        color: color,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.3,
      ),
      labelLarge: TextStyle(
        color: color,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
      labelMedium: TextStyle(
        color: color,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
      labelSmall: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
    );
  }

  static InputDecorationThemeData _inputDecorationTheme({
    required bool isDark,
  }) {
    final textColor = isDark
        ? AppColors.appPrimaryWhite
        : AppColors.appPrimaryBlack;
    final hintColor = isDark ? Colors.white38 : Colors.black38;

    return InputDecorationThemeData(
      hintStyle: TextStyle(
        color: hintColor,
        fontSize: 16,
        fontWeight: FontWeight.w300,
      ),
      labelStyle: TextStyle(
        color: hintColor,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      helperStyle: TextStyle(
        color: hintColor,
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      errorStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
      counterStyle: TextStyle(
        color: hintColor,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      prefixStyle: TextStyle(
        color: textColor,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      suffixStyle: TextStyle(
        color: textColor,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  static SnackBarThemeData _snackBarTheme({required bool isDark}) {
    return SnackBarThemeData(
      contentTextStyle: TextStyle(
        color: isDark ? AppColors.appPrimaryBlack : AppColors.appPrimaryWhite,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.25,
      ),
    );
  }

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
          return isDark ? AppColors.appPrimaryWhite : AppColors.appPrimaryBlack;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return isDark ? Colors.white38 : Colors.black38;
          }
          return isDark ? AppColors.appPrimaryBlack : AppColors.appPrimaryWhite;
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
          TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.2),
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
          return isDark ? AppColors.appPrimaryWhite : AppColors.appPrimaryBlack;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return isDark ? Colors.white38 : Colors.black38;
          }
          return isDark ? AppColors.appPrimaryBlack : AppColors.appPrimaryWhite;
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
          TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.2),
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
          TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.2),
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
          TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.2),
        ),
      ),
    );
  }
}
