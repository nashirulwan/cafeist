import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/coffee_shop.dart';
import '../services/firebase_service.dart';
import '../providers/auth_provider.dart';

/// Personal cafe tracking service - MyAnimeList-style functionality
class CafeTrackingService {
  static const String _collectionName = 'user_cafe_tracking';

  /// Add cafe to user's wishlist (want to visit)
  static Future<void> addToWishlist(String userId, CoffeeShop cafe) async {
    try {
      if (kDebugMode) {
        print('📝 Adding ${cafe.name} to wishlist for user $userId');
      }

      await FirebaseService.firestore
          .collection(_collectionName)
          .doc(userId)
          .collection('cafes')
          .doc(cafe.id)
          .set({
            'cafeId': cafe.id,
            'trackingStatus': 'wantToVisit',
            'addedAt': DateTime.now().toIso8601String(),
            'basicInfo': {
              'name': cafe.name,
              'address': cafe.address,
              'rating': cafe.rating,
              'latitude': cafe.latitude,
              'longitude': cafe.longitude,
            },
          }, SetOptions(merge: true));

      if (kDebugMode) {
        print('✅ Successfully added ${cafe.name} to wishlist');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to add to wishlist: $e');
      }
      throw Exception('Failed to add to wishlist: $e');
    }
  }

  /// Mark cafe as visited with visit data
  static Future<void> markAsVisited(
    String userId,
    CoffeeShop cafe,
    VisitData visitData
  ) async {
    try {
      if (kDebugMode) {
        print('📍 Marking ${cafe.name} as visited for user $userId');
      }

      await FirebaseService.firestore
          .collection(_collectionName)
          .doc(userId)
          .collection('cafes')
          .doc(cafe.id)
          .set({
            'cafeId': cafe.id,
            'trackingStatus': 'visited',
            'visitData': visitData.toJson(),
            'visitedAt': DateTime.now().toIso8601String(),
            'basicInfo': {
              'name': cafe.name,
              'address': cafe.address,
              'rating': cafe.rating,
              'latitude': cafe.latitude,
              'longitude': cafe.longitude,
            },
          }, SetOptions(merge: true));

      if (kDebugMode) {
        print('✅ Successfully marked ${cafe.name} as visited');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to mark as visited: $e');
      }
      throw Exception('Failed to mark as visited: $e');
    }
  }

  /// Remove cafe from tracking
  static Future<void> removeFromTracking(String userId, String cafeId) async {
    try {
      if (kDebugMode) {
        print('🗑️ Removing cafe $cafeId from user $userId tracking');
      }

      await FirebaseService.firestore
          .collection(_collectionName)
          .doc(userId)
          .collection('cafes')
          .doc(cafeId)
          .delete();

      if (kDebugMode) {
        print('✅ Successfully removed cafe from tracking');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to remove from tracking: $e');
      }
      throw Exception('Failed to remove from tracking: $e');
    }
  }

