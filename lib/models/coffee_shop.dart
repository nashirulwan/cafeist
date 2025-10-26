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
      personalRating: json['personalRating']?.toDouble(),
      privateReview: json['privateReview'],
      visitDates: (json['visitDates'] as List<dynamic>?)
          ?.map((date) => DateTime.parse(date.toString()))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}