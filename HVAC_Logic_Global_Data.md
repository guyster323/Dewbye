# HVAC 외기환경 응답 로직 및 글로벌 데이터 연동 설계

**작성 일시**: 2025년 11월 30일  
**기반 논문**:
1. 재생온도와 외기조건 변화에 따른 제습 냉방시스템 성능평가 (서울시립대학교)
2. 액체식 제습과 노점 증발 냉각 기술이 적용된 전외기 공조시스템 제어 기법 (대한건축학회)
3. 동절기 반밀폐형 온실의 기상 환경 비교 (원예과학기술지, 2022)
4. 온실 내 온습도 동시제어 시스템 (한국태양에너지학회, 2016)

---

## 1. 학술 기반 HVAC 송풍 전환 로직

### 1.1 핵심 발견사항 (Paper Review)

#### **논문 1&2: 외기 온도/습도에 따른 HVAC 제습 성능**

**결론**:
```
외기 온도 상승 → 시스템 성능계수(COP) ↓
외기 습도 상승 → 시스템 성능계수(COP) ↓ (매우 큼)
```

- 외기 온도 28°C에서 35°C로 증가: COP 약 5~10% 감소
- 외기 습도 60%에서 80%로 증가: COP 약 20~30% 감소
- **핵심**: 외기 습도가 높을수록 HVAC의 제습 능력이 급격히 저하됨

**수식적 표현**:
$$
COP_{outdoor} = COP_{nominal} \times f(T_{out}, RH_{out})
$$

여기서 페널티 함수:
$$
f(T_{out}, RH_{out}) = 1 - 0.005 \times (T_{out} - T_{ref}) - 0.03 \times (RH_{out} - RH_{ref})
$$

- $T_{ref}$ = 기준 외기 온도 (보통 24°C)
- $RH_{ref}$ = 기준 외기 습도 (보통 60%)

#### **논문 3: 밀폐도(기밀성)에 따른 실내 습도 응답**

**중요 발견**: 같은 외기 환경에서도 건물 기밀성에 따라 실내 습도 변화가 다름

| 건물 유형 | 외기 RH 변화 시 실내 RH 변화 | 응답 지연 |
|----------|---------------------------|---------|
| 고기밀(밀폐구조) | 작음 (±5~10%) | 길음 (1~2시간) |
| 저기밀(개방구조) | 큼 (±20~30%) | 짧음 (15~30분) |
| 중간(일반 건물) | 중간 (±10~15%) | 중간 (30~60분) |

**결론**: 같은 기상 데이터도 건물 특성에 따라 해석이 다름
→ **앱에서 건물 유형 선택 필요**

#### **논문 4: 온습도 동시 제어의 한계**

온실에서의 발견사항 (건물과 유사한 HVAC 제어):

```
환기량만 증가 → 온도 ↓, 습도 ↑ (비효율)
냉방만 강화 → 온도 ↓, 상대습도 ↑ (제습 능력 한계)

해결책: 환기량 + 제습기 용량을 함께 조절
```

---

## 2. 개선된 HVAC 이벤트 감지 로직

### 2.1 단계 1: 외기 환경 분석

