import 'dart:async';
import 'dart:convert';

import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/core/injections/injections.dart';
import 'package:atlas/core/utils/app_snackbar.dart';
import 'package:atlas/core/utils/google_places_photo.dart';
import 'package:atlas/features/place_details/presentation/pages/place_details_page.dart';
import 'package:atlas/features/profile/domain/entities/profile_review_entity.dart';
import 'package:atlas/features/profile/domain/repositories/profile_repository.dart';
import 'package:atlas/features/profile/domain/services/profile_reviews_sync_service.dart';
import 'package:atlas/features/profile/presentation/pages/favorite_places_page.dart';
import 'package:atlas/features/profile/presentation/pages/review_editor_page.dart';
import 'package:atlas/features/profile/presentation/widgets/profile_page_header.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProfileReviewsPage extends StatefulWidget {
  const ProfileReviewsPage({super.key});

  @override
  State<ProfileReviewsPage> createState() => _ProfileReviewsPageState();
}

class _ProfileReviewsPageState extends State<ProfileReviewsPage> {
  final _repository = getIt<ProfileRepository>();
  StreamSubscription<int>? _profileReviewsSubscription;
  bool _isLoading = true;
  String? _errorMessage;
  List<ProfileReviewEntity> _reviews = const [];

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _profileReviewsSubscription = getIt<ProfileReviewsSyncService>().changes
        .listen((_) {
          if (!mounted) return;
          _loadReviews(showLoader: false);
        });
  }

  @override
  void dispose() {
    _profileReviewsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadReviews({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _errorMessage = null;
      });
    }

    final result = await _repository.getProfileReviews();
    if (!mounted) return;

    result.fold(
      (error) => setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      }),
      (reviews) => setState(() {
        _isLoading = false;
        _reviews = reviews;
      }),
    );
  }

  Future<void> _showReviewForm({ProfileReviewEntity? review}) async {
    final result = await Navigator.of(context).push<ReviewEditorResult>(
      MaterialPageRoute(
        builder: (_) => ReviewEditorPage(
          title: review == null ? 'Add review' : 'Edit review',
          initialPlaceName: review?.placeName ?? '',
          allowPlaceNameEditing: true,
          initialRating: review?.rating.round() ?? 4,
          initialText: review?.text ?? '',
          initialPhotoDataUrls: review?.photoDataUrls ?? const [],
          placeSubtitle: [
            review?.placeCity ?? '',
            review?.placeCountry ?? '',
          ].where((part) => part.trim().isNotEmpty).join(', '),
        ),
      ),
    );

    if (result == null || !mounted) return;

    final saveResult = await _repository.saveProfileReview(
      ProfileReviewEntity(
        id: review?.id ?? '',
        placeId: review?.placeId ?? '',
        placeName: result.placeName,
        placeCity: review?.placeCity ?? '',
        placeCountry: review?.placeCountry ?? '',
        photoReference: review?.photoReference,
        rating: result.rating.toDouble(),
        text: result.text,
        photoDataUrls: result.photoDataUrls,
        createdAt: review?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    if (!mounted) return;
    saveResult.fold(
      (error) => AppSnackbar.show(
        context,
        message: error.message,
        type: SnackbarType.error,
      ),
      (_) {
        getIt<ProfileReviewsSyncService>().notifyChanged();
        AppSnackbar.show(
          context,
          message: review == null ? 'Review added.' : 'Review updated.',
          type: SnackbarType.success,
        );
      },
    );
  }

  Future<void> _openReviewedPlace(ProfileReviewEntity review) async {
    if (review.placeId.trim().isEmpty) {
      await _showReviewForm(review: review);
      return;
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlaceDetailsPage(
          placeId: review.placeId,
          placeName: review.placeName,
          city: review.placeCity,
          country: review.placeCountry,
          photoReference: review.photoReference,
          openUserReviewOnLoad: true,
        ),
      ),
    );
  }

  Future<void> _deleteReview(ProfileReviewEntity review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete review?'),
          content: Text('Remove your review for "${review.placeName}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final result = await _repository.deleteProfileReview(review);
    if (!mounted) return;

    result.fold(
      (error) => AppSnackbar.show(
        context,
        message: error.message,
        type: SnackbarType.error,
      ),
      (_) async {
        getIt<ProfileReviewsSyncService>().notifyChanged();
        if (!mounted) return;
        AppSnackbar.show(
          context,
          message: 'Review deleted.',
          type: SnackbarType.success,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ProfilePageHeader(title: 'Reviews'),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadReviews,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? ProfileCollectionErrorState(message: _errorMessage!)
                    : _reviews.isEmpty
                    ? const ProfileCollectionEmptyState(
                        title: 'No reviews yet',
                        message:
                            'Create and edit your own saved reviews here whenever you want.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                        itemCount: _reviews.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final review = _reviews[index];
                          return _ReviewedPlaceCard(
                            review: review,
                            onTap: () => _openReviewedPlace(review),
                            onDelete: () => _deleteReview(review),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewedPlaceCard extends StatelessWidget {
  final ProfileReviewEntity review;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ReviewedPlaceCard({
    required this.review,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final imageProvider = _imageProvider(review.photoDataUrls);
    final photoReference = review.photoReference?.trim();
    final hasPlacePhoto = photoReference != null && photoReference.isNotEmpty;
    final hasImage = imageProvider != null || hasPlacePhoto;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = hasImage
        ? Colors.white
        : (isDark ? AppColors.appPrimaryWhite : AppColors.appPrimaryBlack);
    final subtitleColor = hasImage
        ? Colors.white.withValues(alpha: 0.82)
        : (isDark ? Colors.white60 : Colors.black54);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: SizedBox(
          height: 118,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageProvider != null)
                Image(image: imageProvider, fit: BoxFit.cover)
              else if (hasPlacePhoto)
                Image.network(
                  buildGooglePlacePhotoUrl(photoReference, maxWidthPx: 1200),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      _ReviewedPlacePlaceholder(isDark: isDark),
                )
              else
                _ReviewedPlacePlaceholder(isDark: isDark),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: hasImage
                        ? LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.black.withValues(alpha: 0.78),
                              Colors.black.withValues(alpha: 0.44),
                              Colors.black.withValues(alpha: 0.12),
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          )
                        : null,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Row(
                  children: [
                    _RatingPill(rating: review.rating, onImage: hasImage),
                    const SizedBox(width: 8),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onDelete,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasImage
                              ? Colors.black.withValues(alpha: 0.38)
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.07)),
                        ),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: hasImage
                              ? Colors.white
                              : (isDark
                                    ? AppColors.appPrimaryWhite
                                    : AppColors.appPrimaryBlack),
                          size: 19,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 16,
                right: 18,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      review.placeName.isEmpty
                          ? 'Unnamed place'
                          : review.placeName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ).copyWith(color: titleColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _buildLocationLabel(review),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider<Object>? _imageProvider(List<String> values) {
    for (final value in values) {
      final normalized = value.trim();
      if (normalized.isEmpty) continue;

      final payload = normalized.startsWith('data:image')
          ? normalized.split(',').last
          : normalized;

      try {
        return MemoryImage(base64Decode(payload));
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  String _buildLocationLabel(ProfileReviewEntity review) {
    final parts = [
      review.placeCity,
      review.placeCountry,
    ].map((part) => part.trim()).where((part) => part.isNotEmpty).toList();

    if (parts.isNotEmpty) return parts.join(', ');
    return review.placeId.trim().isEmpty
        ? 'Tap to edit this review'
        : 'Open reviews for this place';
  }
}

class _RatingPill extends StatelessWidget {
  final double rating;
  final bool onImage;

  const _RatingPill({required this.rating, required this.onImage});

  @override
  Widget build(BuildContext context) {
    final normalizedRating = rating.round().clamp(1, 5);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foregroundColor = onImage
        ? Colors.white
        : (isDark ? AppColors.appPrimaryWhite : AppColors.appPrimaryBlack);

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: onImage
            ? Colors.black.withValues(alpha: 0.38)
            : (isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.07)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.star_fill, color: foregroundColor, size: 15),
          const SizedBox(width: 5),
          Text(
            '$normalizedRating',
            style: TextStyle(
              color: foregroundColor,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewedPlacePlaceholder extends StatelessWidget {
  final bool isDark;

  const _ReviewedPlacePlaceholder({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.045),
      ),
    );
  }
}
