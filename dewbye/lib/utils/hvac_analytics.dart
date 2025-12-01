import 'dart:math' as math;
import '../config/constants.dart';
import '../models/weather_data.dart';

/// HVAC 분석 유틸리티 클래스
class HVACAnalytics {
  /// 포화증기압 계산 (Tetens 공식)
  /// [temp] 온도 (°C)
  /// 반환값: 포화증기압 (hPa)
  static double saturationVaporPressure(double temp) {
    return 6.112 * math.exp((17.67 * temp) / (temp + 243.5));
  }

  /// 절대습도 계산
  /// [temp] 온도 (°C)
  /// [relativeHumidity] 상대습도 (%)
  /// 반환값: 절대습도 (g/m³)
  static double absoluteHumidity(double temp, double relativeHumidity) {
    final es = saturationVaporPressure(temp);
    final e = es * (relativeHumidity / 100);
    return (216.7 * e) / (temp + 273.15);
  }

  /// 이슬점 계산 (Magnus 공식)
  /// [temp] 온도 (°C)
  /// [relativeHumidity] 상대습도 (%)
  /// 반환값: 이슬점 (°C)
  static double dewPoint(double temp, double relativeHumidity) {
    const double a = 17.27;
    const double b = 237.7;

    final clampedRH = relativeHumidity.clamp(0.01, 100.0);
    final gamma = (a * temp / (b + temp)) + math.log(clampedRH / 100.0);
    return (b * gamma) / (a - gamma);
  }

  /// 습구온도 계산 (Stull 근사식)
  /// 정확도: ±1°C
  /// [dryBulb] 건구온도 (°C)
  /// [humidity] 상대습도 (%)
  static double wetBulbTemperature(double dryBulb, double humidity) {
    final tw = dryBulb * math.atan(0.151977 * math.sqrt(humidity + 8.313659)) +
        math.atan(dryBulb + humidity) -
        math.atan(humidity - 1.676331) +
        0.00391838 * math.pow(humidity, 1.5) * math.atan(0.023101 * humidity) -
        4.686035;
    return tw;
  }

  /// 열지수 계산 (체감온도)
  /// [temp] 온도 (°C)
  /// [humidity] 상대습도 (%)
  static double heatIndex(double temp, double humidity) {
    // Fahrenheit로 변환
    final tf = temp * 9 / 5 + 32;

    if (tf < 80) return temp; // 26.7°C 이하는 열지수 계산 불필요

    // Rothfusz regression
    double hi = -42.379 +
        2.04901523 * tf +
        10.14333127 * humidity -
        0.22475541 * tf * humidity -
        0.00683783 * tf * tf -
        0.05481717 * humidity * humidity +
        0.00122874 * tf * tf * humidity +
        0.00085282 * tf * humidity * humidity -
        0.00000199 * tf * tf * humidity * humidity;

    // Celsius로 변환
    return (hi - 32) * 5 / 9;
  }
}

/// 외기 환경 분석기
class OutdoorEnvironmentAnalyzer {
  /// 외기 절대습도 계산
  static double outdoorAbsoluteHumidity(double outdoorTemp, double outdoorRH) {
    final es = HVACAnalytics.saturationVaporPressure(outdoorTemp);
    return (outdoorRH / 100 * es) / (461.5 * (outdoorTemp + 273.15));
  }

  /// HVAC 성능 페널티 계산 (논문 기반)
  /// 반환값: 1.0 = 표준 성능, 0.7 = 70% 성능
  static double performancePenalty(
    double outdoorTemp,
    double outdoorRH, {
    double refTemp = 24.0,
    double refRH = 60.0,
  }) {
    // 온도에 따른 페널티 (약 0.5%/°C)
    final tempPenalty = 0.005 * (outdoorTemp - refTemp).abs();

    // 습도에 따른 페널티 (약 3%/10%RH)
    final rhPenalty = 0.03 * ((outdoorRH - refRH).abs() / 10);

    final penalty = 1.0 - (tempPenalty + rhPenalty);
    return math.max(penalty, 0.0);
  }

