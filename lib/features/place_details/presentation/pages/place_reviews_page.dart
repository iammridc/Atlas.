import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/core/localization/app_localizations.dart';
import 'package:atlas/core/utils/app_snackbar.dart';
import 'package:atlas/features/place_details/domain/entities/place_review_entity.dart';
import 'package:atlas/features/place_details/presentation/bloc/place_details_cubit.dart';
import 'package:atlas/features/place_details/presentation/bloc/place_details_state.dart';
import 'package:atlas/features/place_details/presentation/widgets/place_review_card.dart';
import 'package:atlas/features/profile/presentation/pages/review_editor_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PlaceReviewsPage extends StatelessWidget {
  const PlaceReviewsPage({super.key});

  Future<void> _showReviewSheet(
    BuildContext context,
    PlaceDetailsLoaded state,
  ) async {
    final cubit = context.read<PlaceDetailsCubit>();
    final existingReview = state.currentUserReview;
    final result = await Navigator.of(context).push<ReviewEditorResult>(
      MaterialPageRoute(
        builder: (_) => ReviewEditorPage(
          title: existingReview == null
              ? context.l10n.t('addReview')
              : context.l10n.t('editReview'),
          initialPlaceName: state.place.name,
          allowPlaceNameEditing: false,
          initialRating: existingReview?.rating.round() ?? 4,
          initialText: existingReview?.text ?? '',
          initialPhotoDataUrls: existingReview?.photoDataUrls ?? const [],
          placeSubtitle: [
            state.place.city,
            state.place.country,
          ].where((part) => part.trim().isNotEmpty).join(', '),
          photoReference: state.place.photoNames.isEmpty
              ? null
              : state.place.photoNames.first,
        ),
      ),
    );

    if (result == null || !context.mounted) return;

    final error = await cubit.saveCurrentUserReview(
      rating: result.rating.toDouble(),
      text: result.text,
      photoDataUrls: result.photoDataUrls,
    );
    if (!context.mounted) return;

    if (error != null) {
      AppSnackbar.show(context, message: error, type: SnackbarType.error);
      return;
    }

    await cubit.refreshReviews();
    if (!context.mounted) return;

    AppSnackbar.show(
      context,
      message: existingReview == null
          ? context.l10n.t('reviewAdded')
          : context.l10n.t('reviewUpdated'),
      type: SnackbarType.success,
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
        child: BlocBuilder<PlaceDetailsCubit, PlaceDetailsState>(
          builder: (context, state) {
            if (state is! PlaceDetailsLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            final reviews = state.allReviews;

            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              children: [
                _Header(
                  onActionTap: () => _showReviewSheet(context, state),
                  hasCurrentUserReview: state.hasCurrentUserReview,
                ),
                const SizedBox(height: 16),
                _Section(
                  reviews: reviews,
                  emptyMessage: context.l10n.t('noReviewsAvailable'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onActionTap;
  final bool hasCurrentUserReview;

  const _Header({
    required this.onActionTap,
    required this.hasCurrentUserReview,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emphasisColor = isDark
        ? AppColors.appPrimaryWhite
        : AppColors.appPrimaryBlack;

    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const _HeaderIcon(CupertinoIcons.arrow_left),
            ),
          ),
          Text(
            context.l10n.t('reviews'),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: emphasisColor,
              height: 1,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onActionTap,
              child: _HeaderIcon(
                hasCurrentUserReview
                    ? CupertinoIcons.pencil
                    : CupertinoIcons.add,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;

  const _HeaderIcon(this.icon);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        color: isDark ? AppColors.appPrimaryWhite : AppColors.appPrimaryBlack,
        size: 22,
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final List<PlaceReviewEntity> reviews;
  final String emptyMessage;

  const _Section({required this.reviews, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              emptyMessage,
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black45,
                height: 1.45,
              ),
            ),
          )
        else
          Column(
            children: reviews
                .map(
                  (review) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PlaceReviewCard(review: review),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}
