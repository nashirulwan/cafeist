import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import '../models/coffee_shop.dart';

class SimplePlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  static String? _apiKey;
  static bool _isInitialized = false;

  // Initialize with environment variable
  static void initialize() {
    try {
      final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        print('⚠️ GOOGLE_PLACES_API_KEY not found in .env file');
        _apiKey = null;
        _isInitialized = false;
        return;
      }
      _apiKey = apiKey;

      // Set initialization flag
      _isInitialized = true;

      if (kDebugMode) {
        print('✅ Google Places API initialized successfully');
      }
    } catch (e) {
      print('❌ Failed to initialize Places API: $e');
      _apiKey = null;
      _isInitialized = false;
    }
  }

  // Check if API is ready
  static bool get isInitialized => _apiKey != null && _apiKey!.isNotEmpty;

  // Get API key for internal use
  static String? get apiKey => _apiKey;

  /// Mencari kafe dengan text search
  Future<List<CoffeeShop>> searchCafes(String query) async {
    try {
      final uri = Uri.https('maps.googleapis.com', '/maps/api/place/textsearch/json', {
        'query': '$query cafe coffee shop',
        'type': 'cafe',
        'language': 'id',
        'key': _apiKey!,
      });
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (kDebugMode) {
          print('Places API Response: ${data['status']} - ${data['error_message'] ?? 'No error message'}');
        }

        if (data['status'] == 'OK' || data['status'] == 'ZERO_RESULTS') {
          final results = data['results'] as List;
          return results.map((place) => _convertToCoffeeShop(place)).toList();
        } else {
          throw Exception('Places API Error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
        }
      } else {
        if (kDebugMode) {
          print('HTTP Error ${response.statusCode}: ${response.body}');
        }
        throw Exception('HTTP Error ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to search cafes: $e');
      }
      throw Exception('Failed to search cafes: $e');
    }
  }

  /// Mencari kafe di lokasi tertentu dengan pagination
  Future<List<CoffeeShop>> findNearbyCafes(
      double latitude, double longitude, {
      int radius = 5000, // 5km radius
      String? pageToken,
      int limit = 20,
    }) async {
    try {
      final queryParams = <String, String>{
        'location': '$latitude,$longitude',
        'radius': radius.toString(),
        'type': 'cafe',
        'keyword': 'coffee',
        'language': 'id',
        'key': _apiKey!,
      };

      // Add pagination token if available
      if (pageToken != null) {
        queryParams['pagetoken'] = pageToken;
      }

      final uri = Uri.https('maps.googleapis.com', '/maps/api/place/nearbysearch/json', queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (kDebugMode) {
          print('Nearby Search API Response: ${data['status']} - ${data['error_message'] ?? 'No error message'}');
          if (data['next_page_token'] != null) {
            print('Has next page: ${data['next_page_token']}');
          }
          print('Total results: ${data['results']?.length ?? 0}');
        }

        if (data['status'] == 'OK' || data['status'] == 'ZERO_RESULTS') {
          final results = data['results'] as List;
          final cafes = results.map((place) => _convertToCoffeeShop(place)).toList();

          // Limit hasil sesuai dengan parameter limit
          if (cafes.length > limit) {
            return cafes.take(limit).toList();
          }

          return cafes;
        } else {
          throw Exception('Places API Error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
        }
      } else {
        if (kDebugMode) {
          print('HTTP Error ${response.statusCode}: ${response.body}');
        }
        throw Exception('HTTP Error ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to find nearby cafes: $e');
      }
      throw Exception('Failed to find nearby cafes: $e');
    }
  }

  /// Mendapatkan token untuk halaman berikutnya
  String? getNextPageToken(Map<String, dynamic> responseData) {
    return responseData['next_page_token'] as String?;
  }

  /// Cek apakah ada halaman berikutnya
  bool hasNextPage(Map<String, dynamic> responseData) {
    return responseData.containsKey('next_page_token') &&
           responseData['next_page_token'] != null;
  }

  /// Mengconvert data dari Google Places ke model CoffeeShop
  CoffeeShop _convertToCoffeeShop(Map<String, dynamic> place) {
    // Null safety checks for all nested properties
    final geometry = place['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    final photos = place['photos'] as List? ?? [];
    final openingHours = place['opening_hours'] as Map<String, dynamic>?;

    return CoffeeShop(
      id: place['place_id'] as String? ?? '',
      name: place['name'] as String? ?? 'Unknown Cafe',
      description: _getDescription(place),
      address: place['vicinity'] as String? ?? place['formatted_address'] as String? ?? '',
      phoneNumber: place['formatted_phone_number'] as String? ?? '',
      website: place['website'] as String? ?? '',
      latitude: location?['lat']?.toDouble() ?? 0.0,
      longitude: location?['lng']?.toDouble() ?? 0.0,
      rating: place['rating']?.toDouble() ?? 0.0,
      reviewCount: place['user_ratings_total'] as int? ?? 0,
      photos: photos
          .where((photo) => photo != null && photo['photo_reference'] != null)
          .map((photo) => _getPhotoUrl(photo['photo_reference'] as String))
          .where((url) => url != null)
          .cast<String>()
          .toList(),
      reviews: [], // Reviews butuh API call terpisah
      openingHours: _getDefaultOpeningHours(),
      distance: 0.0,
      isOpen: openingHours?['open_now'] as bool? ?? true,
      isFavorite: false,
      trackingStatus: CafeTrackingStatus.notTracked,
      visitData: null,
      socialMedia: null,
    );
  }

  String _getDescription(Map<String, dynamic> place) {
    final types = place['types'] as List? ?? [];
    final description = <String>[];

    if (types.contains('cafe')) description.add('Cafe');
    if (types.contains('coffee_shop')) description.add('Coffee Shop');
    if (types.contains('restaurant')) description.add('Restaurant');
    if (types.contains('bakery')) description.add('Bakery');

    if (description.isEmpty) {
      description.add('Coffee Shop');
    }

    return description.join(' • ');
  }

  String? _getPhotoUrl(String? photoReference) {
    if (photoReference == null) return null;

    return 'https://maps.googleapis.com/maps/api/place/photo'
        '?maxwidth=800'
        '&maxheight=600'
        '&photoreference=$photoReference'
        '&key=${_apiKey!}';
  }

  OpeningHours _getDefaultOpeningHours() {
    return OpeningHours(
      monday: '07:00 – 22:00',
      tuesday: '07:00 – 22:00',
      wednesday: '07:00 – 22:00',
      thursday: '07:00 – 22:00',
      friday: '07:00 – 22:00',
      saturday: '08:00 – 23:00',
      sunday: '08:00 – 23:00',
    );
  }

  /// Enhanced search with filters and sorting
  Future<List<CoffeeShop>> searchCafesWithFilters({
    required String query,
    double? minRating,
    int? minReviewCount,
    bool? openNow,
    double? userLat,
    double? userLng,
    int maxResults = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'query': '$query cafe coffee shop',
        'type': 'cafe',
        'language': 'id',
        'key': _apiKey!,
      };

      // Add filters
      if (minRating != null) {
        queryParams['minprice'] = '0'; // Will be filtered client-side for better results
      }
      if (openNow == true) {
        queryParams['opennow'] = 'true';
      }

      final uri = Uri.https('maps.googleapis.com', '/maps/api/place/textsearch/json', queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' || data['status'] == 'ZERO_RESULTS') {
          List<CoffeeShop> results = (data['results'] as List)
              .map((place) => _convertToCoffeeShop(place))
              .toList();

          // Client-side filtering for more precise control
          if (minRating != null) {
            results = results.where((cafe) => cafe.rating >= minRating).toList();
          }
          if (minReviewCount != null) {
            results = results.where((cafe) => cafe.reviewCount >= minReviewCount).toList();
          }

          // Calculate distances if user location is provided
          if (userLat != null && userLng != null) {
            results = results.map((cafe) {
              final distance = Geolocator.distanceBetween(
                userLat, userLng,
                cafe.latitude, cafe.longitude
              );
              return cafe.copyWith(distance: distance);
            }).toList();

            // Sort by distance
            results.sort((a, b) => a.distance.compareTo(b.distance));
          }

          // Limit results
          if (results.length > maxResults) {
            results = results.take(maxResults).toList();
          }

          return results;
        } else {
          throw Exception('Places API Error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('HTTP Error ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to search cafes with filters: $e');
      }
      throw Exception('Failed to search cafes with filters: $e');
    }
  }

  /// Get detailed information about a specific place
  Future<CoffeeShop?> getPlaceDetails(String placeId) async {
    try {
      final uri = Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
        'place_id': placeId,
        'fields': 'name,formatted_address,formatted_phone_number,website,rating,user_ratings_total,geometry,photos,reviews,opening_hours',
        'language': 'id',
        'key': _apiKey!,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final place = data['result'];
          return _convertToCoffeeShopDetailed(place);
        } else {
          if (kDebugMode) {
            print('Place Details API Error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
          }
          return null;
        }
      } else {
        throw Exception('HTTP Error ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get place details: $e');
      }
      throw Exception('Failed to get place details: $e');
    }
  }

  /// Convert detailed place data with additional fields
  CoffeeShop _convertToCoffeeShopDetailed(Map<String, dynamic> place) {
    final location = place['geometry']['location'];
    final photos = place['photos'] as List? ?? [];
    final reviews = place['reviews'] as List? ?? [];

    return CoffeeShop(
      id: place['place_id'] ?? '',
      name: place['name'] ?? 'Unknown Cafe',
      description: _getDescription(place),
      address: place['formatted_address'] ?? '',
      phoneNumber: place['formatted_phone_number'] ?? '',
      website: place['website'] ?? '',
      latitude: location['lat']?.toDouble() ?? 0.0,
      longitude: location['lng']?.toDouble() ?? 0.0,
      rating: place['rating']?.toDouble() ?? 0.0,
      reviewCount: place['user_ratings_total'] ?? 0,
      photos: photos
          .map((photo) => _getPhotoUrl(photo['photo_reference']))
          .where((url) => url != null)
          .cast<String>()
          .toList(),
      reviews: reviews.map((review) => _convertToReview(review)).toList(),
      openingHours: _convertToOpeningHours(place['opening_hours']),
      distance: 0.0,
      isOpen: place['opening_hours']?['open_now'] ?? true,
      isFavorite: false,
      trackingStatus: CafeTrackingStatus.notTracked,
      visitData: null,
      socialMedia: _extractSocialMedia(place),
    );
  }

  /// Convert review data from Google Places
  Review _convertToReview(Map<String, dynamic> review) {
    return Review(
      id: review['time']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userName: review['author_name'] ?? 'Anonymous',
      rating: review['rating']?.toDouble() ?? 0.0,
      comment: review['text'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(review['time'] ?? 0),
      photos: (review['profile_photo_url'] != null) ? [review['profile_photo_url']] : [],
    );
  }

  /// Convert opening hours data
  OpeningHours _convertToOpeningHours(Map<String, dynamic>? openingHours) {
    if (openingHours == null || openingHours['weekday_text'] == null) {
      return _getDefaultOpeningHours();
    }

    final weekdayText = openingHours['weekday_text'] as List;

    return OpeningHours(
      monday: _extractDayHours(weekdayText, 0),
      tuesday: _extractDayHours(weekdayText, 1),
      wednesday: _extractDayHours(weekdayText, 2),
      thursday: _extractDayHours(weekdayText, 3),
      friday: _extractDayHours(weekdayText, 4),
      saturday: _extractDayHours(weekdayText, 5),
      sunday: _extractDayHours(weekdayText, 6),
    );
  }

  String _extractDayHours(List weekdayText, int dayIndex) {
    if (dayIndex < weekdayText.length) {
      final dayText = weekdayText[dayIndex].toString();
      // Extract hours after colon (e.g., "Monday: 9:00 AM – 5:00 PM" -> "9:00 AM – 5:00 PM")
      final parts = dayText.split(':');
      if (parts.length > 1) {
        return parts.sublist(1).join(':').trim();
      }
    }
    return '09:00 – 21:00'; // Default hours
  }

  /// Extract social media links from place data
  Map<String, String>? _extractSocialMedia(Map<String, dynamic> place) {
    final socialMedia = <String, String>{};

    // This would need to be enhanced with actual social media detection
    if (place['website'] != null) {
      final website = place['website'].toString().toLowerCase();
      if (website.contains('instagram.com')) {
        socialMedia['instagram'] = place['website'];
      } else if (website.contains('facebook.com')) {
        socialMedia['facebook'] = place['website'];
      } else if (website.contains('twitter.com') || website.contains('x.com')) {
        socialMedia['twitter'] = place['website'];
      } else {
        socialMedia['website'] = place['website'];
      }
    }

    return socialMedia.isNotEmpty ? socialMedia : null;
  }

  /// Get popular cafes in a specific region/area
  Future<List<CoffeeShop>> getPopularCafesInRegion({
    required String region,
    double? centerLat,
    double? centerLng,
    int radius = 15000, // 15km radius
  }) async {
    try {
      final query = centerLat != null && centerLng != null
          ? 'popular coffee cafes near $centerLat,$centerLng'
          : 'popular coffee cafes in $region';

      return await searchCafesWithFilters(
        query: query,
        minRating: 4.0,
        minReviewCount: 100,
        userLat: centerLat,
        userLng: centerLng,
        maxResults: 50,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get popular cafes in region: $e');
      }
      throw Exception('Failed to get popular cafes in region: $e');
    }
  }

  /// Search for cafes with specific features (WiFi, power outlets, etc.)
  Future<List<CoffeeShop>> searchCafesByFeatures({
    required List<String> features,
    double? userLat,
    double? userLng,
    int radius = 10000,
  }) async {
    try {
      final featureQuery = features.join(' ');
      final locationQuery = userLat != null && userLng != null
          ? 'coffee shops with $featureQuery near $userLat,$userLng'
          : 'coffee shops with $featureQuery';

      return await findNearbyCafes(
        userLat ?? -6.2088, // Default Jakarta
        userLng ?? 106.8456,
        radius: radius,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to search cafes by features: $e');
      }
      throw Exception('Failed to search cafes by features: $e');
    }
  }
}
