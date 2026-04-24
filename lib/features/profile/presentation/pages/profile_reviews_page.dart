import 'dart:async';

import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/core/injections/injections.dart';
import 'package:atlas/core/utils/relative_time.dart';
import 'package:atlas/core/utils/app_snackbar.dart';
import 'package:atlas/features/profile/domain/entities/profile_review_entity.dart';
import 'package:atlas/features/profile/domain/repositories/profile_repository.dart';
import 'package:atlas/features/profile/domain/services/profile_reviews_sync_service.dart';
import 'package:atlas/features/profile/presentation/pages/favorite_places_page.dart';
import 'package:atlas/features/profile/presentation/pages/review_editor_page.dart';
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
        rating: result.rating.toDouble(),
        text: result.text,
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

  String _buildRatingLabel(double rating) {
    final normalizedRating = rating.round().clamp(1, 5);
    return '$normalizedRating / 5 stars';
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
      appBar: AppBar(title: const Text('Reviews')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showReviewForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add review'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadReviews,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? ProfileCollectionErrorState(
                message: _errorMessage!,
                onRetry: _loadReviews,
              )
            : _reviews.isEmpty
            ? const ProfileCollectionEmptyState(
                title: 'No reviews yet',
                message:
                    'Create and edit your own saved reviews here whenever you want.',
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                itemCount: _reviews.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final review = _reviews[index];
                  return ProfileManagementCard(
                    title: review.placeName,
                    subtitle: _buildRatingLabel(review.rating),
                    body: review.text,
                    trailing: formatRelativeTime(review.createdAt),
                    onTap: () => _showReviewForm(review: review),
                    onDelete: () => _deleteReview(review),
                  );
                },
              ),
      ),
    );
  }
}
