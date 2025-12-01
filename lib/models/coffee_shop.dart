import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/simple_places_service.dart';

class CoffeeShop {
  final String id;
  final String name;
  final String description;
  final String address;
  final String phoneNumber;
  final String website;
  final double latitude;
  final double longitude;
  final double rating;
  final int reviewCount;
  final List<String> photos;
  final List<Review> reviews;
  final OpeningHours openingHours;
  final double distance;
  final bool isOpen;
  final bool isFavorite;
  final CafeTrackingStatus trackingStatus;
  final VisitData? visitData;
  final Map<String, String>? socialMedia;

  CoffeeShop({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.phoneNumber,
    required this.website,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.reviewCount,
    required this.photos,
    required this.reviews,
    required this.openingHours,
    this.distance = 0.0,
    this.isOpen = true,
    this.isFavorite = false,
    this.trackingStatus = CafeTrackingStatus.notTracked,
    this.visitData,
    this.socialMedia,
  });

  CoffeeShop copyWith({
    String? id,
    String? name,
    String? description,
    String? address,
    String? phoneNumber,
    String? website,
    double? latitude,
    double? longitude,
    double? rating,
    int? reviewCount,
    List<String>? photos,
    List<Review>? reviews,
    OpeningHours? openingHours,
    double? distance,
    bool? isOpen,
    bool? isFavorite,
    CafeTrackingStatus? trackingStatus,
    VisitData? visitData,
    Map<String, String>? socialMedia,
  }) {
    return CoffeeShop(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      photos: photos ?? this.photos,
      reviews: reviews ?? this.reviews,
      openingHours: openingHours ?? this.openingHours,
      distance: distance ?? this.distance,
      isOpen: isOpen ?? this.isOpen,
      isFavorite: isFavorite ?? this.isFavorite,
      trackingStatus: trackingStatus ?? this.trackingStatus,
      visitData: visitData ?? this.visitData,
      socialMedia: socialMedia ?? this.socialMedia,
    );
  }

