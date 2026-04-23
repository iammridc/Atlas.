import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/core/injections/injections.dart';
import 'package:atlas/features/place_details/domain/entities/place_details_entity.dart';
import 'package:atlas/features/place_details/domain/entities/place_review_entity.dart';
import 'package:atlas/features/place_details/presentation/bloc/place_details_cubit.dart';
import 'package:atlas/features/place_details/presentation/bloc/place_details_state.dart';
import 'package:atlas/features/place_details/presentation/pages/place_reviews_page.dart';
import 'package:atlas/features/place_details/presentation/widgets/place_photo_gallery.dart';
import 'package:atlas/features/place_details/presentation/widgets/place_reviews_preview_block.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class PlaceDetailsPage extends StatelessWidget {
  final String placeId;
  final String placeName;
  final String city;
  final String country;
  final String? photoReference;

  const PlaceDetailsPage({
    super.key,
    required this.placeId,
    required this.placeName,
    required this.city,
    required this.country,
    this.photoReference,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PlaceDetailsCubit>()
        ..loadPlace(
          placeId: placeId,
          placeName: placeName,
          city: city,
          country: country,
          photoReference: photoReference,
        ),
      child: _PlaceDetailsView(
        placeId: placeId,
        placeName: placeName,
        city: city,
        country: country,
        photoReference: photoReference,
      ),
    );
  }
}

class _PlaceDetailsView extends StatelessWidget {
  final String placeId;
  final String placeName;
  final String city;
  final String country;
  final String? photoReference;

