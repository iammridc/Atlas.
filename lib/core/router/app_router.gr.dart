// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [HomePage]
class HomeRoute extends PageRouteInfo<HomeRouteArgs> {
  HomeRoute({
    Key? key,
    required List<String> categoryTypes,
    List<PageRouteInfo>? children,
  }) : super(
         HomeRoute.name,
         args: HomeRouteArgs(key: key, categoryTypes: categoryTypes),
         initialChildren: children,
       );

  static const String name = 'HomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<HomeRouteArgs>();
      return HomePage(key: args.key, categoryTypes: args.categoryTypes);
    },
  );
}

class HomeRouteArgs {
  const HomeRouteArgs({this.key, required this.categoryTypes});

  final Key? key;

  final List<String> categoryTypes;

  @override
  String toString() {
    return 'HomeRouteArgs{key: $key, categoryTypes: $categoryTypes}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HomeRouteArgs) return false;
    return key == other.key &&
        const ListEquality<String>().equals(categoryTypes, other.categoryTypes);
  }

  @override
  int get hashCode =>
      key.hashCode ^ const ListEquality<String>().hash(categoryTypes);
}

/// generated route for
/// [PlaceDetailsPage]
class PlaceDetailsRoute extends PageRouteInfo<PlaceDetailsRouteArgs> {
  PlaceDetailsRoute({
    Key? key,
    required String placeId,
    required String placeName,
    required String city,
    required String country,
    String? photoReference,
    List<PageRouteInfo>? children,
  }) : super(
         PlaceDetailsRoute.name,
         args: PlaceDetailsRouteArgs(
           key: key,
           placeId: placeId,
           placeName: placeName,
           city: city,
           country: country,
           photoReference: photoReference,
         ),
         initialChildren: children,
       );

  static const String name = 'PlaceDetailsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PlaceDetailsRouteArgs>();
      return PlaceDetailsPage(
        key: args.key,
        placeId: args.placeId,
        placeName: args.placeName,
        city: args.city,
        country: args.country,
        photoReference: args.photoReference,
      );
    },
  );
}

class PlaceDetailsRouteArgs {
  const PlaceDetailsRouteArgs({
    this.key,
    required this.placeId,
    required this.placeName,
    required this.city,
    required this.country,
    this.photoReference,
  });

  final Key? key;

  final String placeId;

  final String placeName;

  final String city;

  final String country;

  final String? photoReference;

  @override
  String toString() {
    return 'PlaceDetailsRouteArgs{key: $key, placeId: $placeId, placeName: $placeName, city: $city, country: $country, photoReference: $photoReference}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PlaceDetailsRouteArgs) return false;
    return key == other.key &&
        placeId == other.placeId &&
        placeName == other.placeName &&
        city == other.city &&
        country == other.country &&
        photoReference == other.photoReference;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      placeId.hashCode ^
      placeName.hashCode ^
      city.hashCode ^
      country.hashCode ^
      photoReference.hashCode;
}

/// generated route for
/// [PreferencesPage]
class PreferencesRoute extends PageRouteInfo<PreferencesRouteArgs> {
  PreferencesRoute({
    Key? key,
    required String uid,
    bool replaceStackOnSave = true,
    bool showSkipAction = true,
    bool allowEmptySelection = false,
    List<String> initialSelectedCategoryIds = const [],
    List<PageRouteInfo>? children,
  }) : super(
         PreferencesRoute.name,
         args: PreferencesRouteArgs(
           key: key,
           uid: uid,
           replaceStackOnSave: replaceStackOnSave,
           showSkipAction: showSkipAction,
           allowEmptySelection: allowEmptySelection,
           initialSelectedCategoryIds: initialSelectedCategoryIds,
         ),
         initialChildren: children,
       );

  static const String name = 'PreferencesRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PreferencesRouteArgs>();
      return PreferencesPage(
        key: args.key,
        uid: args.uid,
        replaceStackOnSave: args.replaceStackOnSave,
        showSkipAction: args.showSkipAction,
        allowEmptySelection: args.allowEmptySelection,
        initialSelectedCategoryIds: args.initialSelectedCategoryIds,
      );
    },
  );
}

class PreferencesRouteArgs {
  const PreferencesRouteArgs({
    this.key,
    required this.uid,
    this.replaceStackOnSave = true,
    this.showSkipAction = true,
    this.allowEmptySelection = false,
    this.initialSelectedCategoryIds = const [],
  });

