import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/core/utils/relative_time.dart';
import 'package:atlas/features/place_details/domain/entities/place_review_entity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PlaceReviewCard extends StatelessWidget {
  final PlaceReviewEntity review;
  final bool compact;
  final bool showRating;
  final bool showSubtitle;

  const PlaceReviewCard({
    super.key,
    required this.review,
    this.compact = false,
    this.showRating = true,
    this.showSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = isDark ? Colors.white54 : Colors.black45;
    final emphasisColor = isDark
        ? AppColors.appPrimaryWhite
        : AppColors.appPrimaryBlack;
    final subtitleParts = [
      if ((review.authorSubtitle ?? '').isNotEmpty) review.authorSubtitle!,
      if ((review.relativeTimeDescription ?? '').isNotEmpty)
        review.relativeTimeDescription!
      else if (review.publishedAt != null)
        formatRelativeTime(review.publishedAt!),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 18 : 16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: compact ? 0.12 : 0.07)
            : Colors.black.withValues(alpha: compact ? 0.06 : 0.04),
        borderRadius: BorderRadius.circular(compact ? 28 : 24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(imageUrl: review.profilePhotoUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName,
                      style: TextStyle(
                        fontSize: compact ? 16 : 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (showSubtitle && subtitleParts.isNotEmpty)
                      Text(
                        subtitleParts.join(' • '),
                        style: TextStyle(
                          fontSize: compact ? 12 : 13,
                          color: subtitleColor,
                          height: 1.2,
                        ),
                      ),
                  ],
                ),
              ),
              if (showRating) ...[
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.star_fill,
                      size: 16,
                      color: emphasisColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      review.rating.toStringAsFixed(
                        review.rating % 1 == 0 ? 0 : 1,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.text,
            style: TextStyle(
              fontSize: compact ? 14 : 15,
              height: 1.45,
              color: isDark
                  ? AppColors.appPrimaryWhite
                  : AppColors.appPrimaryBlack,
            ),
            maxLines: compact ? 3 : null,
            overflow: compact ? TextOverflow.ellipsis : TextOverflow.visible,
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? imageUrl;

  const _Avatar({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(radius: 22, backgroundImage: NetworkImage(imageUrl!));
    }

    return const CircleAvatar(
      radius: 22,
      backgroundColor: Colors.transparent,
      child: Icon(CupertinoIcons.person_crop_circle, size: 34),
    );
  }
}
