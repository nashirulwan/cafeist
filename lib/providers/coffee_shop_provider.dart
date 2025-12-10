import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/coffee_shop.dart';
import '../services/coffee_shop_repository.dart';
import '../services/places_service.dart';
import '../services/personal_tracking_service.dart';
import '../services/recommendation_service.dart';
import '../services/firebase_service.dart';
import '../services/firebase_sync_service.dart';
import '../utils/cache_manager.dart';
import '../utils/logger.dart';
import '../utils/debouncer.dart';

class CoffeeShopProvider extends ChangeNotifier {
  // Private fields
  List<CoffeeShop> _coffeeShops = [];
  List<CoffeeShop> _nearbyCoffeeShops = [];
  
  // Dedicated persistence lists
  List<CoffeeShop> _wishlistShops = [];
  List<CoffeeShop> _favoriteShops = [];
  List<CoffeeShop> _visitedShops = [];

  Set<String> _favoriteIds = {}; // Track favorite IDs independently for quick lookup
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
  
  // Flag to prevent re-initialization
  bool _isInitialized = false;

  // Pagination fields for infinite scroll
  List<CoffeeShop> _displayedCoffeeShops = [];
  int _allCafesPage = 0;
  int _nearbyCafesPage = 0;
  int _topRatedPage = 0;
  int _topReviewPage = 0;
  int _pageSize = 10; // Load 10 more items per page

  // Location field for distance calculations
  Position? _currentPosition;

  // Service instances
  // Repository
  late final CoffeeShopRepository _repository;
  final PersonalTrackingService _trackingService = PersonalTrackingService();
  final PlacesService _placesService = PlacesService();
  final CacheManager _cacheManager = CacheManager();

  final LocationDebouncer _locationDebouncer = LocationDebouncer();

