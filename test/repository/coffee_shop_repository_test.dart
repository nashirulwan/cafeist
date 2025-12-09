import 'package:flutter_test/flutter_test.dart';
import 'package:coffee_finder_app/services/coffee_shop_repository.dart';
import 'package:coffee_finder_app/services/places_service.dart';
import 'package:coffee_finder_app/utils/cache_manager.dart';
import 'package:coffee_finder_app/models/coffee_shop.dart';

// Manual Mock for PlacesService
class MockPlacesService implements PlacesService {
  bool _isReady = true;
  
  @override
  bool get isReady => _isReady;

  @override
  Future<List<CoffeeShop>> findNearbyCafes(
    double latitude,
    double longitude, {
    int radius = 5000,
    String? pageToken,
    int limit = 20,
  }) async {
    return [
      CoffeeShop(
        id: '1',
        name: 'Nearby Cafe',
        address: 'Nearby',
        phoneNumber: '000',
        website: 'example.com',
        description: 'Nearby',
        latitude: latitude + 0.001,
        longitude: longitude + 0.001,
        rating: 4.5,
        reviewCount: 10,
        isOpen: true,
        photos: [],
        reviews: [],
        openingHours: dummyOpeningHours,
      ),
    ];
  }

  @override
  Future<List<CoffeeShop>> searchCafes(String query) async {
    return [
      CoffeeShop(
        id: '99',
        name: 'Searched Cafe',
        address: 'Searched',
        phoneNumber: '000',
        website: 'example.com',
        description: 'Searched',
        latitude: 0,
        longitude: 0,
        rating: 4.5,
        reviewCount: 10,
        isOpen: true,
        photos: [],
        reviews: [],
        openingHours: dummyOpeningHours,
      ),
    ];
  }

  @override
  Future<List<CoffeeShop>> searchCafesWithFilters({
    required String query,
    double? minRating,
    int? minReviewCount,
    bool? openNow,
    double? userLat,
    double? userLng,
    int maxResults = 20,
  }) async {
    return [
      CoffeeShop(
        id: '2',
        name: 'Filtered Cafe',
        address: 'Filtered',
        phoneNumber: '000',
        website: 'example.com',
        description: 'Filtered',
        latitude: userLat ?? 0,
        longitude: userLng ?? 0,
        rating: 5.0,
        reviewCount: 100,
        isOpen: true,
        photos: [],
        reviews: [],
        openingHours: dummyOpeningHours,
      ),
    ];
  }

  // Helper to set ready state for testing
  void setReady(bool ready) {
    _isReady = ready;
  }
  
  @override
  Future<CoffeeShop?> getPlaceDetails(String placeId) async => null;
  @override
  Future<List<CoffeeShop>> getPopularCafesInRegion({required String region, double? centerLat, double? centerLng, int radius = 15000}) async => [];
  @override
  Future<List<CoffeeShop>> searchCafesByFeatures({required List<String> features, double? userLat, double? userLng, int radius = 10000}) async => [];
  
  @override
  String? getNextPageToken(Map<String, dynamic> responseData) => null;
  
  @override
  bool hasNextPage(Map<String, dynamic> responseData) => false;
}

// Manual Mock for CacheManager
class MockCacheManager implements CacheManager {
  final Map<String, List<CoffeeShop>> _cache = {};

  @override
  Future<List<CoffeeShop>?> getCachedSearchResults(String query) async {
    return _cache[query];
  }

  @override
  Future<void> cacheSearchResults(String query, List<CoffeeShop> results) async {
    _cache[query] = results;
  }

  @override
  Future<void> clearCache() async {}
  
  // Dummy implementation for other methods
  @override
  Future<void> cacheCoffeeShops(List<CoffeeShop> coffeeShops) async {}
  
  @override
  Future<void> cacheUserLocation({required double latitude, required double longitude, required String address}) async {}
  
  @override
  Future<void> clear(String key) async {}
  
  @override
  Future<void> clearAll() async {}
  
  @override
  Future<T?> get<T>({required String key, required Function(dynamic) fromJson}) async => null;
  
  @override
  Future<Map<String, dynamic>> getCacheStats() async => {};
  
  @override
  Future<List<CoffeeShop>?> getCachedCoffeeShops() async => null;
  
  @override
  Future<Map<String, dynamic>?> getCachedUserLocation() async => null;
  
  @override
  Future<void> set<T>({required String key, required T data, Duration? expiry, Function(T)? toJson}) async {}
}

final dummyOpeningHours = OpeningHours(
  monday: '09:00 - 17:00',
  tuesday: '09:00 - 17:00',
  wednesday: '09:00 - 17:00',
  thursday: '09:00 - 17:00',
  friday: '09:00 - 17:00',
  saturday: '09:00 - 17:00',
  sunday: 'Closed',
);

void main() {
  group('CoffeeShopRepository', () {
    late CoffeeShopRepository repository;
    late MockPlacesService mockPlacesService;
    late MockCacheManager mockCacheManager;

    setUp(() {
      mockPlacesService = MockPlacesService();
      mockCacheManager = MockCacheManager();
      repository = CoffeeShopRepository(
        placesService: mockPlacesService,
        cacheManager: mockCacheManager,
      );
    });

    test('getNearbyCoffeeShops throws if service not ready', () async {
      mockPlacesService.setReady(false);
      
      expect(
        () => repository.getNearbyCoffeeShops(lat: 0, lng: 0),
        throwsException,
      );
    });

    test('getNearbyCoffeeShops returns data from service', () async {
      mockPlacesService.setReady(true);
      
      final cafes = await repository.getNearbyCoffeeShops(lat: 0, lng: 0);
      
      expect(cafes.length, 1);
      expect(cafes.first.name, 'Nearby Cafe');
    });

    test('searchCoffeeShops returns cached data if available', () async {
      // Setup cache
      await mockCacheManager.cacheSearchResults('latte', [
        CoffeeShop(
          id: 'cache1',
          name: 'Cached Cafe',
          address: 'Cache',
          phoneNumber: '000',
          website: 'example.com',
          description: 'Cache',
          latitude: 0,
          longitude: 0,
          rating: 0,
          reviewCount: 0,
          isOpen: false,
          photos: [],
          reviews: [],
          openingHours: dummyOpeningHours,
        )
      ]);

      final results = await repository.searchCoffeeShops(
        query: 'latte',
        userLat: 0,
        userLng: 0,
      );

      expect(results.length, 1);
      expect(results.first.id, 'cache1');
      // Should not rely on PlacesService for cached data
    });

     test('searchCoffeeShops fetches from service if cache miss', () async {
      mockPlacesService.setReady(true);
      
      final results = await repository.searchCoffeeShops(
        query: 'espresso',
        userLat: 0,
        userLng: 0,
      );

      expect(results.length, 1);
      expect(results.first.name, 'Filtered Cafe'); // Mock returns Filtered Cafe for searchCafesWithFilters
    });
  });
}