  /// 외기 조건 평가
  static OutdoorConditionAssessment assessOutdoorCondition(
    double temp,
    double humidity,
  ) {
    final dewPoint = HVACAnalytics.dewPoint(temp, humidity);
    final absoluteHumidity = HVACAnalytics.absoluteHumidity(temp, humidity);
    final performanceFactor = performancePenalty(temp, humidity);

    String condition;
    String hvacRecommendation;

    if (humidity >= 80) {
      condition = '매우 습함';
      hvacRecommendation = '제습 운전 필요, HVAC 효율 저하 예상';
    } else if (humidity >= 65) {
      condition = '습함';
      hvacRecommendation = '제습 운전 권장';
    } else if (humidity >= 40) {
      condition = '적정';
      hvacRecommendation = '정상 운전';
    } else if (humidity >= 25) {
      condition = '건조';
      hvacRecommendation = '가습 고려';
    } else {
      condition = '매우 건조';
      hvacRecommendation = '가습 필요';
    }

    return OutdoorConditionAssessment(
      condition: condition,
      dewPoint: dewPoint,
      absoluteHumidity: absoluteHumidity,
      performanceFactor: performanceFactor,
      hvacRecommendation: hvacRecommendation,
    );
  }
}

/// 외기 조건 평가 결과
class OutdoorConditionAssessment {
  final String condition;
  final double dewPoint;
  final double absoluteHumidity;
  final double performanceFactor;
  final String hvacRecommendation;

  OutdoorConditionAssessment({
    required this.condition,
    required this.dewPoint,
    required this.absoluteHumidity,
    required this.performanceFactor,
    required this.hvacRecommendation,
  });
}

/// HVAC 모드 열거형
enum HVACMode { heating, cooling, transitioning, idle }

/// HVAC 모드 전환 이벤트
class ModeTransitionEvent {
  final DateTime time;
  final HVACMode previousMode;
  final HVACMode newMode;
  final double tempChangeRate;
  final double durationMinutes;
  final String reason;
  final double? riskBefore;
  final double? riskAfter;

  ModeTransitionEvent({
    required this.time,
    required this.previousMode,
    required this.newMode,
    required this.tempChangeRate,
    required this.durationMinutes,
    required this.reason,
    this.riskBefore,
    this.riskAfter,
  });
}

/// HVAC 모드 감지기
class HVACModeDetector {
  /// 모드 전환 시점 감지
  static List<ModeTransitionEvent> detectModeTransitions(
    List<WeatherData> historicalData,
    double hvacSetpoint, {
    double hvacHysteresis = 1.0,
  }) {
    final events = <ModeTransitionEvent>[];
    HVACMode currentMode = HVACMode.idle;
    HVACMode previousMode = HVACMode.idle;

    for (var i = 1; i < historicalData.length; i++) {
      final prev = historicalData[i - 1];
      final curr = historicalData[i];

      // 온도 변화율 계산
      final dT = curr.temperature - prev.temperature;
      final timeDiffMinutes =
          curr.time.difference(prev.time).inMinutes.toDouble();
      if (timeDiffMinutes == 0) continue;

      final dTperHour = dT * 60 / timeDiffMinutes;

      // 현재 모드 판정 (히스테리시스 적용)
      if (currentMode == HVACMode.idle) {
        if (curr.temperature < hvacSetpoint - hvacHysteresis) {
          currentMode = HVACMode.heating;
        } else if (curr.temperature > hvacSetpoint + hvacHysteresis) {
          currentMode = HVACMode.cooling;
        }
      } else if (currentMode == HVACMode.heating) {
        if (curr.temperature > hvacSetpoint + hvacHysteresis) {
          currentMode = HVACMode.cooling;
        } else if ((curr.temperature - hvacSetpoint).abs() < 0.5) {
          currentMode = HVACMode.idle;
        }
      } else if (currentMode == HVACMode.cooling) {
        if (curr.temperature < hvacSetpoint - hvacHysteresis) {
          currentMode = HVACMode.heating;
        } else if ((curr.temperature - hvacSetpoint).abs() < 0.5) {
          currentMode = HVACMode.idle;
        }
      }

      // 모드 전환 감지
      if (currentMode != previousMode && dTperHour.abs() > 1.5) {
        final reason = currentMode == HVACMode.cooling
            ? '외기 온도 상승 (${curr.temperature.toStringAsFixed(1)}°C)'
            : currentMode == HVACMode.heating
                ? '외기 온도 하강 (${curr.temperature.toStringAsFixed(1)}°C)'
                : '온도 안정화';

        events.add(ModeTransitionEvent(
          time: curr.time,
          previousMode: previousMode,
          newMode: currentMode,
          tempChangeRate: dTperHour,
          durationMinutes: 0,
          reason: reason,
        ));

        previousMode = currentMode;
      }
    }

    return events;
  }

