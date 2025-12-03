import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../services/firebase_sync_service.dart';
import '../services/personal_tracking_service.dart';

class AuthProvider extends ChangeNotifier {
  UserProfile? _user;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserProfile? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get displayName => _user?.displayName ?? 'Guest';
  String get email => _user?.email ?? '';
  String? get photoURL => _user?.photoURL;
  bool get isEmailVerified => _user?.isEmailVerified ?? false;

  AuthProvider() {
    _initializeAuth();
  }

  /// Initialize auth state on app startup
  Future<void> _initializeAuth() async {
    _setLoading(true);
    _clearError();

    try {
      if (kDebugMode) {
        print('🔍 Checking existing auth session...');
      }

      // Check if user is already logged in
      if (FirebaseService.isLoggedIn) {
        final userProfile = await AuthService.getUserProfile(FirebaseService.currentUser!.uid);
        if (userProfile != null) {
          _user = userProfile;
          if (kDebugMode) {
            print('✅ User already logged in: ${userProfile.displayName}');
          }
        } else {
          // User exists in Firebase Auth but not in Firestore
          if (kDebugMode) {
            print('⚠️ Firebase user exists but no profile in Firestore');
          }
          await _signOut(); // Clean up incomplete auth
        }
      }
    } catch (e) {
      _setError('Failed to initialize authentication: $e');
      if (kDebugMode) {
        print('❌ Auth initialization failed: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      if (kDebugMode) {
        print('🔄 Starting Google Sign In...');
      }

      final userProfile = await AuthService.signInWithGoogle();
      _user = userProfile;

      // Create user profile in Firestore if it doesn't exist
      await FirebaseSyncService.createUserProfileIfNotExists(
        userId: userProfile.uid,
        displayName: userProfile.displayName,
        email: userProfile.email,
        photoURL: userProfile.photoURL,
      );

      // Sync data from Firebase to local storage
      await _syncUserDataOnLogin(userProfile.uid);

      if (kDebugMode) {
        print('✅ Google Sign In successful: ${userProfile.displayName}');
        print('✅ User data synced from cloud');
      }
    } catch (e) {
      _setError(e.toString());
      if (kDebugMode) {
        print('❌ Google Sign In failed: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with Email and Password
  Future<void> signInWithEmail(String email, String password) async {
    if (_isLoading) return;

    if (email.isEmpty || password.isEmpty) {
      _setError('Email and password are required');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      if (kDebugMode) {
        print('🔄 Starting Email Sign In...');
      }

      final userProfile = await AuthService.signInWithEmail(email, password);
      _user = userProfile;

      // Create user profile in Firestore if it doesn't exist
      await FirebaseSyncService.createUserProfileIfNotExists(
        userId: userProfile.uid,
        displayName: userProfile.displayName,
        email: userProfile.email,
        photoURL: userProfile.photoURL,
      );

      // Sync data from Firebase to local storage
      await _syncUserDataOnLogin(userProfile.uid);

      if (kDebugMode) {
        print('✅ Email Sign In successful: ${userProfile.displayName}');
        print('✅ User data synced from cloud');
      }
    } catch (e) {
      _setError(e.toString());
      if (kDebugMode) {
        print('❌ Email Sign In failed: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Create new user with Email and Password
  Future<void> createEmailUser(String email, String password, String displayName) async {
    if (_isLoading) return;

    if (email.isEmpty || password.isEmpty || displayName.isEmpty) {
      _setError('Email, password, and display name are required');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      if (kDebugMode) {
        print('🔄 Creating new email user...');
      }

      final userProfile = await AuthService.createEmailUser(email, password, displayName);
      _user = userProfile;

      // Create user profile in Firestore (this will be called in AuthService.createEmailUser too)
      await FirebaseSyncService.createUserProfileIfNotExists(
        userId: userProfile.uid,
        displayName: userProfile.displayName,
        email: userProfile.email,
        photoURL: userProfile.photoURL,
      );

      // Sync data from Firebase to local storage
      await _syncUserDataOnLogin(userProfile.uid);

      if (kDebugMode) {
        print('✅ Email user created successfully: ${userProfile.displayName}');
        print('✅ User data synced from cloud');
      }
    } catch (e) {
      _setError(e.toString());
      if (kDebugMode) {
        print('❌ Email user creation failed: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    if (_isLoading) return;

    if (email.isEmpty) {
      _setError('Email is required');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      await AuthService.resetPassword(email);

      if (kDebugMode) {
        print('✅ Password reset email sent to: $email');
      }
    } catch (e) {
      _setError(e.toString());
      if (kDebugMode) {
        print('❌ Password reset failed: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      await AuthService.signOut();
      _user = null;

      if (kDebugMode) {
        print('✅ User signed out successfully');
      }
    } catch (e) {
      _setError('Failed to sign out: $e');
      if (kDebugMode) {
        print('❌ Sign out failed: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      final userId = _user?.uid;

      await AuthService.deleteAccount();

      // Clear user data from Firebase if user ID is available
      if (userId != null) {
        await FirebaseSyncService.deleteUserDataFromCloud(userId);
      }

      _user = null;

      if (kDebugMode) {
        print('✅ User account and data deleted successfully');
      }
    } catch (e) {
      _setError('Failed to delete account: $e');
      if (kDebugMode) {
        print('❌ Account deletion failed: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh user profile
  Future<void> refreshUserProfile() async {
    if (_user == null || _isLoading) return;

    try {
      final userProfile = await AuthService.getUserProfile(FirebaseService.currentUser!.uid);
      if (userProfile != null) {
        _user = userProfile;
        notifyListeners();

        if (kDebugMode) {
          print('✅ User profile refreshed');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to refresh user profile: $e');
      }
    }
  }

  /// Update user profile
  void updateUserProfile({
    String? displayName,
    String? bio,
    String? location,
    Map<String, dynamic>? preferences,
    bool? notificationsEnabled,
    String? defaultRegion,
  }) {
    if (_user == null) return;

    _user = _user!.copyWith(
      displayName: displayName,
      bio: bio,
      location: location,
      preferences: preferences,
      notificationsEnabled: notificationsEnabled,
      defaultRegion: defaultRegion,
    );

    notifyListeners();
  }

  /// Clear current error
  void clearError() {
    _clearError();
  }

  // Private helper methods
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

  Future<void> _signOut() async {
    try {
      await AuthService.signOut();
      _user = null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Emergency sign out failed: $e');
      }
    }
  }

  /// Sync user data from Firebase to local storage on login
  Future<void> _syncUserDataOnLogin(String userId) async {
    try {
      // Initialize tracking service and sync data
      final trackingService = PersonalTrackingService();
      await trackingService.syncFromCloudToLocal(userId);

      if (kDebugMode) {
        print('✅ User tracking data synced from Firebase');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Warning: Failed to sync user data from Firebase: $e');
        print('🔄 Continuing with local data...');
      }
      // Don't throw error, allow user to continue login even if sync fails
    }
  }
}