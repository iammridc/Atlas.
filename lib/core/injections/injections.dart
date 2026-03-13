import 'package:atlas/core/theme/cubit/theme_cubit.dart';
import 'package:atlas/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:atlas/features/auth/data/repo_impls/AuthRepositoryImpl.dart';
import 'package:atlas/features/auth/domain/repositories/auth_repository.dart';
import 'package:atlas/features/auth/domain/usecases/signin_usecase.dart';
import 'package:atlas/features/auth/domain/usecases/signup_usecase.dart';
import 'package:atlas/features/auth/domain/usecases/signout_usecase.dart';
import 'package:atlas/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:atlas/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:atlas/features/splash/presentation/bloc/splash_cubit.dart';
import 'package:atlas/core/router/app_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Firebase
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );

  // Router
  getIt.registerLazySingleton<AppRouter>(() => AppRouter());

  // Theme
  getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit());
  // Datasource
  getIt.registerLazySingleton<AuthRemoteDatasource>(
    () => AuthRemoteDatasourceImpl(
      firebaseAuth: getIt<FirebaseAuth>(),
      firestore: getIt<FirebaseFirestore>(),
    ),
  );

  // Repository
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt<AuthRemoteDatasource>()),
  );

  // Usecases
  getIt.registerLazySingleton(() => SignInUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => SignUpUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => SignOutUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(
    () => GetCurrentUserUseCase(getIt<AuthRepository>()),
  );

  // Cubits
  getIt.registerFactory<AuthCubit>(
    () => AuthCubit(
      signInUseCase: getIt<SignInUseCase>(),
      signUpUseCase: getIt<SignUpUseCase>(),
      signOutUseCase: getIt<SignOutUseCase>(),
      getCurrentUserUseCase: getIt<GetCurrentUserUseCase>(),
    ),
  );
  getIt.registerFactory<SplashCubit>(() => SplashCubit());
}
