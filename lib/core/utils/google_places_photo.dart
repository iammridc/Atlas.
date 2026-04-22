import 'package:flutter_dotenv/flutter_dotenv.dart';

String buildGooglePlacePhotoUrl(String photoName, {int maxWidthPx = 1200}) {
  final apiKey = dotenv.env['GOOGLE_API_KEY'] ?? '';
  final normalizedPhotoName = photoName
      .trim()
      .replaceFirst(RegExp(r'^https://places\.googleapis\.com/v1/'), '')
      .replaceFirst(RegExp(r'^v1/'), '')
      .replaceFirst(RegExp(r'^/'), '');

  if (normalizedPhotoName.startsWith('http')) {
    return normalizedPhotoName;
  }

  return 'https://places.googleapis.com/v1/$normalizedPhotoName/media'
      '?maxWidthPx=$maxWidthPx&key=$apiKey';
}