  const _PlaceDetailsView({
    required this.placeId,
    required this.placeName,
    required this.city,
    required this.country,
    this.photoReference,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: pageColor,
      body: BlocBuilder<PlaceDetailsCubit, PlaceDetailsState>(
        builder: (context, state) {
          if (state is PlaceDetailsLoading || state is PlaceDetailsInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PlaceDetailsError) {
            return SafeArea(
              child: _ErrorView(
                message: state.message,
                onRetry: () => context.read<PlaceDetailsCubit>().loadPlace(
                  placeId: placeId,
                  placeName: placeName,
                  city: city,
                  country: country,
                  photoReference: photoReference,
                ),
              ),
            );
          }

          final loadedState = state as PlaceDetailsLoaded;
          final place = loadedState.place;
          final previewReviews = _buildPreviewReviews(
            place.googleReviews,
            loadedState.communityReviews,
          );

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _HeroSection(
                  photoNames: place.photoNames,
                  topInset: topInset,
                  onBackPressed: () => context.router.maybePop(),
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: _DetailsSheet(
                  place: place,
                  previewReviews: previewReviews,
                  totalReviewCount: loadedState.totalReviewCount,
                  onReviewsTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<PlaceDetailsCubit>(),
                        child: const PlaceReviewsPage(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<PlaceReviewEntity> _buildPreviewReviews(
    List<PlaceReviewEntity> googleReviews,
    List<PlaceReviewEntity> communityReviews,
  ) {
    if (communityReviews.isNotEmpty) {
      return [communityReviews.first];
    }
    if (googleReviews.isNotEmpty) {
      return [googleReviews.first];
    }
    return const [];
  }
}

class _HeroSection extends StatelessWidget {
  final List<String> photoNames;
  final double topInset;
  final VoidCallback onBackPressed;

  const _HeroSection({
    required this.photoNames,
    required this.topInset,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PlacePhotoGallery(photoNames: photoNames, height: 320),
        Positioned(
          top: topInset + 16,
          left: 12,
          child: GestureDetector(
            onTap: onBackPressed,
            child: const _HeroIcon(CupertinoIcons.chevron_left),
          ),
        ),
        Positioned(
          top: topInset + 16,
          right: 16,
          child: GestureDetector(
            onTap: () {},
            child: const _HeroIcon(CupertinoIcons.star),
          ),
        ),
      ],
    );
  }
}

class _HeroIcon extends StatelessWidget {
  final IconData icon;

  const _HeroIcon(this.icon);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;

    return Icon(
      icon,
      color: iconColor,
      size: 32,
      shadows: [
        Shadow(color: iconColor, offset: const Offset(0.6, 0)),
        Shadow(color: iconColor, offset: const Offset(-0.6, 0)),
        Shadow(color: iconColor, offset: const Offset(0, 0.6)),
        Shadow(color: iconColor, offset: const Offset(0, -0.6)),
      ],
    );
  }
}

class _DetailsSheet extends StatelessWidget {
  final PlaceDetailsEntity place;
  final List<PlaceReviewEntity> previewReviews;
  final int totalReviewCount;
  final VoidCallback onReviewsTap;

  const _DetailsSheet({
    required this.place,
    required this.previewReviews,
    required this.totalReviewCount,
    required this.onReviewsTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final description = _buildDescription(place);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12, 12, 12, 22),
      decoration: BoxDecoration(
        color: sheetColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.08),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TitleBlock(place: place),
          const SizedBox(height: 12),
          _TagWrap(tags: _buildTags(place), isDark: isDark),
          const SizedBox(height: 12),
          _ExpandableDescription(text: description),
          const SizedBox(height: 10),
          PlaceReviewsPreviewBlock(
            previewReviews: previewReviews,
            rating: place.rating,
            totalReviewCount: totalReviewCount,
            onTap: onReviewsTap,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.appPrimaryWhite
                    : AppColors.appPrimaryBlack,
                foregroundColor: isDark
                    ? AppColors.appPrimaryBlack
                    : AppColors.appPrimaryWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Start a Journey!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildDescription(PlaceDetailsEntity place) {
    final rawDescription = place.description?.trim();
    if (rawDescription != null && rawDescription.isNotEmpty) {
      return rawDescription;
    }

    final location = [
      if (place.city.isNotEmpty) place.city,
      if (place.country.isNotEmpty) place.country,
    ].join(', ');

    if (location.isEmpty) {
      return '${place.name} is waiting to be explored. Detailed editorial description is not available for this place yet.';
    }

    return '${place.name} is located in $location. Detailed editorial description is not available for this place yet, but you can still explore photos and reviews before planning your visit.';
  }

  List<_PlaceTagData> _buildTags(PlaceDetailsEntity place) {
    final tags = <_PlaceTagData>[
      ...place.categories.take(3).map(_PlaceTagData.neutral),
    ];

    if ((place.rating ?? 0) >= 4.5) {
      tags.add(
        const _PlaceTagData.highlighted(
          'Must See',
          icon: CupertinoIcons.star_fill,
        ),
      );
    } else if (place.userRatingCount >= 500) {
      tags.add(const _PlaceTagData.highlighted('Popular'));
    }

    if (tags.isEmpty) {
      tags.add(const _PlaceTagData.neutral('Recommended'));
    }

    return tags.take(4).toList();
  }
}

class _TitleBlock extends StatelessWidget {
  final PlaceDetailsEntity place;

  const _TitleBlock({required this.place});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark ? Colors.white38 : Colors.black45;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          place.name,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          place.formattedAddress,
          style: TextStyle(
            fontSize: 16,
            color: secondaryColor,
            fontWeight: FontWeight.w400,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

class _TagWrap extends StatelessWidget {
  final List<_PlaceTagData> tags;
  final bool isDark;

  const _TagWrap({required this.tags, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: tags
          .map(
            (tag) => _TagChip(
              label: tag.label,
              isDark: isDark,
              highlighted: tag.highlighted,
              icon: tag.icon,
            ),
          )
          .toList(),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool isDark;
  final bool highlighted;
  final IconData? icon;

  const _TagChip({
    required this.label,
    required this.isDark,
    required this.highlighted,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = highlighted
        ? (isDark
              ? Colors.white.withValues(alpha: 0.16)
              : Colors.black.withValues(alpha: 0.1))
        : (isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08));
    final foregroundColor = highlighted
        ? (isDark ? AppColors.appPrimaryWhite : AppColors.appPrimaryBlack)
        : (isDark ? Colors.white : Colors.black87);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foregroundColor),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableDescription extends StatefulWidget {
  final String text;

  const _ExpandableDescription({required this.text});

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shouldCollapse = widget.text.trim().length > 180;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: !_expanded && shouldCollapse ? 4 : null,
          overflow: !_expanded && shouldCollapse
              ? TextOverflow.ellipsis
              : TextOverflow.visible,
          style: TextStyle(
            fontSize: 16,
            height: 1.45,
            color: isDark
                ? AppColors.appPrimaryWhite
                : AppColors.appPrimaryBlack,
          ),
        ),
        if (shouldCollapse) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? 'Show Less' : 'Read More',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white38 : Colors.black45,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PlaceTagData {
  final String label;
  final bool highlighted;
  final IconData? icon;

  const _PlaceTagData._(this.label, this.highlighted, this.icon);

  const _PlaceTagData.neutral(String label) : this._(label, false, null);

  const _PlaceTagData.highlighted(String label, {IconData? icon})
    : this._(label, true, icon);
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.router.maybePop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                CupertinoIcons.back,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Place unavailable',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.appPrimaryWhite
                    : AppColors.appPrimaryBlack,
                foregroundColor: isDark
                    ? AppColors.appPrimaryBlack
                    : AppColors.appPrimaryWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: const Text(
                'Try again',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
