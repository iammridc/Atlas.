import 'package:atlas/features/splash/presentation/bloc/splash_cubit.dart';
import 'package:get_it/get_it.dart';
import '../router/app_router.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  getIt.registerLazySingleton<AppRouter>(() => AppRouter());
  getIt.registerFactory<SplashCubit>(() => SplashCubit());
}
