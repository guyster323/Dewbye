import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../models/weather_data.dart';
import '../services/weather_api.dart';
import '../services/kma_api.dart';
import '../services/cache_service.dart';
import '../utils/hvac_analytics.dart';
import '../utils/report_generator.dart';

class AnalysisResult {
  final DateTime date;
  final double outdoorTemp;
  final double outdoorHumidity;
  final double dewPoint;
  final double indoorTemp;
  final double indoorHumidity;
  final double riskScore;
  final RiskLevel riskLevel;
  final String recommendation;
  final List<HvacEvent> events;

  AnalysisResult({
    required this.date,
    required this.outdoorTemp,
    required this.outdoorHumidity,
    required this.dewPoint,
    required this.indoorTemp,
    required this.indoorHumidity,
    required this.riskScore,
    required this.riskLevel,
    required this.recommendation,
    this.events = const [],
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'outdoorTemp': outdoorTemp,
        'outdoorHumidity': outdoorHumidity,
        'dewPoint': dewPoint,
        'indoorTemp': indoorTemp,
        'indoorHumidity': indoorHumidity,
        'riskScore': riskScore,
        'riskLevel': riskLevel.name,
        'recommendation': recommendation,
      };

  factory AnalysisResult.fromJson(Map<String, dynamic> json) => AnalysisResult(
        date: DateTime.parse(json['date'] as String),
        outdoorTemp: (json['outdoorTemp'] as num).toDouble(),
        outdoorHumidity: (json['outdoorHumidity'] as num).toDouble(),
        dewPoint: (json['dewPoint'] as num).toDouble(),
        indoorTemp: (json['indoorTemp'] as num).toDouble(),
        indoorHumidity: (json['indoorHumidity'] as num).toDouble(),
        riskScore: (json['riskScore'] as num).toDouble(),
        riskLevel: RiskLevel.values.firstWhere(
          (e) => e.name == json['riskLevel'],
          orElse: () => RiskLevel.safe,
        ),
        recommendation: json['recommendation'] as String,
      );
}

class HvacEvent {
  final DateTime startTime;
  final DateTime? endTime;
  final HvacMode mode;
  final String description;
  final double riskBefore;
  final double? riskAfter;

  HvacEvent({
    required this.startTime,
    this.endTime,
    required this.mode,
    required this.description,
    required this.riskBefore,
    this.riskAfter,
  });
}

class AnalysisProvider extends ChangeNotifier {
  final WeatherApiService _weatherApi;
  final KmaApiService _kmaApi;
  final CacheService _cacheService;

  BuildingType _buildingType = BuildingType.standard;
  double _indoorTemp = AppConstants.defaultIndoorTemp;
  double _indoorHumidity = AppConstants.defaultIndoorHumidity;
  List<AnalysisResult> _results = [];
  List<WeatherData> _weatherData = [];
  bool _isLoading = false;
  String? _error;

  AnalysisProvider({
    WeatherApiService? weatherApi,
    KmaApiService? kmaApi,
    CacheService? cacheService,
  })  : _weatherApi = weatherApi ?? WeatherApiService(),
        _kmaApi = kmaApi ?? KmaApiService(),
        _cacheService = cacheService ?? CacheService();

  BuildingType get buildingType => _buildingType;
  double get indoorTemp => _indoorTemp;
  double get indoorHumidity => _indoorHumidity;
  List<AnalysisResult> get results => _results;
  List<WeatherData> get weatherData => _weatherData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 현재 위험도 (최신 결과 기준)
  double get currentRiskScore => _results.isNotEmpty ? _results.first.riskScore : 0;
  RiskLevel get currentRiskLevel =>
      _results.isNotEmpty ? _results.first.riskLevel : RiskLevel.safe;

  void setBuildingType(BuildingType type) {
    _buildingType = type;
    notifyListeners();
  }

  void setIndoorConditions({double? temp, double? humidity}) {
    if (temp != null) _indoorTemp = temp;
    if (humidity != null) _indoorHumidity = humidity;
    notifyListeners();
  }

  // 이슬점 계산 (Magnus 공식)
  double calculateDewPoint(double temp, double humidity) {
    const double a = 17.27;
    const double b = 237.7;

    final clampedHumidity = humidity.clamp(0.01, 100.0);
    final double gamma = (a * temp) / (b + temp) + _ln(clampedHumidity / 100.0);
    final double dewPoint = (b * gamma) / (a - gamma);

    return dewPoint;
  }

  // 자연로그 계산
  double _ln(double x) {
    if (x <= 0) return double.negativeInfinity;
    int n = 0;
    while (x >= 2) {
      x /= 2.718281828459045;
      n++;
    }
    while (x < 0.5) {
      x *= 2.718281828459045;
      n--;
    }
    x -= 1;
    double result = 0;
    double term = x;
    for (int i = 1; i <= 100; i++) {
      result += term / i;
      term *= -x;
    }
    return result + n;
  }

