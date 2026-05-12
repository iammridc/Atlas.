import 'package:atlas/core/localization/app_localizations.dart';
import 'package:flutter/widgets.dart';

String localizedGamificationLabel(BuildContext context, String value) {
  final key = _gamificationLabelKeys[value];
  return key == null ? value : context.l10n.t(key);
}

String localizedBadgeDescription(BuildContext context, String value) {
  final key = _badgeDescriptionKeys[value];
  return key == null ? value : context.l10n.t(key);
}

const _gamificationLabelKeys = {
  'Beach Lover': 'badgeBeachLoverTitle',
  'Border Starter': 'badgeBorderStarterTitle',
  'City Collector': 'badgeCityCollectorTitle',
  'City Sampler': 'badgeCitySamplerTitle',
  'Country Hopper': 'badgeCountryHopperTitle',
  'Early Explorer': 'badgeEarlyExplorerTitle',
  'Food Hunter': 'badgeFoodHunterTitle',
  'Great Taste': 'badgeGreatTasteTitle',
  'Hidden Gem Finder': 'badgeHiddenGemFinderTitle',
  'Local Guide': 'badgeLocalGuideTitle',
  'Museum Mind': 'badgeMuseumMindTitle',
  'Opinion Maker': 'badgeOpinionMakerTitle',
  'Photo Reviewer': 'badgePhotoReviewerTitle',
  'Photo Traveler': 'badgePhotoTravelerTitle',
  'Place Collector': 'badgePlaceCollectorTitle',
  'Route Maker': 'badgeRouteMakerTitle',
  'Storyteller': 'badgeStorytellerTitle',
  'Style Sampler': 'badgeStyleSamplerTitle',
  'Tag Curator': 'badgeTagCuratorTitle',
  'Weekend Explorer': 'badgeWeekendExplorerTitle',
  'City Scout': 'levelCityScout',
  'Local Expert': 'levelLocalExpert',
  'New Explorer': 'levelNewExplorer',
  'Route Builder': 'levelRouteBuilder',
  'Travel Legend': 'levelTravelLegend',
  'Weekend Traveler': 'levelWeekendTraveler',
  'World Explorer': 'levelWorldExplorer',
};

const _badgeDescriptionKeys = {
  'Visited 5 beaches': 'badgeBeachLoverDescription',
  'Explored 2 different countries': 'badgeBorderStarterDescription',
  'Visited 10 places in one city': 'badgeCityCollectorDescription',
  'Explored 3 different cities': 'badgeCitySamplerDescription',
  'Visited places in 5 countries': 'badgeCountryHopperDescription',
  'Added recent travel activity': 'badgeEarlyExplorerDescription',
  'Reviewed 10 restaurants': 'badgeFoodHunterDescription',
  'Found 5 places rated 4 stars or higher': 'badgeGreatTasteDescription',
  'Reviewed low-key local places': 'badgeHiddenGemFinderDescription',
  'Wrote 20 helpful reviews': 'badgeLocalGuideDescription',
  'Visited 5 museums': 'badgeMuseumMindDescription',
  'Wrote 5 reviews': 'badgeOpinionMakerDescription',
  'Added photos to 5 reviews': 'badgePhotoReviewerDescription',
  'Uploaded 30 travel photos': 'badgePhotoTravelerDescription',
  'Saved, reviewed, or planned 25 places': 'badgePlaceCollectorDescription',
  'Saved 3 planned trips': 'badgeRouteMakerDescription',
  'Wrote 5 detailed reviews': 'badgeStorytellerDescription',
  'Explored 5 travel categories': 'badgeStyleSamplerDescription',
  'Added tags to 10 reviews': 'badgeTagCuratorDescription',
  'Visited 3 places in one weekend': 'badgeWeekendExplorerDescription',
};
