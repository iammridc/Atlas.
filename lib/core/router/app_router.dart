import 'package:auto_route/auto_route.dart';
import 'package:atlas/features/splash/presentation/pages/splash_page.dart';
import 'package:atlas/features/auth/presentation/pages/signin_page.dart';
import 'package:atlas/features/home/presentation/pages/home_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: SplashRoute.page, initial: true),
    AutoRoute(page: SigninRoute.page),
    AutoRoute(page: HomeRoute.page),
  ];
}
