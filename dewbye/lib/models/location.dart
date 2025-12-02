class GeoLocation {
  final double latitude;
  final double longitude;
  final String? name;
  final String? country;
  final String? admin1; // 시/도
  final String? admin2; // 구/군
  final String? timezone;
  final int? population;
  final double? elevation;

  GeoLocation({
    required this.latitude,
    required this.longitude,
    this.name,
    this.country,
    this.admin1,
    this.admin2,
    this.timezone,
    this.population,
    this.elevation,
  });

  factory GeoLocation.fromOpenMeteoGeocoding(Map<String, dynamic> json) {
    return GeoLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      name: json['name'] as String?,
      country: json['country'] as String?,
      admin1: json['admin1'] as String?,
      admin2: json['admin2'] as String?,
      timezone: json['timezone'] as String?,
      population: json['population'] as int?,
      elevation: (json['elevation'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'name': name,
        'country': country,
        'admin1': admin1,
        'admin2': admin2,
        'timezone': timezone,
        'population': population,
        'elevation': elevation,
      };

  factory GeoLocation.fromJson(Map<String, dynamic> json) => GeoLocation(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        name: json['name'] as String?,
        country: json['country'] as String?,
        admin1: json['admin1'] as String?,
        admin2: json['admin2'] as String?,
        timezone: json['timezone'] as String?,
        population: json['population'] as int?,
        elevation: (json['elevation'] as num?)?.toDouble(),
      );

  String get displayName {
    if (name == null) return '$latitude, $longitude';

    final parts = <String>[name!];
    if (admin2 != null) parts.add(admin2!);
    if (admin1 != null) parts.add(admin1!);
    if (country != null && country != 'South Korea' && country != '대한민국') {
      parts.add(country!);
    }

    return parts.join(', ');
  }

  String get shortName => name ?? '$latitude, $longitude';

  String get fullAddress {
    final parts = <String>[];
    if (country != null) parts.add(country!);
    if (admin1 != null) parts.add(admin1!);
    if (admin2 != null) parts.add(admin2!);
    if (name != null) parts.add(name!);
    return parts.join(' ');
  }
  
  /// English display name for PDF reports
  String get englishDisplayName {
    final parts = <String>[];
    if (name != null) parts.add(name!);
    if (admin2 != null) parts.add(admin2!);
    if (admin1 != null) parts.add(admin1!);
    if (country != null) {
      final englishCountry = switch (country) {
        '대한민국' || 'South Korea' || 'Korea' => 'South Korea',
        '일본' => 'Japan',
        '중국' => 'China',
        '미국' => 'USA',
        _ => country,
      };
      parts.add(englishCountry!);
    }
    if (parts.isEmpty) {
      return 'Lat: ${latitude.toStringAsFixed(4)}, Lon: ${longitude.toStringAsFixed(4)}';
    }
    return parts.join(', ');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GeoLocation &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;

  @override
  String toString() => displayName;
}

class GeocodingResult {
  final List<GeoLocation> results;
  final String? generationTimeMs;

  GeocodingResult({
    required this.results,
    this.generationTimeMs,
  });

  factory GeocodingResult.fromOpenMeteoResponse(Map<String, dynamic> json) {
    final results = (json['results'] as List?)
            ?.map((r) => GeoLocation.fromOpenMeteoGeocoding(r as Map<String, dynamic>))
            .toList() ??
        [];

    return GeocodingResult(
      results: results,
      generationTimeMs: json['generationtime_ms']?.toString(),
    );
  }

  bool get isEmpty => results.isEmpty;
  bool get isNotEmpty => results.isNotEmpty;
}

class SavedLocation {
  final GeoLocation location;
  final DateTime savedAt;
  final bool isFavorite;
  final String? alias;

  SavedLocation({
    required this.location,
    DateTime? savedAt,
    this.isFavorite = false,
    this.alias,
  }) : savedAt = savedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'location': location.toJson(),
        'savedAt': savedAt.toIso8601String(),
        'isFavorite': isFavorite,
        'alias': alias,
      };

  factory SavedLocation.fromJson(Map<String, dynamic> json) => SavedLocation(
        location: GeoLocation.fromJson(json['location'] as Map<String, dynamic>),
        savedAt: DateTime.parse(json['savedAt'] as String),
        isFavorite: json['isFavorite'] as bool? ?? false,
        alias: json['alias'] as String?,
      );

  String get displayName => alias ?? location.displayName;

  SavedLocation copyWith({
    GeoLocation? location,
    DateTime? savedAt,
    bool? isFavorite,
    String? alias,
  }) {
    return SavedLocation(
      location: location ?? this.location,
      savedAt: savedAt ?? this.savedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      alias: alias ?? this.alias,
    );
  }
}
