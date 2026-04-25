import 'package:atlas/core/theme/cubit/theme_cubit.dart';
import 'package:atlas/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:atlas/features/auth/data/repo_impls/AuthRepositoryImpl.dart';
import 'package:atlas/features/auth/domain/repositories/auth_repository.dart';
import 'package:atlas/features/auth/domain/usecases/signin_usecase.dart';
import 'package:atlas/features/auth/domain/usecases/signup_usecase.dart';
import 'package:atlas/features/auth/domain/usecases/signout_usecase.dart';
import 'package:atlas/features/auth/domain/usecases/delete_account_usecase.dart';
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
import 'package:atlas/features/travel_planner/data/datasources/travel_planner_remote_datasource.dart';
import 'package:atlas/features/travel_planner/data/repo_impls/travel_planner_repository_impl.dart';
import 'package:atlas/features/travel_planner/domain/entities/travel_location_entity.dart';
import 'package:atlas/features/travel_planner/domain/repositories/travel_planner_repository.dart';
import 'package:atlas/features/travel_planner/domain/usecases/build_travel_plan_usecase.dart';
import 'package:atlas/features/travel_planner/domain/usecases/search_travel_locations_usecase.dart';
import 'package:atlas/features/travel_planner/presentation/bloc/travel_planner_cubit.dart';
import 'package:atlas/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:atlas/features/profile/data/repo_impls/profile_repository_impl.dart';
import 'package:atlas/features/profile/domain/repositories/profile_repository.dart';
import 'package:atlas/features/profile/domain/services/favorite_places_sync_service.dart';
import 'package:atlas/features/profile/domain/services/profile_reviews_sync_service.dart';
import 'package:atlas/features/profile/presentation/bloc/profile_cubit.dart';
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
    () => DeleteAccountUseCase(getIt<AuthRepository>()),
  );
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
      deleteAccountUseCase: getIt<DeleteAccountUseCase>(),
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
    () => SearchPlacesCubit(
      searchPlaces: getIt<SearchPlacesUseCase>(),
      firebaseAuth: getIt<FirebaseAuth>(),
    ),
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
  getIt.registerLazySingleton<FavoritePlacesSyncService>(
    () => FavoritePlacesSyncService(),
  );
  getIt.registerLazySingleton<ProfileReviewsSyncService>(
    () => ProfileReviewsSyncService(),
  );
  getIt.registerFactory<PlaceDetailsCubit>(
    () => PlaceDetailsCubit(
      getPlaceDetailsUseCase: getIt<GetPlaceDetailsUseCase>(),
      getPlaceCommunityReviewsUseCase: getIt<GetPlaceCommunityReviewsUseCase>(),
      profileRepository: getIt<ProfileRepository>(),
      favoritePlacesSyncService: getIt<FavoritePlacesSyncService>(),
      profileReviewsSyncService: getIt<ProfileReviewsSyncService>(),
    ),
  );

  getIt.registerLazySingleton<TravelPlannerRemoteDatasource>(
    () => TravelPlannerRemoteDatasourceImpl(dio: getIt<Dio>()),
  );
  getIt.registerLazySingleton<TravelPlannerRepository>(
    () => TravelPlannerRepositoryImpl(getIt<TravelPlannerRemoteDatasource>()),
  );
  getIt.registerLazySingleton(
    () => BuildTravelPlanUseCase(getIt<TravelPlannerRepository>()),
  );
  getIt.registerLazySingleton(
    () => SearchTravelLocationsUseCase(getIt<TravelPlannerRepository>()),
  );
  getIt.registerFactoryParam<TravelPlannerCubit, TravelLocationEntity, void>(
    (destination, _) => TravelPlannerCubit(
      buildTravelPlan: getIt<BuildTravelPlanUseCase>(),
      searchLocations: getIt<SearchTravelLocationsUseCase>(),
      profileRepository: getIt<ProfileRepository>(),
      destination: destination,
    ),
  );

  getIt.registerLazySingleton<ProfileRemoteDatasource>(
    () => ProfileRemoteDatasourceImpl(
      firestore: getIt<FirebaseFirestore>(),
      firebaseAuth: getIt<FirebaseAuth>(),
    ),
  );
  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(getIt<ProfileRemoteDatasource>()),
  );
  getIt.registerFactory<ProfileCubit>(
    () => ProfileCubit(profileRepository: getIt<ProfileRepository>()),
  );

  getIt.registerFactory<SplashCubit>(() => SplashCubit());
}
