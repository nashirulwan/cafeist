import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/coffee_shop.dart';
import '../utils/logger.dart';

/// Cache item with timestamp
class CacheItem {
  final dynamic data;
  final DateTime timestamp;
  final Duration expiry;

  CacheItem({required this.data, required this.expiry})
      : timestamp = DateTime.now();

  bool get isExpired => DateTime.now().difference(timestamp) > expiry;

  Map<String, dynamic> toJson() => {
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'expiry': expiry.inMilliseconds,
  };

  factory CacheItem.fromJson(Map<String, dynamic> json, Function fromJson) {
    return CacheItem(
      data: fromJson(json['data']),
      expiry: Duration(milliseconds: (json['expiry'] as num).toInt()),
    );
  }
}

/// Simple in-memory and persistent cache manager
/// Improves performance by avoiding redundant API calls
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  // In-memory cache for fast access
  final Map<String, CacheItem> _memoryCache = {};

  // Cache keys
  static const String _coffeeShopsKey = 'cached_coffee_shops';

  static const String _searchResultsPrefix = 'search_results_';
  static const String _locationKey = 'cached_user_location';

  // Cache duration (in hours)
  static const int _defaultCacheHours = 1;


  /// Save data to both memory and persistent cache
  Future<void> set<T>({
    required String key,
    required T data,
    Duration? expiry,
    Function(T)? toJson,
  }) async {
    try {
      final cacheItem = CacheItem(
        data: data,
        expiry: expiry ?? Duration(hours: _defaultCacheHours),
      );

      // Save to memory cache
      _memoryCache[key] = cacheItem;

      // Save to persistent cache
      final prefs = await SharedPreferences.getInstance();
      if (toJson != null) {
        final jsonData = toJson(data);
        await prefs.setString(key, jsonEncode({
          'data': jsonData,
          'timestamp': cacheItem.timestamp.toIso8601String(),
          'expiry': cacheItem.expiry.inMilliseconds,
        }));
      }
    } catch (e) {
      AppLogger.error('Failed to cache data', error: e, tag: 'Cache');
    }
  }

  /// Get data from cache (memory first, then persistent)
  Future<T?> get<T>({
    required String key,
    required Function(dynamic) fromJson,
  }) async {
    try {
      // Check memory cache first
      final memoryItem = _memoryCache[key];
      if (memoryItem != null && !memoryItem.isExpired) {
        AppLogger.debug('Cache hit (memory): $key', tag: 'Cache');
        return memoryItem.data as T?;
      }

      // Check persistent cache
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(key);
      if (cachedData != null) {
        final jsonData = jsonDecode(cachedData);
        final timestamp = DateTime.parse(jsonData['timestamp']);
        final expiry = Duration(milliseconds: jsonData['expiry']);

        if (DateTime.now().difference(timestamp) <= expiry) {
          final data = fromJson(jsonData['data']);

          // Update memory cache
          _memoryCache[key] = CacheItem(data: data, expiry: expiry);

          AppLogger.debug('Cache hit (persistent): $key', tag: 'Cache');
          return data as T?;
        } else {
          // Remove expired cache
          await prefs.remove(key);
          _memoryCache.remove(key);
          AppLogger.debug('Cache expired and removed: $key', tag: 'Cache');
        }
      }

      AppLogger.debug('Cache miss: $key', tag: 'Cache');
      return null;
    } catch (e) {
      AppLogger.error('Failed to get cached data', error: e, tag: 'Cache');
      return null;
    }
  }

  /// Cache coffee shops list
  Future<void> cacheCoffeeShops(List<CoffeeShop> coffeeShops) async {
    await set<List<CoffeeShop>>(
      key: _coffeeShopsKey,
      data: coffeeShops,
      expiry: Duration(hours: _defaultCacheHours),
      toJson: (shops) => shops.map((shop) => shop.toJson()).toList(),
    );
  }

  /// Get cached coffee shops
  Future<List<CoffeeShop>?> getCachedCoffeeShops() async {
    return await get<List<CoffeeShop>>(
      key: _coffeeShopsKey,
      fromJson: (data) {
        if (data is List) {
          return data.map((item) => CoffeeShop.fromJson(item)).toList();
        }
        return <CoffeeShop>[];
      },
    );
  }

  /// Cache search results
  Future<void> cacheSearchResults(String query, List<CoffeeShop> results) async {
    final key = '$_searchResultsPrefix${query.toLowerCase()}';
    await set<List<CoffeeShop>>(
      key: key,
      data: results,
      expiry: Duration(minutes: 30), // Search results expire faster
      toJson: (shops) => shops.map((shop) => shop.toJson()).toList(),
    );
  }

  /// Get cached search results
  Future<List<CoffeeShop>?> getCachedSearchResults(String query) async {
    final key = '$_searchResultsPrefix${query.toLowerCase()}';
    return await get<List<CoffeeShop>>(
      key: key,
      fromJson: (data) {
        if (data is List) {
          return data.map((item) => CoffeeShop.fromJson(item)).toList();
        }
        return <CoffeeShop>[];
      },
    );
  }

  /// Cache user location
  Future<void> cacheUserLocation({
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    final locationData = {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
    await set<Map<String, dynamic>>(
      key: _locationKey,
      data: locationData,
      expiry: Duration(minutes: 30), // 30 minutes for location
    );
  }

  /// Get cached user location
  Future<Map<String, dynamic>?> getCachedUserLocation() async {
    return await get<Map<String, dynamic>>(
      key: _locationKey,
      fromJson: (data) => Map<String, dynamic>.from(data),
    );
  }

  /// Clear specific cache entry
  Future<void> clear(String key) async {
    _memoryCache.remove(key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  /// Clear all cache
  Future<void> clearAll() async {
    _memoryCache.clear();
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('cached_') || key.startsWith('search_results_')) {
        await prefs.remove(key);
      }
    }
    AppLogger.info('All cache cleared', tag: 'Cache');
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final memorySize = _memoryCache.length;

    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) =>
      key.startsWith('cached_') || key.startsWith('search_results_')
    ).toList();

    return {
      'memoryCacheEntries': memorySize,
      'persistentCacheEntries': keys.length,
      'totalKeys': keys,
    };
  }
}