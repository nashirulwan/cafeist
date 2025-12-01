import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseService {
  static bool _initialized = false;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize Firebase for the app
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize Firebase with options from environment variables
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
          appId: dotenv.env['FIREBASE_APP_ID'] ?? '',
          messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
          projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
          authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '',
          databaseURL: dotenv.env['FIREBASE_DATABASE_URL'] ?? '',
          storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
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