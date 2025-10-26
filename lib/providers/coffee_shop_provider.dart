import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/coffee_shop.dart';
import '../services/location_service.dart';

class CoffeeShopProvider with ChangeNotifier {
  List<CoffeeShop> _coffeeShops = [];
  List<CoffeeShop> _nearbyCoffeeShops = [];
  bool _isLoading = false;
  String? _error;
  String? _searchQuery;
  double _userLatitude = 0.0;
  double _userLongitude = 0.0;

  List<CoffeeShop> get coffeeShops => _coffeeShops;
  List<CoffeeShop> get nearbyCoffeeShops => _nearbyCoffeeShops;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get searchQuery => _searchQuery;

  CoffeeShopProvider() {
    _initializeCoffeeShops();
  }

  Future<void> _initializeCoffeeShops() async {
    try {
      // Load JSON file from assets
      final String jsonString = await rootBundle.loadString('assets/data/coffee_shops.json');
      final List<dynamic> jsonData = json.decode(jsonString);

      // Convert JSON to CoffeeShop objects
      _coffeeShops = jsonData.map((json) => _parseCoffeeShop(json)).toList();

      _nearbyCoffeeShops = List.from(_coffeeShops);
      notifyListeners();
    } catch (e) {
      // If JSON loading fails, use empty list
      if (kDebugMode) {
        print('Error loading coffee shops from JSON: $e');
      }
      _coffeeShops = [];
      _nearbyCoffeeShops = [];
      notifyListeners();
    }
  }

