class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final String authProvider; // 'google', 'email', etc.
  final String? bio;
  final String? location;
  final Map<String, dynamic>? preferences;
  final bool notificationsEnabled;
  final String? defaultRegion;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    required this.isEmailVerified,
    required this.createdAt,
    required this.lastLoginAt,
    required this.authProvider,
    this.bio,
    this.location,
    this.preferences,
    this.notificationsEnabled = true,
    this.defaultRegion,
  });

  // Factory constructor from Firestore data
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      photoURL: json['photoURL'] as String?,
      isEmailVerified: json['isEmailVerified'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: DateTime.parse(json['lastLoginAt'] as String),
      authProvider: json['authProvider'] as String,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      preferences: json['preferences'] as Map<String, dynamic>?,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      defaultRegion: json['defaultRegion'] as String?,
    );
  }

  // Convert to Firestore JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'authProvider': authProvider,
      'bio': bio,
      'location': location,
      'preferences': preferences,
      'notificationsEnabled': notificationsEnabled,
      'defaultRegion': defaultRegion,
    };
  }

  // Copy with modifications
  UserProfile copyWith({
    String? displayName,
    String? photoURL,
    String? bio,
    String? location,
    Map<String, dynamic>? preferences,
    bool? notificationsEnabled,
    String? defaultRegion,
    DateTime? lastLoginAt,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      isEmailVerified: isEmailVerified,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      authProvider: authProvider,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      preferences: preferences ?? this.preferences,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      defaultRegion: defaultRegion ?? this.defaultRegion,
    );
  }

  @override
  String toString() {
    return 'UserProfile{uid: $uid, email: $email, displayName: $displayName}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}

// User preferences structure
class UserPreferences {
  final String theme; // 'light', 'dark', 'system'
  final String language; // 'en', 'id', etc.
  final bool pushNotifications;
  final bool emailNotifications;
  final bool locationServices;
  final double searchRadius; // in km
  final String discoveryRadius; // 'region', 'city', 'national'

  UserPreferences({
    this.theme = 'system',
    this.language = 'id',
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.locationServices = true,
    this.searchRadius = 10.0,
    this.discoveryRadius = 'region',
  });

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'language': language,
      'pushNotifications': pushNotifications,
      'emailNotifications': emailNotifications,
      'locationServices': locationServices,
      'searchRadius': searchRadius,
      'discoveryRadius': discoveryRadius,
    };
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      theme: json['theme'] as String? ?? 'system',
      language: json['language'] as String? ?? 'id',
      pushNotifications: json['pushNotifications'] as bool? ?? true,
      emailNotifications: json['emailNotifications'] as bool? ?? true,
      locationServices: json['locationServices'] as bool? ?? true,
      searchRadius: (json['searchRadius'] as num?)?.toDouble() ?? 10.0,
      discoveryRadius: json['discoveryRadius'] as String? ?? 'region',
    );
  }

  UserPreferences copyWith({
    String? theme,
    String? language,
    bool? pushNotifications,
    bool? emailNotifications,
    bool? locationServices,
    double? searchRadius,
    String? discoveryRadius,
  }) {
    return UserPreferences(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      locationServices: locationServices ?? this.locationServices,
      searchRadius: searchRadius ?? this.searchRadius,
      discoveryRadius: discoveryRadius ?? this.discoveryRadius,
    );
  }
}