  /// 취약 시간대 감지
  static List<VulnerableTimeSlot> detectVulnerableTimeSlots(
    List<WeatherData> data,
    BuildingType buildingType,
  ) {
    final slots = <VulnerableTimeSlot>[];

    for (var i = 0; i < data.length; i++) {
      final weather = data[i];
      final dewPoint = HVACAnalytics.dewPoint(weather.temperature, weather.humidity);
      final gap = weather.temperature - dewPoint;

      // 이슬점 마진이 작을 때
      if (gap < AppConstants.warningDewPointMargin) {
        // 연속된 취약 시간대 찾기
        int endIndex = i;
        for (var j = i + 1; j < data.length; j++) {
          final nextWeather = data[j];
          final nextDewPoint = HVACAnalytics.dewPoint(
            nextWeather.temperature,
            nextWeather.humidity,
          );
          final nextGap = nextWeather.temperature - nextDewPoint;

          if (nextGap < AppConstants.warningDewPointMargin) {
            endIndex = j;
          } else {
            break;
          }
        }

        if (endIndex > i) {
          final startTime = data[i].time;
          final endTime = data[endIndex].time;
          final duration = endTime.difference(startTime).inMinutes;

          // 최소 30분 이상 지속되는 경우만
          if (duration >= 30) {
            final avgGap = data
                .sublist(i, endIndex + 1)
                .map((w) => w.temperature - HVACAnalytics.dewPoint(w.temperature, w.humidity))
                .reduce((a, b) => a + b) / (endIndex - i + 1);

            slots.add(VulnerableTimeSlot(
              startTime: startTime,
              endTime: endTime,
              durationMinutes: duration,
              averageDewPointGap: avgGap,
              riskLevel: _getRiskLevel(avgGap),
              recommendation: _getTimeSlotRecommendation(avgGap, buildingType),
            ));
          }

          i = endIndex; // 다음 검색 시작점
        }
      }
    }

    return slots;
  }

  static RiskLevel _getRiskLevel(double gap) {
    if (gap <= 0) return RiskLevel.danger;
    if (gap < AppConstants.criticalDewPointMargin) return RiskLevel.warning;
    if (gap < AppConstants.warningDewPointMargin) return RiskLevel.caution;
    return RiskLevel.safe;
  }

  static String _getTimeSlotRecommendation(double gap, BuildingType type) {
    if (gap <= 0) {
      return '즉시 제습 및 환기 필요. 결로 발생 중.';
    } else if (gap < AppConstants.criticalDewPointMargin) {
      if (type.airtightness < 0.5) {
        return '제습기 가동 권장. 저기밀 구조로 습도 유입 빠름.';
      }
      return '제습 또는 실내 온도 상승 필요.';
    } else {
      return '습도 모니터링 강화. 상황 변화 주시.';
    }
  }
}

/// 취약 시간대
class VulnerableTimeSlot {
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final double averageDewPointGap;
  final RiskLevel riskLevel;
  final String recommendation;

