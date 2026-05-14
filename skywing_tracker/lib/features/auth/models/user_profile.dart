class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final String? clubName;
  final String? breederLocation;
  final String? avatarUrl;
  final double? loftLatitude;
  final double? loftLongitude;
  final bool useKilometers;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.clubName,
    this.breederLocation,
    this.avatarUrl,
    this.loftLatitude,
    this.loftLongitude,
    this.useKilometers = true,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String,
      clubName: json['club_name'] as String?,
      breederLocation: json['breeder_location'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      loftLatitude: (json['loft_latitude'] as num?)?.toDouble(),
      loftLongitude: (json['loft_longitude'] as num?)?.toDouble(),
      useKilometers: json['use_kilometers'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'club_name': clubName,
      'breeder_location': breederLocation,
      'avatar_url': avatarUrl,
      'loft_latitude': loftLatitude,
      'loft_longitude': loftLongitude,
      'use_kilometers': useKilometers,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? clubName,
    String? breederLocation,
    String? avatarUrl,
    double? loftLatitude,
    double? loftLongitude,
    bool? useKilometers,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      clubName: clubName ?? this.clubName,
      breederLocation: breederLocation ?? this.breederLocation,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      loftLatitude: loftLatitude ?? this.loftLatitude,
      loftLongitude: loftLongitude ?? this.loftLongitude,
      useKilometers: useKilometers ?? this.useKilometers,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