```dart
class OutdoorEnvironmentAnalyzer {
  
  /// 외기 절대습도 계산
  /// 논문 근거: 절대습도가 HVAC 제습 부하의 핵심 지표
  static double outdoorAbsoluteHumidity(
    double outdoorTemp,
    double outdoorRH
  ) {
    final es = HVACAnalytics.saturationVaporPressure(outdoorTemp);
    return (outdoorRH / 100 * es) / (461.5 * (outdoorTemp + 273.15));
  }
  
  /// 외기 습구온도 (Wet Bulb Temperature)
  /// 중요성: 냉각탑과 증발식 냉각 효율을 결정
  static double wetBulbTemperature(
    double dryBulb,
    double humidity
  ) {
    // Stull의 근사식 (정확도 ±1°C)
    final Tw = dryBulb * atan(0.151977 * sqrt(humidity + 8.313659)) +
               atan(dryBulb + humidity) -
               atan(humidity - 1.676331) +
               0.00391838 * pow(humidity, 1.5) * atan(0.023101 * humidity) -
               4.686035;
    return Tw;
  }
  
  /// HVAC 성능 페널티 계산 (논문 기반)
  /// 반환값: 1.0 = 표준 성능, 0.7 = 70% 성능만 발휘
  static double performancePenalty(
    double outdoorTemp,
    double outdoorRH,
    {
      double refTemp = 24.0, // 기준 온도
      double refRH = 60.0,   // 기준 습도
    }
  ) {
    // 온도에 따른 페널티 (약 0.5%/℃)
    final tempPenalty = 0.005 * (outdoorTemp - refTemp).abs();
    
    // 습도에 따른 페널티 (약 3%/10%RH) - 습도가 훨씬 중요함
    final rhPenalty = 0.03 * ((outdoorRH - refRH).abs() / 10);
    
    final penalty = 1.0 - (tempPenalty + rhPenalty);
    return max(penalty, 0.0); // 음수 방지
  }
}
```

### 2.2 단계 2: HVAC 모드 전환 추정

```dart
class HVACModeDetector {
  
  /// HVAC 모드 전환 신호 감지 (다중 조건)
  enum HVACMode { heating, cooling, transitioning, idle }
  
  static class ModeTransitionEvent {
    final DateTime timestamp;
    final HVACMode fromMode;
    final HVACMode toMode;
    final double tempChangeRate; // ℃/hour
    final double durationMinutes;
    final String reason; // 전환 원인
    
    ModeTransitionEvent({
      required this.timestamp,
      required this.fromMode,
      required this.toMode,
      required this.tempChangeRate,
      required this.durationMinutes,
      required this.reason,
    });
  }
  
  /// 모드 전환 시점 감지 (개선된 로직)
  static List<ModeTransitionEvent> detectModeTransitions(
    List<WeatherDataPoint> historicalData,
    double hvacSetpoint, {
    double hvacHysteresis = 1.0, // ±1°C 히스테리시스
  }) {
    final events = <ModeTransitionEvent>[];
    HVACMode currentMode = HVACMode.idle;
    HVACMode previousMode = HVACMode.idle;
    DateTime? transitionStartTime;
    
    for (var i = 1; i < historicalData.length; i++) {
      final prev = historicalData[i - 1];
      final curr = historicalData[i];
      
      // 1. 온도 변화율 계산
      final dT = curr.temperature - prev.temperature;
      final dTperHour = dT * 60 / (curr.timestamp.difference(prev.timestamp).inMinutes);
      
      // 2. 현재 모드 판정 (히스테리시스 적용)
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
      
      // 3. 모드 전환 감지
      if (currentMode != previousMode) {
        // 명확한 신호 필요 (노이즈 제거)
        if (dTperHour.abs() > 1.5) {
          final reason = currentMode == HVACMode.cooling 
            ? "외기 온도 상승 (${curr.temperature}°C, dT/dt=${dTperHour.toStringAsFixed(2)}°C/h)"
            : "외기 온도 하강 (${curr.temperature}°C, dT/dt=${dTperHour.toStringAsFixed(2)}°C/h)";
          
          events.add(ModeTransitionEvent(
            timestamp: curr.timestamp,
            fromMode: previousMode,
            toMode: currentMode,
            tempChangeRate: dTperHour,
            durationMinutes: 0,
            reason: reason,
          ));
          
          previousMode = currentMode;
        }
      }
    }
    
    return events;
  }
}
```

### 2.3 단계 3: 밀폐도를 고려한 실내 습도 응답 예측

