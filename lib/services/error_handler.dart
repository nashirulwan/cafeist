import 'package:flutter/foundation.dart';


/// Global Error Handler untuk aplikasi Cafeist
class AppErrorHandler {
  static final AppErrorHandler _instance = AppErrorHandler._internal();
  factory AppErrorHandler() => _instance;
  AppErrorHandler._internal();

  /// Handle errors dengan logging dan user-friendly feedback
  static void handleError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    bool showToUser = false,
    VoidCallback? retryCallback,
  }) {
    // Log error untuk debugging
    _logError(error, stackTrace, context);

    // Tampilkan user-friendly message jika diperlukan
    if (showToUser && retryCallback != null) {
      _showUserFriendlyError(error, retryCallback);
    }

    // Report ke analytics di production
    if (!kDebugMode) {
      _reportToAnalytics(error, stackTrace, context);
    }
  }

  /// Log error ke console dengan format yang rapi
  static void _logError(dynamic error, StackTrace? stackTrace, String? context) {
    if (kDebugMode) {
      print('🔴 ERROR: ${context != null ? '[$context] ' : ''}${error.toString()}');
      if (stackTrace != null) {
        print('📍 Stack Trace: $stackTrace');
      }
    }
  }

  /// Tampilkan user-friendly error message
  static void _showUserFriendlyError(dynamic error, VoidCallback retryCallback) {
    // Get user-friendly message based on error type
    final String userMessage = _getUserFriendlyMessage(error);

    // Show snackbar dengan action untuk retry
    _showErrorSnackbar(userMessage, retryCallback);
  }

  /// Generate user-friendly error message
  static String _getUserFriendlyMessage(dynamic error) {
    final String errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('host') ||
        errorString.contains('socket')) {
      return '❌ Koneksi internet bermasalah. Silakan periksa koneksi Anda.';
    }

    // API errors
    if (errorString.contains('api') ||
        errorString.contains('401') ||
        errorString.contains('403') ||
        errorString.contains('404')) {
      return '⚠️ Gagal memuat data. Silakan coba lagi.';
    }

    // Location errors
    if (errorString.contains('location') ||
        errorString.contains('permission') ||
        errorString.contains('gps')) {
      return '📍 Tidak dapat mengakses lokasi. Silakan izinkan akses lokasi di pengaturan.';
    }

    // Firebase errors
    if (errorString.contains('firebase') ||
        errorString.contains('auth') ||
        errorString.contains('firestore')) {
      return '🔐 Terjadi masalah dengan akun Anda. Silakan login kembali.';
    }

    // Generic errors
    if (errorString.contains('format') ||
        errorString.contains('parse') ||
        errorString.contains('json')) {
      return '📝 Data tidak valid. Silakan refresh aplikasi.';
    }

    // Default message
    return '🚀 Terjadi kesalahan tak terduga. Silakan coba lagi.';
  }

  /// Show error snackbar dengan retry action
  static void _showErrorSnackbar(String message, VoidCallback retryCallback) {
    // Ini akan dipanggil dari UI context
    // Implementasi akan dilakukan di UI components
  }

  /// Report error ke analytics (production)
  static void _reportToAnalytics(dynamic error, StackTrace? stackTrace, String? context) {
    // Integrasi dengan Firebase Analytics atau Crashlytics
    // Implementasi untuk production
  }
}

/// Custom Error types untuk aplikasi
class AppException implements Exception {
  final String message;
  final String code;
  final String? context;

  const AppException({
    required this.message,
    required this.code,
    this.context,
  });

  @override
  String toString() {
    return 'AppException($code): $message';
  }
}

/// Network related exceptions
class NetworkException extends AppException {
  const NetworkException({String? message, super.context})
      : super(
          message: message ?? 'Network connection error',
          code: 'NETWORK_ERROR',
        );
}

/// API related exceptions
class ApiException extends AppException {
  const ApiException({String? message, super.context})
      : super(
          message: message ?? 'API request failed',
          code: 'API_ERROR',
        );
}

/// Location related exceptions
class LocationException extends AppException {
  const LocationException({String? message, super.context})
      : super(
          message: message ?? 'Location access error',
          code: 'LOCATION_ERROR',
        );
}

/// Authentication related exceptions
class AuthException extends AppException {
  const AuthException({String? message, super.context})
      : super(
          message: message ?? 'Authentication error',
          code: 'AUTH_ERROR',
        );
}

/// Data parsing related exceptions
class DataException extends AppException {
  const DataException({String? message, super.context})
      : super(
          message: message ?? 'Data parsing error',
          code: 'DATA_ERROR',
        );
}