  VulnerableTimeSlot({
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.averageDewPointGap,
    required this.riskLevel,
    required this.recommendation,
  });

  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (hours > 0) {
      return '$hours시간 $minutes분';
    }
    return '$minutes분';
  }

  String get timeRange {
    final startStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$startStr ~ $endStr';
  }
}

/// 건물 습도 응답 예측기
class BuildingHumidityResponse {
  /// 기밀도별 응답 파라미터
  static Map<String, dynamic> getResponseParams(BuildingType type) {
    switch (type) {
      case BuildingType.passive:
        return {
          'indoorRHchange': 0.05,
          'responseDelayMinutes': 120,
          'damping': 0.95,
        };
      case BuildingType.modern:
        return {
          'indoorRHchange': 0.08,
          'responseDelayMinutes': 90,
          'damping': 0.9,
        };
      case BuildingType.standard:
        return {
          'indoorRHchange': 0.15,
          'responseDelayMinutes': 45,
          'damping': 0.5,
        };
      case BuildingType.oldHouse:
        return {
          'indoorRHchange': 0.25,
          'responseDelayMinutes': 20,
          'damping': 0.3,
        };
    }
  }

  /// 예상 실내 습도 계산
  static double predictIndoorHumidity(
    double currentIndoorRH,
    double outdoorRH,
    BuildingType buildingType,
    int minutesElapsed,
  ) {
    final params = getResponseParams(buildingType);

    final responseDelay = params['responseDelayMinutes'] as int;
    final damping = params['damping'] as double;
    final rhChangeRate = params['indoorRHchange'] as double;

    // 응답 함수: 1 - exp(-t/tau)
    final tau = responseDelay.toDouble();
    final influenceFactor = 1 - math.exp(-minutesElapsed / tau);

    // 외기와의 습도 갭
    final rhDifference = outdoorRH - currentIndoorRH;

    // 실제 습도 변화 (댐핑 적용)
    final rhChange = rhDifference * rhChangeRate * influenceFactor * (1.0 - damping);

    // 최종 예상 실내 습도
    return (currentIndoorRH + rhChange).clamp(0.0, 100.0);
  }

  /// 시간별 습도 예측
  static List<HumidityPrediction> predictHumidityOverTime(
    double initialIndoorRH,
    List<WeatherData> outdoorData,
    BuildingType buildingType,
  ) {
    final predictions = <HumidityPrediction>[];
    double currentRH = initialIndoorRH;
    DateTime? lastTime;

    for (final data in outdoorData) {
      int elapsed = 60; // 기본 1시간
      if (lastTime != null) {
        elapsed = data.time.difference(lastTime).inMinutes;
      }

      final predictedRH = predictIndoorHumidity(
        currentRH,
        data.humidity,
        buildingType,
        elapsed,
      );

      final dewPoint = HVACAnalytics.dewPoint(data.temperature, predictedRH);
      final condensationRisk = _calculateCondensationRisk(
        data.temperature,
        predictedRH,
        dewPoint,
        data.humidity,
        buildingType,
      );

      predictions.add(HumidityPrediction(
        time: data.time,
        outdoorHumidity: data.humidity,
        predictedIndoorHumidity: predictedRH,
        dewPoint: dewPoint,
        condensationRisk: condensationRisk,
      ));

      currentRH = predictedRH;
      lastTime = data.time;
    }

    return predictions;
  }

  static double _calculateCondensationRisk(
    double indoorTemp,
    double indoorRH,
    double dewPoint,
    double outdoorRH,
    BuildingType buildingType,
  ) {
    double score = 0;

    // 1. 이슬점 접근도 (50%)
    final gap = indoorTemp - dewPoint;
    if (gap <= 0) score += 50;
    else if (gap < 1.0) score += 40;
    else if (gap < 2.0) score += 30;
    else if (gap < 3.0) score += 20;
    else if (gap < 5.0) score += 10;

    // 2. 실내 습도 (25%)
    if (indoorRH >= 80) score += 25;
    else if (indoorRH >= 70) score += 20;
    else if (indoorRH >= 60) score += 10;

    // 3. 기밀도 보정 (25%)
    final airtightBonus = buildingType.airtightness * 25;
    score = score - airtightBonus;

    return score.clamp(0.0, 100.0);
  }
}