  final Key? key;

  final String uid;

  final bool replaceStackOnSave;

  final bool showSkipAction;

  final bool allowEmptySelection;

  final List<String> initialSelectedCategoryIds;

  @override
  String toString() {
    return 'PreferencesRouteArgs{key: $key, uid: $uid, replaceStackOnSave: $replaceStackOnSave, showSkipAction: $showSkipAction, allowEmptySelection: $allowEmptySelection, initialSelectedCategoryIds: $initialSelectedCategoryIds}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PreferencesRouteArgs) return false;
    return key == other.key &&
        uid == other.uid &&
        replaceStackOnSave == other.replaceStackOnSave &&
        showSkipAction == other.showSkipAction &&
        allowEmptySelection == other.allowEmptySelection &&
        const ListEquality<String>().equals(
          initialSelectedCategoryIds,
          other.initialSelectedCategoryIds,
        );
  }

  @override
  int get hashCode =>
      key.hashCode ^
      uid.hashCode ^
      replaceStackOnSave.hashCode ^
      showSkipAction.hashCode ^
      allowEmptySelection.hashCode ^
      const ListEquality<String>().hash(initialSelectedCategoryIds);
}

/// generated route for
/// [SigninPage]
class SigninRoute extends PageRouteInfo<void> {
  const SigninRoute({List<PageRouteInfo>? children})
    : super(SigninRoute.name, initialChildren: children);

  static const String name = 'SigninRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SigninPage();
    },
  );
}

/// generated route for
/// [SignupPage]
class SignupRoute extends PageRouteInfo<void> {
  const SignupRoute({List<PageRouteInfo>? children})
    : super(SignupRoute.name, initialChildren: children);

  static const String name = 'SignupRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SignupPage();
    },
  );
}

/// generated route for
/// [SplashPage]
class SplashRoute extends PageRouteInfo<void> {
  const SplashRoute({List<PageRouteInfo>? children})
    : super(SplashRoute.name, initialChildren: children);

  static const String name = 'SplashRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SplashPage();
    },
  );
}

/// generated route for
/// [TravelPlannerPage]
class TravelPlannerRoute extends PageRouteInfo<TravelPlannerRouteArgs> {
  TravelPlannerRoute({
    Key? key,
    required String placeId,
    required String placeName,
    required String address,
    required String city,
    required String country,
    required double latitude,
    required double longitude,
    String? photoReference,
    List<PageRouteInfo>? children,
  }) : super(
         TravelPlannerRoute.name,
         args: TravelPlannerRouteArgs(
           key: key,
           placeId: placeId,
           placeName: placeName,
           address: address,
           city: city,
           country: country,
           latitude: latitude,
           longitude: longitude,
           photoReference: photoReference,
         ),
         initialChildren: children,
       );

  static const String name = 'TravelPlannerRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TravelPlannerRouteArgs>();
      return TravelPlannerPage(
        key: args.key,
        placeId: args.placeId,
        placeName: args.placeName,
        address: args.address,
        city: args.city,
        country: args.country,
        latitude: args.latitude,
        longitude: args.longitude,
        photoReference: args.photoReference,
      );
    },
  );
}

class TravelPlannerRouteArgs {
  const TravelPlannerRouteArgs({
    this.key,
    required this.placeId,
    required this.placeName,
    required this.address,
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.photoReference,
  });

  final Key? key;

  final String placeId;

  final String placeName;

  final String address;

  final String city;

  final String country;

  final double latitude;

  final double longitude;

  final String? photoReference;

  @override
  String toString() {
    return 'TravelPlannerRouteArgs{key: $key, placeId: $placeId, placeName: $placeName, address: $address, city: $city, country: $country, latitude: $latitude, longitude: $longitude, photoReference: $photoReference}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TravelPlannerRouteArgs) return false;
    return key == other.key &&
        placeId == other.placeId &&
        placeName == other.placeName &&
        address == other.address &&
        city == other.city &&
        country == other.country &&
        latitude == other.latitude &&
        longitude == other.longitude &&
        photoReference == other.photoReference;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      placeId.hashCode ^
      placeName.hashCode ^
      address.hashCode ^
      city.hashCode ^
      country.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      photoReference.hashCode;
}
