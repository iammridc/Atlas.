// recommendations_remote_datasource.dart

import 'dart:math';
import 'package:atlas/core/errors/app_exception.dart';
import 'package:atlas/core/services/categories_services.dart';
import 'package:atlas/features/home/data/models/recommendation_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract class RecommendationsRemoteDatasource {
  Future<List<RecommendationModel>> getRecommendations(
    List<String> categoryTypes,
  );

  Future<List<RecommendationModel>> searchPlaces(String query);
}

class RecommendationsRemoteDatasourceImpl
    implements RecommendationsRemoteDatasource {
  final Dio _dio;

  static const _baseUrl = 'https://places.googleapis.com/v1/places:searchText';
  static const _fieldMask =
      'nextPageToken,'
      'places.id,'
      'places.displayName,'
      'places.addressComponents,'
      'places.photos';

  static const _queryPrefixes = [
    'world famous',
    'most visited',
    'top rated',
    'iconic',
    'must see',
    'best',
    'popular',
    'legendary',
    'breathtaking',
    'hidden gem',
  ];

  RecommendationsRemoteDatasourceImpl({required Dio dio}) : _dio = dio;

  String get _apiKey => dotenv.env['GOOGLE_API_KEY'] ?? '';

  @override
  Future<List<RecommendationModel>> getRecommendations(
    List<String> categoryTypes,
  ) async {
    final futures = categoryTypes.map(_fetchByCategory);
    final results = await Future.wait(futures);

    final seen = <String>{};
    final combined = results
        .expand((places) => places)
        .where((place) => seen.add(place.id))
        .toList();

    combined.shuffle(Random());
    return combined;
  }

  Future<List<RecommendationModel>> _fetchByCategory(
    String categoryType,
  ) async {
    try {
      final prefix = _queryPrefixes[Random().nextInt(_queryPrefixes.length)];
      return _searchText(
        textQuery: '$prefix ${categoryType.replaceAll('_', ' ')}',
        pageSize: 10,
      );
    } on DioException catch (e) {
      throw ServerException(
        message:
            e.response?.data?['error']?['message'] ??
            'Failed to fetch category: $categoryType',
      );
    }
  }

  @override
  Future<List<RecommendationModel>> searchPlaces(String query) async {
    final normalizedQuery = _normalizeText(query);
    if (normalizedQuery.isEmpty) return const [];

    DioException? typedSearchError;

    try {
      final searchIntent = _detectCategoryIntent(query);
      if (searchIntent != null) {
        try {
          final typedResults = await _searchCategoryPlaces(searchIntent);
          if (typedResults.isNotEmpty) {
            return typedResults;
          }
        } on DioException catch (error) {
          typedSearchError = error;
        }
      }

      return await _searchGenericPlaces(query);
    } on DioException catch (e) {
      throw ServerException(
        message:
            typedSearchError?.response?.data?['error']?['message'] ??
            e.response?.data?['error']?['message'] ??
            'Failed to search for places.',
      );
    }
  }

  Future<List<RecommendationModel>> _searchText({
    required String textQuery,
    required int pageSize,
    String? includedType,
    bool strictTypeFiltering = false,
    int maxPages = 1,
  }) async {
    final collectedPlaces = <String, RecommendationModel>{};
    String? nextPageToken;
    var fetchedPages = 0;

    while (fetchedPages < maxPages) {
      final response = await _searchTextPage(
        textQuery: textQuery,
        pageSize: pageSize,
        includedType: includedType,
        strictTypeFiltering: strictTypeFiltering,
        pageToken: nextPageToken,
      );

      for (final place in response.places) {
        collectedPlaces.putIfAbsent(place.id, () => place);
      }

      fetchedPages++;
      nextPageToken = response.nextPageToken;
      if (nextPageToken == null || nextPageToken.isEmpty) {
        break;
      }
    }

    return collectedPlaces.values.toList();
  }

  Future<_TextSearchResponse> _searchTextPage({
    required String textQuery,
    required int pageSize,
    String? includedType,
    bool strictTypeFiltering = false,
    String? pageToken,
  }) async {
    final response = await _dio.post(
      _baseUrl,
      data: {
        'textQuery': textQuery,
        'pageSize': pageSize,
        'languageCode': 'en',
        'rankPreference': 'RELEVANCE',
        if (strictTypeFiltering) 'strictTypeFiltering': true,
        ...?includedType == null ? null : {'includedType': includedType},
        ...?pageToken == null ? null : {'pageToken': pageToken},
      },
      options: Options(
        headers: {'X-Goog-Api-Key': _apiKey, 'X-Goog-FieldMask': _fieldMask},
      ),
    );

    final places = response.data['places'] as List? ?? [];
    return _TextSearchResponse(
      places: places
          .map((place) => RecommendationModel.fromJson(place))
          .toList(),
      nextPageToken: response.data['nextPageToken'] as String?,
    );
  }

  Future<List<RecommendationModel>> _searchGenericPlaces(String query) async {
    final normalizedQuery = _normalizeText(query);
    final fallbackQueries = _buildFallbackQueries(normalizedQuery);
    final collectedPlaces = <String, RecommendationModel>{};
    DioException? originalSearchError;

    try {
      final exactResults = await _searchText(textQuery: query, pageSize: 20);
      for (final place in exactResults) {
        collectedPlaces[place.id] = place;
      }
    } on DioException catch (e) {
      originalSearchError = e;
    }

    for (final fallbackQuery in fallbackQueries) {
      try {
        final fallbackResults = await _searchText(
          textQuery: fallbackQuery,
          pageSize: 12,
        );

        for (final place in fallbackResults) {
          collectedPlaces.putIfAbsent(place.id, () => place);
        }
      } on DioException {
        // Keep partial results from other successful queries instead of failing
        // the whole search when a secondary broadening query misses.
      }
    }

    if (collectedPlaces.isEmpty && originalSearchError != null) {
      throw originalSearchError;
    }

    final rankedResults =
        collectedPlaces.values
            .map(
              (place) =>
                  (place: place, score: _calculateMatchScore(place, query)),
            )
            .toList()
          ..sort((a, b) => b.score.compareTo(a.score));

    final filteredResults = rankedResults
        .where((entry) => entry.score >= _minimumAcceptedScore(normalizedQuery))
        .toList();

    final visibleResults = filteredResults.isNotEmpty
        ? filteredResults
        : rankedResults.take(8).toList();

    return visibleResults.map((entry) => entry.place).take(20).toList();
  }

  Future<List<RecommendationModel>> _searchCategoryPlaces(
    _CategorySearchIntent intent,
  ) async {
    final collectedPlaces = <String, RecommendationModel>{};

    for (var index = 0; index < intent.queryVariants.length; index++) {
      final queryVariant = intent.queryVariants[index];

      final results = await _searchText(
        textQuery: queryVariant,
        pageSize: 20,
        includedType: intent.categoryId,
        strictTypeFiltering: true,
        maxPages: index == 0 ? 3 : 1,
      );

      for (final place in results) {
        collectedPlaces.putIfAbsent(place.id, () => place);
      }
    }

    return collectedPlaces.values.take(60).toList();
  }

  List<String> _buildFallbackQueries(String normalizedQuery) {
    final tokens = normalizedQuery
        .split(' ')
        .where((token) => token.length >= 3)
        .toList();
    final fallbackQueries = <String>{};

    if (tokens.length > 1) {
      fallbackQueries.add(tokens.join(' '));
      fallbackQueries.add(tokens.first);
      fallbackQueries.add(tokens.last);

      final longestToken = tokens.reduce(
        (current, next) => current.length >= next.length ? current : next,
      );
      fallbackQueries.add(longestToken);
    } else if (tokens.length == 1) {
      final token = tokens.first;
      if (token.length >= 4) {
        fallbackQueries.add(token.substring(0, token.length - 1));
      }
      if (token.length >= 5) {
        fallbackQueries.add(token.substring(0, 4));
      }
    }

    fallbackQueries.remove(normalizedQuery);
    return fallbackQueries.toList();
  }

  _CategorySearchIntent? _detectCategoryIntent(String query) {
    final normalizedQuery = _normalizeText(query);
    final queryTokens = _tokenize(normalizedQuery);
    if (queryTokens.isEmpty) return null;

    _CategoryMatch? bestMatch;

    for (final category in CategoriesService.searchableCategories) {
      final labelTokens = _tokenize(_normalizeText(category.label));
      if (labelTokens.isEmpty || labelTokens.length > queryTokens.length) {
        continue;
      }

      for (
        var startIndex = 0;
        startIndex <= queryTokens.length - labelTokens.length;
        startIndex++
      ) {
        double totalScore = 0;
        var strongMatches = 0;

        for (
          var tokenIndex = 0;
          tokenIndex < labelTokens.length;
          tokenIndex++
        ) {
          final similarity = _categoryTokenSimilarity(
            queryTokens[startIndex + tokenIndex],
            labelTokens[tokenIndex],
          );

          totalScore += similarity;
          if (similarity >= 0.84) {
            strongMatches++;
          }
        }

        final averageScore = totalScore / labelTokens.length;
        final requiredScore = labelTokens.length == 1 ? 0.82 : 0.84;
        final matchesAllTokens = strongMatches == labelTokens.length;

        if (averageScore < requiredScore || !matchesAllTokens) {
          continue;
        }

        final boostedScore = averageScore + labelTokens.length * 0.015;
        if (bestMatch == null || boostedScore > bestMatch.score) {
          bestMatch = _CategoryMatch(
            categoryId: category.id,
            label: category.label,
            labelTokens: labelTokens,
            startIndex: startIndex,
            score: boostedScore,
          );
        }
      }
    }

    if (bestMatch == null) {
      return null;
    }

    final canonicalQuery = _buildCanonicalCategoryQuery(queryTokens, bestMatch);
    final normalizedCanonicalQuery = _normalizeText(canonicalQuery);
    final normalizedLabel = _normalizeText(bestMatch.label);

    final queryVariants = <String>{
      if (normalizedCanonicalQuery.isNotEmpty) normalizedCanonicalQuery,
      normalizedQuery,
      normalizedLabel,
    }.toList();

    return _CategorySearchIntent(
      categoryId: bestMatch.categoryId,
      queryVariants: queryVariants,
    );
  }

  String _buildCanonicalCategoryQuery(
    List<String> queryTokens,
    _CategoryMatch match,
  ) {
    final replacedTokens = [
      ...queryTokens.sublist(0, match.startIndex),
      ...match.labelTokens,
      ...queryTokens.sublist(match.startIndex + match.labelTokens.length),
    ];

    return replacedTokens.join(' ').trim();
  }

  double _calculateMatchScore(RecommendationModel place, String query) {
    final normalizedQuery = _normalizeText(query);
    final queryTokens = _tokenize(normalizedQuery);
    if (queryTokens.isEmpty) return 0;

    final candidateTexts = [
      place.name,
      '${place.name} ${place.city}',
      '${place.name} ${place.city} ${place.country}',
    ].map(_normalizeText).toList();

    final candidateTokens = candidateTexts
        .expand(_tokenize)
        .where((token) => token.isNotEmpty)
        .toSet()
        .toList();

    final phraseScore = candidateTexts
        .map((candidate) => _phraseSimilarity(candidate, normalizedQuery))
        .fold<double>(0, (best, score) => score > best ? score : best);

    double matchedTokenScore = 0;
    int stronglyMatchedTokens = 0;

    for (final queryToken in queryTokens) {
      double bestTokenScore = 0;

      for (final candidateToken in candidateTokens) {
        final tokenScore = _tokenSimilarity(queryToken, candidateToken);
        if (tokenScore > bestTokenScore) {
          bestTokenScore = tokenScore;
        }
      }

      matchedTokenScore += bestTokenScore;
      if (bestTokenScore >= 0.72) {
        stronglyMatchedTokens++;
      }
    }

    final coverageScore = matchedTokenScore / queryTokens.length;
    final coverageBonus = stronglyMatchedTokens / queryTokens.length * 0.18;

    return phraseScore * 0.45 + coverageScore * 0.55 + coverageBonus;
  }

  double _phraseSimilarity(String candidate, String query) {
    if (candidate.isEmpty || query.isEmpty) return 0;
    if (candidate == query) return 1;
    if (candidate.startsWith(query)) return 0.96;
    if (candidate.contains(query)) return 0.9;

    final candidateTokens = _tokenize(candidate);
    final queryTokens = _tokenize(query);
    if (candidateTokens.isEmpty || queryTokens.isEmpty) return 0;

    int matchedTokens = 0;
    for (final queryToken in queryTokens) {
      final hasMatch = candidateTokens.any(
        (candidateToken) =>
            _tokenSimilarity(queryToken, candidateToken) >= 0.72,
      );
      if (hasMatch) {
        matchedTokens++;
      }
    }

    return matchedTokens / queryTokens.length;
  }

  double _tokenSimilarity(String queryToken, String candidateToken) {
    if (queryToken.isEmpty || candidateToken.isEmpty) return 0;
    if (queryToken == candidateToken) return 1;
    if (candidateToken.startsWith(queryToken)) return 0.95;
    if (candidateToken.contains(queryToken)) return 0.88;
    if (queryToken.startsWith(candidateToken) && candidateToken.length >= 3) {
      return 0.78;
    }

    final distance = _levenshteinDistance(queryToken, candidateToken);
    final maxLength = queryToken.length >= candidateToken.length
        ? queryToken.length
        : candidateToken.length;
    final similarity = 1 - distance / maxLength;

    if (similarity >= 0.84) return similarity;

    final overlap = _commonPrefixLength(queryToken, candidateToken) / maxLength;
    return overlap >= 0.5 ? overlap * 0.9 : similarity;
  }

  double _categoryTokenSimilarity(String queryToken, String candidateToken) {
    if (queryToken.isEmpty || candidateToken.isEmpty) return 0;
    if (queryToken == candidateToken) return 1;
    if (_isPluralForm(queryToken, candidateToken)) return 0.97;
    if (queryToken.startsWith(candidateToken) && candidateToken.length >= 4) {
      return 0.9;
    }

    final distance = _levenshteinDistance(queryToken, candidateToken);
    final maxLength = queryToken.length >= candidateToken.length
        ? queryToken.length
        : candidateToken.length;
    final similarity = 1 - distance / maxLength;

    return similarity >= 0.74 ? similarity : 0;
  }

  int _levenshteinDistance(String source, String target) {
    if (source == target) return 0;
    if (source.isEmpty) return target.length;
    if (target.isEmpty) return source.length;

    final previous = List<int>.generate(target.length + 1, (index) => index);
    final current = List<int>.filled(target.length + 1, 0);

    for (var i = 1; i <= source.length; i++) {
      current[0] = i;

      for (var j = 1; j <= target.length; j++) {
        final substitutionCost = source[i - 1] == target[j - 1] ? 0 : 1;
        final deletion = previous[j] + 1;
        final insertion = current[j - 1] + 1;
        final substitution = previous[j - 1] + substitutionCost;

        current[j] = [
          deletion,
          insertion,
          substitution,
        ].reduce((best, value) => value < best ? value : best);
      }

      for (var j = 0; j <= target.length; j++) {
        previous[j] = current[j];
      }
    }

    return previous[target.length];
  }

  int _commonPrefixLength(String source, String target) {
    final maxLength = source.length <= target.length
        ? source.length
        : target.length;

    var index = 0;
    while (index < maxLength && source[index] == target[index]) {
      index++;
    }

    return index;
  }

  bool _isPluralForm(String queryToken, String candidateToken) {
    if (queryToken == '${candidateToken}s') return true;
    if (queryToken == '${candidateToken}es') return true;
    if (candidateToken.endsWith('y') &&
        queryToken ==
            '${candidateToken.substring(0, candidateToken.length - 1)}ies') {
      return true;
    }
    return false;
  }

  List<String> _tokenize(String value) {
    return value.split(' ').where((token) => token.isNotEmpty).toList();
  }

  String _normalizeText(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  double _minimumAcceptedScore(String normalizedQuery) {
    if (normalizedQuery.length <= 3) return 0.34;
    if (normalizedQuery.length <= 6) return 0.4;
    return 0.44;
  }
}

class _TextSearchResponse {
  final List<RecommendationModel> places;
  final String? nextPageToken;

  const _TextSearchResponse({required this.places, this.nextPageToken});
}

class _CategorySearchIntent {
  final String categoryId;
  final List<String> queryVariants;

  const _CategorySearchIntent({
    required this.categoryId,
    required this.queryVariants,
  });
}

class _CategoryMatch {
  final String categoryId;
  final String label;
  final List<String> labelTokens;
  final int startIndex;
  final double score;

  const _CategoryMatch({
    required this.categoryId,
    required this.label,
    required this.labelTokens,
    required this.startIndex,
    required this.score,
  });
}
