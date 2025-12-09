import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/coffee_shop.dart';
import '../services/places_service.dart';
import '../services/cafe_tracking_service.dart';

/// Enhanced location discovery service with regional filtering
class LocationDiscoveryService {
  static const List<String> _majorIndonesianCities = [
    'Jakarta', 'Surabaya', 'Bandung', 'Medan', 'Semarang', 'Makassar',
    'Palembang', 'Tangerang', 'South Tangerang', 'Depok', 'Bekasi',
    'Batam', 'Pekanbaru', 'Bandar Lampung', 'Malang', 'Yogyakarta',
    'Samarinda', 'Balikpapan', 'Pontianak', 'Manado', 'Mataram',
    'Kupang', 'Jayapura', 'Ambon', 'Ternate', 'Kendari', 'Palu',
    'Gorontalo', 'Padang', 'Bengkulu', 'Jambi', 'Pangkal Pinang',
    'Denpasar', 'Mataram', 'Kupang',
  ];

  /// Get user's current location
  static Future<Position?> getCurrentLocation() async {
    try {
      if (kDebugMode) {
        print('📍 Getting current location...');
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) {
          print('❌ Location services are disabled');
        }
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (kDebugMode) {
            print('❌ Location permissions are denied');
          }
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (kDebugMode) {
          print('❌ Location permissions are permanently denied');
        }
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (kDebugMode) {
        print('✅ Current location: ${position.latitude}, ${position.longitude}');
      }

      return position;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get current location: $e');
      }
      return null;
    }
  }

  /// Get cafes near user's current location
  static Future<List<CoffeeShop>> getCafesNearCurrentLocation({
    int radius = 5000,
    double? minRating,
    bool? openNow,
    int maxResults = 20,
  }) async {
    try {
      if (kDebugMode) {
        print('🔍 Getting cafes near current location');
      }

      PlacesService.initialize();

      final currentLocation = await getCurrentLocation();
      if (currentLocation == null) {
        if (kDebugMode) {
          print('❌ Cannot get nearby cafes - no location available');
        }
        return [];
      }

      return await getCafesNearLocation(
        currentLocation.latitude,
        currentLocation.longitude,
        radius: radius,
        minRating: minRating,
        openNow: openNow,
        maxResults: maxResults,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get cafes near current location: $e');
      }
      return [];
    }
  }

  /// Get cafes near specific location
  static Future<List<CoffeeShop>> getCafesNearLocation(
    double latitude,
    double longitude, {
    int radius = 5000,
    double? minRating,
    bool? openNow,
    int maxResults = 20,
  }) async {
    try {
      if (kDebugMode) {
        print('🔍 Searching cafes near $latitude, $longitude');
      }

      if (!PlacesService.isInitialized) {
        PlacesService.initialize();
      }

      final placesService = PlacesService();
      final cafes = await placesService.findNearbyCafes(
        latitude,
        longitude,
        radius: radius,
        limit: maxResults,
      );

      // Apply additional filters
      var filteredCafes = cafes.where((cafe) {
        if (minRating != null && cafe.rating < minRating) return false;
        if (openNow == true && !cafe.isOpen) return false;
        return true;
      }).toList();

      // Sort by distance and rating (weighted)
      filteredCafes.sort((a, b) {
        final aScore = (a.distance / 1000) + (5.0 - a.rating);
        final bScore = (b.distance / 1000) + (5.0 - b.rating);
        return aScore.compareTo(bScore);
      });

      if (kDebugMode) {
        print('✅ Found ${filteredCafes.length} cafes near location');
      }

      return filteredCafes.take(maxResults).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get cafes near location: $e');
      }
      return [];
    }
  }

  /// Discover cafes by region/city
  static Future<List<CoffeeShop>> discoverCafesByRegion({
    required String region,
    double? minRating,
    int minReviewCount = 10,
    int maxResults = 30,
  }) async {
    try {
      if (kDebugMode) {
        print('🌍 Discovering cafes in region: $region');
      }

      PlacesService.initialize();

      // Try to get coordinates for the region
      List<Location> locations = await locationFromAddress(region);
      double? centerLat, centerLng;

      if (locations.isNotEmpty) {
        centerLat = locations.first.latitude;
        centerLng = locations.first.longitude;
      }

      final placesService = PlacesService();
      final cafes = await placesService.getPopularCafesInRegion(
        region: region,
        centerLat: centerLat,
        centerLng: centerLng,
      );

      // Apply filters
      var filteredCafes = cafes.where((cafe) {
        if (minRating != null && cafe.rating < minRating) return false;
        if (cafe.reviewCount < minReviewCount) return false;
        return true;
      }).toList();

      // Sort by rating and review count
      filteredCafes.sort((a, b) {
        final aScore = (a.rating * 2) + (a.reviewCount / 100);
        final bScore = (b.rating * 2) + (b.reviewCount / 100);
        return bScore.compareTo(aScore);
      });

      if (kDebugMode) {
        print('✅ Found ${filteredCafes.length} cafes in $region');
      }

      return filteredCafes.take(maxResults).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to discover cafes in $region: $e');
      }
      return [];
    }
  }

  /// Get trending cafes in a region
  static Future<List<CoffeeShop>> getTrendingCafes({
    String? region,
    int maxResults = 15,
  }) async {
    try {
      if (kDebugMode) {
        print('🔥 Getting trending cafes ${region != null ? 'in $region' : 'globally'}');
      }

      PlacesService.initialize();

      final placesService = PlacesService();
      final cafes = await placesService.searchCafesWithFilters(
        query: region != null
            ? 'trending popular coffee shops $region'
            : 'trending popular coffee shops',
        minRating: 4.2,
        minReviewCount: 50,
        maxResults: maxResults,
      );

      // Sort by rating and review count with more weight to rating
      cafes.sort((a, b) {
        final aScore = (a.rating * 3) + (a.reviewCount / 100);
        final bScore = (b.rating * 3) + (b.reviewCount / 100);
        return bScore.compareTo(aScore);
      });

      if (kDebugMode) {
        print('✅ Found ${cafes.length} trending cafes');
      }

      return cafes;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get trending cafes: $e');
      }
      return [];
    }
  }

  /// Discover cafes with specific features
  static Future<List<CoffeeShop>> discoverCafesWithFeatures({
    required List<String> features,
    String? region,
    Position? userLocation,
    int radius = 15000,
    int maxResults = 20,
  }) async {
    try {
      if (kDebugMode) {
        print('🎯 Discovering cafes with features: ${features.join(', ')}');
      }

      PlacesService.initialize();

      double? userLat = userLocation?.latitude;
      double? userLng = userLocation?.longitude;

      // If no user location, try to get current location
      if (userLat == null || userLng == null) {
        final currentLocation = await getCurrentLocation();
        if (currentLocation != null) {
          userLat = currentLocation.latitude;
          userLng = currentLocation.longitude;
        }
      }

      final placesService = PlacesService();
      final cafes = await placesService.searchCafesByFeatures(
        features: features,
        userLat: userLat,
        userLng: userLng,
        radius: radius,
      );

      // Apply region filter if specified
      var filteredCafes = cafes;
      if (region != null && region.isNotEmpty) {
        filteredCafes = cafes.where((cafe) {
          return cafe.address.toLowerCase().contains(region.toLowerCase()) ||
                 cafe.name.toLowerCase().contains(region.toLowerCase());
        }).toList();
      }

      // Sort by distance if user location is available
      if (userLat != null && userLng != null) {
        filteredCafes.sort((a, b) => a.distance.compareTo(b.distance));
      }

      if (kDebugMode) {
        print('✅ Found ${filteredCafes.length} cafes with specified features');
      }

      return filteredCafes.take(maxResults).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to discover cafes with features: $e');
      }
      return [];
    }
  }

  /// Get region recommendations based on user location
  static Future<Map<String, dynamic>> getRegionalRecommendations({
    Position? userLocation,
    int radius = 20000,
  }) async {
    try {
      if (kDebugMode) {
        print('🗺️ Getting regional recommendations');
      }

      // Get user location if not provided
      userLocation ??= await getCurrentLocation();
      if (userLocation == null) {
        return {
          'currentRegion': 'Unknown',
          'nearbyCities': [],
          'recommendedCafes': [],
          'trendingCafes': [],
        };
      }

      // Get current address to determine region
      final placemarks = await placemarkFromCoordinates(
        userLocation.latitude,
        userLocation.longitude,
      );

      String currentRegion = 'Unknown';
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        currentRegion = placemark.locality ??
                       placemark.subAdministrativeArea ??
                       placemark.administrativeArea ??
                       'Unknown';
      }

      // Get nearby cities (simplified for Indonesia)
      final nearbyCities = _getNearbyCities(currentRegion);

      // Get recommended cafes near user
      final recommendedCafes = await getCafesNearLocation(
        userLocation.latitude,
        userLocation.longitude,
        radius: radius,
        minRating: 4.0,
        maxResults: 10,
      );

      // Get trending cafes in the region
      final trendingCafes = await getTrendingCafes(region: currentRegion, maxResults: 10);

      final recommendations = {
        'currentRegion': currentRegion,
        'nearbyCities': nearbyCities,
        'recommendedCafes': recommendedCafes,
        'trendingCafes': trendingCafes,
        'location': {
          'latitude': userLocation.latitude,
          'longitude': userLocation.longitude,
        },
      };

      if (kDebugMode) {
        print('✅ Regional recommendations generated for $currentRegion');
      }

      return recommendations;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get regional recommendations: $e');
      }
      return {
        'currentRegion': 'Unknown',
        'nearbyCities': [],
        'recommendedCafes': [],
        'trendingCafes': [],
      };
    }
  }

  /// Search cafes with advanced filters
  static Future<List<CoffeeShop>> searchCafesAdvanced({
    String? query,
    double? userLat,
    double? userLng,
    int radius = 10000,
    double? minRating,
    int? minReviewCount,
    bool? openNow,
    String? sortBy, // 'rating', 'distance', 'reviews'
    int maxResults = 20,
  }) async {
    try {
      if (kDebugMode) {
        print('🔍 Advanced cafe search with filters');
      }

      PlacesService.initialize();

      final searchQuery = query ?? 'coffee cafes';
      final placesService = PlacesService();
      final cafes = await placesService.searchCafesWithFilters(
        query: searchQuery,
        userLat: userLat,
        userLng: userLng,
        minRating: minRating,
        minReviewCount: minReviewCount,
        openNow: openNow,
        maxResults: maxResults,
      );

      // Apply sorting
      switch (sortBy) {
        case 'rating':
          cafes.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'distance':
          // Already sorted by distance in service
          break;
        case 'reviews':
          cafes.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
          break;
        default:
          // Mixed score
          cafes.sort((a, b) {
            final aScore = (a.rating * 2) + (a.reviewCount / 100) + (a.distance / 1000);
            final bScore = (b.rating * 2) + (b.reviewCount / 100) + (b.distance / 1000);
            return aScore.compareTo(bScore);
          });
      }

      if (kDebugMode) {
        print('✅ Found ${cafes.length} cafes with advanced search');
      }

      return cafes;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed advanced cafe search: $e');
      }
      return [];
    }
  }

  /// Get personalized cafe recommendations
  static Future<List<CoffeeShop>> getPersonalizedRecommendations({
    required String userId,
    int maxResults = 15,
  }) async {
    try {
      if (kDebugMode) {
        print('🎯 Getting personalized recommendations for user $userId');
      }

      // Get user's tracked cafes
      final history = await CafeTrackingService.getUserHistory(userId);
      final wishlist = history['wishlist'] as List<CoffeeShop>;
      final visited = history['visited'] as List<CoffeeShop>;

      if (wishlist.isEmpty && visited.isEmpty) {
        // No tracking data, return trending cafes
        return await getTrendingCafes(maxResults: maxResults);
      }

      // Analyze user preferences
      final averageRating = visited.isNotEmpty
          ? visited.map((c) => c.rating).reduce((a, b) => a + b) / visited.length
          : 4.0;

      final preferredRegions = <String>{};
      final allTracked = [...wishlist, ...visited];
      for (final cafe in allTracked) {
        // Extract city from address
        final addressParts = cafe.address.split(',');
        if (addressParts.isNotEmpty) {
          final city = addressParts.last.trim();
          if (_majorIndonesianCities.any((c) => c.toLowerCase() == city.toLowerCase())) {
            preferredRegions.add(city);
          }
        }
      }

      // Get current location for nearby recommendations
      final currentLocation = await getCurrentLocation();

      // Generate personalized recommendations
      final recommendations = <CoffeeShop>[];

      // 1. Cafes similar to user's preferences
      if (currentLocation != null) {
        final nearbyCafes = await getCafesNearLocation(
          currentLocation.latitude,
          currentLocation.longitude,
          minRating: averageRating - 0.5,
          maxResults: maxResults ~/ 2,
        );
        recommendations.addAll(nearbyCafes);
      }

      // 2. Cafes in preferred regions
      for (final region in preferredRegions) {
        final regionalCafes = await discoverCafesByRegion(
          region: region,
          minRating: averageRating - 0.3,
          maxResults: 5,
        );
        recommendations.addAll(regionalCafes);
      }

      // 3. Remove already tracked cafes
      recommendations.removeWhere((cafe) =>
          allTracked.any((tracked) => tracked.id == cafe.id));

      // Sort by personal relevance score
      recommendations.sort((a, b) {
        final aScore = _calculatePersonalRelevanceScore(a, visited, preferredRegions);
        final bScore = _calculatePersonalRelevanceScore(b, visited, preferredRegions);
        return bScore.compareTo(aScore);
      });

      if (kDebugMode) {
        print('✅ Generated ${recommendations.length} personalized recommendations');
      }

      return recommendations.take(maxResults).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get personalized recommendations: $e');
      }
      // Fallback to trending cafes
      return await getTrendingCafes(maxResults: maxResults);
    }
  }

  /// Helper methods

  static List<String> _getNearbyCities(String currentRegion) {
    // Simplified nearby cities logic for Indonesia
    final regionLower = currentRegion.toLowerCase();

    for (final city in _majorIndonesianCities) {
      if (city.toLowerCase() == regionLower) {
        // Return cities in the same province/area (simplified)
        switch (city) {
          case 'Jakarta':
            return ['Jakarta', 'Bogor', 'Depok', 'Tangerang', 'Bekasi'];
          case 'Surabaya':
            return ['Surabaya', 'Malang', 'Kediri', 'Blitar'];
          case 'Bandung':
            return ['Bandung', 'Cimahi', 'Garut', 'Tasikmalaya'];
          case 'Yogyakarta':
            return ['Yogyakarta', 'Sleman', 'Bantul', 'Klaten'];
          default:
            return [city];
        }
      }
    }

    return [currentRegion];
  }

  static double _calculatePersonalRelevanceScore(
    CoffeeShop cafe,
    List<CoffeeShop> visitedCafes,
    Set<String> preferredRegions,
  ) {
    double score = cafe.rating * 2;

    // Bonus for review count
    score += cafe.reviewCount / 50;

    // Bonus for distance (if location info is available)
    if (cafe.distance > 0) {
      score += (10000 - cafe.distance) / 2000;
    }

    // Bonus for preferred regions
    for (final region in preferredRegions) {
      if (cafe.address.toLowerCase().contains(region.toLowerCase())) {
        score += 1.5;
      }
    }

    // Bonus for similar ratings to user's preferences
    if (visitedCafes.isNotEmpty) {
      final avgUserRating = visitedCafes
          .map((c) => c.rating)
          .reduce((a, b) => a + b) / visitedCafes.length;
      final ratingDifference = (cafe.rating - avgUserRating).abs();
      score += (2.0 - ratingDifference);
    }

    return score;
  }
}