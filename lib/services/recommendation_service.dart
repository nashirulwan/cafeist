import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/coffee_shop.dart';
import '../services/personal_tracking_service.dart';

class RecommendationService {
  static final PersonalTrackingService _trackingService = PersonalTrackingService();
  static final Random _random = Random();

  /// Get personalized coffee shop recommendations based on user preferences
  static Future<List<CoffeeShop>> getRecommendations(List<CoffeeShop> allCoffeeShops) async {
    try {
      if (allCoffeeShops.isEmpty) return [];

      // Get user's preferences and history
      final userVisits = allCoffeeShops.where((cafe) =>
        cafe.trackingStatus == CafeTrackingStatus.visited
      ).toList();

      final userFavorites = allCoffeeShops.where((cafe) => cafe.isFavorite).toList();
      final userWishlist = allCoffeeShops.where((cafe) =>
        cafe.trackingStatus == CafeTrackingStatus.wantToVisit
      ).toList();

      if (kDebugMode) {
        print('🔍 Analyzing user preferences...');
        print('📊 Visited: ${userVisits.length}, Favorites: ${userFavorites.length}, Wishlist: ${userWishlist.length}');
      }

      // Calculate user preferences
      final userPrefs = _calculateUserPreferences(userVisits, userFavorites, userWishlist);

      // Score and recommend cafes
      final scoredCafes = allCoffeeShops
          .where((cafe) => cafe.trackingStatus == CafeTrackingStatus.notTracked)
          .map((cafe) => MapEntry(cafe, _calculateRecommendationScore(cafe, userPrefs)))
          .toList();

      // Sort by score (highest first)
      scoredCafes.sort((a, b) => b.value.compareTo(a.value));

      // Get top recommendations with variety
      final recommendations = _getDiverseRecommendations(scoredCafes, 10);

      if (kDebugMode) {
        print('✅ Generated ${recommendations.length} recommendations');
      }

      return recommendations;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating recommendations: $e');
      }
      // Fallback: return random high-rated cafes
      return _getFallbackRecommendations(allCoffeeShops);
    }
  }

  /// Calculate user preferences based on their history
  static Map<String, dynamic> _calculateUserPreferences(
    List<CoffeeShop> visits,
    List<CoffeeShop> favorites,
    List<CoffeeShop> wishlist,
  ) {
    final preferences = <String, dynamic>{};

    // Calculate average rating preference
    final allRatedCafes = [...visits, ...favorites]
        .where((cafe) => cafe.rating > 0);

    if (allRatedCafes.isNotEmpty) {
      final avgRating = allRatedCafes
          .map((cafe) => cafe.rating)
          .reduce((a, b) => a + b) / allRatedCafes.length;
      preferences['preferredRating'] = avgRating;
    } else {
      preferences['preferredRating'] = 4.0; // Default
    }

    // Calculate distance preference
    if (visits.isNotEmpty) {
      final avgDistance = visits
          .map((cafe) => cafe.distance)
          .reduce((a, b) => a + b) / visits.length;
      preferences['maxPreferredDistance'] = avgDistance * 1.5; // Will travel 50% further
    } else {
      preferences['maxPreferredDistance'] = 5000; // 5km default
    }

    // Extract keywords from descriptions
    final descriptionKeywords = <String, int>{};
    final userCafes = [...visits, ...favorites];

    for (final cafe in userCafes) {
      final words = cafe.description.toLowerCase().split(' ');
      for (final word in words) {
        if (word.length > 3) { // Ignore short words
          descriptionKeywords[word] = (descriptionKeywords[word] ?? 0) + 1;
        }
      }
    }

    // Get top keywords
    final sortedKeywords = descriptionKeywords.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    preferences['preferredKeywords'] = sortedKeywords
        .take(5)
        .map((entry) => entry.key)
        .toList();

    // Calculate preferred features
    preferences['prefersWiFi'] = _analyzeFeaturePreference(userCafes, ['wifi', 'work', 'laptop']);
    preferences['prefersQuiet'] = _analyzeFeaturePreference(userCafes, ['quiet', 'study', 'focus']);
    preferences['prefersSocial'] = _analyzeFeaturePreference(userCafes, ['social', 'meet', 'chat']);

    if (kDebugMode) {
      print('🎯 User preferences: $preferences');
    }

    return preferences;
  }

  /// Analyze if user prefers certain features
  static bool _analyzeFeaturePreference(List<CoffeeShop> cafes, List<String> keywords) {
    if (cafes.isEmpty) return false;

    int matches = 0;
    for (final cafe in cafes) {
      final description = cafe.description.toLowerCase();
      if (keywords.any((keyword) => description.contains(keyword))) {
        matches++;
      }
    }

    return matches / cafes.length > 0.3; // 30% threshold
  }

  /// Calculate recommendation score for a specific coffee shop
  static double _calculateRecommendationScore(CoffeeShop cafe, Map<String, dynamic> userPrefs) {
    double score = 0.0;

    // Factor 1: Rating match (25% weight)
    final preferredRating = userPrefs['preferredRating'] ?? 4.0;
    final ratingDiff = (cafe.rating - preferredRating).abs();
    final ratingScore = max(0, 25 - (ratingDiff * 10)); // Penalty for difference
    score += ratingScore;

    // Factor 2: Distance proximity (20% weight)
    final maxDistance = userPrefs['maxPreferredDistance'] ?? 5000;
    if (cafe.distance <= maxDistance) {
      final distanceScore = 20 * (1 - (cafe.distance / maxDistance));
      score += distanceScore;
    }

    // Factor 3: Review count/popularity (15% weight)
    final reviewScore = min(15, (cafe.reviewCount / 50) * 15); // Cap at 15 points
    score += reviewScore;

    // Factor 4: Keyword matching (20% weight)
    final preferredKeywords = userPrefs['preferredKeywords'] ?? [];
    final cafeDescription = cafe.description.toLowerCase();
    int keywordMatches = 0;

    for (final keyword in preferredKeywords.cast<String>()) {
      if (cafeDescription.contains(keyword.toLowerCase())) {
        keywordMatches++;
      }
    }

    if (preferredKeywords.isNotEmpty) {
      final keywordScore = 20 * (keywordMatches / preferredKeywords.length);
      score += keywordScore;
    }

    // Factor 5: Feature preferences (10% weight)
    if (userPrefs['prefersWiFi'] == true &&
        cafeDescription.contains('wifi')) score += 5;
    if (userPrefs['prefersQuiet'] == true &&
        cafeDescription.contains('quiet')) score += 5;
    if (userPrefs['prefersSocial'] == true &&
        cafeDescription.contains('social')) score += 5;

    // Factor 6: Random variety (10% weight) - to add some randomness
    score += _random.nextDouble() * 10;

    // Bonus points for highly rated cafes
    if (cafe.rating >= 4.5) score += 5;
    if (cafe.rating >= 4.8) score += 5;

    return score;
  }

  /// Get diverse recommendations to avoid showing similar cafes
  static List<CoffeeShop> _getDiverseRecommendations(
    List<MapEntry<CoffeeShop, double>> scoredCafes,
    int count,
  ) {
    final recommendations = <CoffeeShop>[];
    final selectedScores = <double>[];

    for (final entry in scoredCafes) {
      if (recommendations.length >= count) break;

      // Add variety: don't select cafes with very similar scores
      if (selectedScores.isEmpty ||
          selectedScores.every((score) => (score - entry.value).abs() > 5)) {
        recommendations.add(entry.key);
        selectedScores.add(entry.value);
      }
    }

    // If we don't have enough diverse recommendations, fill with highest scored
    if (recommendations.length < count) {
      for (final entry in scoredCafes) {
        if (recommendations.length >= count) break;
        if (!recommendations.contains(entry.key)) {
          recommendations.add(entry.key);
        }
      }
    }

    return recommendations;
  }

  /// Get fallback recommendations when personalized recommendations fail
  static List<CoffeeShop> _getFallbackRecommendations(List<CoffeeShop> allCoffeeShops) {
    try {
      // Sort by rating and get top rated cafes
      final topRated = List<CoffeeShop>.from(allCoffeeShops)
        ..sort((a, b) => b.rating.compareTo(a.rating));

      // Return top 10 highest rated cafes that haven't been visited
      return topRated
          .where((cafe) => cafe.trackingStatus == CafeTrackingStatus.notTracked)
          .take(10)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Even fallback recommendations failed: $e');
      }
      return [];
    }
  }

  /// Get recommendations for a specific category (e.g., "best for work", "best for meetings")
  static Future<List<CoffeeShop>> getRecommendationsByCategory(
    List<CoffeeShop> allCoffeeShops,
    String category,
  ) async {
    try {
      List<CoffeeShop> filtered;

      switch (category.toLowerCase()) {
        case 'work':
          filtered = allCoffeeShops.where((cafe) =>
            cafe.description.toLowerCase().contains('work') ||
            cafe.description.toLowerCase().contains('wifi') ||
            cafe.description.toLowerCase().contains('laptop')
          ).toList();
          break;
        case 'study':
          filtered = allCoffeeShops.where((cafe) =>
            cafe.description.toLowerCase().contains('study') ||
            cafe.description.toLowerCase().contains('quiet') ||
            cafe.description.toLowerCase().contains('focus')
          ).toList();
          break;
        case 'social':
          filtered = allCoffeeShops.where((cafe) =>
            cafe.description.toLowerCase().contains('social') ||
            cafe.description.toLowerCase().contains('meet') ||
            cafe.description.toLowerCase().contains('chat')
          ).toList();
          break;
        case 'cozy':
          filtered = allCoffeeShops.where((cafe) =>
            cafe.description.toLowerCase().contains('cozy') ||
            cafe.description.toLowerCase().contains('comfortable')
          ).toList();
          break;
        default:
          return getRecommendations(allCoffeeShops);
      }

      // Sort by rating within the category
      filtered.sort((a, b) => b.rating.compareTo(a.rating));

      return filtered.take(10).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting category recommendations: $e');
      }
      return [];
    }
  }

  /// Refresh recommendations with updated user data
  static Future<List<CoffeeShop>> refreshRecommendations(
    List<CoffeeShop> allCoffeeShops,
  ) async {
    try {
      if (kDebugMode) {
        print('🔄 Refreshing recommendations...');
      }

      return await getRecommendations(allCoffeeShops);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error refreshing recommendations: $e');
      }
      return _getFallbackRecommendations(allCoffeeShops);
    }
  }
}