  // 절대습도 계산 (g/m³)
  double calculateAbsoluteHumidity(double temp, double relativeHumidity) {
    // 포화증기압 (hPa) - Tetens 공식
    final double es = 6.112 * _exp((17.67 * temp) / (temp + 243.5));
    // 실제 증기압
    final double e = es * (relativeHumidity / 100);
    // 절대습도 (g/m³)
    return (216.7 * e) / (temp + 273.15);
  }

  double _exp(double x) {
    double result = 1.0;
    double term = 1.0;
    for (int i = 1; i <= 20; i++) {
      term *= x / i;
      result += term;
    }
    return result;
  }

  // 위험도 계산
  double calculateRiskScore({
    required double outdoorTemp,
    required double outdoorHumidity,
    required double indoorTemp,
    required double indoorHumidity,
  }) {
    final dewPoint = calculateDewPoint(outdoorTemp, outdoorHumidity);
    final margin = indoorTemp - dewPoint;

    // 기본 위험도 (이슬점 마진 기반)
    double riskScore = 0;

    if (margin <= 0) {
      riskScore = 100; // 결로 발생
    } else if (margin <= AppConstants.criticalDewPointMargin) {
      riskScore = 90 - (margin / AppConstants.criticalDewPointMargin) * 15;
    } else if (margin <= AppConstants.warningDewPointMargin) {
      riskScore = 75 -
          ((margin - AppConstants.criticalDewPointMargin) /
                  (AppConstants.warningDewPointMargin -
                      AppConstants.criticalDewPointMargin)) *
              50;
    } else {
      riskScore = 25 * (1 - (margin - AppConstants.warningDewPointMargin) / 10);
    }

    // 건물 기밀도 보정
    final airtightnessBonus = _buildingType.airtightness * 10;
    riskScore = (riskScore - airtightnessBonus).clamp(0.0, 100.0);

    return riskScore;
  }

  // 권장 조치 생성
  String getRecommendation(double riskScore, double dewPoint, double indoorTemp) {
    if (riskScore >= 75) {
      return '즉시 환기 또는 제습이 필요합니다. 창문 주변 결로 발생 가능성이 매우 높습니다.';
    } else if (riskScore >= 50) {
      return '실내 습도 관리가 필요합니다. 제습기 가동 또는 간헐적 환기를 권장합니다.';
    } else if (riskScore >= 25) {
      return '현재 상태 유지. 습도 변화를 모니터링하세요.';
    } else {
      return '결로 위험이 낮습니다. 정상 상태입니다.';
    }
  }