  CoffeeShop _parseCoffeeShop(Map<String, dynamic> json) {
    // Parse opening hours
    final openingHoursJson = json['openingHours'] as Map<String, dynamic>;
    final openingHours = OpeningHours(
      monday: openingHoursJson['monday'] ?? '',
      tuesday: openingHoursJson['tuesday'] ?? '',
      wednesday: openingHoursJson['wednesday'] ?? '',
      thursday: openingHoursJson['thursday'] ?? '',
      friday: openingHoursJson['friday'] ?? '',
      saturday: openingHoursJson['saturday'] ?? '',
      sunday: openingHoursJson['sunday'] ?? '',
    );

    // Parse reviews
    final reviewsJson = json['reviews'] as List<dynamic>? ?? [];
    final reviews = reviewsJson.map((reviewJson) {
      return Review(
        id: reviewJson['id'] ?? '',
        userName: reviewJson['userName'] ?? '',
        rating: (reviewJson['rating'] ?? 0.0).toDouble(),
        comment: reviewJson['comment'] ?? '',
        date: DateTime.parse(reviewJson['date'] ?? DateTime.now().toIso8601String()),
        photos: (reviewJson['photos'] as List<dynamic>?)?.cast<String>() ?? [],
      );
    }).toList();

    // Parse visit data if exists
    VisitData? visitData;
    if (json['visitData'] != null) {
      final visitJson = json['visitData'] as Map<String, dynamic>;
      final visitDatesJson = visitJson['visitDates'] as List<dynamic>? ?? [];
      visitData = VisitData(
        personalRating: visitJson['personalRating']?.toDouble(),
        privateReview: visitJson['privateReview'],
        visitDates: visitDatesJson.map((date) => DateTime.parse(date)).toList(),
        createdAt: DateTime.parse(visitJson['createdAt'] ?? DateTime.now().toIso8601String()),
        updatedAt: DateTime.parse(visitJson['updatedAt'] ?? DateTime.now().toIso8601String()),
      );
    }

    // Parse tracking status
    CafeTrackingStatus trackingStatus;
    switch (json['trackingStatus']) {
      case 'visited':
        trackingStatus = CafeTrackingStatus.visited;
        break;
      case 'wantToVisit':
        trackingStatus = CafeTrackingStatus.wantToVisit;
        break;
      default:
        trackingStatus = CafeTrackingStatus.notTracked;
    }

    return CoffeeShop(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      website: json['website'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      photos: (json['photos'] as List<dynamic>?)?.cast<String>() ?? [],
      reviews: reviews,
      openingHours: openingHours,
      distance: 0.0,
      isOpen: true,
      isFavorite: false,
      trackingStatus: trackingStatus,
      visitData: visitData,
      socialMedia: (json['socialMedia'] as Map<String, dynamic>?)?.cast<String, String>(),
    );
  }

  Future<void> updateNearbyCoffeeShops() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        _userLatitude = position.latitude;
        _userLongitude = position.longitude;

        _nearbyCoffeeShops = _coffeeShops.map((shop) {
          final distance = LocationService.calculateDistance(
            _userLatitude,
            _userLongitude,
            shop.latitude,
            shop.longitude,
          );
          return shop.copyWith(distance: distance);
        }).toList();

        _nearbyCoffeeShops.sort((a, b) => a.distance.compareTo(b.distance));
      }
    } catch (e) {
      _error = 'Failed to get location';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void searchCoffeeShops(String query) {
    _searchQuery = query;
    _filterCoffeeShops();
  }

  void _filterCoffeeShops() {
    _nearbyCoffeeShops = _coffeeShops.where((shop) {
      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        return shop.name.toLowerCase().contains(_searchQuery!.toLowerCase()) ||
               shop.description.toLowerCase().contains(_searchQuery!.toLowerCase()) ||
               shop.address.toLowerCase().contains(_searchQuery!.toLowerCase());
      }
      return true;
    }).toList();

    notifyListeners();
  }

  void toggleFavorite(String coffeeShopId) {
    final index = _coffeeShops.indexWhere((shop) => shop.id == coffeeShopId);
    if (index != -1) {
      _coffeeShops[index] = _coffeeShops[index].copyWith(
        isFavorite: !_coffeeShops[index].isFavorite,
      );

      final nearbyIndex = _nearbyCoffeeShops.indexWhere((shop) => shop.id == coffeeShopId);
      if (nearbyIndex != -1) {
        _nearbyCoffeeShops[nearbyIndex] = _nearbyCoffeeShops[nearbyIndex].copyWith(
          isFavorite: _nearbyCoffeeShops[nearbyIndex].isFavorite,
        );
      }

      notifyListeners();
    }
  }

  List<CoffeeShop> getFavoriteCoffeeShops() {
    return _coffeeShops.where((shop) => shop.isFavorite).toList();
  }

  CoffeeShop? getCoffeeShopById(String id) {
    try {
      return _coffeeShops.firstWhere((shop) => shop.id == id);
    } catch (e) {
      return null;
    }
  }

  // Tracking functionality
  void addToWantToVisit(String coffeeShopId) {
    _updateTrackingStatus(coffeeShopId, CafeTrackingStatus.wantToVisit, null);
  }

  void markAsVisited(String coffeeShopId, {
    double? personalRating,
    String? privateReview,
    DateTime? visitDate,
    List<DateTime>? visitDates,
  }) {
    final shopIndex = _coffeeShops.indexWhere((shop) => shop.id == coffeeShopId);
    if (shopIndex == -1) return;

    final currentShop = _coffeeShops[shopIndex];
    List<DateTime> finalVisitDates = [];

    if (currentShop.visitData != null) {
      finalVisitDates = List.from(currentShop.visitData!.visitDates);
    }

    if (visitDates != null && visitDates.isNotEmpty) {
      finalVisitDates.addAll(visitDates);
    } else if (visitDate != null) {
      finalVisitDates.add(visitDate);
    }

    // Sort dates
    finalVisitDates.sort((a, b) => a.compareTo(b));

    final visitData = VisitData(
      personalRating: personalRating,
      privateReview: privateReview,
      visitDates: finalVisitDates,
    );

    _updateTrackingStatus(coffeeShopId, CafeTrackingStatus.visited, visitData);
  }

  void addVisitDate(String coffeeShopId, DateTime visitDate) {
    final shopIndex = _coffeeShops.indexWhere((shop) => shop.id == coffeeShopId);
    if (shopIndex == -1) return;

    final currentShop = _coffeeShops[shopIndex];
    if (currentShop.visitData == null) return;

    final updatedVisitDates = List<DateTime>.from(currentShop.visitData!.visitDates)
      ..add(visitDate);

    final updatedVisitData = currentShop.visitData!.copyWith(
      visitDates: updatedVisitDates,
    );

    _coffeeShops[shopIndex] = currentShop.copyWith(visitData: updatedVisitData);

    final nearbyIndex = _nearbyCoffeeShops.indexWhere((shop) => shop.id == coffeeShopId);
    if (nearbyIndex != -1) {
      _nearbyCoffeeShops[nearbyIndex] = _nearbyCoffeeShops[nearbyIndex].copyWith(
        visitData: updatedVisitData,
      );
    }

    notifyListeners();
  }

  void updateVisitData(String coffeeShopId, {
    double? personalRating,
    String? privateReview,
    List<DateTime>? visitDates,
  }) {
    final shopIndex = _coffeeShops.indexWhere((shop) => shop.id == coffeeShopId);
    if (shopIndex == -1) return;

    final currentShop = _coffeeShops[shopIndex];
    if (currentShop.visitData == null) return;

    final updatedVisitData = currentShop.visitData!.copyWith(
      personalRating: personalRating,
      privateReview: privateReview,
      visitDates: visitDates,
    );

    _coffeeShops[shopIndex] = currentShop.copyWith(visitData: updatedVisitData);

    final nearbyIndex = _nearbyCoffeeShops.indexWhere((shop) => shop.id == coffeeShopId);
    if (nearbyIndex != -1) {
      _nearbyCoffeeShops[nearbyIndex] = _nearbyCoffeeShops[nearbyIndex].copyWith(
        visitData: updatedVisitData,
      );
    }

    notifyListeners();
  }

  void removeFromWantToVisit(String coffeeShopId) {
    _updateTrackingStatus(coffeeShopId, CafeTrackingStatus.notTracked, null);
  }

  void removeFromTracking(String coffeeShopId) {
    _updateTrackingStatus(coffeeShopId, CafeTrackingStatus.notTracked, null);
  }

  void _updateTrackingStatus(String coffeeShopId, CafeTrackingStatus status, VisitData? visitData) {
    final index = _coffeeShops.indexWhere((shop) => shop.id == coffeeShopId);
    if (index != -1) {
      _coffeeShops[index] = _coffeeShops[index].copyWith(
        trackingStatus: status,
        visitData: visitData,
      );

      final nearbyIndex = _nearbyCoffeeShops.indexWhere((shop) => shop.id == coffeeShopId);
      if (nearbyIndex != -1) {
        _nearbyCoffeeShops[nearbyIndex] = _nearbyCoffeeShops[nearbyIndex].copyWith(
          trackingStatus: status,
          visitData: visitData,
        );
      }

      notifyListeners();
    }
  }

  List<CoffeeShop> getWantToVisitCoffeeShops() {
    return _coffeeShops.where((shop) => shop.trackingStatus == CafeTrackingStatus.wantToVisit).toList();
  }

  List<CoffeeShop> getVisitedCoffeeShops() {
    return _coffeeShops.where((shop) => shop.trackingStatus == CafeTrackingStatus.visited).toList();
  }

  List<CoffeeShop> getNotTrackedCoffeeShops() {
    return _coffeeShops.where((shop) => shop.trackingStatus == CafeTrackingStatus.notTracked).toList();
  }
}