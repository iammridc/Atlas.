import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/features/place_details/domain/entities/place_review_entity.dart';
import 'package:atlas/features/place_details/presentation/widgets/place_review_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PlaceReviewsPreviewBlock extends StatelessWidget {
  final List<PlaceReviewEntity> previewReviews;
  final double? rating;
  final int totalReviewCount;
  final VoidCallback onTap;

  const PlaceReviewsPreviewBlock({
    super.key,
    required this.previewReviews,
    required this.totalReviewCount,
    required this.onTap,
    this.rating,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark ? Colors.white54 : Colors.black45;
    final emphasisColor = isDark
        ? AppColors.appPrimaryWhite
        : AppColors.appPrimaryBlack;
    final previewReview = previewReviews.isEmpty ? null : previewReviews.first;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$totalReviewCount Reviews',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const Spacer(),
              if (rating != null)
                Row(
                  children: [
                    Text(
                      rating!.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      CupertinoIcons.star_fill,
                      size: 28,
                      color: emphasisColor,
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (previewReview == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.09)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Text(
                'No reviews yet. This place will show Google reviews first and Atlas user reviews as they are added.',
                style: TextStyle(height: 1.45, color: secondaryColor),
              ),
            )
          else
            PlaceReviewCard(
              review: previewReview,
              compact: true,
              showRating: false,
              showSubtitle: false,
            ),
        ],
      ),
    );
  }
}
