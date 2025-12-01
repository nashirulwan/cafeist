import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/coffee_shop.dart';
import '../services/location_discovery_service.dart';
import '../services/firebase_service.dart';

/// Provider for location-based cafe discovery
class LocationDiscoveryProvider extends ChangeNotifier {
  Position? _currentLocation;
  List<CoffeeShop> _nearbyCafes = [];
  List<CoffeeShop> _regionalCafes = [];
  List<CoffeeShop> _trendingCafes = [];
  List<CoffeeShop> _personalizedRecommendations = [];
  Map<String, dynamic> _regionalRecommendations = {};
  String _selectedRegion = '';
  List<String> _nearbyCities = [];
  bool _isLoading = false;
  bool _isLocationEnabled = false;
  String? _error;

  // Getters
  Position? get currentLocation => _currentLocation;
  List<CoffeeShop> get nearbyCafes => List.unmodifiable(_nearbyCafes);
  List<CoffeeShop> get regionalCafes => List.unmodifiable(_regionalCafes);
  List<CoffeeShop> get trendingCafes => List.unmodifiable(_trendingCafes);
  List<CoffeeShop> get personalizedRecommendations => List.unmodifiable(_personalizedRecommendations);
  Map<String, dynamic> get regionalRecommendations => Map.unmodifiable(_regionalRecommendations);
  String get selectedRegion => _selectedRegion;
  List<String> get nearbyCities => List.unmodifiable(_nearbyCities);
  bool get isLoading => _isLoading;
  bool get isLocationEnabled => _isLocationEnabled;
  String? get error => _error;

  // Computed properties
  List<CoffeeShop> get allDiscoveredCafes {
    return [
      ..._nearbyCafes,
      ..._regionalCafes,
      ..._trendingCafes,
      ..._personalizedRecommendations,
    ];
  }

  bool get hasLocation => _currentLocation != null;

