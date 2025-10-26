import 'package:flutter/foundation.dart';
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

  void _initializeCoffeeShops() {
    _coffeeShops = [
      CoffeeShop(
        id: '1',
        name: 'And Coffee Space Malang',
        description: 'Modern coffee shop with minimalist design and specialty coffee beans. Perfect for working and studying.',
        address: 'Jl. Soekarno Hatta No. 24, Malang, East Java',
        phoneNumber: '+62 341 493 888',
        website: 'https://andcoffeespace.com',
        latitude: -7.9445,
        longitude: 112.6286,
        rating: 4.7,
        reviewCount: 286,
        photos: [
          'https://picsum.photos/seed/andcoffee1/400/300',
          'https://picsum.photos/seed/andcoffee2/400/300',
          'https://picsum.photos/seed/andcoffee3/400/300',
        ],
        reviews: [
          Review(
            id: '1',
            userName: 'Rina Wijaya',
            rating: 5.0,
            comment: 'Great coffee and cozy atmosphere! Perfect spot for working on laptop.',
            date: DateTime.now().subtract(const Duration(days: 2)),
            photos: [],
          ),
          Review(
            id: '2',
            userName: 'Budi Santoso',
            rating: 4.5,
            comment: 'Love the minimalist design. Espresso is top-notch!',
            date: DateTime.now().subtract(const Duration(days: 5)),
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
        trackingStatus: CafeTrackingStatus.visited,
        visitData: VisitData(
          personalRating: 4.5,
          privateReview: 'Excellent coffee and great working environment. Fast WiFi.',
          visitDates: [
            DateTime.now().subtract(const Duration(days: 12)),
            DateTime.now().subtract(const Duration(days: 4)),
          ],
        ),
        socialMedia: {
          'instagram': 'https://instagram.com/andcoffeespace',
          'facebook': 'https://facebook.com/andcoffeespace',
        },
      ),
      CoffeeShop(
        id: '2',
        name: 'Lafayette Coffee Malang',
        description: 'Elegant coffee shop with French-inspired interior and premium single origin coffee.',
        address: 'Jl. Borobudur No. 12, Malang, East Java',
        phoneNumber: '+62 341 368 999',
        website: 'https://lafayettecoffee.com',
        latitude: -7.9790,
        longitude: 112.6345,
        rating: 4.8,
        reviewCount: 412,
        photos: [
          'https://picsum.photos/seed/lafayette1/400/300',
          'https://picsum.photos/seed/lafayette2/400/300',
          'https://picsum.photos/seed/lafayette3/400/300',
        ],
        reviews: [
          Review(
            id: '3',
            userName: 'Maya Putri',
            rating: 5.0,
            comment: 'Beautiful ambiance and exceptional coffee! Perfect for dates.',
            date: DateTime.now().subtract(const Duration(days: 1)),
            photos: [],
          ),
          Review(
            id: '4',
            userName: 'Kevin Pratama',
            rating: 4.5,
            comment: 'Their pour-over coffee is amazing. Love the classical music.',
            date: DateTime.now().subtract(const Duration(days: 7)),
            photos: [],
          ),
        ],
        openingHours: OpeningHours(
          monday: '10:00 AM - 10:00 PM',
          tuesday: '10:00 AM - 10:00 PM',
          wednesday: '10:00 AM - 10:00 PM',
          thursday: '10:00 AM - 10:00 PM',
          friday: '10:00 AM - 12:00 AM',
          saturday: '10:00 AM - 12:00 AM',
          sunday: '10:00 AM - 10:00 PM',
        ),
        trackingStatus: CafeTrackingStatus.wantToVisit,
        visitData: null,
        socialMedia: {
          'instagram': 'https://instagram.com/lafayettecoffeemalang',
          'facebook': 'https://facebook.com/lafayettecoffeemalang',
        },
      ),
      CoffeeShop(
        id: '3',
        name: 'Motiv Coffee Malang',
        description: 'Trendy coffee shop with motivational quotes and energetic atmosphere. Great for productivity.',
        address: 'Jl. Simpang Borobudur No. 8, Malang, East Java',
        phoneNumber: '+62 341 426 777',
        website: 'https://motivcoffee.com',
        latitude: -7.9621,
        longitude: 112.6183,
        rating: 4.6,
        reviewCount: 198,
        photos: [
          'https://picsum.photos/seed/motiv1/400/300',
          'https://picsum.photos/seed/motiv2/400/300',
          'https://picsum.photos/seed/motiv3/400/300',
        ],
        reviews: [
          Review(
            id: '5',
            userName: 'Diana Kartika',
            rating: 4.5,
            comment: 'Energetic atmosphere! Perfect for getting work done.',
            date: DateTime.now().subtract(const Duration(days: 3)),
            photos: [],
          ),
        ],
        openingHours: OpeningHours(
          monday: '7:00 AM - 9:00 PM',
          tuesday: '7:00 AM - 9:00 PM',
          wednesday: '7:00 AM - 9:00 PM',
          thursday: '7:00 AM - 9:00 PM',
          friday: '7:00 AM - 10:00 PM',
          saturday: '8:00 AM - 10:00 PM',
          sunday: '8:00 AM - 8:00 PM',
        ),
        trackingStatus: CafeTrackingStatus.wantToVisit,
        visitData: null,
        socialMedia: {
          'instagram': 'https://instagram.com/motivcoffeemalang',
          'tiktok': 'https://tiktok.com/@motivcoffeemalang',
        },
      ),
      CoffeeShop(
        id: '4',
        name: 'TW Cafe & Eatery Malang',
        description: 'Cozy cafe serving both coffee and delicious meals. Great for brunch and casual meetings.',
        address: 'Jl. Kahuripan No. 9, Malang, East Java',
        phoneNumber: '+62 341 324 555',
        website: 'https://twcafeeatery.com',
        latitude: -7.9664,
        longitude: 112.6327,
        rating: 4.5,
        reviewCount: 324,
        photos: [
          'https://picsum.photos/seed/twcafe1/400/300',
          'https://picsum.photos/seed/twcafe2/400/300',
          'https://picsum.photos/seed/twcafe3/400/300',
        ],
        reviews: [
          Review(
            id: '6',
            userName: 'Andi Wijaya',
            rating: 4.0,
            comment: 'Good coffee and great food! Perfect for lunch dates.',
            date: DateTime.now().subtract(const Duration(days: 4)),
            photos: [],
          ),
        ],
        openingHours: OpeningHours(
          monday: '8:00 AM - 9:00 PM',
          tuesday: '8:00 AM - 9:00 PM',
          wednesday: '8:00 AM - 9:00 PM',
          thursday: '8:00 AM - 9:00 PM',
          friday: '8:00 AM - 10:00 PM',
          saturday: '9:00 AM - 10:00 PM',
          sunday: '9:00 AM - 8:00 PM',
        ),
        trackingStatus: CafeTrackingStatus.notTracked,
        visitData: null,
        socialMedia: {
          'instagram': 'https://instagram.com/twcafeeaterymalang',
          'facebook': 'https://facebook.com/twcafeeaterymalang',
        },
      ),
      CoffeeShop(
        id: '5',
        name: 'Lifika Cafe Malang',
        description: 'Charming cafe with vintage decor and artisanal coffee. Known for signature latte art.',
        address: 'Jl. Semeru No. 45, Malang, East Java',
        phoneNumber: '+62 341 482 333',
        website: 'https://lifikacafe.com',
        latitude: -7.9838,
        longitude: 112.6217,
        rating: 4.7,
        reviewCount: 276,
        photos: [
          'https://picsum.photos/seed/lifika1/400/300',
          'https://picsum.photos/seed/lifika2/400/300',
          'https://picsum.photos/seed/lifika3/400/300',
        ],
        reviews: [
          Review(
            id: '7',
            userName: 'Siti Nurhaliza',
            rating: 5.0,
            comment: 'Beautiful vintage cafe! Their latte art is stunning and coffee is delicious.',
            date: DateTime.now().subtract(const Duration(days: 6)),
            photos: [],
          ),
        ],
        openingHours: OpeningHours(
          monday: '9:00 AM - 8:00 PM',
          tuesday: '9:00 AM - 8:00 PM',
          wednesday: '9:00 AM - 8:00 PM',
          thursday: '9:00 AM - 8:00 PM',
          friday: '9:00 AM - 9:00 PM',
          saturday: '9:00 AM - 9:00 PM',
          sunday: '10:00 AM - 7:00 PM',
        ),
        trackingStatus: CafeTrackingStatus.notTracked,
        visitData: null,
        socialMedia: {
          'instagram': 'https://instagram.com/lifikacafemalang',
          'tiktok': 'https://tiktok.com/@lifikacafe',
        },
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