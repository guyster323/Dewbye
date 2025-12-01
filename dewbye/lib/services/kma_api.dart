import 'package:dio/dio.dart';
import '../models/weather_data.dart';

/// 기상청 API 서비스 (한국 기상 데이터)
///
/// 기상청 공공데이터포털 API를 사용합니다.
/// API 키가 필요합니다: https://www.data.go.kr
class KmaApiService {
  // 기상청 API 엔드포인트
  static const String _baseUrl = 'http://apis.data.go.kr/1360000';
  static const String _ultraShortForecast = '/VilageFcstInfoService_2.0/getUltraSrtFcst';
  static const String _shortForecast = '/VilageFcstInfoService_2.0/getVilageFcst';
  static const String _ultraShortNow = '/VilageFcstInfoService_2.0/getUltraSrtNcst';

  final Dio _dio;
  final String? _apiKey;

  KmaApiService({Dio? dio, String? apiKey})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 30),
            )),
        _apiKey = apiKey;

  /// 초단기 실황 조회 (현재 기상 데이터)
  Future<KmaWeatherData?> getUltraShortNowcast({
    required int nx,
    required int ny,
    DateTime? baseDateTime,
  }) async {
    if (_apiKey == null || _apiKey.isEmpty) {
      throw KmaApiException('API 키가 설정되지 않았습니다');
    }

    final now = baseDateTime ?? DateTime.now();
    final baseDate = _formatDate(now);
    final baseTime = _getUltraShortBaseTime(now);

    try {
      final response = await _dio.get(
        '$_baseUrl$_ultraShortNow',
        queryParameters: {
          'serviceKey': _apiKey,
          'pageNo': 1,
          'numOfRows': 100,
          'dataType': 'JSON',
          'base_date': baseDate,
          'base_time': baseTime,
          'nx': nx,
          'ny': ny,
        },
      );

      if (response.statusCode == 200) {
        return _parseNowcastResponse(response.data);
      } else {
        throw KmaApiException(
          'API 요청 실패: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw KmaApiException(_getDioErrorMessage(e), e.response?.statusCode);
    }
  }

  /// 초단기 예보 조회 (6시간 예보)
  Future<List<KmaWeatherData>> getUltraShortForecast({
    required int nx,
    required int ny,
    DateTime? baseDateTime,
  }) async {
    if (_apiKey == null || _apiKey.isEmpty) {
      throw KmaApiException('API 키가 설정되지 않았습니다');
    }

    final now = baseDateTime ?? DateTime.now();
    final baseDate = _formatDate(now);
    final baseTime = _getUltraShortBaseTime(now);

    try {
      final response = await _dio.get(
        '$_baseUrl$_ultraShortForecast',
        queryParameters: {
          'serviceKey': _apiKey,
          'pageNo': 1,
          'numOfRows': 1000,
          'dataType': 'JSON',
          'base_date': baseDate,
          'base_time': baseTime,
          'nx': nx,
          'ny': ny,
        },
      );

      if (response.statusCode == 200) {
        return _parseForecastResponse(response.data);
      } else {
        throw KmaApiException(
          'API 요청 실패: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw KmaApiException(_getDioErrorMessage(e), e.response?.statusCode);
    }
  }

  /// 단기 예보 조회 (3일 예보)
  Future<List<KmaWeatherData>> getShortForecast({
    required int nx,
    required int ny,
    DateTime? baseDateTime,
  }) async {
    if (_apiKey == null || _apiKey.isEmpty) {
      throw KmaApiException('API 키가 설정되지 않았습니다');
    }

    final now = baseDateTime ?? DateTime.now();
    final baseDate = _formatDate(now);
    final baseTime = _getShortBaseTime(now);

    try {
      final response = await _dio.get(
        '$_baseUrl$_shortForecast',
        queryParameters: {
          'serviceKey': _apiKey,
          'pageNo': 1,
          'numOfRows': 1000,
          'dataType': 'JSON',
          'base_date': baseDate,
          'base_time': baseTime,
          'nx': nx,
          'ny': ny,
        },
      );

      if (response.statusCode == 200) {
        return _parseForecastResponse(response.data);
      } else {
        throw KmaApiException(
          'API 요청 실패: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw KmaApiException(_getDioErrorMessage(e), e.response?.statusCode);
    }
  }

  /// 위경도 → 격자 좌표 변환 (기상청 격자)
  static GridCoordinate latLonToGrid(double lat, double lon) {
    const double re = 6371.00877; // 지구 반경(km)
    const double grid = 5.0; // 격자 간격(km)
    const double slat1 = 30.0; // 표준 위도 1
    const double slat2 = 60.0; // 표준 위도 2
    const double olon = 126.0; // 기준점 경도
    const double olat = 38.0; // 기준점 위도
    const double xo = 43.0; // 기준점 X좌표
    const double yo = 136.0; // 기준점 Y좌표

    const double degrad = 3.141592653589793 / 180.0;
    const double re2 = re / grid;

    double slat1Rad = slat1 * degrad;
    double slat2Rad = slat2 * degrad;
    double olatRad = olat * degrad;
    double olonRad = olon * degrad;

    double sn = Math.tan(3.141592653589793 * 0.25 + slat2Rad * 0.5) /
        Math.tan(3.141592653589793 * 0.25 + slat1Rad * 0.5);
    sn = Math.log(Math.cos(slat1Rad) / Math.cos(slat2Rad)) / Math.log(sn);

    double sf = Math.tan(3.141592653589793 * 0.25 + slat1Rad * 0.5);
    sf = Math.pow(sf, sn) * Math.cos(slat1Rad) / sn;

    double ro = Math.tan(3.141592653589793 * 0.25 + olatRad * 0.5);
    ro = re2 * sf / Math.pow(ro, sn);

    double latRad = lat * degrad;
    double lonRad = lon * degrad;

    double ra = Math.tan(3.141592653589793 * 0.25 + latRad * 0.5);
    ra = re2 * sf / Math.pow(ra, sn);

    double theta = lonRad - olonRad;
    if (theta > 3.141592653589793) theta -= 2.0 * 3.141592653589793;
    if (theta < -3.141592653589793) theta += 2.0 * 3.141592653589793;
    theta *= sn;

    int nx = (ra * Math.sin(theta) + xo + 0.5).floor();
    int ny = (ro - ra * Math.cos(theta) + yo + 0.5).floor();

    return GridCoordinate(nx: nx, ny: ny);
  }

  // 초단기 실황 응답 파싱
  KmaWeatherData? _parseNowcastResponse(dynamic data) {
    try {
      final response = data['response'];
      final header = response['header'];

      if (header['resultCode'] != '00') {
        throw KmaApiException('API 오류: ${header['resultMsg']}');
      }

      final body = response['body'];
      final items = body['items']['item'] as List?;

      if (items == null || items.isEmpty) {
        return null;
      }

      double? temperature;
      double? humidity;
      double? windSpeed;
      double? precipitation;
      String? precipitationType;

      for (final item in items) {
        final category = item['category'] as String;
        final value = item['obsrValue']?.toString();

        if (value == null) continue;

        switch (category) {
          case 'T1H': // 기온
            temperature = double.tryParse(value);
            break;
          case 'REH': // 습도
            humidity = double.tryParse(value);
            break;
          case 'WSD': // 풍속
            windSpeed = double.tryParse(value);
            break;
          case 'RN1': // 1시간 강수량
            precipitation = double.tryParse(value);
            break;
          case 'PTY': // 강수형태
            precipitationType = _getPrecipitationType(value);
            break;
        }
      }

      if (temperature == null || humidity == null) {
        return null;
      }

      // 이슬점 계산
      final dewPoint = _calculateDewPoint(temperature, humidity);

      return KmaWeatherData(
        time: DateTime.now(),
        temperature: temperature,
        humidity: humidity,
        dewPoint: dewPoint,
        windSpeed: windSpeed,
        precipitation: precipitation,
        precipitationType: precipitationType,
      );
    } catch (e) {
      throw KmaApiException('응답 파싱 오류: $e');
    }
  }

  // 예보 응답 파싱
  List<KmaWeatherData> _parseForecastResponse(dynamic data) {
    try {
      final response = data['response'];
      final header = response['header'];

      if (header['resultCode'] != '00') {
        throw KmaApiException('API 오류: ${header['resultMsg']}');
      }

      final body = response['body'];
      final items = body['items']['item'] as List?;

      if (items == null || items.isEmpty) {
        return [];
      }

      // 시간별 데이터 그룹화
      final Map<String, Map<String, dynamic>> groupedData = {};

      for (final item in items) {
        final fcstDate = item['fcstDate'] as String;
        final fcstTime = item['fcstTime'] as String;
        final key = '$fcstDate$fcstTime';
        final category = item['category'] as String;
        final value = item['fcstValue']?.toString();

        groupedData.putIfAbsent(key, () => {
          'date': fcstDate,
          'time': fcstTime,
        });
        groupedData[key]![category] = value;
      }

      // KmaWeatherData 리스트로 변환
      final List<KmaWeatherData> results = [];

      for (final entry in groupedData.entries) {
        final data = entry.value;
        final date = data['date'] as String;
        final time = data['time'] as String;

        final year = int.parse(date.substring(0, 4));
        final month = int.parse(date.substring(4, 6));
        final day = int.parse(date.substring(6, 8));
        final hour = int.parse(time.substring(0, 2));

        final dateTime = DateTime(year, month, day, hour);

        final temp = double.tryParse(data['TMP'] ?? data['T1H'] ?? '');
        final humidity = double.tryParse(data['REH'] ?? '');

        if (temp == null || humidity == null) continue;

        final dewPoint = _calculateDewPoint(temp, humidity);

        results.add(KmaWeatherData(
          time: dateTime,
          temperature: temp,
          humidity: humidity,
          dewPoint: dewPoint,
          windSpeed: double.tryParse(data['WSD'] ?? ''),
          precipitation: double.tryParse(data['PCP'] ?? data['RN1'] ?? ''),
          precipitationType: _getPrecipitationType(data['PTY']),
          skyCondition: _getSkyCondition(data['SKY']),
        ));
      }

      results.sort((a, b) => a.time.compareTo(b.time));
      return results;
    } catch (e) {
      throw KmaApiException('응답 파싱 오류: $e');
    }
  }

  // 이슬점 계산 (Magnus 공식)
  double _calculateDewPoint(double temp, double humidity) {
    const double a = 17.27;
    const double b = 237.7;
    double gamma = (a * temp / (b + temp)) + Math.log(humidity / 100.0);
    return (b * gamma) / (a - gamma);
  }

  // 강수형태 변환
  String _getPrecipitationType(String? code) {
    switch (code) {
      case '0':
        return '없음';
      case '1':
        return '비';
      case '2':
        return '비/눈';
      case '3':
        return '눈';
      case '4':
        return '소나기';
      case '5':
        return '빗방울';
      case '6':
        return '빗방울눈날림';
      case '7':
        return '눈날림';
      default:
        return '알 수 없음';
    }
  }

  // 하늘상태 변환
  String _getSkyCondition(String? code) {
    switch (code) {
      case '1':
        return '맑음';
      case '3':
        return '구름많음';
      case '4':
        return '흐림';
      default:
        return '알 수 없음';
    }
  }

  // 초단기 실황/예보 기준시간 (매시 40분 발표)
  String _getUltraShortBaseTime(DateTime now) {
    int hour = now.hour;
    int minute = now.minute;

    // 40분 이전이면 이전 시간 사용
    if (minute < 40) {
      hour = hour - 1;
      if (hour < 0) hour = 23;
    }

    return '${hour.toString().padLeft(2, '0')}00';
  }

  // 단기예보 기준시간 (0200, 0500, 0800, 1100, 1400, 1700, 2000, 2300)
  String _getShortBaseTime(DateTime now) {
    final baseTimes = [2, 5, 8, 11, 14, 17, 20, 23];
    int hour = now.hour;
    int minute = now.minute;

    // 현재 시간에서 10분 빼기 (API 생성 시간 고려)
    if (minute < 10) {
      hour = hour - 1;
      if (hour < 0) hour = 23;
    }

    // 가장 가까운 이전 발표 시간 찾기
    int baseTime = 23;
    for (int i = baseTimes.length - 1; i >= 0; i--) {
      if (hour >= baseTimes[i]) {
        baseTime = baseTimes[i];
        break;
      }
    }

    return '${baseTime.toString().padLeft(2, '0')}00';
  }

  // 날짜 포맷팅
  String _formatDate(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  // Dio 에러 메시지 변환
  String _getDioErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return '연결 시간 초과';
      case DioExceptionType.receiveTimeout:
        return '응답 시간 초과';
      case DioExceptionType.badResponse:
        return 'API 응답 오류: ${e.response?.statusCode}';
      case DioExceptionType.connectionError:
        return '네트워크 연결 오류';
      default:
        return '알 수 없는 오류: ${e.message}';
    }
  }
}

/// 수학 유틸리티
class Math {
  static double log(double x) => _log(x);
  static double tan(double x) => _tan(x);
  static double cos(double x) => _cos(x);
  static double sin(double x) => _sin(x);
  static double pow(double x, double y) => _pow(x, y);

  static double _log(double x) {
    return _ln(x);
  }

  static double _ln(double x) {
    if (x <= 0) return double.nan;
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

  static double _tan(double x) {
    return _sin(x) / _cos(x);
  }

  static double _cos(double x) {
    x = x % (2 * 3.141592653589793);
    double result = 1;
    double term = 1;
    for (int i = 1; i <= 20; i++) {
      term *= -x * x / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }

  static double _sin(double x) {
    x = x % (2 * 3.141592653589793);
    double result = x;
    double term = x;
    for (int i = 1; i <= 20; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  static double _pow(double base, double exp) {
    if (exp == 0) return 1;
    if (exp == 1) return base;
    if (base == 0) return 0;

    // 정수 지수
    if (exp == exp.truncateToDouble()) {
      double result = 1;
      int n = exp.abs().toInt();
      for (int i = 0; i < n; i++) {
        result *= base;
      }
      return exp < 0 ? 1 / result : result;
    }

    // 실수 지수: e^(exp * ln(base))
    return _exp(exp * _ln(base));
  }

  static double _exp(double x) {
    double result = 1;
    double term = 1;
    for (int i = 1; i <= 50; i++) {
      term *= x / i;
      result += term;
    }
    return result;
  }
}

/// 기상청 날씨 데이터
class KmaWeatherData {
  final DateTime time;
  final double temperature;
  final double humidity;
  final double dewPoint;
  final double? windSpeed;
  final double? precipitation;
  final String? precipitationType;
  final String? skyCondition;

  KmaWeatherData({
    required this.time,
    required this.temperature,
    required this.humidity,
    required this.dewPoint,
    this.windSpeed,
    this.precipitation,
    this.precipitationType,
    this.skyCondition,
  });

  /// WeatherData로 변환
  WeatherData toWeatherData() {
    return WeatherData(
      time: time,
      temperature: temperature,
      humidity: humidity,
      dewPoint: dewPoint,
      windSpeed: windSpeed,
      precipitation: precipitation,
      weatherCode: _getWeatherCode(),
    );
  }

  int? _getWeatherCode() {
    // 강수형태에 따른 WMO 코드 매핑
    switch (precipitationType) {
      case '비':
        return 61;
      case '비/눈':
        return 67;
      case '눈':
        return 71;
      case '소나기':
        return 80;
      case '빗방울':
        return 51;
      default:
        // 하늘상태에 따른 코드
        switch (skyCondition) {
          case '맑음':
            return 0;
          case '구름많음':
            return 2;
          case '흐림':
            return 3;
          default:
            return null;
        }
    }
  }
}

/// 격자 좌표
class GridCoordinate {
  final int nx;
  final int ny;

  GridCoordinate({required this.nx, required this.ny});

  @override
  String toString() => 'GridCoordinate(nx: $nx, ny: $ny)';
}

/// 기상청 API 예외
class KmaApiException implements Exception {
  final String message;
  final int? statusCode;

  KmaApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'KmaApiException: $message (code: $statusCode)';
}
