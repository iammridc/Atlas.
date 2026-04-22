import 'package:auto_route/auto_route.dart';
import 'package:atlas/features/splash/presentation/pages/splash_page.dart';
import 'package:atlas/features/auth/presentation/pages/signin_page.dart';
import 'package:atlas/features/auth/presentation/pages/signup_page.dart';
import 'package:atlas/features/home/presentation/pages/home_page.dart';
import 'package:atlas/features/place_details/presentation/pages/place_details_page.dart';
import 'package:atlas/features/preferences/presentation/pages/preferences_page.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: SplashRoute.page, initial: true),
    AutoRoute(page: SigninRoute.page),
    AutoRoute(page: SignupRoute.page),
    AutoRoute(page: HomeRoute.page),
    AutoRoute(page: PlaceDetailsRoute.page),
    AutoRoute(page: PreferencesRoute.page),
  ];
}