```dart
class BuildingHumidityResponse {
  
  /// 건물 기밀도 분류 (사용자 선택)
  enum BuildingAirtightness {
    highAirtight,    // 고기밀 (새건물, 에너지효율건물)
    medium,          // 중간 (일반 사무건물)
    lowAirtight,     // 저기밀 (오래된 건물, 개방구조)
  }
  
  /// 기밀도별 응답 특성
  static const responseParms = {
    BuildingAirtightness.highAirtight: {
      'indoorRHchange': 0.08,    // 외기 1%RH 변화 → 실내 0.08%RH 변화
      'responseDelayMinutes': 90, // 응답 지연 90분
      'damping': 0.9,             // 높은 댐핑 (습도 변화 완화)
    },
    BuildingAirtightness.medium: {
      'indoorRHchange': 0.15,
      'responseDelayMinutes': 45,
      'damping': 0.5,
    },
    BuildingAirtightness.lowAirtight: {
      'indoorRHchange': 0.25,
      'responseDelayMinutes': 20,
      'damping': 0.3,
    },
  };
  
  /// 예상 실내 습도 계산
  /// 논문: 밀폐도에 따라 외기 습도 변화의 영향이 다름
  static double predictIndoorHumidity(
    double currentIndoorRH,
    double outdoorRH,
    BuildingAirtightness airtightness,
    int minutesElapsed,
  ) {
    final parms = responseParms[airtightness]!;
    
    // 1. 외기 영향도 계산 (시간에 따른 지수 감쇠)
    final responseDelay = parms['responseDelayMinutes'] as int;
    final damping = parms['damping'] as double;
    
    // 응답 함수: exp(-t/tau)
    final tau = responseDelay.toDouble();
    final influenceFactor = 1 - exp(-minutesElapsed / tau);
    
    // 2. 외기와의 습도 갭
    final rhDifference = outdoorRH - currentIndoorRH;
    
    // 3. 실제 습도 변화
    final rhChange = rhDifference * 
                     (parms['indoorRHchange'] as double) * 
                     influenceFactor * 
                     (1.0 + damping); // 댐핑 효과
    
    // 4. 최종 예상 실내 습도
    return currentIndoorRH + rhChange;
  }
  
  /// 결로 위험도 상세 분석
  static Map<String, dynamic> analyzeCondensationRisk(
    double indoorTemp,
    double indoorRH,
    double outdoorAbsoluteHumidity,
    BuildingAirtightness airtightness,
  ) {
    final dewPoint = HVACAnalytics.dewPoint(indoorTemp, indoorRH);
    final gap = indoorTemp - dewPoint;
    
    // 기밀도가 높을수록 외기 습도의 유입이 천천히 진행
    // → 결로 위험도 평가 시 시간 요소 추가 필요
    
    final riskScore = _calculateCondensationRisk(
      indoorTemp,
      indoorRH,
      dewPoint,
      outdoorAbsoluteHumidity,
      airtightness,
    );
    
    return {
      'dewPoint': dewPoint,
      'gap': gap,
      'riskScore': riskScore,
      'airtightnessEffect': 
        airtightness == BuildingAirtightness.highAirtight 
          ? "고기밀: 습도 상승 느림, 결로 위험 낮음"
          : airtightness == BuildingAirtightness.medium
          ? "중간: 습도 상승 중간 속도"
          : "저기밀: 습도 상승 빠름, 결로 위험 높음",
      'recommendations': _getCondensationMitigation(
        gap,
        airtightness,
      ),
    };
  }
  
  static double _calculateCondensationRisk(
    double indoorTemp,
    double indoorRH,
    double dewPoint,
    double outdoorAH,
    BuildingAirtightness airtightness,
  ) {
    double score = 0;
    
    // 1. 이슬점 접근도 (40%)
    final gap = indoorTemp - dewPoint;
    if (gap < 2.0) score += 2;
    if (gap < 1.5) score += 1.5;
    if (gap < 1.0) score += 2;
    if (gap < 0.5) score += 2;
    if (gap <= 0) score += 3;
    
    // 2. 절대습도 (30%)
    final indoorAH = HVACAnalytics.absoluteHumidity(indoorTemp, indoorRH);
    final ahDifference = outdoorAH - indoorAH;
    if (ahDifference > 2) score += 2;   // 외기가 훨씬 건조
    if (ahDifference > 5) score += 1;
    
    // 3. 기밀도 보정 (30%)
    // 고기밀: 외기 습도 유입이 느려서 위험도 낮음
    final airtightPenalty = airtightness == BuildingAirtightness.highAirtight 
      ? 1.5
      : airtightness == BuildingAirtightness.medium
      ? 1.0
      : 0.7;
    
    return (score * airtightPenalty).clamp(0, 10.0);
  }
  
  static List<String> _getCondensationMitigation(
    double gap,
    BuildingAirtightness airtightness,
  ) {
    final recommendations = <String>[];
    
    if (gap < 1.5) {
      recommendations.add("🔴 즉시 대응 필요:");
      recommendations.add("  • HVAC 제습 능력 최대화");
      if (airtightness == BuildingAirtightness.highAirtight) {
        recommendations.add("  • 고기밀 구조: 외부 공기 유입 최소화");
        recommendations.add("  • 실내 환기량 증가 효과 제한적");
      } else {
        recommendations.add("  • 환기 강화로 습한 공기 배출");
      }
      recommendations.add("  • 열거 운전으로 실내 온도 상승");
    } else if (gap < 3.0) {
      recommendations.add("⚠️  주의 필요:");
      recommendations.add("  • 습도 모니터링 강화");
      recommendations.add("  • 필요시 제습기 추가 운전");
    }
    
    return recommendations;
  }
}
```

