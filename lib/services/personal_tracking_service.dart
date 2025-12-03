import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/coffee_shop.dart';
import 'firebase_sync_service.dart';

class PersonalTrackingService {
  static const String _visitKey = 'user_visits';
  static const String _wishlistKey = 'user_wishlist';
  static const String _favoritesKey = 'user_favorites';
  static const String _statsKey = 'user_stats';

  final Uuid _uuid = const Uuid();

  /// Save visit data for a coffee shop (with Firebase sync)
  Future<void> saveVisitData(String coffeeShopId, VisitData visitData) async {
    try {
      // Save to local storage first
      final prefs = await SharedPreferences.getInstance();
      final visitsJson = prefs.getString(_visitKey) ?? '{}';
      final Map<String, dynamic> allVisits = json.decode(visitsJson);

      allVisits[coffeeShopId] = visitData.toJson();

      await prefs.setString(_visitKey, json.encode(allVisits));
      await _updateVisitStats(coffeeShopId, visitData);

      // Sync to Firebase if user is logged in
      if (FirebaseSyncService.isUserLoggedIn()) {
        final userId = FirebaseSyncService.getCurrentUserId()!;
        await FirebaseSyncService.syncVisitToCloud(
          userId: userId,
          coffeeShopId: coffeeShopId,
          visitData: visitData.toJson(),
        );
      }

      print('✅ Visit data saved locally and synced to cloud');
    } catch (e) {
      print('❌ Error saving visit data: $e');
      throw Exception('Failed to save visit data: $e');
    }
  }

