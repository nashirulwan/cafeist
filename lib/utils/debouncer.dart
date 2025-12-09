import 'dart:async';
import 'package:flutter/foundation.dart';

/// Utility class for debouncing function calls
/// Prevents excessive API calls and improves performance
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  /// Run the function after specified delay
  /// If called again before delay expires, previous call is cancelled
  void run(VoidCallback action) {
    if (_timer?.isActive ?? false) {
      _timer?.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  /// Cancel any pending execution
  void cancel() {
    _timer?.cancel();
  }

  /// Check if there's a pending execution
  bool get isPending => _timer?.isActive ?? false;

  /// Dispose the debouncer
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Specialized debouncer for search functionality
class SearchDebouncer extends Debouncer {
  SearchDebouncer() : super(milliseconds: 500); // 500ms delay for search

  Future<void> search(Future<void> Function(String query) searchFunction, String query) async {
    if (query.trim().isEmpty) return;

    await Future.delayed(Duration(milliseconds: milliseconds));
    if (_timer?.isActive ?? false) return; // Was cancelled by new call

    await searchFunction(query);
  }
}

/// Debouncer for location updates
class LocationDebouncer extends Debouncer {
  LocationDebouncer() : super(milliseconds: 2000); // 2 seconds for location
}

/// Debouncer for API calls
class ApiDebouncer extends Debouncer {
  ApiDebouncer() : super(milliseconds: 1000); // 1 second for API calls
}