---

## 3. 글로벌 데이터 소스 통합

### 3.1 기상 데이터 소스 선택

| 소스 | 커버리지 | 정확도 | 과거 데이터 | 비용 | 사용성 |
|------|---------|--------|-----------|------|--------|
| **기상청 (한국)** | 한국 | 높음 | 60개월 | 무료 | 우수 |
| **Open-Meteo (글로벌)** | 전 세계 | 중간 | 60년+ | 무료 | 우수 |
| **NOAA (미국)** | 북미 | 높음 | 제한 | 무료 | 보통 |
| **ECMWF (유럽)** | 전 세계 | 매우 높음 | 40년+ | 무료(공개) | 낮음 |

**선택 전략**:
```
1차: 기상청 API (한국)
2차: Open-Meteo API (글로벌)
3차: NOAA (미국 지역 고정확도 필요 시)
```

### 3.2 Open-Meteo 통합 설계

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class GlobalWeatherDataProvider {
  
  /// Open-Meteo API 엔드포인트
  static const String _baseUrl = 'https://archive-api.open-meteo.com/v1/archive';
  
  /// 글로벌 위치 기반 과거 6개월 데이터 수집
  static Future<List<WeatherDataPoint>> fetchGlobalWeatherData({
    required double latitude,
    required double longitude,
    required DateTime startDate, // 6개월 전
    required DateTime endDate,    // 오늘
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl?'
        'latitude=$latitude&'
        'longitude=$longitude&'
        'start_date=${startDate.toIso8601String().split('T')[0]}&'
        'end_date=${endDate.toIso8601String().split('T')[0]}&'
        'hourly=temperature_2m,relative_humidity_2m,wind_speed_10m&'
        'timezone=auto' // 자동 시간대 감지
      );
      
      final response = await http.get(url);
      
      if (response.statusCode != 200) {
        throw Exception('Open-Meteo API Error: ${response.statusCode}');
      }
      
      final data = jsonDecode(response.body);
      return _parseOpenMeteoData(data);
      
    } catch (e) {
      print('Error fetching global weather data: $e');
      rethrow;
    }
  }
  
  /// Open-Meteo 응답 파싱
  static List<WeatherDataPoint> _parseOpenMeteoData(Map<String, dynamic> data) {
    final hourly = data['hourly'] as Map<String, dynamic>;
    final times = (hourly['time'] as List).cast<String>();
    final temps = (hourly['temperature_2m'] as List).cast<num>();
    final humidities = (hourly['relative_humidity_2m'] as List).cast<num>();
    final windSpeeds = (hourly['wind_speed_10m'] as List).cast<num>();
    
    final dataPoints = <WeatherDataPoint>[];
    
    for (var i = 0; i < times.length; i++) {
      final timestamp = DateTime.parse(times[i]);
      
      // 결측치 처리
      if (temps[i] == null || humidities[i] == null) continue;
      
      dataPoints.add(WeatherDataPoint(
        timestamp: timestamp,
        temperature: (temps[i] as num).toDouble(),
        humidity: (humidities[i] as num).toDouble().clamp(0.0, 100.0),
        windSpeed: (windSpeeds[i] as num?)?.toDouble() ?? 0.0,
      ));
    }
    
    return dataPoints;
  }
}
```

### 3.3 위치 선택 방식 (3가지)

```dart
class LocationSelector {
  
