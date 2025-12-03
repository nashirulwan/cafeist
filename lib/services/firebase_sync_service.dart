import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/coffee_shop.dart';
import '../models/user_profile.dart';

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

      print('✅ User data synced to cloud successfully');
    } catch (e) {
      print('❌ Error syncing user data to cloud: $e');
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
        print('✅ User data loaded from cloud successfully');
        return {
          'wishlist': List<String>.from(data['wishlist'] ?? []),
          'favorites': List<String>.from(data['favorites'] ?? []),
          'visits': Map<String, dynamic>.from(data['visits'] ?? {}),
          'lastSync': data['lastSync'],
          'updatedAt': data['updatedAt'],
        };
      } else {
        print('ℹ️ No user data found in cloud, using empty data');
        return {
          'wishlist': <String>[],
          'favorites': <String>[],
          'visits': <String, dynamic>{},
          'lastSync': null,
          'updatedAt': null,
        };
      }
    } catch (e) {
      print('❌ Error getting user data from cloud: $e');
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

      print('✅ Visit data synced to cloud: $coffeeShopId');
    } catch (e) {
      print('❌ Error syncing visit to cloud: $e');
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

      print('✅ Wishlist synced to cloud: ${wishlist.length} items');
    } catch (e) {
      print('❌ Error syncing wishlist to cloud: $e');
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

      print('✅ Favorites synced to cloud: ${favorites.length} items');
    } catch (e) {
      print('❌ Error syncing favorites to cloud: $e');
      rethrow;
    }
  }

  /// Delete user data from cloud (for account deletion)
  static Future<void> deleteUserDataFromCloud(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      await userRef.delete();

      print('✅ User data deleted from cloud successfully');
    } catch (e) {
      print('❌ Error deleting user data from cloud: $e');
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

        print('✅ User profile created in Firestore');
      } else {
        print('ℹ️ User profile already exists in Firestore');
      }
    } catch (e) {
      print('❌ Error creating user profile: $e');
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

      print('✅ User stats updated in cloud');
    } catch (e) {
      print('❌ Error updating user stats: $e');
      rethrow;
    }
  }
}