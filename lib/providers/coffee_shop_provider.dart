import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/coffee_shop.dart';
import '../services/simple_places_service.dart';
import '../services/personal_tracking_service.dart';
import '../services/recommendation_service.dart';

class CoffeeShopProvider extends ChangeNotifier {
  // Private fields
  List<CoffeeShop> _coffeeShops = [];
  List<CoffeeShop> _nearbyCoffeeShops = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreCafes = true;
  int _currentLimit = 20; // Show 20 cafes first
  String? _error;
  String? _searchQuery;
  double _userLatitude = 0.0;
  double _userLongitude = 0.0;
  String _userLocation = 'Getting location...'; // Real-time GPS location
  String _activeFilter = 'all'; // 'all', 'nearby', 'topRated', 'openNow'

  // Service instances
  final SimplePlacesService _placesService = SimplePlacesService();
  final PersonalTrackingService _trackingService = PersonalTrackingService();

  // Public getters
  List<CoffeeShop> get coffeeShops => _coffeeShops;
  List<CoffeeShop> get nearbyCoffeeShops => _nearbyCoffeeShops;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreCafes => _hasMoreCafes;
  int get currentLimit => _currentLimit;
  String? get error => _error;
  String? get searchQuery => _searchQuery;
  double get userLatitude => _userLatitude;
  double get userLongitude => _userLongitude;
  String get userLocation => _userLocation;
  String get activeFilter => _activeFilter;

  // Get user region as formatted string
  String get userRegion {
    if (_userLocation == 'Getting location...' || _userLocation == 'Location disabled') {
      return 'Indonesia';
    }
    return _userLocation;
  }

  CoffeeShopProvider() {
    // Initialize Places API first
    SimplePlacesService.initialize();
    _initializeCoffeeShops();
    // Load tracking data from persistent storage AFTER coffee shops are loaded
    _loadTrackingDataFromPersistentStorage();
    _updateUserLocation();
  }

  // Initialize method that can be called after construction
  Future<void> initialize() async {
    await _loadTrackingDataFromPersistentStorage();
    await _updateUserLocation();
  }

  // Initialize with offline JSON data as fallback
  Future<void> _initializeCoffeeShops() async {
    _setLoading(true);
    try {
      // Try to get real-time location first
      await _updateUserLocation();

      // If we have user location, try nearby search first
      if (_userLatitude != 0.0 && _userLongitude != 0.0) {
        await _loadNearbyCoffeeShops();
      } else {
        // Fallback to JSON data
        await _useJsonDataWithDistance();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing coffee shops: $e');
      }
      // Fallback to JSON data if all else fails
      await _useJsonDataWithDistance();
    } finally {
      _setLoading(false);
    }
  }

  // Update user location using GPS
  Future<void> _updateUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _userLocation = 'Location disabled';
        _userLatitude = 0.0;
        _userLongitude = 0.0;
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _userLocation = 'Location permission denied';
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _userLocation = 'Location permission permanently denied';
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _userLatitude = position.latitude;
      _userLongitude = position.longitude;

      // Get address from coordinates (reverse geocoding)
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String city = place.locality ?? place.subAdministrativeArea ?? '';
        String sublocality = place.subLocality ?? place.name ?? '';