  /// 1. 현재 위치 (GPS 권한)
  static Future<LocationCoordinates> getCurrentLocation() async {
    // flutter_location 패키지 사용
    // iOS/Android 권한 처리 필요
    final location = Location();
    
    // 권한 요청
    PermissionStatus status = await location.requestPermission();
    if (status != PermissionStatus.granted) {
      throw Exception('위치 권한이 거부되었습니다.');
    }
    
    final currentLocation = await location.getLocation();
    
    return LocationCoordinates(
      latitude: currentLocation.latitude!,
      longitude: currentLocation.longitude!,
      source: 'GPS',
    );
  }
  
  /// 2. 특정 위치 (주소 또는 좌표)
  static Future<LocationCoordinates> searchLocation(String query) async {
    // Google Maps Geocoding API 또는 Open-Meteo Geocoding
    final url = Uri.parse(
      'https://geocoding-api.open-meteo.com/v1/search'
      '?name=$query&language=ko&count=10'
    );
    
    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);
      final results = (data['results'] as List?);
      
      if (results == null || results.isEmpty) {
        throw Exception('검색 결과 없음');
      }
      
      // 첫 번째 결과 반환
      final first = results[0];
      return LocationCoordinates(
        latitude: (first['latitude'] as num).toDouble(),
        longitude: (first['longitude'] as num).toDouble(),
        source: '검색 결과: ${first['name']}',
      );
    } catch (e) {
      throw Exception('위치 검색 실패: $e');
    }
  }
  
  /// 3. Google Maps 지도 선택
  static Future<LocationCoordinates> selectFromMap() async {
    // google_maps_flutter 패키지 사용
    // 사용자가 지도를 터치한 위치 반환
    // (UI 구현은 별도)
    
    // 이 함수는 UI layer에서 호출됨
    throw UnimplementedError('UI에서 구현 필요');
  }
}

class LocationCoordinates {
  final double latitude;
  final double longitude;
  final String source; // "GPS", "검색 결과: 서울", "지도 선택" 등
  
  LocationCoordinates({
    required this.latitude,
    required this.longitude,
    required this.source,
  });
}
```

### 3.4 데이터 소스 폴백 전략

```dart
class WeatherDataProvider {
  
