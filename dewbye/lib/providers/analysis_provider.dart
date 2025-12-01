import 'package:flutter/material.dart';
import '../config/constants.dart';

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
  BuildingType _buildingType = BuildingType.standard;
  double _indoorTemp = AppConstants.defaultIndoorTemp;
  double _indoorHumidity = AppConstants.defaultIndoorHumidity;
  List<AnalysisResult> _results = [];
  bool _isLoading = false;
  String? _error;

  BuildingType get buildingType => _buildingType;
  double get indoorTemp => _indoorTemp;
  double get indoorHumidity => _indoorHumidity;
  List<AnalysisResult> get results => _results;
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

    final double gamma = (a * temp) / (b + temp) + (humidity / 100).clamp(0.01, 1.0);
    final double dewPoint = (b * gamma) / (a - gamma);

    return dewPoint;
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
    // 간단한 지수 함수 근사
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
    riskScore = (riskScore - airtightnessBonus).clamp(0, 100);

    return riskScore;
  }

  // 권장 조치 생성
  String getRecommendation(double riskScore, double dewPoint, double indoorTemp) {
    // margin 값은 향후 더 상세한 권장 조치에 활용 예정
    // final margin = indoorTemp - dewPoint;

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

  Future<void> analyze({
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: 실제 API 호출 구현 (Phase 3에서)
      // 현재는 샘플 데이터로 테스트

      _results = _generateSampleResults(startDate, endDate);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<AnalysisResult> _generateSampleResults(DateTime start, DateTime end) {
    final results = <AnalysisResult>[];
    var current = start;

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      // 샘플 데이터 생성
      final outdoorTemp = 15.0 + (current.hour - 12).abs() * 0.5;
      final outdoorHumidity = 60.0 + (current.hour % 12) * 2.0;
      final dewPoint = calculateDewPoint(outdoorTemp, outdoorHumidity);
      final riskScore = calculateRiskScore(
        outdoorTemp: outdoorTemp,
        outdoorHumidity: outdoorHumidity,
        indoorTemp: _indoorTemp,
        indoorHumidity: _indoorHumidity,
      );

      results.add(AnalysisResult(
        date: current,
        outdoorTemp: outdoorTemp,
        outdoorHumidity: outdoorHumidity,
        dewPoint: dewPoint,
        indoorTemp: _indoorTemp,
        indoorHumidity: _indoorHumidity,
        riskScore: riskScore,
        riskLevel: RiskLevel.fromScore(riskScore),
        recommendation: getRecommendation(riskScore, dewPoint, _indoorTemp),
      ));

      current = current.add(const Duration(hours: 1));
    }

    return results;
  }

  void clearResults() {
    _results.clear();
    _error = null;
    notifyListeners();
  }
}