  // Performance tracking
  DateTime? _lastUpdateTime;
  bool _isRefreshing = false;

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
    _repository = CoffeeShopRepository();
    // Initialize repository/services
    PlacesService.initialize();
  }

  // Initialize method that can be called after construction
  Future<void> initialize() async {
    await _loadTrackingDataFromPersistentStorage();
    await _updateUserLocation();
  }

  /// Called after user login to refresh tracking data from SharedPreferences
  /// (which was just synced from Firebase cloud)
  Future<void> refreshTrackingDataAfterLogin() async {
    if (kDebugMode) {
      print('🔄 Refreshing tracking data after login...');
    }
    await _loadTrackingDataFromPersistentStorage();
    notifyListeners();
  }

  /// Called after user logout to clear in-memory tracking data
  void clearTrackingDataAfterLogout() {
    if (kDebugMode) {
      print('🧹 Clearing in-memory tracking data after logout...');
    }
    _favoriteIds.clear();
    _wishlistShops.clear();
    _favoriteShops.clear();
    // Clear tracking status from coffee shops
    _coffeeShops = _coffeeShops.map((shop) => shop.copyWith(
      trackingStatus: CafeTrackingStatus.notTracked,
      isFavorite: false,
      visitData: null,
    )).toList();
    _nearbyCoffeeShops = _nearbyCoffeeShops.map((shop) => shop.copyWith(
      trackingStatus: CafeTrackingStatus.notTracked,
      isFavorite: false,
      visitData: null,
    )).toList();
    notifyListeners();
  }

  /// Initialize only if not already initialized - prevents re-init on navigation
  Future<void> initializeIfNeeded() async {
    if (_isInitialized && _coffeeShops.isNotEmpty) return;
    _isInitialized = true;
    await _initializeCoffeeShops();
  }

  // Initialize coffee shops - API ONLY, no local JSON fallback
  Future<void> _initializeCoffeeShops() async {
    _setLoading(true);
    _error = null;
    
    try {
      // Get user location first - REQUIRED for API calls
      await _updateUserLocation();

      // Must have valid location to load cafes
      if (_userLatitude == 0.0 || _userLongitude == 0.0) {
        _error = 'Location required to find cafes. Please enable GPS.';
        _coffeeShops = [];
        _nearbyCoffeeShops = [];
        _setLoading(false);
        return;
      }

      // Load cafes from API based on current location
      await _loadNearbyCoffeeShops();
      
      // If no results from API, show appropriate message
      if (_coffeeShops.isEmpty) {
        _error = 'No cafes found nearby. Try a different location.';
      }
      
      // Apply the active filter
      _applyActiveFilter();
      
      // Load tracking data
      await _loadTrackingDataFromPersistentStorage();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing coffee shops: $e');
      }
      _error = 'Failed to load cafes. Please check your connection.';
      _coffeeShops = [];
      _nearbyCoffeeShops = [];
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

      _currentPosition = position;
      _userLatitude = position.latitude;
      _userLongitude = position.longitude;

      // Get address from coordinates (reverse geocoding)
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        // Build location string with proper international support
        List<String> locationParts = [];

        // Add street/area if available
        if (place.thoroughfare?.isNotEmpty == true) {
          locationParts.add(place.thoroughfare!);
        } else if (place.subLocality?.isNotEmpty == true) {
          locationParts.add(place.subLocality!);
        } else if (place.name?.isNotEmpty == true && !place.name!.contains('Unnamed')) {
          locationParts.add(place.name!);
        }

        // Determine country for proper formatting
        final country = place.country ?? '';
        final isIndonesia = country.toLowerCase().contains('indonesia') || country == 'ID';

        // Build location string based on country
        if (isIndonesia) {
          // Indonesian format: District, City
          String? city;
          if (place.locality?.isNotEmpty == true) {
            city = place.locality;
          } else if (place.subAdministrativeArea?.isNotEmpty == true) {
            city = place.subAdministrativeArea;
          } else if (place.administrativeArea?.isNotEmpty == true) {
            city = place.administrativeArea;
          }

          if (city != null && city.isNotEmpty) {
            locationParts.add(city);
          }

          // Only add country if we need more context
          if (locationParts.length < 2) {
            locationParts.add('Indonesia');
          }
        } else {
          // International format: Street/District, City, State/Country

          // Add city/town first
          String? city;
          if (place.locality?.isNotEmpty == true) {
            city = place.locality;
          } else if (place.subAdministrativeArea?.isNotEmpty == true) {
            city = place.subAdministrativeArea;
          } else if (place.administrativeArea?.isNotEmpty == true) {
            city = place.administrativeArea;
          }

          if (city != null && city.isNotEmpty) {
            locationParts.add(city);
          }

          // Add state/province for international locations
          if (place.administrativeArea?.isNotEmpty == true &&
              place.administrativeArea != city) {
            locationParts.add(place.administrativeArea!);
          }

          // Always add country for international locations
          if (country.isNotEmpty) {
            locationParts.add(country);
          }
        }

        // Build final location string
        if (locationParts.isNotEmpty) {
          _userLocation = locationParts.join(', ');
          AppLogger.info('Location parsed: $_userLocation', tag: 'Location');
        } else {
          _userLocation = 'Unknown location';
          AppLogger.warning('Could not parse location from: ${place.toJson()}', tag: 'Location');
        }
      } else {
        _userLocation = 'Location found';
        AppLogger.debug('Location found but no placemarks', tag: 'Location');
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

  // Load nearby coffee shops - API ONLY
  Future<void> _loadNearbyCoffeeShops({bool isLoadMore = false}) async {
    // Require valid GPS location
    if (_userLatitude == 0.0 || _userLongitude == 0.0) {
      _error = 'Location required. Please enable GPS.';
      _coffeeShops = [];
      _nearbyCoffeeShops = [];
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
      final cafes = await _repository.getNearbyCoffeeShops(
        lat: _userLatitude,
        lng: _userLongitude,
        radius: 5000,
        limit: _currentLimit,
      );

      if (cafes.isNotEmpty) {
        if (!isLoadMore) {
          _coffeeShops = cafes;
        } else {
          _coffeeShops.addAll(cafes);
        }

        // Sort by distance
        _coffeeShops.sort((a, b) => a.distance.compareTo(b.distance));

        _hasMoreCafes = cafes.length >= _currentLimit;
      } else {
        if (!isLoadMore) {
          _coffeeShops = [];
          _nearbyCoffeeShops = [];
        }
        _hasMoreCafes = false;
        _error = 'No cafes found nearby.';
      }

      _applyActiveFilter();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading nearby cafes: $e');
      }
      _error = 'Failed to load cafes. Check your connection.';
      if (!isLoadMore) {
        _coffeeShops = [];
        _nearbyCoffeeShops = [];
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

  // NOTE: Local JSON loading methods removed - app uses API only

  // Apply the active filter to coffee shops
  void _applyActiveFilter() {
    switch (_activeFilter) {
      case 'nearby':
        final nearby = _coffeeShops.where((cafe) => cafe.distance <= 10.0).toList(); // 10km in kilometers
        nearby.sort((a, b) => a.distance.compareTo(b.distance)); // Sort by distance
        _nearbyCoffeeShops = nearby.take(_currentLimit).toList();
        _hasMoreCafes = nearby.length > _currentLimit;
        break;
      case 'topRated':
        // Filter by distance FIRST (within 10km), then by rating
        final topRatedNearby = _coffeeShops.where((cafe) => cafe.distance <= 10.0 && cafe.rating >= 4.0).toList();
        topRatedNearby.sort((a, b) => b.rating.compareTo(a.rating)); // Sort by rating (highest first)
        _nearbyCoffeeShops = topRatedNearby.take(_currentLimit).toList();
        _hasMoreCafes = topRatedNearby.length > _currentLimit;
        break;
      case 'topReview':
        // Filter by distance FIRST (within 10km), then by review count
        final topReviewNearby = _coffeeShops.where((cafe) => cafe.distance <= 10.0).toList();
        topReviewNearby.sort((a, b) => b.reviewCount.compareTo(a.reviewCount)); // Sort by review count
        _nearbyCoffeeShops = topReviewNearby.take(_currentLimit).toList();
        _hasMoreCafes = topReviewNearby.length > _currentLimit;
        break;
      case 'openNow':
        final openNow = _coffeeShops.where((cafe) => cafe.isOpen).toList();
        openNow.sort((a, b) => a.distance.compareTo(b.distance)); // Sort open cafes by distance
        _nearbyCoffeeShops = openNow.take(_currentLimit).toList();
        _hasMoreCafes = openNow.length > _currentLimit;
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
      print('Filter "$_activeFilter": ${_coffeeShops.length} total, showing ${_nearbyCoffeeShops.length}, hasMore: $_hasMoreCafes');
      // Debug: Check for empty IDs
      final emptyIdCafes = _nearbyCoffeeShops.where((c) => c.id.isEmpty).length;
      if (emptyIdCafes > 0) {
        print('⚠️ WARNING: $emptyIdCafes cafes have empty IDs!');
        print('First few cafe IDs: ${_nearbyCoffeeShops.take(5).map((c) => c.id).toList()}');
      }
    }
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Public setLoading method for pagination
  void setLoading(bool loading) {
    _setLoading(loading);
  }

  // Calculate distance between two points
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000.0; // Convert to km
  }

  // Update nearby coffee shops (for pull-to-refresh)
  Future<void> updateNearbyCoffeeShops({bool forceRefresh = false}) async {
    await _updateUserLocation();
    await _loadNearbyCoffeeShops();
  }

  // Search coffee shops by query (optimized with debouncing and caching)
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
      AppLogger.debug('Searching for: $query', tag: 'Search');

      // Use repository for search
      final results = await _repository.searchCoffeeShops(
        query: query,
        userLat: _userLatitude != 0.0 ? _userLatitude : null,
        userLng: _userLongitude != 0.0 ? _userLongitude : null,
        maxResults: _currentLimit,
      );

      if (results.isEmpty) {
        _coffeeShops = [];
        _nearbyCoffeeShops = [];
        _error = 'No results found for "$query"';
      } else {
        _coffeeShops = results;
        _error = null;
      }

      _applyActiveFilter();
    } catch (e) {
      AppLogger.error('Error searching coffee shops', error: e, tag: 'Search');
      _error = 'Search failed. Please check your connection.';
      _coffeeShops = [];
      _nearbyCoffeeShops = [];
    } finally {
      _setLoading(false);
    }
  }

  // Load more coffee shops with pagination
  Future<void> loadMoreCoffeeShops() async {
    if (_isLoadingMore || !_hasMoreCafes) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      AppLogger.info('Loading more cafes... currentLimit: $_currentLimit, total: ${_coffeeShops.length}', tag: 'Pagination');
      
      if (_activeFilter == 'all') {
        // For "All" filter - show more from existing shuffled list
        if (_coffeeShops.length > _currentLimit) {
          _currentLimit += 10;
          _nearbyCoffeeShops = _coffeeShops.take(_currentLimit).toList();
          AppLogger.info('Showing $_currentLimit of ${_coffeeShops.length} cafes', tag: 'Pagination');
        } else {
          // No more cafes to show
          _hasMoreCafes = false;
          AppLogger.info('No more cafes to load', tag: 'Pagination');
        }
      } else {
        // For other filters, show more from already-filtered list
        final previousCount = _nearbyCoffeeShops.length;
        _currentLimit += 10;
        _applyActiveFilter();
        
        // Check if we've shown all available cafes for this filter
        if (_nearbyCoffeeShops.length == previousCount) {
          _hasMoreCafes = false;
          AppLogger.info('No more filtered cafes to load', tag: 'Pagination');
        }
      }
    } catch (e) {
      AppLogger.error('Error loading more cafes', error: e, tag: 'Pagination');
      _hasMoreCafes = false;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Set active filter - now triggers API calls for specific filters
  Future<void> setActiveFilter(String filter, {bool isRefresh = false}) async {
    if (_activeFilter == filter && !isRefresh) return;

    _activeFilter = filter;
    
    // Reset limit when switching filters
    _currentLimit = 20;
    
    _setLoading(true);

    try {
      if (filter == 'topRated' || filter == 'topReview') {
        // Fetch FRESH data from API for these filters
        await _loadFilteredCoffeeShops(filter);
      } else if (filter == 'nearby') {
        // "Nearby" is effectively our default load
        if (_coffeeShops.isEmpty || isRefresh) {
          await _loadNearbyCoffeeShops();
        } else {
           // Just re-apply helper to cached list
           _applyActiveFilter();
        }
      } else if (filter == 'all') {
         if (isRefresh) await refreshCoffeeShops();
         else _applyActiveFilter();
      } else {
        // Other filters (openNow, etc.) just re-sort existing
        _applyActiveFilter();
      }
    } catch (e) {
      AppLogger.error('Error setting filter', error: e, tag: 'Provider');
      _error = 'Failed to load data for filter';
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Load specifically filtered shops from API
  Future<void> _loadFilteredCoffeeShops(String filter) async {
    if (_userLatitude == 0.0 || _userLongitude == 0.0) {
      // No GPS - show message instead of wrong data
      _nearbyCoffeeShops = [];
      _hasMoreCafes = false;
      AppLogger.warning('Cannot load filtered shops: no GPS location', tag: 'Provider');
      return;
    }
    
    try {
      List<CoffeeShop> results = [];
      
      if (filter == 'topRated') {
         // Use repository to fetch with minRating
         results = await _repository.loadMoreCafes(
           filter: 'topRated',
           lat: _userLatitude, 
           lng: _userLongitude,
           currentIds: {},
           maxResults: 20
         );
         // Sort by rating (highest first)
         results.sort((a, b) => b.rating.compareTo(a.rating));
      } else if (filter == 'topReview') {
         results = await _repository.loadMoreCafes(
           filter: 'topReview',
           lat: _userLatitude,
           lng: _userLongitude,
           currentIds: {},
           maxResults: 20
         );
         // Sort by review count (most reviews first)
         results.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
      }
      
      if (results.isNotEmpty) {
        _nearbyCoffeeShops = results;
        _hasMoreCafes = results.length >= _currentLimit;
      } else {
         // API returned empty - show empty list, don't fall back to stale data
         // The distance filter in _applyActiveFilter will handle this correctly
         // but only if _coffeeShops has correct distances based on CURRENT location
         
         // Recalculate distances for existing shops before filtering
         _coffeeShops = _coffeeShops.map((cafe) {
           final distanceInMeters = Geolocator.distanceBetween(
             _userLatitude, _userLongitude,
             cafe.latitude, cafe.longitude,
           );
           return cafe.copyWith(distance: distanceInMeters / 1000.0);
         }).toList();
         
         _applyActiveFilter();
      }
    } catch (e) {
      AppLogger.error('Error loading filtered shops', error: e, tag: 'Provider');
      // On error, also recalculate distances before applying filter
      _coffeeShops = _coffeeShops.map((cafe) {
        final distanceInMeters = Geolocator.distanceBetween(
          _userLatitude, _userLongitude,
          cafe.latitude, cafe.longitude,
        );
        return cafe.copyWith(distance: distanceInMeters / 1000.0);
      }).toList();
      _applyActiveFilter();
    }
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

  // Remove coffee shop from visited list
  Future<void> removeFromVisited(String coffeeShopId) async {
    await _trackingService.removeFromVisited(coffeeShopId);
    await _loadTrackingDataFromPersistentStorage();
  }

  // Toggle coffee shop favorite status
  Future<void> toggleFavorite(String coffeeShopId) async {
    // Optimistically update local state first
    if (_favoriteIds.contains(coffeeShopId)) {
      _favoriteIds.remove(coffeeShopId);
    } else {
      _favoriteIds.add(coffeeShopId);
    }
    notifyListeners(); // Immediate feedback

    // Toggle in local storage and sync (async)
    try {
      await _trackingService.toggleFavorite(coffeeShopId);
      
      // We don't need to full reload tracking data if we just want to update favorites
      // But _loadTrackingDataFromPersistentStorage updates the _coffeeShops list objects too
      await _loadTrackingDataFromPersistentStorage();
    } catch (e) {
      // Revert if failed
      if (_favoriteIds.contains(coffeeShopId)) {
        _favoriteIds.remove(coffeeShopId);
      } else {
        _favoriteIds.add(coffeeShopId);
      }
      notifyListeners();
      if (kDebugMode) {
        print('❌ Failed to toggle favorite: $e');
      }
    }
  }

  // Get want-to-visit coffee shops (sync version for screens)
  List<CoffeeShop> get wantToVisitCoffeeShops {
    return _wishlistShops;
  }

  // Get favorite coffee shops (sync version for screens)
  List<CoffeeShop> get favoriteCoffeeShops {
    return _favoriteShops;
  }

  // Get visited coffee shops (sync version for screens)
  List<CoffeeShop> get visitedCoffeeShops {
    return _coffeeShops.where((shop) => shop.trackingStatus == CafeTrackingStatus.visited).toList();
  }

  // Get not tracked coffee shops (sync version for screens)
  List<CoffeeShop> get notTrackedCoffeeShops {
    return _coffeeShops.where((shop) => shop.trackingStatus == CafeTrackingStatus.notTracked).toList();
  }

  // Get want-to-visit coffee shops (async version) - fetches missing details from API
  Future<List<CoffeeShop>> getWantToVisitCoffeeShops() async {
    final wishlistIds = await _trackingService.getWishlist();
    
    // Get wishlisted shops available in local memory cache
    var wishlistShops = _coffeeShops.where((shop) => wishlistIds.contains(shop.id)).toList();
    
    // Find IDs that are NOT in local cache
    final cachedIds = wishlistShops.map((s) => s.id).toSet();
    final missingIds = wishlistIds.where((id) => id.isNotEmpty && !cachedIds.contains(id)).toList();
    
    // Fetch details for missing IDs from API
    if (missingIds.isNotEmpty) {
      final fetchedFutures = missingIds.map((id) async {
         try {
           return await _repository.getCoffeeShopById(id);
         } catch (e) {
           return null;
         }
      });
      
      final fetchedShops = await Future.wait(fetchedFutures);
      for (final shop in fetchedShops) {
        if (shop != null) {
          wishlistShops.add(shop.copyWith(trackingStatus: CafeTrackingStatus.wantToVisit));
        }
      }
    }

    // Calculate distances for wishlist shops
    if (_userLatitude != 0.0 && _userLongitude != 0.0) {
      wishlistShops = wishlistShops.map((cafe) {
        final distanceInMeters = Geolocator.distanceBetween(
          _userLatitude,
          _userLongitude,
          cafe.latitude,
          cafe.longitude,
        );
        return cafe.copyWith(distance: distanceInMeters / 1000.0);
      }).toList();

      // Sort by distance
      wishlistShops.sort((a, b) => a.distance.compareTo(b.distance));
    }

    return wishlistShops;
  }

  // Get favorite coffee shops (async version)
  Future<List<CoffeeShop>> getFavoriteCoffeeShops() async {
    // Use in-memory _favoriteIds as source of truth to ensure immediate UI updates
    final favoriteIds = _favoriteIds.toList();
    
    // Get favorites available in local memory cache
    var favoriteShops = _coffeeShops.where((shop) => _favoriteIds.contains(shop.id)).toList();
    
    // Find IDs that are NOT in local cache (e.g. from Explore/Search)
    final cachedIds = favoriteShops.map((s) => s.id).toSet();
    final missingIds = favoriteIds.where((id) => id.isNotEmpty && !cachedIds.contains(id)).toList();
    
    // Fetch details for missing IDs
    if (missingIds.isNotEmpty) {
      final fetchedFutures = missingIds.map((id) async {
         try {
           return await _repository.getCoffeeShopById(id);
         } catch (e) {
           return null;
         }
      });
      
      final fetchedShops = await Future.wait(fetchedFutures);
      for (final shop in fetchedShops) {
        if (shop != null) {
          favoriteShops.add(shop.copyWith(isFavorite: true));
        }
      }
    }

    // Calculate distances for favorite shops
    if (_userLatitude != 0.0 && _userLongitude != 0.0) {
      favoriteShops = favoriteShops.map((cafe) {
        final distanceInMeters = Geolocator.distanceBetween(
          _userLatitude,
          _userLongitude,
          cafe.latitude,
          cafe.longitude,
        );
        final distanceInKm = distanceInMeters / 1000.0;
        return cafe.copyWith(distance: distanceInKm);
      }).toList();

      favoriteShops.sort((a, b) => a.distance.compareTo(b.distance));
    }

    return favoriteShops;
  }

  // Get visited coffee shops (async version) - fetches missing details from API
  Future<List<CoffeeShop>> getVisitedCoffeeShops() async {
    final visitedIds = await _trackingService.getVisitedIds();
    
    // Get visited shops available in local memory cache
    var visitedShops = _coffeeShops.where((shop) => visitedIds.contains(shop.id)).toList();
    
    // Find IDs that are NOT in local cache
    final cachedIds = visitedShops.map((s) => s.id).toSet();
    final missingIds = visitedIds.where((id) => id.isNotEmpty && !cachedIds.contains(id)).toList();
    
    // Fetch details for missing IDs from API
    if (missingIds.isNotEmpty) {
      final fetchedFutures = missingIds.map((id) async {
         try {
           final shop = await _repository.getCoffeeShopById(id);
           if (shop != null) {
             final visitData = await _trackingService.getVisitData(id);
             return shop.copyWith(
               trackingStatus: CafeTrackingStatus.visited,
               visitData: visitData,
             );
           }
           return null;
         } catch (e) {
           return null;
         }
      });
      
      final fetchedShops = await Future.wait(fetchedFutures);
      for (final shop in fetchedShops) {
        if (shop != null) {
          visitedShops.add(shop);
        }
      }
    }

    // Ensure all shops have visit data
    visitedShops = await Future.wait(visitedShops.map((shop) async {
      if (shop.visitData == null) {
        final visitData = await _trackingService.getVisitData(shop.id);
        return shop.copyWith(visitData: visitData, trackingStatus: CafeTrackingStatus.visited);
      }
      return shop;
    }));

    // Calculate distances for visited shops
    if (_userLatitude != 0.0 && _userLongitude != 0.0) {
      visitedShops = visitedShops.map((cafe) {
        final distanceInMeters = Geolocator.distanceBetween(
          _userLatitude,
          _userLongitude,
          cafe.latitude,
          cafe.longitude,
        );
        return cafe.copyWith(distance: distanceInMeters / 1000.0);
      }).toList();

      // Sort by distance
      visitedShops.sort((a, b) => a.distance.compareTo(b.distance));
    }

    return visitedShops;
  }

  // Get not tracked coffee shops (async version)
  Future<List<CoffeeShop>> getNotTrackedCoffeeShops() async {
    final wishlistIds = await _trackingService.getWishlist();
    final favoriteIds = await _trackingService.getFavorites();
    final trackedIds = <String>{...wishlistIds, ...favoriteIds};
    return _coffeeShops.where((shop) => !trackedIds.contains(shop.id) && shop.trackingStatus == CafeTrackingStatus.notTracked).toList();
  }

  // Mark coffee shop as visited
  Future<void> markAsVisited(String coffeeShopId, {String? note, int? rating, List<String>? photos, List<DateTime>? visitDates}) async {
    final visitData = VisitData(
      personalRating: rating?.toDouble(),
      privateReview: note ?? '',
      visitDates: visitDates ?? [DateTime.now()],
    );
    await _trackingService.saveVisitData(coffeeShopId, visitData);
    await _loadTrackingDataFromPersistentStorage();
  }

  // Update visit data
  Future<void> updateVisitData(String coffeeShopId, VisitData visitData) async {
    await _trackingService.saveVisitData(coffeeShopId, visitData);
    await _loadTrackingDataFromPersistentStorage();
  }

  // Add visit date
  Future<void> addVisitDate(String coffeeShopId, VisitData visitData) async {
    await _trackingService.saveVisitData(coffeeShopId, visitData);
    await _loadTrackingDataFromPersistentStorage();
  }

  // Get visit data
  Future<VisitData?> getVisitData(String coffeeShopId) async {
    return await _trackingService.getVisitData(coffeeShopId);
  }

  // Get user stats
  Future<UserStats> getUserStats() async {
    return await _trackingService.getUserStats();
  }

  // Clear all data
  Future<void> clearAllTrackingData() async {
    await _trackingService.clearAllData();
    await _loadTrackingDataFromPersistentStorage();
  }

  // Get by ID
  CoffeeShop? getCoffeeShopById(String coffeeShopId) {
    try {
      return _coffeeShops.firstWhere((shop) => shop.id == coffeeShopId);
    } catch (e) {
      return null;
    }
  }

  // Is favorite
  bool isFavorite(String id) {
    return _favoriteIds.contains(id);
  }

  // Load tracking data from persistent storage and update coffee shops
  Future<void> _loadTrackingDataFromPersistentStorage() async {
    try {
      print('🔄 Loading tracking data from persistent storage...');

      final wishlistIds = (await _trackingService.getWishlist()).where((id) => id.isNotEmpty).toList();
      final favoriteIds = (await _trackingService.getFavorites()).where((id) => id.isNotEmpty).toList();
      
      // Update the main list status as before
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
        }
        
        updatedShops.add(shop.copyWith(
          trackingStatus: status,
          visitData: visitData,
          isFavorite: favoriteIds.contains(shop.id),
        ));
      }
      _coffeeShops = updatedShops;
      
      // NOW: Build dedicated persistence lists
      // 1. Wishlist
      _wishlistShops.clear();
      for (final id in wishlistIds) {
        // Try finding in current loaded main list
        var shop = _coffeeShops.firstWhere((s) => s.id == id, orElse: () => CoffeeShop.empty());
        
        if (shop.id.isEmpty) {
           // Not in main list? Try repository fetch (async but we need to await)
           final fetched = await _repository.getCoffeeShopById(id);
           if (fetched != null) {
             shop = fetched.copyWith(trackingStatus: CafeTrackingStatus.wantToVisit);
           }
        }
        
        if (shop.id.isNotEmpty) {
          _wishlistShops.add(shop);
        }
      }
      
      // 2. Favorites
      _favoriteShops.clear();
      for (final id in favoriteIds) {
         var shop = _coffeeShops.firstWhere((s) => s.id == id, orElse: () => CoffeeShop.empty());
         
         if (shop.id.isEmpty) {
            final fetched = await _repository.getCoffeeShopById(id);
            if (fetched != null) {
              shop = fetched.copyWith(isFavorite: true);
            }
         }
         
         if (shop.id.isNotEmpty) {
           // Ensure isFavorite is true
           if (!shop.isFavorite) shop = shop.copyWith(isFavorite: true);
           _favoriteShops.add(shop);
         }
      }

      // 3. Visited
      _visitedShops.clear();
      // We need to find all shops that have visit data. 
      // This is a bit more complex as we don't have a simple list of IDs like wishlist/favorites
      // But we can iterate the visits map if we had it, or we rely on the implementation detail that tracking service
      // stores visits in a map key-ed by ID. 
      // However, here we only have getVisitData(id).
      // Let's assume for now we only support visited shops that are in the main list OR 
      // we need to ask TrackingService for ALL visited IDs.
      // The current PersonalTrackingService doesn't expose getAllVisitedIds easily without getting the whole map.
      // Let's update PersonalTrackingService later if needed, but for now, let's just leave Visited as is 
      // OR better: The user strictly complained about "My List" (Wishlist) and "Favorites".
      // Let's just fix the Visited getter to be consistent if we can, otherwise leave it safely as a "subset of available" 
      // if that's acceptable, but ideally we want it all. 
      // Actually tracking service has `getVisitData` but not `getAllVisitedIds`.
      // Let's stick to what we promised: Wishlist and Favorites.
      
      print('✅ Tracking data loaded: ${_wishlistShops.length} wishlist, ${_favoriteShops.length} favorites');
      _favoriteIds = Set<String>.from(favoriteIds);
      
      // Re-apply filter to update UI view
      if (_activeFilter != 'topRated' && _activeFilter != 'topReview') {
         _applyActiveFilter();
      } else {
         notifyListeners();
      }
      notifyListeners();
    } catch (e) {
      print('❌ Error loading tracking data: $e');
      // Continue without tracking data if error occurs
      _applyActiveFilter();
      notifyListeners();
    }
  }

  // Refresh coffee shops with new random order and diverse results
  Future<void> refreshCoffeeShops() async {
    if (_isRefreshing) return; // Prevent multiple simultaneous refreshes

    _isRefreshing = true;
    _setLoading(true);
    _error = null;

    try {
      AppLogger.info('Refreshing coffee shops with enhanced diversity', tag: 'Refresh');

      // Clear cache to force fresh data
      await _cacheManager.clearAll();

      // Reset pagination limits
      _currentLimit = 20;

      // Update location for fresh results
      await _updateUserLocation();

      // Must have valid location
      if (_userLatitude == 0.0 || _userLongitude == 0.0) {
        _error = 'Location required. Please enable GPS.';
        _coffeeShops = [];
        _nearbyCoffeeShops = [];
        _isRefreshing = false;
        _setLoading(false);
        return;
      }

      // Use API for fresh results
      await _loadDiverseCoffeeShopsFromAPI();

      // Apply tracking data to maintain user's existing tracking
      await _loadTrackingDataFromPersistentStorage();

      // Clear any existing filter to show fresh results
      if (_activeFilter == 'all') {
        _nearbyCoffeeShops = _coffeeShops.take(_currentLimit).toList();
        _hasMoreCafes = _coffeeShops.length > _currentLimit;
      } else {
        _applyActiveFilter();
      }

      AppLogger.success('Coffee shops refreshed successfully: ${_coffeeShops.length} total', tag: 'Refresh');
    } catch (e) {
      AppLogger.error('Error refreshing coffee shops', error: e, tag: 'Refresh');
      _error = 'Failed to refresh coffee shops: $e';
    } finally {
      _isRefreshing = false;
      _setLoading(false);
    }
  }

  // Load diverse coffee shops from API with random parameters
  Future<void> _loadDiverseCoffeeShopsFromAPI() async {
    try {
      AppLogger.info('Loading diverse coffee shops from API', tag: 'API');

      // Generate random search terms for diversity
      final random = math.Random();
      final searchTerms = [
        'coffee shop',
        'cafe',
        'espresso',
        'latte art',
        'wifi coffee',
        'study cafe',
        'breakfast coffee',
        'specialty coffee',
        'coffee beans',
        'local coffee',
        'third wave coffee',
        'artisan coffee',
        'roastery',
        'coffee house',
        'kopi',
        'coffee bar',
      ];

      // Use multiple search terms and radius variations for diversity
      List<CoffeeShop> diverseResults = [];
      final selectedTerms = searchTerms..shuffle(random);
      final numTerms = math.min(4, selectedTerms.length); // Use up to 4 different terms

      // Vary radius for different search types
      final radii = [3000, 5000, 8000, 12000]; // 3km, 5km, 8km, 12km
      radii.shuffle(random);

      for (int i = 0; i < numTerms; i++) {
        final term = selectedTerms[i];
        final radius = radii[i % radii.length];

        try {
          List<CoffeeShop> results;

          // Use radius-based search for first half, text search for second half
          if (i < (numTerms / 2)) {
            results = await _placesService.findNearbyCafes(
              _userLatitude,
              _userLongitude,
              radius: radius,
              limit: 20,
            );
          } else {
            results = await _placesService.searchCafesWithFilters(
              query: term,
              userLat: _userLatitude,
              userLng: _userLongitude,
              maxResults: 20,
            );
          }

          // Add results that aren't already in our list
          for (final cafe in results) {
            if (!diverseResults.any((existing) => existing.id == cafe.id)) {
              diverseResults.add(cafe);
            }
          }
        } catch (e) {
          AppLogger.warning('Failed search for term: $term, radius: $radius', tag: 'API');
          continue; // Continue with next term even if one fails
        }
      }

      // Calculate distances if not already calculated
      if (_userLatitude != 0.0 && _userLongitude != 0.0) {
        diverseResults = diverseResults.map((cafe) {
          final distanceInMeters = Geolocator.distanceBetween(
            _userLatitude,
            _userLongitude,
            cafe.latitude,
            cafe.longitude,
          );
          final distanceInKm = distanceInMeters / 1000.0;
          return cafe.copyWith(distance: distanceInKm);
        }).toList();
      }

      // Mix sorting: partially by distance, partially random for discovery
      final sortedByDistance = List<CoffeeShop>.from(diverseResults)
        ..sort((a, b) => a.distance.compareTo(b.distance));

      final shuffled = List<CoffeeShop>.from(diverseResults)..shuffle(random);

      // Combine: 60% distance-sorted, 40% random for discovery
      final distanceCount = (sortedByDistance.length * 0.6).round();
      final randomCount = (shuffled.length * 0.4).round();

      diverseResults = [
        ...sortedByDistance.take(distanceCount),
        ...shuffled.take(randomCount),
      ];

      // Remove duplicates that might appear in both lists
      final uniqueCafes = <String>{};
      diverseResults = diverseResults.where((cafe) {
        if (uniqueCafes.contains(cafe.id)) return false;
        uniqueCafes.add(cafe.id);
        return true;
      }).toList();

      _coffeeShops = diverseResults.take(60).toList(); // Increased limit for more variety
      _applyActiveFilter();

      AppLogger.success('Loaded ${_coffeeShops.length} diverse coffee shops', tag: 'API');
    } catch (e) {
      AppLogger.error('Error loading diverse coffee shops from API', error: e, tag: 'API');
      _error = 'Failed to load cafes. Please check your connection.';
      _coffeeShops = [];
      _nearbyCoffeeShops = [];
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

  // Pagination methods for infinite scroll









  /// Get visible coffee shops based on current filter and pagination
  List<CoffeeShop> getVisibleCoffeeShops() {
    switch (_activeFilter) {
      case 'all':
      case 'nearby':
      case 'topRated':
      case 'topReview':
      case 'openNow':
      case 'recommended':
        return _nearbyCoffeeShops;
      default:
        return _coffeeShops.take(_currentLimit).toList();
    }
  }






  /// Sort cafes by distance from current location
  List<CoffeeShop> _sortCafesByDistance(List<CoffeeShop> cafes) {
    if (_currentPosition == null) return cafes;

    final cafesWithDistance = cafes.map((cafe) {
      final distance = _calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        cafe.latitude,
        cafe.longitude,
      );
      return cafe.copyWith(distance: distance);
    }).toList();

    cafesWithDistance.sort((a, b) => a.distance.compareTo(b.distance));
    return cafesWithDistance;
  }

  void setError(String error) {
    _error = error;
    notifyListeners();
  }



  /// Check if provider is mounted (for async operations)
  bool get mounted => true; // Simplified for provider

  // Load more cafes from API for ALL filter
  Future<void> _loadMoreAllCafesFromAPI() async {
    try {
      final newCafes = await _placesService.findNearbyCafes(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        radius: 20000, // 20km radius for variety
      );

      // Calculate distances
      final newCafesWithDistance = newCafes.map((cafe) {
        final distance = _calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          cafe.latitude,
          cafe.longitude,
        );
        return cafe.copyWith(distance: distance);
      }).toList();

      // Add to existing coffee shops and remove duplicates
      final existingIds = _coffeeShops.map((cafe) => cafe.id).toSet();
      final uniqueNewCafes = newCafesWithDistance.where((cafe) => !existingIds.contains(cafe.id)).toList();

      if (uniqueNewCafes.isNotEmpty) {
        _coffeeShops.addAll(uniqueNewCafes);
        AppLogger.info('Loaded ${uniqueNewCafes.length} new cafes from API', tag: 'Pagination');
      }

      _applyActiveFilter();
    } catch (e) {
      AppLogger.error('Failed to load more cafes from API', error: e, tag: 'Pagination');
      _hasMoreCafes = false; // No more data available
    }
  }

  // Load more cafes from API for NEARBY filter
  Future<void> _loadMoreNearbyCafesFromAPI() async {
    try {
      final newCafes = await _placesService.findNearbyCafes(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        radius: 30000, // 30km radius for more nearby options
      );

      // Calculate distances
      final newCafesWithDistance = newCafes.map((cafe) {
        final distance = _calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          cafe.latitude,
          cafe.longitude,
        );
        return cafe.copyWith(distance: distance);
      }).toList();

      // Add to existing coffee shops and remove duplicates
      final existingIds = _coffeeShops.map((cafe) => cafe.id).toSet();
      final uniqueNewCafes = newCafesWithDistance.where((cafe) => !existingIds.contains(cafe.id)).toList();

      if (uniqueNewCafes.isNotEmpty) {
        _coffeeShops.addAll(uniqueNewCafes);
        AppLogger.info('Loaded ${uniqueNewCafes.length} new nearby cafes from API', tag: 'Pagination');
      }

      _applyActiveFilter();
    } catch (e) {
      AppLogger.error('Failed to load more nearby cafes from API', error: e, tag: 'Pagination');
      _hasMoreCafes = false; // No more data available
    }
  }

  // Load more cafes from API for TOP RATED filter
  Future<void> _loadMoreTopRatedCafesFromAPI() async {
    try {
      final newCafes = await _placesService.searchCafesWithFilters(
        query: 'cafe',
        userLat: _currentPosition!.latitude,
        userLng: _currentPosition!.longitude,
        maxResults: 20,
        minRating: 4.0,
      );

      // Calculate distances
      final newCafesWithDistance = newCafes.map((cafe) {
        final distance = _calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          cafe.latitude,
          cafe.longitude,
        );
        return cafe.copyWith(distance: distance);
      }).toList();

      // Add to existing coffee shops and remove duplicates
      final existingIds = _coffeeShops.map((cafe) => cafe.id).toSet();
      final uniqueNewCafes = newCafesWithDistance.where((cafe) => !existingIds.contains(cafe.id)).toList();

      if (uniqueNewCafes.isNotEmpty) {
        _coffeeShops.addAll(uniqueNewCafes);
        AppLogger.info('Loaded ${uniqueNewCafes.length} new top rated cafes from API', tag: 'Pagination');
      }

      _applyActiveFilter();
    } catch (e) {
      AppLogger.error('Failed to load more top rated cafes from API', error: e, tag: 'Pagination');
      _hasMoreCafes = false; // No more data available
    }
  }

  // Load more cafes from API for TOP REVIEW filter
  Future<void> _loadMoreTopReviewCafesFromAPI() async {
    try {
      final newCafes = await _placesService.searchCafesWithFilters(
        query: 'cafe',
        userLat: _currentPosition!.latitude,
        userLng: _currentPosition!.longitude,
        maxResults: 20,
        minReviewCount: 50,
      );

      // Calculate distances
      final newCafesWithDistance = newCafes.map((cafe) {
        final distance = _calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          cafe.latitude,
          cafe.longitude,
        );
        return cafe.copyWith(distance: distance);
      }).toList();

      // Add to existing coffee shops and remove duplicates
      final existingIds = _coffeeShops.map((cafe) => cafe.id).toSet();
      final uniqueNewCafes = newCafesWithDistance.where((cafe) => !existingIds.contains(cafe.id)).toList();

      if (uniqueNewCafes.isNotEmpty) {
        _coffeeShops.addAll(uniqueNewCafes);
        AppLogger.info('Loaded ${uniqueNewCafes.length} new top review cafes from API', tag: 'Pagination');
      }

      _applyActiveFilter();
    } catch (e) {
      AppLogger.error('Failed to load more top review cafes from API', error: e, tag: 'Pagination');
      _hasMoreCafes = false; // No more data available
    }
  }
}