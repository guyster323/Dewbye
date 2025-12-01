class WeatherData {
  final DateTime time;
  final double temperature;
  final double humidity;
  final double dewPoint;
  final double? precipitation;
  final double? windSpeed;
  final double? pressure;
  final int? weatherCode;

  WeatherData({
    required this.time,
    required this.temperature,
    required this.humidity,
    required this.dewPoint,
    this.precipitation,
    this.windSpeed,
    this.pressure,
    this.weatherCode,
  });

  factory WeatherData.fromOpenMeteo(Map<String, dynamic> hourlyData, int index) {
    final time = DateTime.parse(hourlyData['time'][index] as String);
    final temperature = (hourlyData['temperature_2m'][index] as num).toDouble();
    final humidity = (hourlyData['relative_humidity_2m'][index] as num).toDouble();
    final dewPoint = (hourlyData['dew_point_2m'][index] as num).toDouble();

    return WeatherData(
      time: time,
      temperature: temperature,
      humidity: humidity,
      dewPoint: dewPoint,
      precipitation: hourlyData['precipitation']?[index]?.toDouble(),
      windSpeed: hourlyData['wind_speed_10m']?[index]?.toDouble(),
      pressure: hourlyData['surface_pressure']?[index]?.toDouble(),
      weatherCode: hourlyData['weather_code']?[index] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'temperature': temperature,
        'humidity': humidity,
        'dewPoint': dewPoint,
        'precipitation': precipitation,
        'windSpeed': windSpeed,
        'pressure': pressure,
        'weatherCode': weatherCode,
      };

  factory WeatherData.fromJson(Map<String, dynamic> json) => WeatherData(
        time: DateTime.parse(json['time'] as String),
        temperature: (json['temperature'] as num).toDouble(),
        humidity: (json['humidity'] as num).toDouble(),
        dewPoint: (json['dewPoint'] as num).toDouble(),
        precipitation: (json['precipitation'] as num?)?.toDouble(),
        windSpeed: (json['windSpeed'] as num?)?.toDouble(),
        pressure: (json['pressure'] as num?)?.toDouble(),
        weatherCode: json['weatherCode'] as int?,
      );

  String get weatherDescription {
    if (weatherCode == null) return '알 수 없음';

    switch (weatherCode) {
      case 0:
        return '맑음';
      case 1:
      case 2:
      case 3:
        return '구름 조금';
      case 45:
      case 48:
        return '안개';
      case 51:
      case 53:
      case 55:
        return '이슬비';
      case 61:
      case 63:
      case 65:
        return '비';
      case 71:
      case 73:
      case 75:
        return '눈';
      case 80:
      case 81:
      case 82:
        return '소나기';
      case 95:
        return '천둥번개';
      default:
        return '기타';
    }
  }
}

class WeatherForecast {
  final double latitude;
  final double longitude;
  final String? timezone;
  final List<WeatherData> hourlyData;
  final DateTime fetchedAt;

  WeatherForecast({
    required this.latitude,
    required this.longitude,
    this.timezone,
    required this.hourlyData,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  factory WeatherForecast.fromOpenMeteoResponse(Map<String, dynamic> json) {
    final hourly = json['hourly'] as Map<String, dynamic>;
    final times = hourly['time'] as List;
    final hourlyData = <WeatherData>[];

    for (int i = 0; i < times.length; i++) {
      hourlyData.add(WeatherData.fromOpenMeteo(hourly, i));
    }

    return WeatherForecast(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timezone: json['timezone'] as String?,
      hourlyData: hourlyData,
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'timezone': timezone,
        'hourlyData': hourlyData.map((d) => d.toJson()).toList(),
        'fetchedAt': fetchedAt.toIso8601String(),
      };

  factory WeatherForecast.fromJson(Map<String, dynamic> json) => WeatherForecast(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        timezone: json['timezone'] as String?,
        hourlyData: (json['hourlyData'] as List)
            .map((d) => WeatherData.fromJson(d as Map<String, dynamic>))
            .toList(),
        fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      );

  // 특정 시간대의 데이터 가져오기
  WeatherData? getDataAt(DateTime time) {
    try {
      return hourlyData.firstWhere(
        (d) =>
            d.time.year == time.year &&
            d.time.month == time.month &&
            d.time.day == time.day &&
            d.time.hour == time.hour,
      );
    } catch (e) {
      return null;
    }
  }

  // 특정 기간의 데이터 가져오기
  List<WeatherData> getDataRange(DateTime start, DateTime end) {
    return hourlyData.where((d) => d.time.isAfter(start) && d.time.isBefore(end)).toList();
  }

  // 캐시 유효성 검사 (1시간)
  bool get isExpired {
    return DateTime.now().difference(fetchedAt).inHours >= 1;
  }
}

class DailyWeatherSummary {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final double avgHumidity;
  final double avgDewPoint;
  final double maxRiskScore;
  final int highRiskHours;

  DailyWeatherSummary({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.avgHumidity,
    required this.avgDewPoint,
    required this.maxRiskScore,
    required this.highRiskHours,
  });

  factory DailyWeatherSummary.fromHourlyData(DateTime date, List<WeatherData> hourlyData) {
    if (hourlyData.isEmpty) {
      return DailyWeatherSummary(
        date: date,
        maxTemp: 0,
        minTemp: 0,
        avgHumidity: 0,
        avgDewPoint: 0,
        maxRiskScore: 0,
        highRiskHours: 0,
      );
    }

    final temps = hourlyData.map((d) => d.temperature).toList();
    final humidities = hourlyData.map((d) => d.humidity).toList();
    final dewPoints = hourlyData.map((d) => d.dewPoint).toList();

    return DailyWeatherSummary(
      date: date,
      maxTemp: temps.reduce((a, b) => a > b ? a : b),
      minTemp: temps.reduce((a, b) => a < b ? a : b),
      avgHumidity: humidities.reduce((a, b) => a + b) / humidities.length,
      avgDewPoint: dewPoints.reduce((a, b) => a + b) / dewPoints.length,
      maxRiskScore: 0, // 분석 엔진에서 계산
      highRiskHours: 0, // 분석 엔진에서 계산
    );
  }
}
