import 'package:atlas/core/errors/app_exception.dart';
import 'package:atlas/features/profile/data/models/favorite_place_model.dart';
import 'package:atlas/features/profile/data/models/planned_trip_model.dart';
import 'package:atlas/features/profile/data/models/profile_review_model.dart';
import 'package:atlas/features/profile/data/models/profile_summary_model.dart';
import 'package:atlas/features/profile/domain/entities/favorite_place_entity.dart';
import 'package:atlas/features/profile/domain/entities/planned_trip_entity.dart';
import 'package:atlas/features/profile/domain/entities/profile_review_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ProfileRemoteDatasource {
  Future<ProfileSummaryModel> getProfileSummary();
  Future<void> updateUsername(String username);
  Future<void> updateAvatar(String? avatarUrl);
  Future<bool> isFavoritePlace(String id);
  Future<List<FavoritePlaceModel>> getFavoritePlaces();
  Future<FavoritePlaceModel> saveFavoritePlace(FavoritePlaceEntity place);
  Future<void> deleteFavoritePlace(String id);
  Future<List<ProfileReviewModel>> getProfileReviews();
  Future<ProfileReviewModel?> getProfileReviewForPlace(String placeId);
  Future<ProfileReviewModel> saveProfileReview(ProfileReviewEntity review);
  Future<void> deleteProfileReview(ProfileReviewEntity review);
  Future<void> setReviewsPublic(bool isPublic);
  Future<List<PlannedTripModel>> getPlannedTrips();
  Future<PlannedTripModel> savePlannedTrip(PlannedTripEntity trip);
  Future<void> deletePlannedTrip(String id);
}

