import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/logger.dart';

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
        AppLogger.info('Firebase initialized successfully', tag: 'Firebase');
        AppLogger.debug('App ready for authentication and database', tag: 'Firebase');
      }

      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('Firebase initialization failed', error: e, tag: 'Firebase');
        AppLogger.warning('Continuing without Firebase functionality', tag: 'Firebase');
      }
      // Don't throw error - continue without Firebase
      AppLogger.warning('Using Firebase with basic configuration for development...', tag: 'Firebase');
    }
  }

  /// Wait for the auth state to ensure we have a valid user or null
  static Future<bool> waitForAuthReady() async {
    if (!_initialized) return false;
    try {
      // Wait for first auth state emission
      await _auth.authStateChanges().first;
      return true;
    } catch (e) {
      AppLogger.error('Error waiting for auth ready', error: e, tag: 'Firebase');
      return false;
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
        AppLogger.info('User signed out successfully', tag: 'Auth');
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('Sign out failed', error: e, tag: 'Auth');
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
          AppLogger.info('User account deleted successfully', tag: 'Auth');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('Account deletion failed', error: e, tag: 'Auth');
      }
      throw Exception('Account deletion failed: $e');
    }
  }
}