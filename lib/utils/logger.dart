import 'package:flutter/foundation.dart';

/// Centralized logging utility for the application
/// Replaces direct print statements with proper logging levels
class AppLogger {
  static const String _tag = 'Cafeist';

  /// Debug level logging - only in debug mode
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      _log('🔍', message, tag: tag);
    }
  }

  /// Info level logging - only in debug mode
  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      _log('ℹ️', message, tag: tag);
    }
  }

  /// Success logging - only in debug mode
  static void success(String message, {String? tag}) {
    if (kDebugMode) {
      _log('✅', message, tag: tag);
    }
  }

  /// Warning logging - only in debug mode
  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      _log('⚠️', message, tag: tag);
    }
  }

  /// Error logging - only in debug mode but could be sent to crash reporting in production
  static void error(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
    if (kDebugMode) {
      _log('❌', message, tag: tag);
      if (error != null) {
        _log('💥', 'Error: $error', tag: tag);
      }
      if (stackTrace != null && kDebugMode) {
        _log('📋', 'StackTrace: $stackTrace', tag: tag);
      }
    }

    // In production, you could send errors to Crashlytics here
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }

  /// Network logging - for API calls
  static void network(String message, {String? tag}) {
    if (kDebugMode) {
      _log('🌐', message, tag: tag);
    }
  }

  /// Database logging - for Firestore/SQLite operations
  static void database(String message, {String? tag}) {
    if (kDebugMode) {
      _log('🗄️', message, tag: tag);
    }
  }

  /// Authentication logging
  static void auth(String message, {String? tag}) {
    if (kDebugMode) {
      _log('🔐', message, tag: tag);
    }
  }

  /// Location logging
  static void location(String message, {String? tag}) {
    if (kDebugMode) {
      _log('📍', message, tag: tag);
    }
  }

  /// Performance logging
  static void performance(String message, {String? tag}) {
    if (kDebugMode) {
      _log('⚡', message, tag: tag);
    }
  }

  /// User action logging
  static void userAction(String message, {String? tag}) {
    if (kDebugMode) {
      _log('👤', message, tag: tag);
    }
  }

  /// Core logging method
  static void _log(String emoji, String message, {String? tag}) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String().substring(11, 19);
      final finalTag = tag ?? _tag;
      print('[$timestamp] $emoji $finalTag: $message');
    }
  }

  /// Method to log sensitive data with masking
  static void sensitive(String message, {String? tag}) {
    if (kDebugMode) {
      // Mask sensitive information like API keys, tokens, etc.
      String maskedMessage = message;

      // Mask API keys (pattern: simple alphanumeric strings longer than 20 chars)
      maskedMessage = maskedMessage.replaceAllMapped(
        RegExp(r'[a-zA-Z0-9]{20,}'),
        (match) => '${match.group(0)!.substring(0, 8)}...${match.group(0)!.substring(match.group(0)!.length - 4)}',
      );

      // Mask email addresses
      maskedMessage = maskedMessage.replaceAllMapped(
        RegExp(r'([a-zA-Z0-9._%+-]+)@([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})'),
        (match) => '${match.group(1)!.substring(0, 3)}***@${match.group(2)}',
      );

      _log('🔒', maskedMessage, tag: tag);
    }
  }
}