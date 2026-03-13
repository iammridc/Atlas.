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
  );
}