/// 습도 예측 결과
class HumidityPrediction {
  final DateTime time;
  final double outdoorHumidity;
  final double predictedIndoorHumidity;
  final double dewPoint;
  final double condensationRisk;

  HumidityPrediction({
    required this.time,
    required this.outdoorHumidity,
    required this.predictedIndoorHumidity,
    required this.dewPoint,
    required this.condensationRisk,
  });
}

/// 결로 발생 예측기
class CondensationPredictor {
  /// 결로 발생 시점 예측
  static CondensationPrediction? predictCondensationTime(
    List<WeatherData> forecastData,
    double indoorTemp,
    double indoorHumidity,
    BuildingType buildingType,
  ) {
    final predictions = BuildingHumidityResponse.predictHumidityOverTime(
      indoorHumidity,
      forecastData,
      buildingType,
    );

    for (final prediction in predictions) {
      // 이슬점에 도달하는 시점 찾기
      final gap = indoorTemp - prediction.dewPoint;

      if (gap <= 0) {
        // 결로 발생 예측
        return CondensationPrediction(
          predictedTime: prediction.time,
          predictedIndoorHumidity: prediction.predictedIndoorHumidity,
          dewPoint: prediction.dewPoint,
          hoursUntil: prediction.time.difference(DateTime.now()).inHours,
          preventionActions: _getPreventionActions(gap, buildingType),
          probability: 100,
        );
      }

      // 위험 수준에 근접
      if (gap < AppConstants.criticalDewPointMargin && prediction.condensationRisk >= 75) {
        return CondensationPrediction(
          predictedTime: prediction.time,
          predictedIndoorHumidity: prediction.predictedIndoorHumidity,
          dewPoint: prediction.dewPoint,
          hoursUntil: prediction.time.difference(DateTime.now()).inHours,
          preventionActions: _getPreventionActions(gap, buildingType),
          isWarning: true,
          probability: prediction.condensationRisk,
        );
      }
    }

    return null; // 결로 발생 예측 없음
  }

  static List<String> _getPreventionActions(double gap, BuildingType type) {
    final actions = <String>[];

    if (gap <= 0) {
      actions.add('즉시 제습기 가동');
      actions.add('환기를 통해 습한 공기 배출');
      actions.add('실내 온도 2-3°C 상승');
    } else if (gap < 2) {
      actions.add('제습기 가동 권장');
      if (type.airtightness < 0.5) {
        actions.add('창문 틈새 점검 (저기밀 구조)');
      }
      actions.add('습도 모니터링 강화');
    } else {
      actions.add('정기적인 습도 확인');
      actions.add('필요시 환기');
    }

    return actions;
  }
}

/// 결로 발생 예측 결과
class CondensationPrediction {
  final DateTime? predictedTime;
  final double predictedIndoorHumidity;
  final double dewPoint;
  final int hoursUntil;
  final List<String> preventionActions;
  final bool isWarning;
  final double probability;

  CondensationPrediction({
    this.predictedTime,
    required this.predictedIndoorHumidity,
    required this.dewPoint,
    required this.hoursUntil,
    required this.preventionActions,
    this.isWarning = false,
    this.probability = 0,
  });

  String get urgencyText {
    if (hoursUntil <= 1) return '1시간 이내';
    if (hoursUntil <= 3) return '3시간 이내';
    if (hoursUntil <= 6) return '6시간 이내';
    if (hoursUntil <= 12) return '12시간 이내';
    if (hoursUntil <= 24) return '24시간 이내';
    return '$hoursUntil시간 후';
  }
}