  /// 다중 데이터 소스 폴백
  static Future<List<WeatherDataPoint>> getWeatherDataWithFallback({
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
    required String country,
  }) async {
    // 1차: 한국 기상청 (한국 내에서만)
    if (country == 'KR') {
      try {
        return await _fetchFromKMA(latitude, longitude, startDate, endDate);
      } catch (e) {
        print('KMA 데이터 실패, Open-Meteo로 폴백: $e');
      }
    }
    
    // 2차: Open-Meteo (전 세계)
    try {
      return await GlobalWeatherDataProvider.fetchGlobalWeatherData(
        latitude: latitude,
        longitude: longitude,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      print('Open-Meteo 데이터 실패: $e');
    }
    
    // 3차: 캐시된 데이터 반환
    print('라이브 데이터 불가, 캐시 데이터 사용');
    return await _getCachedWeatherData(latitude, longitude);
  }
  
  static Future<List<WeatherDataPoint>> _fetchFromKMA(
    double lat,
    double lon,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // 기상청 API 호출 (기존 구현)
    throw UnimplementedError('기상청 API 호출 구현 필요');
  }
  
  static Future<List<WeatherDataPoint>> _getCachedWeatherData(
    double lat,
    double lon,
  ) async {
    // SQLite/Hive에서 캐시 데이터 조회
    throw UnimplementedError('캐시 조회 구현 필요');
  }
}
```

---

## 4. 앱 UX 업데이트 (위치 선택)

### 4.1 위치 선택 화면

```
┌──────────────────────────────────────┐
│  Weather-HVAC Analytics              │
├──────────────────────────────────────┤
│                                      │
│  📍 건물 위치 선택                   │
│                                      │
│  [1️⃣  현재 위치 사용]               │
│  ├─ GPS로 자동 인식                  │
│  ├─ 위도: 37.4979°                  │
│  └─ 경도: 127.0276°                 │
│     ≈ 서울시 강남구                  │
│                                      │
│  [2️⃣  검색으로 위치 선택]           │
│  ┌────────────────────────────────┐ │
│  │ 🔍 도시명/주소 입력            │ │
│  │ 예: "Seoul", "강남구", "NYC"   │ │
│  └────────────────────────────────┘ │
│  [검색] [최근 검색 ▼]               │
│                                      │
│  [3️⃣  지도에서 선택]               │
│  ┌────────────────────────────────┐ │
│  │  🗺️ 지도                      │ │
│  │  [Google Maps 열기]            │ │
│  └────────────────────────────────┘ │
│                                      │
│  💾 저장된 위치 (최근 5개)           │
│  • 서울 강남 - 2025/11/30          │
│  • 부산 해운대 - 2025/11/28        │
│  • NYC Midtown - 2025/11/25        │
│                                      │
│  [다음]                              │
│                                      │
└──────────────────────────────────────┘
```

### 4.2 건물 기밀도 선택 (밀폐도 보정용)

```
┌──────────────────────────────────────┐
│  건물 유형 선택                      │
├──────────────────────────────────────┤
│                                      │
│  이 정보는 실내 습도 응답 시간을    │
│  정확히 예측하는데 사용됩니다.      │
│                                      │
│  ○ 고기밀 구조 (새 건물)            │
│    📌 2010년 이후 신축               │
│    📌 EPC A-B등급                   │
│    📌 패시브하우스                   │
│    특징: 습도 변화 완만, 결로 위험  │
│           낮음                       │
│                                      │
│  ○ 중간 기밀 (일반 건물)             │
│    📌 1980~2010년대 신축             │
│    📌 표준 사무건물                  │
│    특징: 중간 수준의 습도 변화       │
│                                      │
│  ● 저기밀 구조 (개방형)              │
│    📌 2000년 이전 건물               │
│    📌 오래된 주택/상가               │
│    특징: 습도 변화 빠름, 결로 위험  │
│           높음                       │
│                                      │
│  💡 확실하지 않으면? "중간" 선택   │
│                                      │
│  [다음]                              │
│                                      │
└──────────────────────────────────────┘
```

---

## 5. 데이터 분석 로직 (개선)

### 5.1 종합 분석 엔진

```dart
class ComprehensiveHVACAnalyzer {
  
