import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';
import '../models/user_profile.dart';

class AuthService {
  static GoogleSignIn? _googleSignIn;

  /// Initialize Google Sign-In
  static void initializeGoogleSignIn() {
    if (_googleSignIn != null) return;

    _googleSignIn = GoogleSignIn(
      scopes: [
        'email',
        'profile',
      ],
    );
  }

  /// Get Google Sign-In instance
  static GoogleSignIn get googleSignIn {
    _googleSignIn ??= GoogleSignIn(
      scopes: [
        'email',
        'profile',
      ],
    );
    return _googleSignIn!;
  }

  /// Sign in with Google
  static Future<UserProfile> signInWithGoogle() async {
    try {
      // Show debug info
      if (kDebugMode) {
        print('🔄 Starting Google Sign In...');
      }

      // Initialize Google Sign-In if not already initialized
      initializeGoogleSignIn();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await FirebaseService.auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) {
        throw Exception('Failed to sign in with Google');
      }

      // Create or update user profile in Firestore
      final userProfile = UserProfile(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? 'User',
        photoURL: user.photoURL,
        isEmailVerified: user.emailVerified,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        authProvider: 'google',
      );

      // Save to Firestore
      await _saveUserProfile(userProfile);

      if (kDebugMode) {
        print('✅ Google Sign In successful for: ${user.displayName}');
      }

      return userProfile;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Google Sign In failed: $e');

        // Provide more specific error information
        if (e.toString().contains('ApiException:10')) {
          print('🔧 This error usually means:');
          print('   1. OAuth client ID is not configured correctly');
          print('   2. SHA-1 fingerprint is missing from Firebase console');
          print('   3. Google Sign-In is not enabled in Firebase console');
        }
      }

