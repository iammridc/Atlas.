import 'package:atlas/core/utils/google_places_photo.dart';
import 'package:flutter/material.dart';

class PlacePhotoGallery extends StatelessWidget {
  final List<String> photoNames;
  final double height;

  const PlacePhotoGallery({
    super.key,
    required this.photoNames,
    this.height = 340,
  });

  @override
  Widget build(BuildContext context) {
    final photos = photoNames;

    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photos.isEmpty)
              _placeholder()
            else
              PageView.builder(
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    buildGooglePlacePhotoUrl(photos[index]),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _placeholder(),
                  );
                },
              ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.08),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.42),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: Colors.grey[300],
    child: const Center(
      child: Icon(Icons.image_outlined, color: Colors.grey, size: 48),
    ),
  );
}
