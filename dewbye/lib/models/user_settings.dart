enum BuildingType {
  residential('주거용'),
  commercial('상업용'),
  industrial('산업용'),
  warehouse('창고'),
  office('사무실');

  final String label;
  const BuildingType(this.label);
}

class UserSettings {
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final BuildingType buildingType;
  final double indoorTemperature;
  final double indoorHumidity;

  UserSettings({
    this.latitude,
    this.longitude,
    this.locationName,
    required this.buildingType,
    required this.indoorTemperature,
    required this.indoorHumidity,
  });

  UserSettings copyWith({
    double? latitude,
    double? longitude,
    String? locationName,
    BuildingType? buildingType,
    double? indoorTemperature,
    double? indoorHumidity,
  }) {
    return UserSettings(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      buildingType: buildingType ?? this.buildingType,
      indoorTemperature: indoorTemperature ?? this.indoorTemperature,
      indoorHumidity: indoorHumidity ?? this.indoorHumidity,
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'locationName': locationName,
        'buildingType': buildingType.name,
        'indoorTemperature': indoorTemperature,
        'indoorHumidity': indoorHumidity,
      };

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
        latitude: json['latitude'] as double?,
        longitude: json['longitude'] as double?,
        locationName: json['locationName'] as String?,
        buildingType: BuildingType.values.firstWhere(
          (e) => e.name == json['buildingType'],
          orElse: () => BuildingType.residential,
        ),
        indoorTemperature: (json['indoorTemperature'] as num).toDouble(),
        indoorHumidity: (json['indoorHumidity'] as num).toDouble(),
      );

  static UserSettings get defaultSettings => UserSettings(
        buildingType: BuildingType.residential,
        indoorTemperature: 22.0,
        indoorHumidity: 50.0,
      );
}