  /// 예보 기반 분석 (Open-Meteo API)
  Future<void> analyzeForecast({
    required double latitude,
    required double longitude,
    int forecastDays = 7,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 캐시 확인
      final cacheKey = _cacheService.getLocationCacheKey(latitude, longitude);
      final cacheValid = await _cacheService.isWeatherCacheValid(cacheKey);

      WeatherForecast? forecast;

      if (cacheValid) {
        forecast = await _cacheService.getCachedWeatherForecast(cacheKey);
      }

      if (forecast == null || forecast.isExpired) {
        // API 호출
        forecast = await _weatherApi.getForecastWeather(
          latitude: latitude,
          longitude: longitude,
          forecastDays: forecastDays,
          pastDays: 1,
        );

        // 캐시 저장
        await _cacheService.cacheWeatherForecast(cacheKey, forecast);
      }

      _weatherData = forecast.hourlyData;
      _results = _analyzeWeatherData(forecast.hourlyData);
    } on WeatherApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = '분석 중 오류가 발생했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 과거 데이터 분석 (Archive API)
  Future<void> analyzeHistorical({
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final forecast = await _weatherApi.getHistoricalWeather(
        latitude: latitude,
        longitude: longitude,
        startDate: startDate,
        endDate: endDate,
      );

      _weatherData = forecast.hourlyData;
      _results = _analyzeWeatherData(forecast.hourlyData);
    } on WeatherApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = '분석 중 오류가 발생했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 기상청 API 분석 (한국 전용, 더 높은 정확도)
  Future<void> analyzeWithKma({
    required int nx,
    required int ny,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final kmaData = await _kmaApi.getShortForecast(nx: nx, ny: ny);

      if (kmaData.isEmpty) {
        throw KmaApiException('기상 데이터를 가져올 수 없습니다');
      }

      // KMA 데이터를 WeatherData로 변환
      _weatherData = kmaData.map((k) => k.toWeatherData()).toList();
      _results = _analyzeWeatherData(_weatherData);
    } on KmaApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = '기상청 API 분석 중 오류: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 날씨 데이터 분석
  List<AnalysisResult> _analyzeWeatherData(List<WeatherData> data) {
    final results = <AnalysisResult>[];

    for (final weather in data) {
      final riskScore = calculateRiskScore(
        outdoorTemp: weather.temperature,
        outdoorHumidity: weather.humidity,
        indoorTemp: _indoorTemp,
        indoorHumidity: _indoorHumidity,
      );

      results.add(AnalysisResult(
        date: weather.time,
        outdoorTemp: weather.temperature,
        outdoorHumidity: weather.humidity,
        dewPoint: weather.dewPoint,
        indoorTemp: _indoorTemp,
        indoorHumidity: _indoorHumidity,
        riskScore: riskScore,
        riskLevel: RiskLevel.fromScore(riskScore),
        recommendation: getRecommendation(riskScore, weather.dewPoint, _indoorTemp),
      ));
    }

    // 최신순 정렬
    results.sort((a, b) => b.date.compareTo(a.date));
    return results;
  }

  /// 일별 요약 생성
  Map<DateTime, DailySummary> getDailySummary() {
    final Map<DateTime, List<AnalysisResult>> grouped = {};

    for (final result in _results) {
      final date = DateTime(result.date.year, result.date.month, result.date.day);
      grouped.putIfAbsent(date, () => []).add(result);
    }

    final Map<DateTime, DailySummary> summary = {};

    for (final entry in grouped.entries) {
      final dayResults = entry.value;
      final maxRisk = dayResults.map((r) => r.riskScore).reduce((a, b) => a > b ? a : b);
      final minRisk = dayResults.map((r) => r.riskScore).reduce((a, b) => a < b ? a : b);
      final avgRisk = dayResults.map((r) => r.riskScore).reduce((a, b) => a + b) / dayResults.length;
      final highRiskHours = dayResults.where((r) => r.riskScore >= 50).length;

      summary[entry.key] = DailySummary(
        date: entry.key,
        maxRiskScore: maxRisk,
        minRiskScore: minRisk,
        avgRiskScore: avgRisk,
        highRiskHours: highRiskHours,
        maxRiskLevel: RiskLevel.fromScore(maxRisk),
      );
    }

    return summary;
  }

  void clearResults() {
    _results.clear();
    _weatherData.clear();
    _error = null;
    notifyListeners();
  }

  // ============ Phase 4: 고급 분석 기능 ============

  /// 취약 시간대 감지
  List<VulnerableTimeSlot> getVulnerableTimeSlots() {
    if (_weatherData.isEmpty) return [];
    return HVACModeDetector.detectVulnerableTimeSlots(_weatherData, _buildingType);
  }

  /// HVAC 모드 전환 이벤트 감지
  List<ModeTransitionEvent> getModeTransitions({double setpoint = 22.0}) {
    if (_weatherData.isEmpty) return [];
    return HVACModeDetector.detectModeTransitions(_weatherData, setpoint);
  }

  /// 습도 예측 (시간별)
  List<HumidityPrediction> getHumidityPredictions() {
    if (_weatherData.isEmpty) return [];
    return BuildingHumidityResponse.predictHumidityOverTime(
      _indoorHumidity,
      _weatherData,
      _buildingType,
    );
  }

  /// 결로 발생 예측
  CondensationPrediction? getCondensationPrediction() {
    if (_weatherData.isEmpty) return null;
    return CondensationPredictor.predictCondensationTime(
      _weatherData,
      _indoorTemp,
      _indoorHumidity,
      _buildingType,
    );
  }

  /// 일별 리포트 생성
  List<DailyReport> generateDailyReports() {
    if (_weatherData.isEmpty || _results.isEmpty) return [];
    return ReportGenerator.generateDailyReportsFromAnalysis(
      _weatherData,
      _results,
      _buildingType,
    );
  }

  /// 주별 리포트 생성
  WeeklyReport? generateWeeklyReport() {
    final dailyReports = generateDailyReports();
    if (dailyReports.isEmpty) return null;
    return ReportGenerator.generateWeeklyReport(dailyReports);
  }

  /// 외기 조건 평가
  OutdoorConditionAssessment? getCurrentOutdoorAssessment() {
    if (_weatherData.isEmpty) return null;
    final latest = _weatherData.first;
    return OutdoorEnvironmentAnalyzer.assessOutdoorCondition(
      latest.temperature,
      latest.humidity,
    );
  }

  /// HVAC 성능 페널티 계산
  double getCurrentPerformancePenalty() {
    if (_weatherData.isEmpty) return 1.0;
    final latest = _weatherData.first;
    return OutdoorEnvironmentAnalyzer.performancePenalty(
      latest.temperature,
      latest.humidity,
    );
  }
}

/// 일별 요약
class DailySummary {
  final DateTime date;
  final double maxRiskScore;
  final double minRiskScore;
  final double avgRiskScore;
  final int highRiskHours;
  final RiskLevel maxRiskLevel;

  DailySummary({
    required this.date,
    required this.maxRiskScore,
    required this.minRiskScore,
    required this.avgRiskScore,
    required this.highRiskHours,
    required this.maxRiskLevel,
  });
}