      // Re-throw with user-friendly message
      if (e.toString().contains('ApiException:10')) {
        throw Exception('Google Sign-In is not properly configured. Please contact app administrator.');
      } else if (e.toString().contains('cancelled')) {
        throw Exception('Sign in was cancelled');
      } else {
        throw Exception('Google Sign In failed: ${e.toString()}');
      }
    }
  }

  /// Sign in with Email and Password
  static Future<UserProfile> signInWithEmail(String email, String password) async {
    try {
      if (kDebugMode) {
        print('🔄 Starting Email Sign In for: $email');
      }

      final UserCredential userCredential = await FirebaseService.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;

      if (user == null) {
        throw Exception('Failed to sign in with email');
      }

      // Get user profile from Firestore
      final userProfile = await _getUserProfile(user.uid);

      // Update last login
      await _updateLastLogin(user.uid);

      if (kDebugMode) {
        print('✅ Email Sign In successful for: ${user.displayName}');
      }

      return userProfile;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Email Sign In failed: $e');
      }

      // Handle specific Firebase auth errors
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            throw Exception('No user found with this email address');
          case 'wrong-password':
            throw Exception('Incorrect password provided');
          case 'invalid-email':
            throw Exception('The email address is not valid');
          case 'user-disabled':
            throw Exception('This user account has been disabled');
          case 'too-many-requests':
            throw Exception('Too many failed attempts. Please try again later');
          default:
            throw Exception('Sign in failed: ${e.message}');
        }
      }

      throw Exception('Email Sign In failed: $e');
    }
  }

  /// Create new user with Email and Password
  static Future<UserProfile> createEmailUser(String email, String password, String displayName) async {
    try {
      if (kDebugMode) {
        print('🔄 Creating new email user: $email');
      }

      final UserCredential userCredential = await FirebaseService.auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;

      if (user == null) {
        throw Exception('Failed to create user');
      }

      // Update display name
      await user.updateDisplayName(displayName);

      // Send email verification
      await user.sendEmailVerification();

      // Create user profile
      final userProfile = UserProfile(
        uid: user.uid,
        email: user.email ?? email,
        displayName: displayName,
        photoURL: null,
        isEmailVerified: false,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        authProvider: 'email',
      );

      // Save to Firestore
      await _saveUserProfile(userProfile);

      if (kDebugMode) {
        print('✅ Email user created successfully: $displayName');
        print('📧 Verification email sent to: $email');
      }

      return userProfile;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Email user creation failed: $e');
      }

      // Handle specific Firebase auth errors
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'weak-password':
            throw Exception('The password provided is too weak');
          case 'email-already-in-use':
            throw Exception('An account already exists for this email');
          case 'invalid-email':
            throw Exception('The email address is not valid');
          default:
            throw Exception('Account creation failed: ${e.message}');
        }
      }

      throw Exception('Email user creation failed: $e');
    }
  }

  /// Sign out current user
  static Future<void> signOut() async {
    try {
      // Sign out from Google if signed in
      if (_googleSignIn != null && await _googleSignIn!.isSignedIn()) {
        await _googleSignIn!.signOut();
      }

      // Sign out from Firebase
      await FirebaseService.signOut();

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

  /// Get current user profile
  static Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final User? user = FirebaseService.currentUser;
      if (user == null) return null;

      return await _getUserProfile(user.uid);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get current user profile: $e');
      }
      return null;
    }
  }

  /// Get user profile by UID (public method)
  static Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await FirebaseService.firestore
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) {
        return null;
      }

      return UserProfile.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get user profile: $e');
      }
      return null;
    }
  }

  /// Delete user account
  static Future<void> deleteAccount() async {
    try {
      final User? user = FirebaseService.currentUser;
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

  /// Reset password
  static Future<void> resetPassword(String email) async {
    try {
      if (kDebugMode) {
        print('🔄 Sending password reset email to: $email');
      }

      await FirebaseService.auth.sendPasswordResetEmail(email: email);

      if (kDebugMode) {
        print('✅ Password reset email sent successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Password reset failed: $e');
      }

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-email':
            throw Exception('The email address is not valid');
          case 'user-not-found':
            throw Exception('No user found with this email address');
          default:
            throw Exception('Password reset failed: ${e.message}');
        }
      }

      throw Exception('Password reset failed: $e');
    }
  }

  // Private helper methods

  /// Save user profile to Firestore
  static Future<void> _saveUserProfile(UserProfile profile) async {
    try {
      await FirebaseService.firestore
          .collection('users')
          .doc(profile.uid)
          .set(profile.toJson());

      if (kDebugMode) {
        print('✅ User profile saved to Firestore');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to save user profile: $e');
      }
      throw Exception('Failed to save user profile: $e');
    }
  }

  /// Get user profile from Firestore
  static Future<UserProfile> _getUserProfile(String uid) async {
    try {
      final doc = await FirebaseService.firestore
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) {
        throw Exception('User profile not found');
      }

      return UserProfile.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get user profile: $e');
      }
      throw Exception('Failed to get user profile: $e');
    }
  }

  /// Update user's last login time
  static Future<void> _updateLastLogin(String uid) async {
    try {
      await FirebaseService.firestore
          .collection('users')
          .doc(uid)
          .update({
        'lastLoginAt': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        print('✅ Last login time updated');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to update last login time: $e');
      }
      // Don't throw error for non-critical update
    }
  }

  /// Update user display name in Firebase Auth
  static Future<void> updateDisplayName(String userId, String newDisplayName) async {
    try {
      if (kDebugMode) {
        print('🔄 Updating display name in Firebase Auth for user: $userId');
      }

      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.uid == userId) {
        await currentUser.updateDisplayName(newDisplayName);
        await currentUser.reload();

        if (kDebugMode) {
          print('✅ Display name updated in Firebase Auth');
        }
      } else {
        throw Exception('Current user mismatch or not logged in');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to update display name in Firebase Auth: $e');
      }
      rethrow;
    }
  }

  /// Update user profile photo in Firebase Auth
  static Future<void> updateProfilePhoto(String userId, String? newPhotoURL) async {
    try {
      if (kDebugMode) {
        print('🔄 Updating profile photo in Firebase Auth for user: $userId');
      }

      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.uid == userId) {
        await currentUser.updatePhotoURL(newPhotoURL);
        await currentUser.reload();

        if (kDebugMode) {
          print('✅ Profile photo updated in Firebase Auth');
        }
      } else {
        throw Exception('Current user mismatch or not logged in');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to update profile photo in Firebase Auth: $e');
      }
      rethrow;
    }
  }

  /// Check if Google Sign In is available
  static bool get isGoogleSignInAvailable => true; // Always available in mobile app
}