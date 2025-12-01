class AppConstants {
  // 앱 정보
  static const String appName = 'Dewbye';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Weather-HVAC Analytics';

  // API 엔드포인트
  static const String openMeteoArchiveUrl =
      'https://archive-api.open-meteo.com/v1/archive';
  static const String openMeteoGeocodingUrl =
      'https://geocoding-api.open-meteo.com/v1/search';
  static const String kmaApiUrl = 'https://apis.data.go.kr/1360000';

  // 기본 설정값
  static const int defaultForecastDays = 7;
  static const int defaultHistoryDays = 30;
  static const double defaultLatitude = 37.5665; // 서울
  static const double defaultLongitude = 126.9780;

  // 분석 설정
  static const double criticalDewPointMargin = 2.0; // °C
  static const double warningDewPointMargin = 5.0; // °C
  static const double defaultIndoorTemp = 22.0; // °C
  static const double defaultIndoorHumidity = 50.0; // %

  // 건물 기밀도 타입
  static const Map<String, double> buildingAirtightness = {
    'old_house': 0.3, // 구형 주택 (취약)
    'standard': 0.5, // 일반 건물
    'modern': 0.7, // 현대식 건물
    'passive': 0.9, // 패시브하우스
  };

  // HVAC 운전 모드
  static const List<String> hvacModes = [
    'off',
    'cooling',
    'heating',
    'dehumidify',
    'ventilation',
    'auto',
  ];

  // 위험도 임계값
  static const double riskThresholdLow = 25.0;
  static const double riskThresholdMedium = 50.0;
  static const double riskThresholdHigh = 75.0;

  // 캐시 설정
  static const Duration cacheExpiry = Duration(hours: 1);
  static const String weatherCacheKey = 'weather_cache';
  static const String locationCacheKey = 'location_cache';

  // 애니메이션 설정
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration slideshowInterval = Duration(seconds: 5);

  // UI 설정
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const double glassOpacity = 0.2;
  static const double glassBlur = 10.0;
}

// 건물 타입 enum
enum BuildingType {
  oldHouse('old_house', '구형 주택', 0.3),
  standard('standard', '일반 건물', 0.5),
  modern('modern', '현대식 건물', 0.7),
  passive('passive', '패시브하우스', 0.9);

  final String key;
  final String label;
  final double airtightness;

  const BuildingType(this.key, this.label, this.airtightness);
}

// HVAC 모드 enum
enum HvacMode {
  off('off', '꺼짐'),
  cooling('cooling', '냉방'),
  heating('heating', '난방'),
  dehumidify('dehumidify', '제습'),
  ventilation('ventilation', '환기'),
  auto('auto', '자동');

  final String key;
  final String label;

  const HvacMode(this.key, this.label);
}

// 위험도 레벨 enum
enum RiskLevel {
  safe('safe', '안전', 0, 25),
  caution('caution', '주의', 25, 50),
  warning('warning', '경고', 50, 75),
  danger('danger', '위험', 75, 100);

  final String key;
  final String label;
  final double minScore;
  final double maxScore;

  const RiskLevel(this.key, this.label, this.minScore, this.maxScore);

  static RiskLevel fromScore(double score) {
    if (score < 25) return RiskLevel.safe;
    if (score < 50) return RiskLevel.caution;
    if (score < 75) return RiskLevel.warning;
    return RiskLevel.danger;
  }
}