  factory CoffeeShop.fromJson(Map<String, dynamic> json) {
    // Parse reviews
    List<Review> reviews = [];
    if (json['reviews'] != null) {
      reviews = (json['reviews'] as List).map((review) => Review(
        id: review['id']?.toString() ?? '',
        userName: review['userName'] ?? 'Anonymous',
        rating: (review['rating'] as num?)?.toDouble() ?? 0.0,
        comment: review['text'] ?? review['comment'] ?? '',
        date: review['time'] != null
            ? DateTime.fromMillisecondsSinceEpoch(review['time'])
            : DateTime.now(),
        photos: review['photos'] != null
            ? List<String>.from(review['photos'])
            : [],
      )).toList();
    }

    // Parse opening hours
    OpeningHours openingHours;
    if (json['opening_hours'] != null) {
      final weekdayText = json['opening_hours']['weekday_text'] as List? ?? [];
      openingHours = OpeningHours(
        monday: _extractDayHours(weekdayText, 0),
        tuesday: _extractDayHours(weekdayText, 1),
        wednesday: _extractDayHours(weekdayText, 2),
        thursday: _extractDayHours(weekdayText, 3),
        friday: _extractDayHours(weekdayText, 4),
        saturday: _extractDayHours(weekdayText, 5),
        sunday: _extractDayHours(weekdayText, 6),
      );
    } else {
      openingHours = OpeningHours(
        monday: '07:00 – 22:00',
        tuesday: '07:00 – 22:00',
        wednesday: '07:00 – 22:00',
        thursday: '07:00 – 22:00',
        friday: '07:00 – 22:00',
        saturday: '08:00 – 23:00',
        sunday: '08:00 – 23:00',
      );
    }

    // Parse photos
    List<String> photos = [];
    if (json['photos'] != null) {
      final apiKey = SimplePlacesService.apiKey ?? dotenv.env['GOOGLE_PLACES_API_KEY'];
      photos = (json['photos'] as List)
          .where((photo) => photo['photo_reference'] != null)
          .map((photo) {
            final photoUrl = 'https://maps.googleapis.com/maps/api/place/photo'
                '?maxwidth=800'
                '&maxheight=600'
                '&photoreference=${photo['photo_reference']}';
            if (apiKey != null && apiKey.isNotEmpty) {
              return '$photoUrl&key=$apiKey';
            }
            return photoUrl;
          })
          .cast<String>()
          .toList();
    }

    // Get location
    final geometry = json['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;

    return CoffeeShop(
      id: json['place_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Cafe',
      description: _getDescription(json),
      address: json['vicinity'] as String? ?? json['formatted_address'] as String? ?? '',
      phoneNumber: json['formatted_phone_number'] as String? ?? '',
      website: json['website'] as String? ?? '',
      latitude: location?['lat']?.toDouble() ?? (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: location?['lng']?.toDouble() ?? (json['longitude'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['user_ratings_total'] as int? ?? json['review_count'] as int? ?? 0,
      photos: photos,
      reviews: reviews,
      openingHours: openingHours,
      distance: 0.0,
      isOpen: json['opening_hours']?['open_now'] as bool? ?? true,
      isFavorite: false,
      trackingStatus: CafeTrackingStatus.notTracked,
      visitData: null,
      socialMedia: null,
    );
  }

  static String _getDescription(Map<String, dynamic> json) {
    final types = json['types'] as List? ?? [];
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

  static String _extractDayHours(List weekdayText, int dayIndex) {
    if (dayIndex < weekdayText.length) {
      final dayText = weekdayText[dayIndex].toString();
      final parts = dayText.split(':');
      if (parts.length > 1) {
        return parts.sublist(1).join(':').trim();
      }
    }
    return '09:00 – 21:00';
  }
}

class Review {
  final String id;
  final String userName;
  final double rating;
  final String comment;
  final DateTime date;
  final List<String> photos;

  Review({
    required this.id,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.date,
    required this.photos,
  });
}

class OpeningHours {
  final String monday;
  final String tuesday;
  final String wednesday;
  final String thursday;
  final String friday;
  final String saturday;
  final String sunday;

  OpeningHours({
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
    required this.sunday,
  });

  String getTodayHours() {
    final today = DateTime.now().weekday;
    switch (today) {
      case 1:
        return monday;
      case 2:
        return tuesday;
      case 3:
        return wednesday;
      case 4:
        return thursday;
      case 5:
        return friday;
      case 6:
        return saturday;
      case 7:
        return sunday;
      default:
        return monday;
    }
  }
}

enum CafeTrackingStatus {
  notTracked,
  wantToVisit,
  visited,
}

class VisitData {
  final double? personalRating;
  final String? privateReview;
  final List<DateTime> visitDates;
  final DateTime createdAt;
  final DateTime updatedAt;

  VisitData({
    this.personalRating,
    this.privateReview,
    List<DateTime>? visitDates,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : visitDates = visitDates ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  VisitData copyWith({
    double? personalRating,
    String? privateReview,
    List<DateTime>? visitDates,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VisitData(
      personalRating: personalRating ?? this.personalRating,
      privateReview: privateReview ?? this.privateReview,
      visitDates: visitDates ?? this.visitDates,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'personalRating': personalRating,
      'privateReview': privateReview,
      'visitDates': visitDates.map((date) => date.toIso8601String()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory VisitData.fromJson(Map<String, dynamic> json) {
    return VisitData(
      personalRating: _parseRating(json['personalRating']),
      privateReview: json['privateReview'],
      visitDates: (json['visitDates'] as List<dynamic>?)
          ?.map((date) => DateTime.parse(date.toString()))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  static double? _parseRating(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    // Handle string case (for JSON string values)
    if (value is String) {
      try {
        return double.tryParse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Safe rating extraction that skips problematic JSON parsing
  static double? extractRatingFromVisitData(Map<String, dynamic>? visitData) {
    if (visitData == null) return null;

    final rating = visitData!['personalRating'];
    if (rating == null) return null;
    if (rating is double) return rating;
    if (rating is int) return rating.toDouble();
    if (rating is num) return rating.toDouble();
    if (rating is String) {
      try {
        return double.tryParse(rating.toString());
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}