class ProfileRemoteDatasourceImpl implements ProfileRemoteDatasource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  ProfileRemoteDatasourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth firebaseAuth,
  }) : _firestore = firestore,
       _firebaseAuth = firebaseAuth;

  User get _currentUser {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const ServerException(message: 'Please sign in again.');
    }
    return user;
  }

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(_currentUser.uid);

  CollectionReference<Map<String, dynamic>> get _favoritePlacesCollection =>
      _userDoc.collection('favorite_places');

  CollectionReference<Map<String, dynamic>> get _reviewsCollection =>
      _userDoc.collection('reviews');

  CollectionReference<Map<String, dynamic>> get _plannedTripsCollection =>
      _userDoc.collection('planned_trips');

  CollectionReference<Map<String, dynamic>> get _hotAtlasLikesCollection =>
      _firestore.collection('hot_atlas_likes');

  CollectionReference<Map<String, dynamic>> _placeReviewsCollection(
    String placeId,
  ) => _firestore.collection('places').doc(placeId).collection('reviews');

  Future<void> _ensureUserDoc() async {
    final user = _currentUser;
    final email = user.email ?? '';
    final fallbackUsername = email.isEmpty
        ? 'Atlas Traveler'
        : email.split('@').first;
    final snapshot = await _userDoc.get();
    if (snapshot.exists) return;

    await _userDoc.set({
      'id': user.uid,
      'email': email,
      'username': user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : fallbackUsername,
      'avatarUrl': user.photoURL,
      'preferences': const <String>[],
      'likedPlaces': const <String>[],
      'createdRoutes': const <String>[],
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<ProfileSummaryModel> getProfileSummary() async {
    try {
      await _ensureUserDoc();
      final user = _currentUser;

      final results = await Future.wait([
        _userDoc.get(),
        _favoritePlacesCollection.get(),
        _reviewsCollection.get(),
        _plannedTripsCollection.get(),
      ]);

      final userSnapshot = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final favoriteSnapshot =
          results[1] as QuerySnapshot<Map<String, dynamic>>;
      final reviewSnapshot = results[2] as QuerySnapshot<Map<String, dynamic>>;
      final tripSnapshot = results[3] as QuerySnapshot<Map<String, dynamic>>;

      return ProfileSummaryModel.fromJson(
        userSnapshot.data() ?? const <String, dynamic>{},
        userId: user.uid,
        email: user.email ?? '',
        favoritePlacesCount: favoriteSnapshot.docs.length,
        reviewsCount: reviewSnapshot.docs.length,
        plannedTripsCount: tripSnapshot.docs.length,
      );
    } on AppException {
      rethrow;
    } catch (_) {
      throw const ServerException(message: 'Failed to load your profile.');
    }
  }

  @override
  Future<void> updateUsername(String username) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty) {
      throw const ServerException(message: 'Username cannot be empty.');
    }

    try {
      await _ensureUserDoc();
      await _userDoc.set({'username': trimmed}, SetOptions(merge: true));
      await _currentUser.updateDisplayName(trimmed);
      await _syncCommunityReviewAuthor({'authorName': trimmed});
    } on AppException {
      rethrow;
    } catch (_) {
      throw const ServerException(message: 'Failed to update username.');
    }
  }

  @override
  Future<void> updateAvatar(String? avatarUrl) async {
    try {
      await _ensureUserDoc();
      await _userDoc.set({'avatarUrl': avatarUrl}, SetOptions(merge: true));
      await _syncCommunityReviewAuthor({'profilePhotoUrl': avatarUrl});
    } on AppException {
      rethrow;
    } catch (_) {
      throw const ServerException(message: 'Failed to update avatar.');
    }
  }

  @override
  Future<List<FavoritePlaceModel>> getFavoritePlaces() async {
    try {
      await _ensureUserDoc();
      final snapshot = await _favoritePlacesCollection
          .orderBy('savedAt', descending: true)
          .get();

      return snapshot.docs.map(FavoritePlaceModel.fromFirestore).toList();
    } on AppException {
      rethrow;
    } catch (_) {
      throw const ServerException(message: 'Failed to load favourite places.');
    }
  }

  @override
  Future<bool> isFavoritePlace(String id) async {
    try {
      await _ensureUserDoc();
      final snapshot = await _favoritePlacesCollection.doc(id).get();
      return snapshot.exists;
    } on AppException {
      rethrow;
    } catch (_) {
      throw const ServerException(message: 'Failed to check favourite status.');
    }
  }

  @override
  Future<FavoritePlaceModel> saveFavoritePlace(
    FavoritePlaceEntity place,
  ) async {
    final trimmedName = place.name.trim();
    final trimmedLocation = place.location.trim();

    if (trimmedName.isEmpty || trimmedLocation.isEmpty) {
      throw const ServerException(
        message: 'Place name and location are required.',
      );
    }

    try {
      await _ensureUserDoc();
      final doc = place.id.isEmpty
          ? _favoritePlacesCollection.doc()
          : _favoritePlacesCollection.doc(place.id);

      final model = FavoritePlaceModel(
        id: doc.id,
        name: trimmedName,
        location: trimmedLocation,
        city: place.city.trim(),
        country: place.country.trim(),
        photoReference: place.photoReference?.trim(),
        note: place.note.trim(),
        savedAt: DateTime.now(),
      );

      await doc.set(model.toJson(), SetOptions(merge: true));
      await _hotAtlasLikesCollection.doc('${_currentUser.uid}_${doc.id}').set({
        'placeId': doc.id,
        'likedByUserId': _currentUser.uid,
        'likedAt': model.savedAt,
        'name': model.name,
        'location': model.location,
        'city': model.city,
        'country': model.country,
        'photoReference': model.photoReference,
      }, SetOptions(merge: true));
      await _userDoc.set({
        'likedPlaces': FieldValue.arrayUnion([doc.id]),
      }, SetOptions(merge: true));

      return model;
    } on AppException {
      rethrow;
    } catch (_) {
      throw const ServerException(message: 'Failed to save favourite place.');
    }
  }

  @override
  Future<void> deleteFavoritePlace(String id) async {
    try {
      await _favoritePlacesCollection.doc(id).delete();
      await _hotAtlasLikesCollection.doc('${_currentUser.uid}_$id').delete();
      await _userDoc.set({
        'likedPlaces': FieldValue.arrayRemove([id]),
      }, SetOptions(merge: true));
    } catch (_) {
      throw const ServerException(message: 'Failed to delete favourite place.');
    }
  }

  @override
  Future<List<ProfileReviewModel>> getProfileReviews() async {
    try {
      await _ensureUserDoc();
      final snapshot = await _reviewsCollection
          .orderBy('updatedAt', descending: true)
          .get();

      return snapshot.docs.map(ProfileReviewModel.fromFirestore).toList();
    } on AppException {
      rethrow;
    } catch (_) {
      throw const ServerException(message: 'Failed to load reviews.');
    }
  }

  @override
  Future<ProfileReviewModel?> getProfileReviewForPlace(String placeId) async {
    try {
      await _ensureUserDoc();
      final snapshot = await _reviewsCollection.doc(placeId).get();
      if (!snapshot.exists) return null;
      return ProfileReviewModel.fromDocument(snapshot);
    } on AppException {
      rethrow;
    } catch (_) {
      throw const ServerException(message: 'Failed to load your review.');
    }
  }

  @override
  Future<ProfileReviewModel> saveProfileReview(
    ProfileReviewEntity review,
  ) async {
    final trimmedPlaceId = review.placeId.trim();
    final trimmedPlaceName = review.placeName.trim();
    final trimmedText = review.text.trim();

    if (trimmedPlaceName.isEmpty || trimmedText.isEmpty) {
      throw const ServerException(
        message: 'Place name and review text are required.',
      );
    }

    try {
      await _ensureUserDoc();
      final docId = review.id.isNotEmpty
          ? review.id
          : (trimmedPlaceId.isNotEmpty
                ? trimmedPlaceId
                : _reviewsCollection.doc().id);
      final doc = _reviewsCollection.doc(docId);
      final existingSnapshot = await doc.get();
      final existingReview = existingSnapshot.exists
          ? ProfileReviewModel.fromDocument(existingSnapshot)
          : null;
      final now = DateTime.now();

      final model = ProfileReviewModel(
        id: doc.id,
        placeId: trimmedPlaceId,
        placeName: trimmedPlaceName,
        placeCity: review.placeCity.trim(),
        placeCountry: review.placeCountry.trim(),
        rating: review.rating,
        text: trimmedText,
        createdAt: existingReview?.createdAt ?? review.createdAt,
        updatedAt: now,
      );

      await doc.set(model.toJson(), SetOptions(merge: true));
      if (trimmedPlaceId.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final isPublic = prefs.getBool('settings_public_reviews') ?? true;
        if (isPublic) {
          await _upsertPlaceReview(model);
        } else {
          await _placeReviewsCollection(
            trimmedPlaceId,
          ).doc(_currentUser.uid).delete();
        }
      }
      return model;
    } on AppException {
      rethrow;
    } catch (_) {
      throw const ServerException(message: 'Failed to save review.');
    }
  }

  @override
  Future<void> deleteProfileReview(ProfileReviewEntity review) async {
    try {
      await _reviewsCollection.doc(review.id).delete();
      final trimmedPlaceId = review.placeId.trim();
      if (trimmedPlaceId.isNotEmpty) {
        await _placeReviewsCollection(
          trimmedPlaceId,
        ).doc(_currentUser.uid).delete();
      }
    } catch (_) {
      throw const ServerException(message: 'Failed to delete review.');
    }
  }

  @override
  Future<void> setReviewsPublic(bool isPublic) async {
    try {
      await _ensureUserDoc();
      final snapshot = await _reviewsCollection.get();
      for (final doc in snapshot.docs) {
        final review = ProfileReviewModel.fromDocument(doc);
        final placeId = review.placeId.trim();
        if (placeId.isEmpty) continue;

        if (isPublic) {
          await _upsertPlaceReview(review);
        } else {
          await _placeReviewsCollection(placeId).doc(_currentUser.uid).delete();
        }
      }
    } on AppException {
      rethrow;
    } catch (_) {
      throw const ServerException(message: 'Failed to update review privacy.');
    }
  }

  Future<void> _upsertPlaceReview(ProfileReviewModel review) async {
    final user = _currentUser;
    final userSnapshot = await _userDoc.get();
    final userData = userSnapshot.data() ?? const <String, dynamic>{};
    final email = user.email ?? '';
    final fallbackName = email.isEmpty ? 'Traveler' : email.split('@').first;
    final authorName =
        (userData['username'] as String?)?.trim().isNotEmpty == true
        ? (userData['username'] as String).trim()
        : (user.displayName?.trim().isNotEmpty == true
              ? user.displayName!.trim()
              : fallbackName);
    final avatarUrl = userData.containsKey('avatarUrl')
        ? userData['avatarUrl'] as String?
        : user.photoURL;

    await _placeReviewsCollection(review.placeId).doc(user.uid).set({
      'userId': user.uid,
      'authorName': authorName,
      'authorSubtitle': FieldValue.delete(),
      'text': review.text.trim(),
      'rating': review.rating,
      'createdAt': review.createdAt,
      'updatedAt': review.updatedAt,
      'profilePhotoUrl': avatarUrl,
      'placeId': review.placeId,
      'placeName': review.placeName,
      'placeCity': review.placeCity,
      'placeCountry': review.placeCountry,
    }, SetOptions(merge: true));
  }

  Future<void> _syncCommunityReviewAuthor(Map<String, dynamic> data) async {
    final snapshot = await _reviewsCollection.get();
    final futures = snapshot.docs.map((doc) {
      final reviewData = doc.data();
      final placeId = (reviewData['placeId'] as String?)?.trim();
      if (placeId == null || placeId.isEmpty) return Future<void>.value();
      return _placeReviewsCollection(
        placeId,
      ).doc(_currentUser.uid).set(data, SetOptions(merge: true));
    });

    await Future.wait(futures);
  }

  @override
  Future<List<PlannedTripModel>> getPlannedTrips() async {
    try {
      await _ensureUserDoc();
      final snapshot = await _plannedTripsCollection
          .orderBy('updatedAt', descending: true)
          .get();

      return snapshot.docs.map(PlannedTripModel.fromFirestore).toList();
    } on AppException {
      rethrow;
    } catch (_) {
      throw const ServerException(message: 'Failed to load planned trips.');
    }
  }

  @override
  Future<PlannedTripModel> savePlannedTrip(PlannedTripEntity trip) async {
    final trimmedTitle = trip.title.trim();
    final trimmedRouteSummary = trip.routeSummary.trim();

    if (trimmedTitle.isEmpty || trimmedRouteSummary.isEmpty) {
      throw const ServerException(
        message: 'Trip title and route are required.',
      );
    }

    try {
      await _ensureUserDoc();
      final doc = trip.id.isEmpty
          ? _plannedTripsCollection.doc()
          : _plannedTripsCollection.doc(trip.id);

      final model = PlannedTripModel(
        id: doc.id,
        title: trimmedTitle,
        routeSummary: trimmedRouteSummary,
        note: trip.note.trim(),
        updatedAt: DateTime.now(),
        origin: trip.origin,
        destination: trip.destination,
        route: trip.route,
        selectedPointsOfInterest: trip.selectedPointsOfInterest,
        selectedHotels: trip.selectedHotels,
      );

      await doc.set(model.toJson(), SetOptions(merge: true));
      await _userDoc.set({
        'createdRoutes': FieldValue.arrayUnion([doc.id]),
      }, SetOptions(merge: true));

      return model;
    } on AppException {
      rethrow;
    } catch (_) {
      throw const ServerException(message: 'Failed to save planned trip.');
    }
  }

  @override
  Future<void> deletePlannedTrip(String id) async {
    try {
      await _plannedTripsCollection.doc(id).delete();
      await _userDoc.set({
        'createdRoutes': FieldValue.arrayRemove([id]),
      }, SetOptions(merge: true));
    } catch (_) {
      throw const ServerException(message: 'Failed to delete planned trip.');
    }
  }
}
