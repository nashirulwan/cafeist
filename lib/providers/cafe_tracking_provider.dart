import 'package:flutter/foundation.dart';
import '../models/coffee_shop.dart';
import '../services/cafe_tracking_service.dart';
import '../services/firebase_service.dart';

/// Provider for managing personal cafe tracking state
class CafeTrackingProvider extends ChangeNotifier {
  List<CoffeeShop> _wishlist = [];
  List<CoffeeShop> _visitedCafes = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  List<CoffeeShop> get wishlist => List.unmodifiable(_wishlist);
  List<CoffeeShop> get visitedCafes => List.unmodifiable(_visitedCafes);
  Map<String, dynamic> get statistics => Map.unmodifiable(_statistics);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Computed properties
  int get wishlistCount => _wishlist.length;
  int get visitedCount => _visitedCafes.length;
  int get totalTracked => wishlistCount + visitedCount;
  double get averagePersonalRating => _statistics['averagePersonalRating']?.toDouble() ?? 0.0;

  /// Initialize tracking data for current user
  Future<void> initialize() async {
    _setLoading(true);
    _clearError();

    try {
      final userId = FirebaseService.currentUserId;
      if (userId == null) {
        _setError('No user logged in');
        return;
      }

      if (kDebugMode) {
        print('🔄 Initializing cafe tracking for user $userId');
      }

      // Load all data in parallel
      final futures = await Future.wait([
        CafeTrackingService.getUserWishlist(userId),
        CafeTrackingService.getUserVisitedCafes(userId),
        CafeTrackingService.getUserStats(userId),
      ]);

      _wishlist = futures[0] as List<CoffeeShop>;
      _visitedCafes = futures[1] as List<CoffeeShop>;
      _statistics = futures[2] as Map<String, dynamic>;

      if (kDebugMode) {
        print('✅ Cafe tracking initialized: $wishlistCount wishlist, $visitedCount visited');
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to initialize tracking: $e');
      if (kDebugMode) {
        print('❌ Tracking initialization failed: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Add cafe to wishlist
  Future<void> addToWishlist(CoffeeShop cafe) async {
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      final userId = FirebaseService.currentUserId;
      if (userId == null) {
        _setError('No user logged in');
        return;
      }

      // Check if already tracked
      if (_isCafeTracked(cafe.id)) {
        _setError('Cafe is already in your wishlist or visited list');
        return;
      }

      await CafeTrackingService.addToWishlist(userId, cafe);

      // Update local state
      _wishlist.insert(0, cafe);
      _updateStatistics();

      if (kDebugMode) {
        print('✅ Added ${cafe.name} to wishlist');
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to add to wishlist: $e');
      if (kDebugMode) {
        print('❌ Failed to add to wishlist: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Mark cafe as visited
  Future<void> markAsVisited(CoffeeShop cafe, VisitData visitData) async {
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      final userId = FirebaseService.currentUserId;
      if (userId == null) {
        _setError('No user logged in');
        return;
      }

      await CafeTrackingService.markAsVisited(userId, cafe, visitData);

      // Update local state
      _wishlist.removeWhere((c) => c.id == cafe.id);
      final updatedCafe = cafe.copyWith(
        trackingStatus: CafeTrackingStatus.visited,
        visitData: visitData,
        rating: visitData.personalRating ?? cafe.rating,
      );
      _visitedCafes.insert(0, updatedCafe);
      _updateStatistics();

      if (kDebugMode) {
        print('✅ Marked ${cafe.name} as visited');
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to mark as visited: $e');
      if (kDebugMode) {
        print('❌ Failed to mark as visited: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Remove cafe from tracking
  Future<void> removeFromTracking(String cafeId) async {
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      final userId = FirebaseService.currentUserId;
      if (userId == null) {
        _setError('No user logged in');
        return;
      }

      await CafeTrackingService.removeFromTracking(userId, cafeId);

      // Update local state
      _wishlist.removeWhere((cafe) => cafe.id == cafeId);
      _visitedCafes.removeWhere((cafe) => cafe.id == cafeId);
      _updateStatistics();

      if (kDebugMode) {
        print('✅ Removed cafe $cafeId from tracking');
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to remove from tracking: $e');
      if (kDebugMode) {
        print('❌ Failed to remove from tracking: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Update visit data for a cafe
  Future<void> updateVisitData(String cafeId, VisitData visitData) async {
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      final userId = FirebaseService.currentUserId;
      if (userId == null) {
        _setError('No user logged in');
        return;
      }

      await CafeTrackingService.updateVisitData(userId, cafeId, visitData);

      // Update local state
      final index = _visitedCafes.indexWhere((cafe) => cafe.id == cafeId);
      if (index != -1) {
        _visitedCafes[index] = _visitedCafes[index].copyWith(
          visitData: visitData,
          rating: visitData.personalRating ?? _visitedCafes[index].rating,
        );
        _updateStatistics();
      }

      if (kDebugMode) {
        print('✅ Updated visit data for cafe $cafeId');
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to update visit data: $e');
      if (kDebugMode) {
        print('❌ Failed to update visit data: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Search within tracked cafes
  Future<List<CoffeeShop>> searchTrackedCafes(String query) async {
    try {
      final userId = FirebaseService.currentUserId;
      if (userId == null) return [];

      return await CafeTrackingService.searchTrackedCafes(userId, query);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to search tracked cafes: $e');
      }
      return [];
    }
  }

  /// Export user data
  Future<Map<String, dynamic>?> exportUserData() async {
    try {
      final userId = FirebaseService.currentUserId;
      if (userId == null) return null;

      return await CafeTrackingService.exportUserData(userId);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to export user data: $e');
      }
      return null;
    }
  }

  /// Get tracking status for a specific cafe
  CafeTrackingStatus getCafeTrackingStatus(String cafeId) {
    if (_wishlist.any((cafe) => cafe.id == cafeId)) {
      return CafeTrackingStatus.wantToVisit;
    } else if (_visitedCafes.any((cafe) => cafe.id == cafeId)) {
      return CafeTrackingStatus.visited;
    } else {
      return CafeTrackingStatus.notTracked;
    }
  }

  /// Get cafe details from tracking
  CoffeeShop? getCafeFromTracking(String cafeId) {
    final wishlistCafe = _wishlist.firstWhere((cafe) => cafe.id == cafeId, orElse: () => _wishlist.first);
    if (wishlistCafe.id == cafeId) return wishlistCafe;

    final visitedCafe = _visitedCafes.firstWhere((cafe) => cafe.id == cafeId, orElse: () => _visitedCafes.first);
    if (visitedCafe.id == cafeId) return visitedCafe;

    return null;
  }

  /// Refresh data from server
  Future<void> refresh() async {
    await initialize();
  }

  /// Clear current error
  void clearError() {
    _clearError();
  }

  /// Reset all tracking data (for testing purposes)
  void reset() {
    _wishlist.clear();
    _visitedCafes.clear();
    _statistics.clear();
    _clearError();
    _setLoading(false);
    notifyListeners();
  }

  // Private helper methods

  bool _isCafeTracked(String cafeId) {
    return _wishlist.any((cafe) => cafe.id == cafeId) ||
           _visitedCafes.any((cafe) => cafe.id == cafeId);
  }

  Future<void> _updateStatistics() async {
    try {
      final userId = FirebaseService.currentUserId;
      if (userId == null) return;

      _statistics = await CafeTrackingService.getUserStats(userId);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to update statistics: $e');
      }
    }
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