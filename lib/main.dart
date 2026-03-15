import 'package:atlas/core/services/categories_services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:atlas/core/injections/injections.dart';
import 'package:atlas/core/router/app_router.dart';
import 'package:atlas/core/theme/app_theme.dart';
import 'package:atlas/core/theme/cubit/theme_cubit.dart';
import 'package:atlas/firebase_options.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await CategoriesService.seedIfNeeded();
  await configureDependencies();
  await getIt<ThemeCubit>().loadGuestTheme();

  FlutterNativeSplash.remove();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appRouter = AppRouter();

    return BlocProvider.value(
      value: getIt<ThemeCubit>(),
      child: BlocBuilder<ThemeCubit, AppThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'Atlas',
            routerConfig: appRouter.config(),
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: switch (themeMode) {
              AppThemeMode.light => ThemeMode.light,
              AppThemeMode.dark => ThemeMode.dark,
              AppThemeMode.system => ThemeMode.system,
            },
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(1.0)),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