  /// Get visit data for a specific coffee shop
  Future<VisitData?> getVisitData(String coffeeShopId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final visitsJson = prefs.getString(_visitKey) ?? '{}';
      final Map<String, dynamic> allVisits = json.decode(visitsJson);

      if (allVisits.containsKey(coffeeShopId)) {
        return VisitData.fromJson(allVisits[coffeeShopId]);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Add coffee shop to wishlist (with Firebase sync)
  Future<void> addToWishlist(String coffeeShopId) async {
    try {
      // Add to local storage first
      final prefs = await SharedPreferences.getInstance();
      final wishlistJson = prefs.getString(_wishlistKey) ?? '[]';
      final List<dynamic> wishlist = json.decode(wishlistJson);

      if (!wishlist.contains(coffeeShopId)) {
        wishlist.add(coffeeShopId);
        await prefs.setString(_wishlistKey, json.encode(wishlist));

        // Sync to Firebase if user is logged in
        if (FirebaseSyncService.isUserLoggedIn()) {
          final userId = FirebaseSyncService.getCurrentUserId()!;
          final updatedWishlist = List<String>.from(wishlist);
          await FirebaseSyncService.syncWishlistToCloud(
            userId: userId,
            wishlist: updatedWishlist,
          );
        }

        print('✅ Added to wishlist and synced to cloud: $coffeeShopId');
      }
    } catch (e) {
      print('❌ Error adding to wishlist: $e');
      throw Exception('Failed to add to wishlist: $e');
    }
  }

  /// Remove coffee shop from wishlist
  Future<void> removeFromWishlist(String coffeeShopId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wishlistJson = prefs.getString(_wishlistKey) ?? '[]';
      final List<dynamic> wishlist = json.decode(wishlistJson);

      wishlist.remove(coffeeShopId);
      await prefs.setString(_wishlistKey, json.encode(wishlist));
    } catch (e) {
      throw Exception('Failed to remove from wishlist: $e');
    }
  }

  /// Get all wishlist items
  Future<List<String>> getWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wishlistJson = prefs.getString(_wishlistKey) ?? '[]';
      return List<String>.from(json.decode(wishlistJson));
    } catch (e) {
      return [];
    }
  }

  /// Toggle favorite status (with Firebase sync)
  Future<void> toggleFavorite(String coffeeShopId) async {
    try {
      // Update local storage first
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_favoritesKey) ?? '[]';
      final List<dynamic> favorites = json.decode(favoritesJson);

      if (favorites.contains(coffeeShopId)) {
        favorites.remove(coffeeShopId);
      } else {
        favorites.add(coffeeShopId);
      }

      await prefs.setString(_favoritesKey, json.encode(favorites));

      // Sync to Firebase if user is logged in
      if (FirebaseSyncService.isUserLoggedIn()) {
        final userId = FirebaseSyncService.getCurrentUserId()!;
        final updatedFavorites = List<String>.from(favorites);
        await FirebaseSyncService.syncFavoritesToCloud(
          userId: userId,
          favorites: updatedFavorites,
        );
      }

      print('✅ Favorite status updated and synced to cloud: $coffeeShopId');
    } catch (e) {
      print('❌ Error toggling favorite: $e');
      throw Exception('Failed to toggle favorite: $e');
    }
  }

  /// Get all favorite coffee shops
  Future<List<String>> getFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_favoritesKey) ?? '[]';
      return List<String>.from(json.decode(favoritesJson));
    } catch (e) {
      return [];
    }
  }

  /// Check if coffee shop is favorited
  Future<bool> isFavorited(String coffeeShopId) async {
    final favorites = await getFavorites();
    return favorites.contains(coffeeShopId);
  }

  /// Get user statistics
  Future<UserStats> getUserStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString(_statsKey) ?? '{}';
      final Map<String, dynamic> stats = json.decode(statsJson);

      return UserStats(
        totalVisits: stats['totalVisits'] ?? 0,
        uniqueCafes: stats['uniqueCafes'] ?? 0,
        totalWishlist: stats['totalWishlist'] ?? 0,
        totalFavorites: stats['totalFavorites'] ?? 0,
        lastVisitDate: stats['lastVisitDate'] != null
            ? DateTime.parse(stats['lastVisitDate'])
            : null,
        mostVisitedCafe: stats['mostVisitedCafe'],
        streakDays: stats['streakDays'] ?? 0,
      );
    } catch (e) {
      return UserStats();
    }
  }

  /// Update visit statistics
  Future<void> _updateVisitStats(String coffeeShopId, VisitData visitData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString(_statsKey) ?? '{}';
      final Map<String, dynamic> stats = json.decode(statsJson);

      // Update basic stats
      final currentVisits = stats['totalVisits'] ?? 0;
      stats['totalVisits'] = currentVisits + visitData.visitDates.length;

      // Update unique cafes count
      final visitsJson = prefs.getString(_visitKey) ?? '{}';
      final Map<String, dynamic> allVisits = json.decode(visitsJson);
      stats['uniqueCafes'] = allVisits.keys.length;

      // Update last visit date
      if (visitData.visitDates.isNotEmpty) {
        visitData.visitDates.sort((a, b) => b.compareTo(a));
        stats['lastVisitDate'] = visitData.visitDates.first.toIso8601String();
      }

      // Update wishlist count
      final wishlist = await getWishlist();
      stats['totalWishlist'] = wishlist.length;

      // Update favorites count
      final favorites = await getFavorites();
      stats['totalFavorites'] = favorites.length;

      await prefs.setString(_statsKey, json.encode(stats));
    } catch (e) {
      // Ignore stats update errors
    }
  }

  /// Sync data from Firebase to local storage
  Future<void> syncFromCloudToLocal(String userId) async {
    try {
      // Get data from Firebase
      final cloudData = await FirebaseSyncService.getUserDataFromCloud(userId);

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();

      // Sync visits
      final cloudVisits = cloudData['visits'] as Map<String, dynamic>;
      await prefs.setString(_visitKey, json.encode(cloudVisits));

      // Sync wishlist
      final cloudWishlist = List<String>.from(cloudData['wishlist']);
      await prefs.setString(_wishlistKey, json.encode(cloudWishlist));

      // Sync favorites
      final cloudFavorites = List<String>.from(cloudData['favorites']);
      await prefs.setString(_favoritesKey, json.encode(cloudFavorites));

      print('✅ Data synced from cloud to local storage');
    } catch (e) {
      print('❌ Error syncing from cloud: $e');
      // Don't throw, just continue with local data
    }
  }

  /// Sync all local data to Firebase
  Future<void> syncAllToCloud(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get all local data
      final visitsJson = prefs.getString(_visitKey) ?? '{}';
      final wishlistJson = prefs.getString(_wishlistKey) ?? '[]';
      final favoritesJson = prefs.getString(_favoritesKey) ?? '[]';

      // Sync to Firebase
      await FirebaseSyncService.syncUserDataToCloud(
        userId: userId,
        wishlist: List<String>.from(json.decode(wishlistJson)),
        favorites: List<String>.from(json.decode(favoritesJson)),
        visits: json.decode(visitsJson),
      );

      print('✅ All local data synced to cloud');
    } catch (e) {
      print('❌ Error syncing all data to cloud: $e');
      throw Exception('Failed to sync data to cloud: $e');
    }
  }

  /// Clear all user data (for testing/reset)
  Future<void> clearAllData() async {
    try {
      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_visitKey);
      await prefs.remove(_wishlistKey);
      await prefs.remove(_favoritesKey);
      await prefs.remove(_statsKey);

      // Clear cloud data if user is logged in
      if (FirebaseSyncService.isUserLoggedIn()) {
        final userId = FirebaseSyncService.getCurrentUserId()!;
        await FirebaseSyncService.deleteUserDataFromCloud(userId);
      }

      print('✅ All user data cleared locally and from cloud');
    } catch (e) {
      print('❌ Error clearing data: $e');
      throw Exception('Failed to clear data: $e');
    }
  }
}

class UserStats {
  final int totalVisits;
  final int uniqueCafes;
  final int totalWishlist;
  final int totalFavorites;
  final DateTime? lastVisitDate;
  final String? mostVisitedCafe;
  final int streakDays;

  UserStats({
    this.totalVisits = 0,
    this.uniqueCafes = 0,
    this.totalWishlist = 0,
    this.totalFavorites = 0,
    this.lastVisitDate,
    this.mostVisitedCafe,
    this.streakDays = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalVisits': totalVisits,
      'uniqueCafes': uniqueCafes,
      'totalWishlist': totalWishlist,
      'totalFavorites': totalFavorites,
      'lastVisitDate': lastVisitDate?.toIso8601String(),
      'mostVisitedCafe': mostVisitedCafe,
      'streakDays': streakDays,
    };
  }
}