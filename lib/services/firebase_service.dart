import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static bool _initialized = false;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize Firebase for the app
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize Firebase with options from google-services.json
      // Firebase will automatically read from google-services.json on Android
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyCjMXoQ27VQotN_nzWIbaxbxOmDvtnwO2w',
          appId: '1:510769430776:android:8dd2cc7edf1ea2d99e3b0d',
          messagingSenderId: '510769430776',
          projectId: 'cafeist-7a684',
          authDomain: 'cafeist-7a684.firebaseapp.com',
          databaseURL: 'https://cafeist-7a684-default-rtdb.firebaseio.com',
          storageBucket: 'cafeist-7a684.firebasestorage.app',
        ),
      );

      // Set Firestore settings for better performance
      if (kDebugMode) {
        print('✅ Firebase initialized successfully');
        print('📱 App ready for authentication and database');
      }

      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firebase initialization failed: $e');
        print('⚠️ Continuing without Firebase functionality');
      }
      // Don't throw error - continue without Firebase
      print('⚠️ Using Firebase with basic configuration for development...');
    }
  }

  /// Get Firebase Auth instance
  static FirebaseAuth get auth => _auth;

  /// Get Firestore instance
  static FirebaseFirestore get firestore => _firestore;

  /// Check if Firebase is initialized
  static bool get isInitialized => _initialized;

  /// Get current user
  static User? get currentUser => _auth.currentUser;

  /// Check if user is logged in
  static bool get isLoggedIn => currentUser != null;

  /// Get current user ID
  static String? get currentUserId => currentUser?.uid;

  /// Sign out user
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      if (kDebugMode) {
        print('✅ User signed out successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Sign out failed: $e');
      }
      throw Exception('Sign out failed: $e');
    }
  }

  /// Delete user account
  static Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user != null) {
        await user.delete();
        if (kDebugMode) {
          print('✅ User account deleted successfully');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Account deletion failed: $e');
      }
      throw Exception('Account deletion failed: $e');
    }
  }
}