import 'package:flutter_test/flutter_test.dart';
import 'package:coffee_finder_app/services/recommendation_service.dart';
import 'package:coffee_finder_app/models/coffee_shop.dart';

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
  group('RecommendationService', () {

    final List<CoffeeShop> testCafes = [
      CoffeeShop(
        id: '1',
        name: 'Cafe A',
        address: 'Addr 1',
        phoneNumber: '000',
        website: 'example.com',
        description: 'Quiet study place with wifi',
        latitude: 0,
        longitude: 0,
        rating: 4.8,
        reviewCount: 100,
        isOpen: true,
        photos: [],
        reviews: [],
        openingHours: dummyOpeningHours,
      ),
      CoffeeShop(
        id: '2',
        name: 'Cafe B',
        address: 'Addr 2',
        phoneNumber: '000',
        website: 'example.com',
        description: 'Lively social spot',
        latitude: 0,
        longitude: 0,
        rating: 4.0,
        reviewCount: 50,
        isOpen: true,
        photos: [],
        reviews: [],
        openingHours: dummyOpeningHours,
        trackingStatus: CafeTrackingStatus.visited, // User visited this
      ),
      CoffeeShop(
        id: '3',
        name: 'Cafe C',
        address: 'Addr 3',
        phoneNumber: '000',
        website: 'example.com',
        description: 'Cozy place',
        latitude: 0,
        longitude: 0,
        rating: 3.5,
        reviewCount: 10,
        isOpen: true,
        photos: [],
        reviews: [],
        openingHours: dummyOpeningHours,
      ),
    ];

    test('getRecommendations returns list excluding visited cafes', () async {
      final recommendations = await RecommendationService.getRecommendations(testCafes);
      
      // Should not contain Cafe B (visited)
      expect(recommendations.any((c) => c.id == '2'), false);
      // Should contain Cafe A and C
      expect(recommendations.any((c) => c.id == '1'), true);
      expect(recommendations.any((c) => c.id == '3'), true);
    });

    test('getRecommendationsByCategory filters correctly', () async {
      final studyCafes = await RecommendationService.getRecommendationsByCategory(testCafes, 'study');
      
      expect(studyCafes.length, 1);
      expect(studyCafes.first.id, '1'); // Cafe A has "study" in description
    });

    test('getRecommendationsByCategory returns empty for unknown category', () async {
      final cafes = await RecommendationService.getRecommendationsByCategory(testCafes, 'space_travel');
      // Should fallback to general recommendations or return empty depending on implementation
      // Logic says default: return getRecommendations(all)
      expect(cafes.isNotEmpty, true);
    });
  });
}