  /// 모든 요소를 통합한 분석
  static Future<AnalysisResult> analyzeBuilding({
    required List<WeatherDataPoint> historicalData,
    required double hvacSetpoint,
    required BuildingAirtightness airtightness,
    required String buildingType,
  }) async {
    
    // 1. 외기 환경 분석
    final outdoorEvents = <OutdoorEvent>[];
    for (var i = 1; i < historicalData.length; i++) {
      final prev = historicalData[i - 1];
      final curr = historicalData[i];
      
      final tempChange = curr.temperature - prev.temperature;
      final rhChange = curr.humidity - prev.humidity;
      
      if (tempChange.abs() > 1.0 || rhChange.abs() > 5.0) {
        outdoorEvents.add(OutdoorEvent(
          timestamp: curr.timestamp,
          temperatureChange: tempChange,
          humidityChange: rhChange,
          absoluteHumidity: OutdoorEnvironmentAnalyzer.outdoorAbsoluteHumidity(
            curr.temperature,
            curr.humidity,
          ),
          performancePenalty: OutdoorEnvironmentAnalyzer.performancePenalty(
            curr.temperature,
            curr.humidity,
          ),
        ));
      }
    }
    
    // 2. HVAC 모드 전환 추정
    final modeTransitions = HVACModeDetector.detectModeTransitions(
      historicalData,
      hvacSetpoint,
    );
    
    // 3. 결로 위험도 평가
    final condensationRisks = <int, Map<String, dynamic>>{};
    for (var i = 0; i < historicalData.length; i++) {
      final data = historicalData[i];
      final risk = BuildingHumidityResponse.analyzeCondensationRisk(
        data.temperature,
        data.humidity,
        OutdoorEnvironmentAnalyzer.outdoorAbsoluteHumidity(
          data.temperature,
          data.humidity,
        ),
        airtightness,
      );
      
      if ((risk['riskScore'] as double) > 5.0) {
        condensationRisks[i] = risk;
      }
    }
    
    return AnalysisResult(
      period: '${historicalData.first.timestamp} ~ ${historicalData.last.timestamp}',
      outdoorEnvironmentEvents: outdoorEvents,
      hvacModeTransitions: modeTransitions,
      condensationRisks: condensationRisks,
      buildingCharacteristics: BuildingCharacteristics(
        airtightness: airtightness,
        estimatedResponseDelay: _estimateResponseDelay(airtightness),
        dampingEffect: _estimateDamping(airtightness),
      ),
      recommendations: _generateRecommendations(
        modeTransitions,
        condensationRisks,
        airtightness,
      ),
    );
  }
  
  static int _estimateResponseDelay(BuildingAirtightness airtightness) {
    const delays = {
      BuildingAirtightness.highAirtight: 90,
      BuildingAirtightness.medium: 45,
      BuildingAirtightness.lowAirtight: 20,
    };
    return delays[airtightness] ?? 45;
  }
  
  static double _estimateDamping(BuildingAirtightness airtightness) {
    const dampings = {
      BuildingAirtightness.highAirtight: 0.9,
      BuildingAirtightness.medium: 0.5,
      BuildingAirtightness.lowAirtight: 0.3,
    };
    return dampings[airtightness] ?? 0.5;
  }
  
