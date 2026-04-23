import 'package:atlas/core/router/app_router.dart';
import 'package:atlas/core/utils/google_places_photo.dart';
import 'package:atlas/features/home/domain/entity/recommendation_entity.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SearchResultCard extends StatelessWidget {
  final RecommendationEntity place;
  final VoidCallback? onTap;

  const SearchResultCard({super.key, required this.place, this.onTap});

  @override
  Widget build(BuildContext context) {
    final locationLabel = _buildLocationLabel(place);

    return GestureDetector(
      onTap: () {
        onTap?.call();
        context.router.push(
          PlaceDetailsRoute(
            placeId: place.id,
            placeName: place.name,
            city: place.city,
            country: place.country,
            photoReference: place.photoReference,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: SizedBox(
          height: 118,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (place.photoReference != null)
                Image.network(
                  buildGooglePlacePhotoUrl(
                    place.photoReference!,
                    maxWidthPx: 1200,
                  ),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _SearchResultPlaceholder(),
                )
              else
                const _SearchResultPlaceholder(),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.78),
                        Colors.black.withValues(alpha: 0.44),
                        Colors.black.withValues(alpha: 0.12),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
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
                      place.name.isEmpty ? 'Unnamed place' : place.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      locationLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
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

  String _buildLocationLabel(RecommendationEntity place) {
    final parts = [
      place.city,
      place.country,
    ].map((part) => part.trim()).where((part) => part.isNotEmpty).toList();

    if (parts.isEmpty) {
      return 'Explore this destination';
    }

    return parts.join(', ');
  }
}

class _SearchResultPlaceholder extends StatelessWidget {
  const _SearchResultPlaceholder();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08),
            isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.03),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          CupertinoIcons.photo,
          color: isDark
              ? Colors.white.withValues(alpha: 0.38)
              : Colors.black.withValues(alpha: 0.28),
          size: 30,
        ),
      ),
    );
  }
}
