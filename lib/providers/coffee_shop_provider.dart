import 'package:flutter/foundation.dart';
import '../models/coffee_shop.dart';
import '../services/location_service.dart';

class CoffeeShopProvider with ChangeNotifier {
  List<CoffeeShop> _coffeeShops = [];
  List<CoffeeShop> _nearbyCoffeeShops = [];
  bool _isLoading = false;
  String? _error;
  String? _searchQuery;
  List<String> _selectedFeatures = [];
  double _userLatitude = 0.0;
  double _userLongitude = 0.0;

  List<CoffeeShop> get coffeeShops => _coffeeShops;
  List<CoffeeShop> get nearbyCoffeeShops => _nearbyCoffeeShops;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get searchQuery => _searchQuery;
  List<String> get selectedFeatures => _selectedFeatures;

  CoffeeShopProvider() {
    _initializeCoffeeShops();
  }

  void _initializeCoffeeShops() {
    _coffeeShops = [
      CoffeeShop(
        id: '1',
        name: 'Artisan Coffee Roasters',
        description: 'Premium coffee shop with specialty beans and expert baristas. Perfect for coffee connoisseurs.',
        address: '123 Main St, New York, NY 10001',
        phoneNumber: '+1 (555) 123-4567',
        website: 'https://artisancoffee.com',
        latitude: 40.7580,
        longitude: -73.9855,
        rating: 4.8,
        reviewCount: 324,
        photos: [
          'https://picsum.photos/seed/coffee1/400/300',
          'https://picsum.photos/seed/coffee2/400/300',
          'https://picsum.photos/seed/coffee3/400/300',
        ],
        features: ['WiFi', 'Outdoor Seating', 'Pet Friendly', 'Vegan Options'],
        reviews: [
          Review(
            id: '1',
            userName: 'Sarah Johnson',
            rating: 5.0,
            comment: 'Amazing coffee and atmosphere! The baristas are so knowledgeable.',
            date: DateTime.now().subtract(const Duration(days: 2)),
            photos: [],
          ),
          Review(
            id: '2',
            userName: 'Mike Chen',
            rating: 4.5,
            comment: 'Great place to work. Fast WiFi and excellent coffee.',
            date: DateTime.now().subtract(const Duration(days: 5)),
            photos: [],
          ),
        ],
        openingHours: OpeningHours(
          monday: '7:00 AM - 8:00 PM',
          tuesday: '7:00 AM - 8:00 PM',
          wednesday: '7:00 AM - 8:00 PM',
          thursday: '7:00 AM - 8:00 PM',
          friday: '7:00 AM - 9:00 PM',
          saturday: '8:00 AM - 9:00 PM',
          sunday: '8:00 AM - 7:00 PM',
        ),
        trackingStatus: CafeTrackingStatus.visited,
        visitData: VisitData(
          personalRating: 4.5,
          privateReview: 'Great atmosphere for working, excellent espresso.',
          visitDates: [
            DateTime.now().subtract(const Duration(days: 10)),
            DateTime.now().subtract(const Duration(days: 3)),
          ],
        ),
        pricePerPerson: 12.50,
        socialMedia: {
          'instagram': 'https://instagram.com/artisancoffee',
          'facebook': 'https://facebook.com/artisancoffee',
          'twitter': 'https://twitter.com/artisancoffee',
        },
      ),
      CoffeeShop(
        id: '2',
        name: 'The Daily Grind',
        description: 'Cozy neighborhood coffee shop with fresh pastries and friendly staff.',
        address: '456 Oak Ave, Brooklyn, NY 11201',
        phoneNumber: '+1 (555) 987-6543',
        website: 'https://dailygrind.com',
        latitude: 40.6892,
        longitude: -73.9442,
        rating: 4.6,
        reviewCount: 189,
        photos: [
          'https://picsum.photos/seed/grind1/400/300',
          'https://picsum.photos/seed/grind2/400/300',
        ],
        features: ['WiFi', 'Breakfast', 'Pastries', 'Credit Cards'],
        reviews: [
          Review(
            id: '3',
            userName: 'Emily Davis',
            rating: 4.0,
            comment: 'Good coffee and pastries. Can get busy in the mornings.',
            date: DateTime.now().subtract(const Duration(days: 1)),
            photos: [],
          ),
        ],
        openingHours: OpeningHours(
          monday: '6:30 AM - 6:00 PM',
          tuesday: '6:30 AM - 6:00 PM',
          wednesday: '6:30 AM - 6:00 PM',
          thursday: '6:30 AM - 6:00 PM',
          friday: '6:30 AM - 7:00 PM',
          saturday: '7:00 AM - 7:00 PM',
          sunday: '7:00 AM - 5:00 PM',
        ),
        trackingStatus: CafeTrackingStatus.wantToVisit,
        visitData: null,
        pricePerPerson: 8.75,
        socialMedia: {
          'instagram': 'https://instagram.com/dailygrind',
          'facebook': 'https://facebook.com/dailygrind',
        },
      ),
      CoffeeShop(
        id: '3',
        name: 'Café Lumière',
        description: 'French-inspired café with elegant atmosphere and premium espresso drinks.',
        address: '789 Pine St, Manhattan, NY 10003',
        phoneNumber: '+1 (555) 246-8135',
        website: 'https://cafelumiere.com',
        latitude: 40.7260,
        longitude: -73.9897,
        rating: 4.9,
        reviewCount: 467,
        photos: [
          'https://picsum.photos/seed/lumiere1/400/300',
          'https://picsum.photos/seed/lumiere2/400/300',
          'https://picsum.photos/seed/lumiere3/400/300',
          'https://picsum.photos/seed/lumiere4/400/300',
        ],
        features: ['WiFi', 'Romantic', 'Wine', 'Desserts', 'Outdoor Seating'],
        reviews: [
          Review(
            id: '4',
            userName: 'David Wilson',
            rating: 5.0,
            comment: 'Perfect for a date night or quiet work session. Excellent cappuccino!',
            date: DateTime.now().subtract(const Duration(days: 3)),
            photos: [],
          ),
        ],
        openingHours: OpeningHours(
          monday: '8:00 AM - 10:00 PM',
          tuesday: '8:00 AM - 10:00 PM',
          wednesday: '8:00 AM - 10:00 PM',
          thursday: '8:00 AM - 10:00 PM',
          friday: '8:00 AM - 11:00 PM',
          saturday: '9:00 AM - 11:00 PM',
          sunday: '9:00 AM - 9:00 PM',
        ),
        trackingStatus: CafeTrackingStatus.notTracked,
        visitData: null,
        pricePerPerson: 15.00,
        socialMedia: {
          'instagram': 'https://instagram.com/cafelumiere',
          'tiktok': 'https://tiktok.com/@cafelumiere',
        },
      ),
      CoffeeShop(
        id: '4',
        name: 'Brew & Bloom',
        description: 'Coffee shop with plant-based options and sustainable practices.',
        address: '321 Elm St, Queens, NY 11101',
        phoneNumber: '+1 (555) 369-2580',
        website: 'https://brewandbloom.com',
        latitude: 40.7282,
        longitude: -73.7949,
        rating: 4.7,
        reviewCount: 256,
        photos: [
          'https://picsum.photos/seed/bloom1/400/300',
          'https://picsum.photos/seed/bloom2/400/300',
        ],
        features: ['WiFi', 'Vegan Options', 'Sustainable', 'Organic', 'Gluten-Free'],
        reviews: [
          Review(
            id: '5',
            userName: 'Lisa Park',
            rating: 4.5,
            comment: 'Love their plant-based options! Great atmosphere.',
            date: DateTime.now().subtract(const Duration(days: 4)),
            photos: [],
          ),
        ],
        openingHours: OpeningHours(
          monday: '7:00 AM - 7:00 PM',
          tuesday: '7:00 AM - 7:00 PM',
          wednesday: '7:00 AM - 7:00 PM',
          thursday: '7:00 AM - 7:00 PM',
          friday: '7:00 AM - 8:00 PM',
          saturday: '8:00 AM - 8:00 PM',
          sunday: '8:00 AM - 6:00 PM',
        ),
        trackingStatus: CafeTrackingStatus.wantToVisit,
        visitData: null,
      ),
      CoffeeShop(
        id: '5',
        name: 'Central Perk Cafe',
        description: 'Iconic coffee shop with comfortable seating and great latte art.',
        address: '555 Broadway, New York, NY 10012',
        phoneNumber: '+1 (555) 147-2580',
        website: 'https://centralperkcafe.com',
        latitude: 40.7209,
        longitude: -73.9972,
        rating: 4.4,
        reviewCount: 523,
        photos: [
          'https://picsum.photos/seed/perk1/400/300',
          'https://picsum.photos/seed/perk2/400/300',
          'https://picsum.photos/seed/perk3/400/300',
        ],
        features: ['WiFi', 'Comfortable Seating', 'Group Friendly', 'Events'],
        reviews: [
          Review(
            id: '6',
            userName: 'Tom Anderson',
            rating: 4.0,
            comment: 'Fun atmosphere, good coffee. Gets crowded on weekends.',
            date: DateTime.now().subtract(const Duration(days: 6)),
            photos: [],
          ),
        ],
        openingHours: OpeningHours(
          monday: '6:00 AM - 10:00 PM',
          tuesday: '6:00 AM - 10:00 PM',
          wednesday: '6:00 AM - 10:00 PM',
          thursday: '6:00 AM - 10:00 PM',
          friday: '6:00 AM - 11:00 PM',
          saturday: '7:00 AM - 11:00 PM',
          sunday: '7:00 AM - 9:00 PM',
        ),
        trackingStatus: CafeTrackingStatus.notTracked,
        visitData: null,
      ),
    ];

    _nearbyCoffeeShops = List.from(_coffeeShops);
    notifyListeners();
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

  void filterByFeatures(List<String> features) {
    _selectedFeatures = features;
    _filterCoffeeShops();
  }

  void _filterCoffeeShops() {
    _nearbyCoffeeShops = _coffeeShops.where((shop) {
      bool matchesSearch = true;
      bool matchesFeatures = true;

      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        matchesSearch = shop.name.toLowerCase().contains(_searchQuery!.toLowerCase()) ||
                       shop.description.toLowerCase().contains(_searchQuery!.toLowerCase()) ||
                       shop.address.toLowerCase().contains(_searchQuery!.toLowerCase());
      }

      if (_selectedFeatures.isNotEmpty) {
        matchesFeatures = _selectedFeatures.every((feature) =>
          shop.features.any((shopFeature) =>
            shopFeature.toLowerCase().contains(feature.toLowerCase())
          )
        );
      }

      return matchesSearch && matchesFeatures;
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

  List<String> getAllFeatures() {
    final Set<String> allFeatures = {};
    for (final shop in _coffeeShops) {
      allFeatures.addAll(shop.features);
    }
    return allFeatures.toList();
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