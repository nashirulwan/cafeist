import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/coffee_shop.dart';
import '../models/user_profile.dart';
import '../utils/logger.dart';

class FirebaseSyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sync user's coffee tracking data to Firebase
  static Future<void> syncUserDataToCloud({
    required String userId,
    List<String>? wishlist,
    List<String>? favorites,
    Map<String, dynamic>? visits,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      await userRef.set({
        'wishlist': wishlist ?? [],
        'favorites': favorites ?? [],
        'visits': visits ?? {},
        'lastSync': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      AppLogger.success('User data synced to cloud successfully', tag: 'Firebase');
    } catch (e) {
      AppLogger.error('Error syncing user data to cloud', error: e, tag: 'Firebase');
      rethrow;
    }
  }

  /// Get user's tracking data from Firebase
  static Future<Map<String, dynamic>> getUserDataFromCloud(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final docSnapshot = await userRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        AppLogger.success('User data loaded from cloud successfully', tag: 'Firebase');
        return {
          'wishlist': List<String>.from(data['wishlist'] ?? []),
          'favorites': List<String>.from(data['favorites'] ?? []),
          'visits': Map<String, dynamic>.from(data['visits'] ?? {}),
          'lastSync': data['lastSync'],
          'updatedAt': data['updatedAt'],
        };
      } else {
        AppLogger.info('No user data found in cloud, using empty data', tag: 'Firebase');
        return {
          'wishlist': <String>[],
          'favorites': <String>[],
          'visits': <String, dynamic>{},
          'lastSync': null,
          'updatedAt': null,
        };
      }
    } catch (e) {
      AppLogger.error('Error getting user data from cloud', error: e, tag: 'Firebase');
      rethrow;
    }
  }

  /// Sync coffee shop visits with timestamp
  static Future<void> syncVisitToCloud({
    required String userId,
    required String coffeeShopId,
    required Map<String, dynamic> visitData,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      await userRef.update({
        'visits.$coffeeShopId': visitData,
        'visits.$coffeeShopId.updatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.success('Visit data synced to cloud: $coffeeShopId', tag: 'Firebase');
    } catch (e) {
      AppLogger.error('Error syncing visit to cloud', error: e, tag: 'Firebase');
      rethrow;
    }
  }

  /// Sync wishlist changes
  static Future<void> syncWishlistToCloud({
    required String userId,
    required List<String> wishlist,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      await userRef.update({
        'wishlist': wishlist,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.success('Wishlist synced to cloud: ${wishlist.length} items', tag: 'Firebase');
    } catch (e) {
      AppLogger.error('Error syncing wishlist to cloud', error: e, tag: 'Firebase');
      rethrow;
    }
  }

  /// Add/remove single item from wishlist
  static Future<void> syncWishlistItemToCloud({
    required String userId,
    required String cafeId,
    required String action, // 'add' or 'remove'
    CoffeeShop? coffeeShop,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      if (action == 'add') {
        // Add to wishlist array
        await userRef.update({
          'wishlist': FieldValue.arrayUnion([cafeId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        AppLogger.success('Added to wishlist: $cafeId', tag: 'Firebase');
      } else if (action == 'remove') {
        // Remove from wishlist array
        await userRef.update({
          'wishlist': FieldValue.arrayRemove([cafeId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        AppLogger.success('Removed from wishlist: $cafeId', tag: 'Firebase');
      }
    } catch (e) {
      AppLogger.error('Error syncing wishlist item to cloud', error: e, tag: 'Firebase');
      rethrow;
    }
  }

  /// Sync favorites changes
  static Future<void> syncFavoritesToCloud({
    required String userId,
    required List<String> favorites,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      await userRef.update({
        'favorites': favorites,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.success('Favorites synced to cloud: ${favorites.length} items', tag: 'Firebase');
    } catch (e) {
      AppLogger.error('Error syncing favorites to cloud', error: e, tag: 'Firebase');
      rethrow;
    }
  }

  /// Delete user data from cloud (for account deletion)
  static Future<void> deleteUserDataFromCloud(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      await userRef.delete();

      AppLogger.success('User data deleted from cloud successfully', tag: 'Firebase');
    } catch (e) {
      AppLogger.error('Error deleting user data from cloud', error: e, tag: 'Firebase');
      rethrow;
    }
  }

  /// Check if user is logged in
  static bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  /// Get current user ID
  static String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Create user profile in Firestore if it doesn't exist
  static Future<void> createUserProfileIfNotExists({
    required String userId,
    required String displayName,
    required String email,
    String? photoURL,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final docSnapshot = await userRef.get();

      if (!docSnapshot.exists) {
        await userRef.set({
          'userId': userId,
          'displayName': displayName,
          'email': email,
          'photoURL': photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'wishlist': [],
          'favorites': [],
          'visits': {},
          'stats': {
            'totalVisits': 0,
            'uniqueCafes': 0,
            'avgRating': 0.0,
          },
        });

        AppLogger.success('User profile created in Firestore', tag: 'Firebase');
      } else {
        AppLogger.info('User profile already exists in Firestore', tag: 'Firebase');
      }
    } catch (e) {
      AppLogger.error('Error creating user profile', error: e, tag: 'Firebase');
      rethrow;
    }
  }

  /// Update user statistics
  static Future<void> updateUserStats({
    required String userId,
    required int totalVisits,
    required int uniqueCafes,
    required double avgRating,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      await userRef.update({
        'stats.totalVisits': totalVisits,
        'stats.uniqueCafes': uniqueCafes,
        'stats.avgRating': avgRating,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.success('User stats updated in cloud', tag: 'Firebase');
    } catch (e) {
      AppLogger.error('Error updating user stats', error: e, tag: 'Firebase');
      rethrow;
    }
  }

  /// Sync user profile to Firestore
  static Future<void> syncUserProfile(UserProfile userProfile) async {
    try {
      final userDoc = _firestore.collection('users').doc(userProfile.uid);

      final profileData = {
        'displayName': userProfile.displayName,
        'email': userProfile.email,
        'photoURL': userProfile.photoURL,
        'authProvider': userProfile.authProvider,
        'lastLoginAt': userProfile.lastLoginAt.toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (userProfile.bio != null) 'bio': userProfile.bio,
        if (userProfile.location != null) 'location': userProfile.location,
        if (userProfile.preferences != null) 'preferences': userProfile.preferences,
        'notificationsEnabled': userProfile.notificationsEnabled,
        if (userProfile.defaultRegion != null) 'defaultRegion': userProfile.defaultRegion,
      };

      await userDoc.set(profileData, SetOptions(merge: true));

      AppLogger.success('User profile synced to cloud: ${userProfile.displayName}', tag: 'Firebase');
    } catch (e) {
      AppLogger.error('Error syncing user profile', error: e, tag: 'Firebase');
      rethrow;
    }
  }
}