  /// Get user's wishlist (cafes they want to visit)
  static Future<List<CoffeeShop>> getUserWishlist(String userId) async {
    try {
      if (kDebugMode) {
        print('📋 Fetching wishlist for user $userId');
      }

      final querySnapshot = await FirebaseService.firestore
          .collection(_collectionName)
          .doc(userId)
          .collection('cafes')
          .where('trackingStatus', isEqualTo: 'wantToVisit')
          .orderBy('addedAt', descending: true)
          .get();

      final cafes = <CoffeeShop>[];

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final basicInfo = data['basicInfo'] as Map<String, dynamic>?;

        if (basicInfo != null) {
          cafes.add(CoffeeShop(
            id: data['cafeId'] ?? '',
            name: basicInfo['name'] ?? '',
            description: 'Cafe you want to visit',
            address: basicInfo['address'] ?? '',
            phoneNumber: '',
            website: '',
            latitude: basicInfo['latitude']?.toDouble() ?? 0.0,
            longitude: basicInfo['longitude']?.toDouble() ?? 0.0,
            rating: basicInfo['rating']?.toDouble() ?? 0.0,
            reviewCount: 0,
            photos: [],
            reviews: [],
            openingHours: _getDefaultOpeningHours(),
            distance: 0.0,
            isOpen: true,
            isFavorite: false,
            trackingStatus: CafeTrackingStatus.wantToVisit,
            visitData: null,
            socialMedia: null,
          ));
        }
      }

      if (kDebugMode) {
        print('✅ Found ${cafes.length} cafes in wishlist');
      }

      return cafes;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get wishlist: $e');
      }
      return [];
    }
  }

  /// Get user's visited cafes
  static Future<List<CoffeeShop>> getUserVisitedCafes(String userId) async {
    try {
      if (kDebugMode) {
        print('📚 Fetching visited cafes for user $userId');
      }

      final querySnapshot = await FirebaseService.firestore
          .collection(_collectionName)
          .doc(userId)
          .collection('cafes')
          .where('trackingStatus', isEqualTo: 'visited')
          .orderBy('visitedAt', descending: true)
          .get();

      final cafes = <CoffeeShop>[];

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final basicInfo = data['basicInfo'] as Map<String, dynamic>?;
        final visitDataJson = data['visitData'] as Map<String, dynamic>?;

        if (basicInfo != null) {
          final visitData = visitDataJson != null
              ? VisitData.fromJson(visitDataJson)
              : null;

          cafes.add(CoffeeShop(
            id: data['cafeId'] ?? '',
            name: basicInfo['name'] ?? '',
            description: 'Cafe you have visited',
            address: basicInfo['address'] ?? '',
            phoneNumber: '',
            website: '',
            latitude: basicInfo['latitude']?.toDouble() ?? 0.0,
            longitude: basicInfo['longitude']?.toDouble() ?? 0.0,
            rating: visitData?.personalRating ?? basicInfo['rating']?.toDouble() ?? 0.0,
            reviewCount: 0,
            photos: [],
            reviews: [],
            openingHours: _getDefaultOpeningHours(),
            distance: 0.0,
            isOpen: true,
            isFavorite: false,
            trackingStatus: CafeTrackingStatus.visited,
            visitData: visitData,
            socialMedia: null,
          ));
        }
      }

      if (kDebugMode) {
        print('✅ Found ${cafes.length} visited cafes');
      }

      return cafes;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get visited cafes: $e');
      }
      return [];
    }
  }

  /// Get user's cafe statistics
  static Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      if (kDebugMode) {
        print('📊 Fetching cafe statistics for user $userId');
      }

      final querySnapshot = await FirebaseService.firestore
          .collection(_collectionName)
          .doc(userId)
          .collection('cafes')
          .get();

      int wishlistCount = 0;
      int visitedCount = 0;
      double totalPersonalRating = 0.0;
      int ratedCafes = 0;

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final status = data['trackingStatus'] as String?;

        if (status == 'wantToVisit') {
          wishlistCount++;
        } else if (status == 'visited') {
          visitedCount++;

          final visitDataJson = data['visitData'] as Map<String, dynamic>?;
          if (visitDataJson != null) {
            final personalRating = visitDataJson['personalRating'] as double?;
            if (personalRating != null && personalRating > 0) {
              totalPersonalRating += personalRating;
              ratedCafes++;
            }
          }
        }
      }

      final stats = {
        'wishlistCount': wishlistCount,
        'visitedCount': visitedCount,
        'totalTracked': wishlistCount + visitedCount,
        'averagePersonalRating': ratedCafes > 0 ? totalPersonalRating / ratedCafes : 0.0,
        'ratedCafes': ratedCafes,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      if (kDebugMode) {
        print('✅ User stats: ${stats.toString()}');
      }

      return stats;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get user stats: $e');
      }
      return {
        'wishlistCount': 0,
        'visitedCount': 0,
        'totalTracked': 0,
        'averagePersonalRating': 0.0,
        'ratedCafes': 0,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Get user's cafe history with detailed information
  static Future<Map<String, List<CoffeeShop>>> getUserHistory(String userId) async {
    try {
      if (kDebugMode) {
        print('📜 Fetching cafe history for user $userId');
      }

      final querySnapshot = await FirebaseService.firestore
          .collection(_collectionName)
          .doc(userId)
          .collection('cafes')
          .orderBy(FieldPath.documentId)
          .get();

      final wishlist = <CoffeeShop>[];
      final visited = <CoffeeShop>[];

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final status = data['trackingStatus'] as String?;
        final basicInfo = data['basicInfo'] as Map<String, dynamic>?;

        if (basicInfo != null) {
          final cafe = CoffeeShop(
            id: data['cafeId'] ?? '',
            name: basicInfo['name'] ?? '',
            description: 'Tracked cafe',
            address: basicInfo['address'] ?? '',
            phoneNumber: '',
            website: '',
            latitude: basicInfo['latitude']?.toDouble() ?? 0.0,
            longitude: basicInfo['longitude']?.toDouble() ?? 0.0,
            rating: basicInfo['rating']?.toDouble() ?? 0.0,
            reviewCount: 0,
            photos: [],
            reviews: [],
            openingHours: _getDefaultOpeningHours(),
            distance: 0.0,
            isOpen: true,
            isFavorite: false,
            trackingStatus: status == 'wantToVisit'
                ? CafeTrackingStatus.wantToVisit
                : status == 'visited'
                    ? CafeTrackingStatus.visited
                    : CafeTrackingStatus.notTracked,
            visitData: null,
            socialMedia: null,
          );

          if (status == 'wantToVisit') {
            wishlist.add(cafe);
          } else if (status == 'visited') {
            visited.add(cafe);
          }
        }
      }

      final history = {
        'wishlist': wishlist,
        'visited': visited,
      };

      if (kDebugMode) {
        print('✅ Found ${wishlist.length} wishlist and ${visited.length} visited cafes');
      }

      return history;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get user history: $e');
      }
      return {'wishlist': [], 'visited': []};
    }
  }

  /// Update visit data for a cafe
  static Future<void> updateVisitData(
    String userId,
    String cafeId,
    VisitData visitData
  ) async {
    try {
      if (kDebugMode) {
        print('✏️ Updating visit data for cafe $cafeId');
      }

      await FirebaseService.firestore
          .collection(_collectionName)
          .doc(userId)
          .collection('cafes')
          .doc(cafeId)
          .update({
            'visitData': visitData.toJson(),
            'updatedAt': DateTime.now().toIso8601String(),
          });

      if (kDebugMode) {
        print('✅ Successfully updated visit data');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to update visit data: $e');
      }
      throw Exception('Failed to update visit data: $e');
    }
  }

  /// Search within user's tracked cafes
  static Future<List<CoffeeShop>> searchTrackedCafes(
    String userId,
    String query
  ) async {
    try {
      final history = await getUserHistory(userId);
      final allCafes = [...history['wishlist']!, ...history['visited']!];

      final queryLower = query.toLowerCase();
      final filtered = allCafes.where((cafe) {
        return cafe.name.toLowerCase().contains(queryLower) ||
               cafe.address.toLowerCase().contains(queryLower);
      }).toList();

      if (kDebugMode) {
        print('🔍 Found ${filtered.length} cafes matching "$query"');
      }

      return filtered;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to search tracked cafes: $e');
      }
      return [];
    }
  }

  /// Export user data (for backup purposes)
  static Future<Map<String, dynamic>> exportUserData(String userId) async {
    try {
      final history = await getUserHistory(userId);
      final stats = await getUserStats(userId);

      return {
        'userId': userId,
        'exportDate': DateTime.now().toIso8601String(),
        'statistics': stats,
        'wishlist': history['wishlist']!.map((cafe) => {
          'id': cafe.id,
          'name': cafe.name,
          'address': cafe.address,
          'rating': cafe.rating,
          'latitude': cafe.latitude,
          'longitude': cafe.longitude,
        }).toList(),
        'visited': history['visited']!.map((cafe) => {
          'id': cafe.id,
          'name': cafe.name,
          'address': cafe.address,
          'rating': cafe.rating,
          'latitude': cafe.latitude,
          'longitude': cafe.longitude,
          'personalRating': cafe.rating,
          'visitData': cafe.visitData?.toJson(),
        }).toList(),
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to export user data: $e');
      }
      throw Exception('Failed to export user data: $e');
    }
  }

  /// Default opening hours helper
  static _getDefaultOpeningHours() {
    return {
      'monday': '07:00 – 22:00',
      'tuesday': '07:00 – 22:00',
      'wednesday': '07:00 – 22:00',
      'thursday': '07:00 – 22:00',
      'friday': '07:00 – 22:00',
      'saturday': '08:00 – 23:00',
      'sunday': '08:00 – 23:00',
    };
  }
}