        if (sublocality.isNotEmpty && city.isNotEmpty) {
          _userLocation = '$sublocality, $city';
        } else if (city.isNotEmpty) {
          _userLocation = city;
        } else if (sublocality.isNotEmpty) {
          _userLocation = sublocality;
        } else {
          _userLocation = 'Unknown location';
        }
      } else {
        _userLocation = 'Location found';
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting location: $e');
      }
      _userLocation = 'Location error';
      notifyListeners();
    }
  }

  // Load nearby coffee shops using Google Places API
  Future<void> _loadNearbyCoffeeShops({bool isLoadMore = false}) async {
    if (_userLatitude == 0.0 || _userLongitude == 0.0) {
      await _useJsonDataWithDistance();
      return;
    }

    if (!isLoadMore) {
      _setLoading(true);
      _error = null;
    } else {
      _isLoadingMore = true;
      notifyListeners();
    }

    try {
      // Check if Places API is available
      if (!SimplePlacesService.isInitialized) {
        throw Exception('Places API not initialized');
      }

      final cafes = await _placesService.findNearbyCafes(
        _userLatitude,
        _userLongitude,
        radius: 5000, // 5km radius for more results
        limit: _currentLimit,
      );

      if (cafes.isNotEmpty) {
        if (!isLoadMore) {
          _coffeeShops = cafes;
        } else {
          _coffeeShops.addAll(cafes);
        }

        // Calculate distances for all cafes
        _coffeeShops = _coffeeShops.map((cafe) {
          final distanceInMeters = Geolocator.distanceBetween(
            _userLatitude,
            _userLongitude,
            cafe.latitude,
            cafe.longitude,
          );
          // Convert meters to kilometers
          final distanceInKm = distanceInMeters / 1000.0;
          return cafe.copyWith(distance: distanceInKm);
        }).toList();

        // Sort by distance
        _coffeeShops.sort((a, b) => a.distance.compareTo(b.distance));

        _hasMoreCafes = cafes.length >= _currentLimit;
      } else {
        _hasMoreCafes = false;
      }

      _applyActiveFilter();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading nearby cafes: $e');
      }
      _error = 'Failed to load nearby cafes: $e';

      // Fallback to JSON data
      if (!isLoadMore) {
        await _useJsonDataWithDistance();
      }
    } finally {
      if (!isLoadMore) {
        _setLoading(false);
      } else {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  // Load coffee shops from JSON asset with calculated distances
  Future<void> _useJsonDataWithDistance() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/coffee_shops.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      _coffeeShops = jsonList.map((json) => CoffeeShop.fromJson(json)).toList();

      // Randomize order for variety on each app restart
      _coffeeShops.shuffle(math.Random());

      // Calculate distances if we have user location
      if (_userLatitude != 0.0 && _userLongitude != 0.0) {
        _coffeeShops = _coffeeShops.map((cafe) {
          final distanceInMeters = Geolocator.distanceBetween(
            _userLatitude,
            _userLongitude,
            cafe.latitude,
            cafe.longitude,
          );
          // Convert meters to kilometers
          final distanceInKm = distanceInMeters / 1000.0;
          return cafe.copyWith(distance: distanceInKm);
        }).toList();

        // Sort by distance
        _coffeeShops.sort((a, b) => a.distance.compareTo(b.distance));
      }

      _applyActiveFilter();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading JSON data: $e');
      }
      _error = 'Failed to load coffee data: $e';
    }
  }

  // Apply the active filter to coffee shops
  void _applyActiveFilter() {
    switch (_activeFilter) {
      case 'nearby':
        final nearby = _coffeeShops.where((cafe) => cafe.distance <= 5.0).toList(); // 5km in kilometers
        nearby.sort((a, b) => a.distance.compareTo(b.distance)); // Sort by distance
        _nearbyCoffeeShops = nearby.take(_currentLimit).toList();
        _hasMoreCafes = _coffeeShops.length > _currentLimit && nearby.length >= _currentLimit;
        break;
      case 'topRated':
        final topRated = _coffeeShops.where((cafe) => cafe.rating >= 4.0).toList();
        topRated.sort((a, b) => b.rating.compareTo(a.rating)); // Sort by rating (highest first)
        _nearbyCoffeeShops = topRated.take(_currentLimit).toList();
        _hasMoreCafes = _coffeeShops.length > _currentLimit && topRated.length >= _currentLimit;
        break;
      case 'topReview':
        final topReview = List<CoffeeShop>.from(_coffeeShops);
        topReview.sort((a, b) => b.reviewCount.compareTo(a.reviewCount)); // Sort by review count
        _nearbyCoffeeShops = topReview.take(_currentLimit).toList();
        _hasMoreCafes = _coffeeShops.length > _currentLimit && topReview.length >= _currentLimit;
        break;
      case 'openNow':
        final openNow = _coffeeShops.where((cafe) => cafe.isOpen).toList();
        openNow.sort((a, b) => a.distance.compareTo(b.distance)); // Sort open cafes by distance
        _nearbyCoffeeShops = openNow.take(_currentLimit).toList();
        _hasMoreCafes = _coffeeShops.length > _currentLimit && openNow.length >= _currentLimit;
        break;
      case 'recommended':
        // This is handled by applyRecommendationFilter method
        // Don't apply regular filtering for recommendations
        break;
      case 'all':
      default:
        _nearbyCoffeeShops = _coffeeShops.take(_currentLimit).toList();
        _hasMoreCafes = _coffeeShops.length > _currentLimit;
        break;
    }

    if (kDebugMode && _activeFilter != 'recommended') {
      print('Filter "$_activeFilter": ${_coffeeShops.length} total, showing ${_nearbyCoffeeShops.length}');
    }
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Update nearby coffee shops (for pull-to-refresh)
  Future<void> updateNearbyCoffeeShops({bool forceRefresh = false}) async {
    await _updateUserLocation();
    await _loadNearbyCoffeeShops();
  }

  // Search coffee shops by query
  Future<void> searchCoffeeShops(String query) async {
    if (query.trim().isEmpty) {
      _searchQuery = null;
      await _initializeCoffeeShops();
      return;
    }

    _searchQuery = query;
    _setLoading(true);
    _error = null;

    try {
      // Check if Places API is available
      if (!SimplePlacesService.isInitialized) {
        // Fallback to local search in JSON data
        await _useJsonDataWithDistance();
        _coffeeShops = _coffeeShops.where((cafe) =>
          cafe.name.toLowerCase().contains(query.toLowerCase()) ||
          cafe.description.toLowerCase().contains(query.toLowerCase()) ||
          cafe.address.toLowerCase().contains(query.toLowerCase())
        ).toList();
      } else {
        // Use Google Places API for search
        List<CoffeeShop> searchResults = [];

        if (_userLatitude != 0.0 && _userLongitude != 0.0) {
          searchResults = await _placesService.searchCafesWithFilters(
            query: query,
            userLat: _userLatitude,
            userLng: _userLongitude,
            maxResults: _currentLimit,
          );
        } else {
          searchResults = await _placesService.searchCafes(query);
        }

        _coffeeShops = searchResults;
      }

      _applyActiveFilter();
    } catch (e) {
      if (kDebugMode) {
        print('Error searching coffee shops: $e');
      }
      _error = 'Failed to search: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Load more coffee shops
  Future<void> loadMoreCoffeeShops() async {
    if (_isLoadingMore || !_hasMoreCafes) return;

    _currentLimit += 20;
    _isLoadingMore = true;
    notifyListeners();

    if (_userLatitude != 0.0 && _userLongitude != 0.0 && SimplePlacesService.isInitialized) {
      await _loadNearbyCoffeeShops(isLoadMore: true);
    } else {
      _applyActiveFilter();
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Set active filter
  void setActiveFilter(String filter) {
    _activeFilter = filter;
    _currentLimit = 20; // Reset limit when changing filter
    _applyActiveFilter();
    notifyListeners();
  }

  // Add coffee shop to want-to-visit list
  Future<void> addToWantToVisit(String coffeeShopId) async {
    await _trackingService.addToWishlist(coffeeShopId);
    await _loadTrackingDataFromPersistentStorage();
  }

  // Remove coffee shop from want-to-visit list
  Future<void> removeFromWantToVisit(String coffeeShopId) async {
    await _trackingService.removeFromWishlist(coffeeShopId);
    await _loadTrackingDataFromPersistentStorage();
  }

  // Toggle coffee shop favorite status
  Future<void> toggleFavorite(String coffeeShopId) async {
    await _trackingService.toggleFavorite(coffeeShopId);
    await _loadTrackingDataFromPersistentStorage();
  }

  // Get want-to-visit coffee shops (sync version for screens)
  List<CoffeeShop> get wantToVisitCoffeeShops {
    return _coffeeShops.where((shop) => shop.trackingStatus == CafeTrackingStatus.wantToVisit).toList();
  }

  // Get favorite coffee shops (sync version for screens)
  List<CoffeeShop> get favoriteCoffeeShops {
    return _coffeeShops.where((shop) => shop.isFavorite).toList();
  }

  // Get visited coffee shops (sync version for screens)
  List<CoffeeShop> get visitedCoffeeShops {
    return _coffeeShops.where((shop) => shop.trackingStatus == CafeTrackingStatus.visited).toList();
  }

  // Get not tracked coffee shops (sync version for screens)
  List<CoffeeShop> get notTrackedCoffeeShops {
    return _coffeeShops.where((shop) => shop.trackingStatus == CafeTrackingStatus.notTracked).toList();
  }

  // Get want-to-visit coffee shops (async version)
  Future<List<CoffeeShop>> getWantToVisitCoffeeShops() async {
    final wishlistIds = await _trackingService.getWishlist();
    return _coffeeShops.where((shop) => wishlistIds.contains(shop.id)).toList();
  }

  // Get favorite coffee shops (async version)
  Future<List<CoffeeShop>> getFavoriteCoffeeShops() async {
    final favoriteIds = await _trackingService.getFavorites();
    return _coffeeShops.where((shop) => favoriteIds.contains(shop.id)).toList();
  }

  // Get visited coffee shops (async version)
  Future<List<CoffeeShop>> getVisitedCoffeeShops() async {
    // Visited shops are those with visit data
    return _coffeeShops.where((shop) {
      return shop.trackingStatus == CafeTrackingStatus.visited;
    }).toList();
  }

  // Get not tracked coffee shops (async version)
  Future<List<CoffeeShop>> getNotTrackedCoffeeShops() async {
    final wishlistIds = await _trackingService.getWishlist();
    final favoriteIds = await _trackingService.getFavorites();

    final trackedIds = {...wishlistIds, ...favoriteIds};

    return _coffeeShops.where((shop) =>
      !trackedIds.contains(shop.id) &&
      shop.trackingStatus == CafeTrackingStatus.notTracked
    ).toList();
  }

  // Mark coffee shop as visited
  Future<void> markAsVisited(String coffeeShopId, {
    String? note,
    int? rating,
    List<String>? photos,
    List<DateTime>? visitDates,
  }) async {
    final visitData = VisitData(
      personalRating: rating?.toDouble(),
      privateReview: note ?? '',
      visitDates: visitDates ?? [DateTime.now()],
    );

    await _trackingService.saveVisitData(coffeeShopId, visitData);
    await _loadTrackingDataFromPersistentStorage();
  }

  // Update visit data for a coffee shop
  Future<void> updateVisitData(String coffeeShopId, VisitData visitData) async {
    await _trackingService.saveVisitData(coffeeShopId, visitData);
    await _loadTrackingDataFromPersistentStorage();
  }

  // Add a single visit date to existing visit data
  Future<void> addVisitDate(String coffeeShopId, VisitData visitData) async {
    await _trackingService.saveVisitData(coffeeShopId, visitData);
    await _loadTrackingDataFromPersistentStorage();
  }

  // Get visit data for a specific coffee shop
  Future<VisitData?> getVisitData(String coffeeShopId) async {
    return await _trackingService.getVisitData(coffeeShopId);
  }

  // Get user statistics
  Future<UserStats> getUserStats() async {
    return await _trackingService.getUserStats();
  }

  // Clear all tracking data
  Future<void> clearAllTrackingData() async {
    await _trackingService.clearAllData();
    await _loadTrackingDataFromPersistentStorage();
  }

  // Get coffee shop by ID
  CoffeeShop? getCoffeeShopById(String coffeeShopId) {
    try {
      return _coffeeShops.firstWhere((shop) => shop.id == coffeeShopId);
    } catch (e) {
      return null;
    }
  }

  // Load tracking data from persistent storage and update coffee shops
  Future<void> _loadTrackingDataFromPersistentStorage() async {
    try {
      print('🔄 Loading tracking data from persistent storage...');

      final wishlistIds = await _trackingService.getWishlist();
      final favoriteIds = await _trackingService.getFavorites();

      final updatedShops = <CoffeeShop>[];
      for (final shop in _coffeeShops) {
        CafeTrackingStatus status = CafeTrackingStatus.notTracked;
        VisitData? visitData;

        final shopVisitData = await _trackingService.getVisitData(shop.id);
        if (shopVisitData != null) {
          status = CafeTrackingStatus.visited;
          visitData = shopVisitData;
        } else if (wishlistIds.contains(shop.id)) {
          status = CafeTrackingStatus.wantToVisit;
        } else if (favoriteIds.contains(shop.id)) {
          status = CafeTrackingStatus.wantToVisit;
        }

        updatedShops.add(shop.copyWith(
          trackingStatus: status,
          visitData: visitData,
          isFavorite: favoriteIds.contains(shop.id),
        ));
      }

      _coffeeShops = updatedShops;
      _applyActiveFilter();

      print('✅ Tracking data loaded: ${wishlistIds.length} wishlist, ${favoriteIds.length} favorites');
      notifyListeners();
    } catch (e) {
      print('❌ Error loading tracking data: $e');
      // Continue without tracking data if error occurs
      _applyActiveFilter();
      notifyListeners();
    }
  }

  // Refresh coffee shops with new random order
  Future<void> refreshCoffeeShops() async {
    _setLoading(true);
    _error = null;

    try {
      // Reload JSON data to get fresh random order
      await _useJsonDataWithDistance();

      // Apply tracking data to maintain user's existing tracking
      await _loadTrackingDataFromPersistentStorage();
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing coffee shops: $e');
      }
      _error = 'Failed to refresh coffee shops: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Get personalized recommendations using the RecommendationService
  Future<List<CoffeeShop>> getRecommendations() async {
    try {
      if (kDebugMode) {
        print('🎯 Generating personalized recommendations...');
      }

      // Get recommendations from the service
      final recommendations = await RecommendationService.getRecommendations(_coffeeShops);

      if (kDebugMode) {
        print('✅ Generated ${recommendations.length} personalized recommendations');
      }

      return recommendations;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting recommendations: $e');
      }

      // Fallback to top-rated cafes
      final topRated = _coffeeShops
          .where((cafe) => cafe.rating >= 4.0)
          .toList()
        ..sort((a, b) => b.rating.compareTo(a.rating));

      return topRated.take(10).toList();
    }
  }

  // Get recommendations by specific category
  Future<List<CoffeeShop>> getRecommendationsByCategory(String category) async {
    try {
      if (kDebugMode) {
        print('🎯 Getting recommendations for category: $category');
      }

      return await RecommendationService.getRecommendationsByCategory(_coffeeShops, category);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting category recommendations: $e');
      }
      return [];
    }
  }

  // Refresh recommendations with updated user data
  Future<List<CoffeeShop>> refreshRecommendations() async {
    try {
      if (kDebugMode) {
        print('🔄 Refreshing recommendations with updated user data...');
      }

      // Reload tracking data first
      await _loadTrackingDataFromPersistentStorage();

      // Get fresh recommendations
      return await getRecommendations();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error refreshing recommendations: $e');
      }
      return [];
    }
  }

  // Apply recommendation filter (shows personalized recommendations)
  Future<void> applyRecommendationFilter() async {
    _setLoading(true);
    _activeFilter = 'recommended';

    try {
      // Get personalized recommendations
      final recommendations = await getRecommendations();

      // Update nearby coffee shops with recommendations
      _nearbyCoffeeShops = recommendations;
      _hasMoreCafes = false; // Recommendations are a fixed list

      if (kDebugMode) {
        print('✅ Applied recommendation filter: ${recommendations.length} cafes');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error applying recommendation filter: $e');
      }
      _error = 'Failed to get recommendations: $e';
    } finally {
      _setLoading(false);
    }
  }
}