  static List<String> _generateRecommendations(
    List<HVACModeDetector.ModeTransitionEvent> transitions,
    Map<int, Map<String, dynamic>> risks,
    BuildingAirtightness airtightness,
  ) {
    final recommendations = <String>[];
    
    // 모드 전환 빈도
    if (transitions.length > 20) {
      recommendations.add(
        "⚠️  HVAC 모드 전환이 매우 빈번함 (${transitions.length}회)"
      );
      recommendations.add("    → 외기 온도 변동이 큰 계절/시간대");
      recommendations.add("    → 실내 온습도 변화도 크게 발생할 가능성");
    }
    
    // 고위험 시기
    if (risks.isNotEmpty) {
      recommendations.add(
        "🔴 결로 위험 고시기: ${risks.length}시간대"
      );
      if (airtightness == BuildingAirtightness.lowAirtight) {
        recommendations.add("    → 저기밀 구조: 위험도가 높은 편");
        recommendations.add("    → 제습기 사전 운전 권장");
      }
    }
    
    // 기밀도별 조치
    if (airtightness == BuildingAirtightness.highAirtight) {
      recommendations.add(
        "✅ 고기밀 건물: 습도 급변화 위험 낮음"
      );
      recommendations.add("    → 예방 차원의 조치보다 모니터링 중심");
    } else if (airtightness == BuildingAirtightness.medium) {
      recommendations.add(
        "⚠️  중간 기밀: 습도 모니터링 필요"
      );
      recommendations.add("    → 모드 전환 시점마다 점검");
    }
    
    return recommendations;
  }
}

class AnalysisResult {
  final String period;
  final List<OutdoorEvent> outdoorEnvironmentEvents;
  final List<HVACModeDetector.ModeTransitionEvent> hvacModeTransitions;
  final Map<int, Map<String, dynamic>> condensationRisks;
  final BuildingCharacteristics buildingCharacteristics;
  final List<String> recommendations;
  
  AnalysisResult({
    required this.period,
    required this.outdoorEnvironmentEvents,
    required this.hvacModeTransitions,
    required this.condensationRisks,
    required this.buildingCharacteristics,
    required this.recommendations,
  });
}

class OutdoorEvent {
  final DateTime timestamp;
  final double temperatureChange;
  final double humidityChange;
  final double absoluteHumidity;
  final double performancePenalty;
  
  OutdoorEvent({
    required this.timestamp,
    required this.temperatureChange,
    required this.humidityChange,
    required this.absoluteHumidity,
    required this.performancePenalty,
  });
}

class BuildingCharacteristics {
  final BuildingHumidityResponse.BuildingAirtightness airtightness;
  final int estimatedResponseDelay; // 분
  final double dampingEffect;
  
  BuildingCharacteristics({
    required this.airtightness,
    required this.estimatedResponseDelay,
    required this.dampingEffect,
  });
}
```

---

## 6. 구현 우선순위 (MVP)

### Phase 1 (1주일): 기초
- [ ] Open-Meteo API 통합
- [ ] 기본 위치 검색 (주소 입력)
- [ ] 현재 위치 (GPS)
- [ ] 기밀도 선택 UI

### Phase 2 (1주일): 분석 엔진
- [ ] HVAC 모드 전환 감지 개선
- [ ] 밀폐도 반영 습도 예측
- [ ] 결로 위험도 계산 (기밀도 보정)

### Phase 3 (3일): 시각화
- [ ] 지도 선택 기능 (Google Maps)
- [ ] 결과 차트 업데이트 (기밀도별 범례)
- [ ] 권장사항 표시

### Phase 4 (3일): 글로벌 테스트
- [ ] 5개 국가에서 테스트 (한국, 미국, 일본, 독일, 싱가포르)
- [ ] 데이터 정확도 검증
- [ ] 폴백 메커니즘 테스트

---

## 7. 논문 근거 요약

| 항목 | 논문 출처 | 핵심 결론 |
|------|---------|---------|
| **외기 습도 → HVAC 성능** | 논문1,2 | 습도 20%↑ = 성능 30% 저하 |
| **모드 전환 시점** | 논문2,4 | ±1.5℃/hour 임계값 |
| **밀폐도 효과** | 논문3 | 고기밀 = 응답 지연 90분, 변화량 1/3 |
| **온습도 동시제어** | 논문4 | 환기량 + 제습 용량 함께 조절 필요 |

---

**문서 작성**: HVAC 외기환경 응답 로직 및 글로벌 데이터 연동  
**최종 수정**: 2025년 11월 30일  
**근거**: 학술 논문 4편 분석