  /// Initialize location discovery
  Future<void> initialize() async {
    _setLoading(true);
    _clearError();

    try {
      if (kDebugMode) {
        print('🌍 Initializing location discovery...');
      }

      await _checkLocationPermission();
      if (_isLocationEnabled) {
        await _getCurrentLocation();
        await _loadDiscoveryData();
      } else {
        // Load default data without location
        await _loadDefaultDiscoveryData();
      }

      if (kDebugMode) {
        print('✅ Location discovery initialized');
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to initialize location discovery: $e');
      if (kDebugMode) {
        print('❌ Location discovery initialization failed: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh current location data
  Future<void> refreshLocation() async {
    if (!_isLocationEnabled) return;

    _setLoading(true);
    _clearError();

    try {
      await _getCurrentLocation();
      await _loadDiscoveryData();

      if (kDebugMode) {
        print('✅ Location discovery refreshed');
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to refresh location: $e');
      if (kDebugMode) {
        print('❌ Location refresh failed: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Discover cafes by region
  Future<void> discoverByRegion(String region) async {
    if (region == _selectedRegion) return;

    _setLoading(true);
    _clearError();
    _selectedRegion = region;

    try {
      if (kDebugMode) {
        print('🗺️ Discovering cafes in region: $region');
      }

      _regionalCafes = await LocationDiscoveryService.discoverCafesByRegion(
        region: region,
        maxResults: 30,
      );

      // Update trending cafes for this region
      _trendingCafes = await LocationDiscoveryService.getTrendingCafes(
        region: region,
        maxResults: 15,
      );

      if (kDebugMode) {
        print('✅ Found ${_regionalCafes.length} cafes in $region');
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to discover cafes in $region: $e');
      if (kDebugMode) {
        print('❌ Regional discovery failed: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Search cafes with filters
  Future<void> searchCafesWithFilters({
    String? query,
    double? minRating,
    int? minReviewCount,
    bool? openNow,
    String? sortBy,
    int maxResults = 20,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      if (kDebugMode) {
        print('🔍 Searching cafes with filters: $query');
      }

      final cafes = await LocationDiscoveryService.searchCafesAdvanced(
        query: query,
        userLat: _currentLocation?.latitude,
        userLng: _currentLocation?.longitude,
        minRating: minRating,
        minReviewCount: minReviewCount,
        openNow: openNow,
        sortBy: sortBy,
        maxResults: maxResults,
      );

      // Update nearby cafes if this is a location-based search
      if (_currentLocation != null) {
        _nearbyCafes = cafes;
      } else {
        _regionalCafes = cafes;
      }

      if (kDebugMode) {
        print('✅ Found ${cafes.length} cafes with filters');
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to search cafes: $e');
      if (kDebugMode) {
        print('❌ Cafe search failed: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Discover cafes with specific features
  Future<void> discoverCafesWithFeatures({
    required List<String> features,
    String? region,
    int radius = 15000,
    int maxResults = 20,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      if (kDebugMode) {
        print('🎯 Discovering cafes with features: ${features.join(', ')}');
      }

      final cafes = await LocationDiscoveryService.discoverCafesWithFeatures(
        features: features,
        region: region,
        userLocation: _currentLocation,
        radius: radius,
        maxResults: maxResults,
      );

      // Add to appropriate category
      if (_currentLocation != null) {
        _nearbyCafes.addAll(cafes);
        // Remove duplicates
        _nearbyCafes = _nearbyCafes.where((cafe) =>
            !_regionalCafes.any((r) => r.id == cafe.id) &&
            !_trendingCafes.any((t) => t.id == cafe.id)
        ).toList();
      } else {
        _regionalCafes.addAll(cafes);
        // Remove duplicates
        _regionalCafes = _regionalCafes.where((cafe) =>
            !_nearbyCafes.any((n) => n.id == cafe.id) &&
            !_trendingCafes.any((t) => t.id == cafe.id)
        ).toList();
      }

      if (kDebugMode) {
        print('✅ Found ${cafes.length} cafes with specified features');
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to discover cafes with features: $e');
      if (kDebugMode) {
        print('❌ Feature-based discovery failed: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Load personalized recommendations
  Future<void> loadPersonalizedRecommendations() async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return;

    _setLoading(true);
    _clearError();

    try {
      if (kDebugMode) {
        print('🎯 Loading personalized recommendations for user $userId');
      }

      _personalizedRecommendations = await LocationDiscoveryService.getPersonalizedRecommendations(
        userId: userId,
        maxResults: 20,
      );

      if (kDebugMode) {
        print('✅ Loaded ${_personalizedRecommendations.length} personalized recommendations');
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to load personalized recommendations: $e');
      if (kDebugMode) {
        print('❌ Personalized recommendations failed: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Get cafes near current location
  Future<void> getCafesNearCurrentLocation({
    int radius = 5000,
    double? minRating,
    bool? openNow,
    int maxResults = 20,
  }) async {
    if (_currentLocation == null) {
      _setError('Location not available. Enable location services.');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      if (kDebugMode) {
        print('📍 Getting cafes near current location');
      }

      _nearbyCafes = await LocationDiscoveryService.getCafesNearLocation(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        radius: radius,
        minRating: minRating,
        openNow: openNow,
        maxResults: maxResults,
      );

      if (kDebugMode) {
        print('✅ Found ${_nearbyCafes.length} cafes nearby');
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to get nearby cafes: $e');
      if (kDebugMode) {
        print('❌ Nearby cafes search failed: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Get trending cafes
  Future<void> getTrendingCafes({String? region, int maxResults = 15}) async {
    _setLoading(true);
    _clearError();

    try {
      if (kDebugMode) {
        print('🔥 Getting trending cafes ${region != null ? 'in $region' : 'globally'}');
      }

      _trendingCafes = await LocationDiscoveryService.getTrendingCafes(
        region: region,
        maxResults: maxResults,
      );

      if (kDebugMode) {
        print('✅ Found ${_trendingCafes.length} trending cafes');
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to get trending cafes: $e');
      if (kDebugMode) {
        print('❌ Trending cafes failed: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Get regional recommendations
  Future<void> getRegionalRecommendations() async {
    if (_currentLocation == null) return;

    _setLoading(true);
    _clearError();

    try {
      if (kDebugMode) {
        print('🗺️ Getting regional recommendations');
      }

      _regionalRecommendations = await LocationDiscoveryService.getRegionalRecommendations(
        userLocation: _currentLocation,
        radius: 20000,
      );

      _selectedRegion = _regionalRecommendations['currentRegion'] ?? 'Unknown';
      _nearbyCities = List<String>.from(_regionalRecommendations['nearbyCities'] ?? []);

      if (kDebugMode) {
        print('✅ Regional recommendations loaded for $_selectedRegion');
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to get regional recommendations: $e');
      if (kDebugMode) {
        print('❌ Regional recommendations failed: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Update user's current location
  Future<void> updateLocation(double latitude, double longitude) async {
    _currentLocation = Position(
      latitude: latitude,
      longitude: longitude,
      accuracy: 0.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      timestamp: DateTime.now(),
      floor: 0,
      isMocked: false,
    );

    if (kDebugMode) {
      print('📍 Location updated: $latitude, $longitude');
    }

    notifyListeners();
  }

  /// Clear all discovery data
  void clearDiscoveryData() {
    _nearbyCafes.clear();
    _regionalCafes.clear();
    _trendingCafes.clear();
    _personalizedRecommendations.clear();
    _regionalRecommendations.clear();
    _nearbyCities.clear();
    _selectedRegion = '';

    if (kDebugMode) {
      print('🗑️ Discovery data cleared');
    }

    notifyListeners();
  }

  /// Retry last failed operation
  Future<void> retry() async {
    _clearError();
    await initialize();
  }

  // Private helper methods

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    _isLocationEnabled = serviceEnabled;

    if (!serviceEnabled) {
      if (kDebugMode) {
        print('⚠️ Location services are disabled');
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _isLocationEnabled = false;
        if (kDebugMode) {
          print('❌ Location permissions denied');
        }
        return;
      }
    }

    _isLocationEnabled = true;
    if (kDebugMode) {
      print('✅ Location permissions granted');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      _currentLocation = await LocationDiscoveryService.getCurrentLocation();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get current location: $e');
      }
      _isLocationEnabled = false;
    }
  }

  Future<void> _loadDiscoveryData() async {
    if (_currentLocation == null) {
      await _loadDefaultDiscoveryData();
      return;
    }

    // Load data in parallel
    final futures = await Future.wait([
      LocationDiscoveryService.getCafesNearCurrentLocation(maxResults: 15),
      LocationDiscoveryService.getTrendingCafes(maxResults: 10),
      LocationDiscoveryService.getRegionalRecommendations(userLocation: _currentLocation),
    ]);

    _nearbyCafes = futures[0] as List<CoffeeShop>;
    _trendingCafes = futures[1] as List<CoffeeShop>;
    _regionalRecommendations = futures[2] as Map<String, dynamic>;
    _selectedRegion = _regionalRecommendations['currentRegion'] ?? 'Unknown';
    _nearbyCities = List<String>.from(_regionalRecommendations['nearbyCities'] ?? []);

    // Load personalized recommendations if user is logged in
    final userId = FirebaseService.currentUserId;
    if (userId != null) {
      try {
        _personalizedRecommendations = await LocationDiscoveryService.getPersonalizedRecommendations(
          userId: userId,
          maxResults: 10,
        );
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Failed to load personalized recommendations: $e');
        }
      }
    }
  }

  Future<void> _loadDefaultDiscoveryData() async {
    // Load trending cafes as default when location is not available
    _trendingCafes = await LocationDiscoveryService.getTrendingCafes(maxResults: 25);
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
}