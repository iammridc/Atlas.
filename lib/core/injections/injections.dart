import 'package:atlas/core/theme/cubit/theme_cubit.dart';
import 'package:atlas/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:atlas/features/auth/data/repo_impls/AuthRepositoryImpl.dart';
import 'package:atlas/features/auth/domain/repositories/auth_repository.dart';
import 'package:atlas/features/auth/domain/usecases/signin_usecase.dart';
import 'package:atlas/features/auth/domain/usecases/signup_usecase.dart';
import 'package:atlas/features/auth/domain/usecases/signout_usecase.dart';
import 'package:atlas/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:atlas/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:atlas/features/preferences/data/datasources/preferences_remote_datasource.dart';
import 'package:atlas/features/preferences/data/repo_impls/preferences_repo_impl.dart';
import 'package:atlas/features/preferences/domain/repositories/preferences_repository.dart';
import 'package:atlas/features/preferences/domain/usecases/get_categories_usecase.dart';
import 'package:atlas/features/preferences/domain/usecases/has_preferences.dart';
import 'package:atlas/features/preferences/domain/usecases/save_preferences_usecase.dart';
import 'package:atlas/features/preferences/presentation/bloc/preferences_cubit.dart';
import 'package:atlas/features/home/data/datasources/recommendations_remote_datasource.dart';
import 'package:atlas/features/home/data/repo_impls/recommendations_repository_impl.dart';
import 'package:atlas/features/home/domain/repositories/recommendations_repository.dart';
import 'package:atlas/features/home/domain/usecases/get_recommendations_usecase.dart';
import 'package:atlas/features/home/presentation/bloc/recommendation_cubit.dart';
import 'package:atlas/features/home/domain/usecases/search_places_usecase.dart';
import 'package:atlas/features/home/presentation/bloc/search_places_cubit.dart';
import 'package:atlas/features/place_details/data/datasources/place_details_remote_datasource.dart';
import 'package:atlas/features/place_details/data/repo_impls/place_details_repository_impl.dart';
import 'package:atlas/features/place_details/domain/repositories/place_details_repository.dart';
import 'package:atlas/features/place_details/domain/usecases/get_place_community_reviews_usecase.dart';
import 'package:atlas/features/place_details/domain/usecases/get_place_details_usecase.dart';
import 'package:atlas/features/place_details/presentation/bloc/place_details_cubit.dart';
import 'package:atlas/features/splash/presentation/bloc/splash_cubit.dart';
import 'package:atlas/core/router/app_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );

  getIt.registerLazySingleton<Dio>(() => Dio());

  getIt.registerLazySingleton<AppRouter>(() => AppRouter());

  getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit());

  getIt.registerLazySingleton<AuthRemoteDatasource>(
    () => AuthRemoteDatasourceImpl(
      firebaseAuth: getIt<FirebaseAuth>(),
      firestore: getIt<FirebaseFirestore>(),
    ),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt<AuthRemoteDatasource>()),
  );
  getIt.registerLazySingleton(() => SignInUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => SignUpUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => SignOutUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(
    () => GetCurrentUserUseCase(getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton<PreferencesRemoteDatasource>(
    () => InterestsRemoteDatasourceImpl(getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton<PreferencesRepository>(
    () => PreferencesRepositoryImpl(getIt<PreferencesRemoteDatasource>()),
  );
  getIt.registerLazySingleton(
    () => GetCategoriesUseCase(getIt<PreferencesRepository>()),
  );
  getIt.registerLazySingleton(
    () => SavePreferencesUseCase(getIt<PreferencesRepository>()),
  );
  getIt.registerLazySingleton(
    () => HasPreferencesUseCase(getIt<PreferencesRepository>()),
  );
  getIt.registerFactory<PreferencesCubit>(
    () => PreferencesCubit(
      getCategoriesUseCase: getIt<GetCategoriesUseCase>(),
      savePreferencesUseCase: getIt<SavePreferencesUseCase>(),
    ),
  );

  getIt.registerLazySingleton<AuthCubit>(
    () => AuthCubit(
      signInUseCase: getIt<SignInUseCase>(),
      signUpUseCase: getIt<SignUpUseCase>(),
      signOutUseCase: getIt<SignOutUseCase>(),
      getCurrentUserUseCase: getIt<GetCurrentUserUseCase>(),
      hasPreferencesUseCase: getIt<HasPreferencesUseCase>(),
    ),
  );

  getIt.registerLazySingleton<RecommendationsRemoteDatasource>(
    () => RecommendationsRemoteDatasourceImpl(dio: getIt<Dio>()),
  );
  getIt.registerLazySingleton<RecommendationsRepository>(
    () =>
        RecommendationsRepositoryImpl(getIt<RecommendationsRemoteDatasource>()),
  );
  getIt.registerLazySingleton(
    () => GetRecommendationsUseCase(getIt<RecommendationsRepository>()),
  );
  getIt.registerLazySingleton(
    () => SearchPlacesUseCase(getIt<RecommendationsRepository>()),
  );
  getIt.registerFactory<RecommendationsCubit>(
    () => RecommendationsCubit(
      getRecommendations: getIt<GetRecommendationsUseCase>(),
    ),
  );
  getIt.registerFactory<SearchPlacesCubit>(
    () => SearchPlacesCubit(searchPlaces: getIt<SearchPlacesUseCase>()),
  );

  getIt.registerLazySingleton<PlaceDetailsRemoteDatasource>(
    () => PlaceDetailsRemoteDatasourceImpl(
      dio: getIt<Dio>(),
      firestore: getIt<FirebaseFirestore>(),
    ),
  );
  getIt.registerLazySingleton<PlaceDetailsRepository>(
    () => PlaceDetailsRepositoryImpl(getIt<PlaceDetailsRemoteDatasource>()),
  );
  getIt.registerLazySingleton(
    () => GetPlaceDetailsUseCase(getIt<PlaceDetailsRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetPlaceCommunityReviewsUseCase(getIt<PlaceDetailsRepository>()),
  );
  getIt.registerFactory<PlaceDetailsCubit>(
    () => PlaceDetailsCubit(
      getPlaceDetailsUseCase: getIt<GetPlaceDetailsUseCase>(),
      getPlaceCommunityReviewsUseCase: getIt<GetPlaceCommunityReviewsUseCase>(),
    ),
  );

  getIt.registerFactory<SplashCubit>(() => SplashCubit());
}
