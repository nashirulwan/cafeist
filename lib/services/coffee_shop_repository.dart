import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../models/coffee_shop.dart';
import '../services/places_service.dart';
import '../utils/logger.dart';
import '../utils/cache_manager.dart';

class CoffeeShopRepository {
  final PlacesService _placesService;
  final CacheManager _cacheManager;

  CoffeeShopRepository({
    PlacesService? placesService,
    CacheManager? cacheManager,
  })  : _placesService = placesService ?? PlacesService(),
        _cacheManager = cacheManager ?? CacheManager();

  /// Get coffee shop by ID (fetches from API if needed)
  Future<CoffeeShop?> getCoffeeShopById(String id) async {
    // Check cache logic here if needed, but for now fetch direct if not found
    try {
      if (!_placesService.isReady) return null;
      return await _placesService.getPlaceDetails(id);
    } catch (e) {
      AppLogger.error('Failed to get coffee shop by ID: $id', error: e, tag: 'Repository');
      return null;
    }
  }

  /// Load coffee shops from local JSON asset
  Future<List<CoffeeShop>> getLocalCoffeeShops({
    double? userLat,
    double? userLng,
    bool randomize = false,
  }) async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/coffee_shops.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      var shops = jsonList.map((json) => CoffeeShop.fromJson(json)).toList();

      if (randomize) {
        shops.shuffle(math.Random());
        AppLogger.info('JSON data shuffled', tag: 'Repository');
      }

      if (userLat != null && userLng != null) {
        shops = _calculateDistances(shops, userLat, userLng);
      }
      return shops;
    } catch (e) {
      AppLogger.error('Error loading local data', error: e, tag: 'Repository');
      throw Exception('Failed to load local data: $e');
    }
  }

  /// Fetch nearby coffee shops from API
  Future<List<CoffeeShop>> getNearbyCoffeeShops({
    required double lat,
    required double lng,
    int radius = 5000,
    int? limit,
  }) async {
    if (!_placesService.isReady) {
      throw Exception('Places API not initialized');
    }

    try {
      final cafes = await _placesService.findNearbyCafes(
        lat,
        lng,
        radius: radius,
        limit: limit ?? 20,
      );

      return _calculateDistances(cafes, lat, lng);
    } catch (e) {
      AppLogger.error('Error fetching nearby cafes', error: e, tag: 'Repository');
      rethrow;
    }
  }

  /// Search coffee shops
  Future<List<CoffeeShop>> searchCoffeeShops({
    required String query,
    required double? userLat,
    required double? userLng,
    int? maxResults,
  }) async {
    // Check cache first
    final cachedResults = await _cacheManager.getCachedSearchResults(query);
    if (cachedResults != null) {
      AppLogger.info('Search cache hit: $query', tag: 'Repository');
      return cachedResults;
    }

    if (!_placesService.isReady) {
      // Return empty list to signal caller to fallback to local search
      return [];
    }

    try {
      List<CoffeeShop> results;
      if (userLat != null && userLng != null) {
        results = await _placesService.searchCafesWithFilters(
          query: query,
          userLat: userLat,
          userLng: userLng,
          maxResults: maxResults ?? 20,
        );
      } else {
        results = await _placesService.searchCafes(query);
      }

      await _cacheManager.cacheSearchResults(query, results);
      return results;
    } catch (e) {
      AppLogger.error('Error searching cafes', error: e, tag: 'Repository');
      rethrow;
    }
  }

  /// Load more cafes based on filter
  Future<List<CoffeeShop>> loadMoreCafes({
    required String filter,
    required double lat,
    required double lng,
    required Set<String> currentIds,
    int maxResults = 10,
  }) async {
    if (!_placesService.isReady) return [];

    try {
      List<CoffeeShop> newCafes = [];

      switch (filter) {
        case 'all':
           newCafes = await _placesService.searchCafesWithFilters(
            query: 'coffee shop',
            userLat: lat,
            userLng: lng,
            maxResults: maxResults,
          );
          break;
        case 'nearby':
          newCafes = await _placesService.findNearbyCafes(
            lat,
            lng,
            radius: 5000, // 5km
          );
          break;
        case 'topRated':
          newCafes = await _placesService.searchCafesWithFilters(
            query: 'cafe',
            userLat: lat,
            userLng: lng,
            maxResults: maxResults,
            minRating: 4.0,
          );
          break;
        case 'topReview':
          newCafes = await _placesService.searchCafesWithFilters(
            query: 'cafe',
            userLat: lat,
            userLng: lng,
            maxResults: maxResults,
            minReviewCount: 50,
          );
          break;
        default:
          return [];
      }

      // Calculate distances
      final cafesWithDist = _calculateDistances(newCafes, lat, lng);

      // Filter duplicates
      return cafesWithDist.where((c) => !currentIds.contains(c.id)).toList();
    } catch (e) {
      AppLogger.error('Error loading more cafes', error: e, tag: 'Repository');
      return [];
    }
  }

  /// Helper to calculate distances
  List<CoffeeShop> _calculateDistances(List<CoffeeShop> shops, double lat, double lng) {
    return shops.map((cafe) {
      final distanceInMeters = Geolocator.distanceBetween(
        lat,
        lng,
        cafe.latitude,
        cafe.longitude,
      );
      return cafe.copyWith(distance: distanceInMeters / 1000.0);
    }).toList();
  }
}
