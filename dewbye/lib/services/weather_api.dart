import 'package:dio/dio.dart';
import '../models/weather_data.dart';
import '../models/location.dart';

class WeatherApiService {
  static const String _archiveBaseUrl = 'https://archive-api.open-meteo.com/v1/archive';
  static const String _forecastBaseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String _geocodingBaseUrl = 'https://geocoding-api.open-meteo.com/v1/search';

  final Dio _dio;

  WeatherApiService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 30),
            ));

  // 과거 기상 데이터 조회 (Archive API)
  Future<WeatherForecast> getHistoricalWeather({
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _dio.get(
        _archiveBaseUrl,
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'start_date': _formatDate(startDate),
          'end_date': _formatDate(endDate),
          'hourly': [
            'temperature_2m',
            'relative_humidity_2m',
            'dew_point_2m',
            'precipitation',
            'weather_code',
            'surface_pressure',
            'wind_speed_10m',
          ].join(','),
          'timezone': 'auto',
        },
      );

      if (response.statusCode == 200) {
        return WeatherForecast.fromOpenMeteoResponse(response.data);
      } else {
        throw WeatherApiException(
          'API 요청 실패: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw WeatherApiException(
        _getDioErrorMessage(e),
        e.response?.statusCode,
      );
    }
  }

  // 현재 및 예보 데이터 조회 (Forecast API)
  Future<WeatherForecast> getForecastWeather({
    required double latitude,
    required double longitude,
    int forecastDays = 7,
    int pastDays = 0,
  }) async {
    try {
      final response = await _dio.get(
        _forecastBaseUrl,
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'hourly': [
            'temperature_2m',
            'relative_humidity_2m',
            'dew_point_2m',
            'precipitation',
            'weather_code',
            'surface_pressure',
            'wind_speed_10m',
          ].join(','),
          'forecast_days': forecastDays,
          'past_days': pastDays,
          'timezone': 'auto',
        },
      );

      if (response.statusCode == 200) {
        return WeatherForecast.fromOpenMeteoResponse(response.data);
      } else {
        throw WeatherApiException(
          'API 요청 실패: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw WeatherApiException(
        _getDioErrorMessage(e),
        e.response?.statusCode,
      );
    }
  }

  // 위치 검색 (Geocoding API)
  Future<GeocodingResult> searchLocation(String query, {int count = 10}) async {
    if (query.trim().isEmpty) {
      return GeocodingResult(results: []);
    }

    try {
      final response = await _dio.get(
        _geocodingBaseUrl,
        queryParameters: {
          'name': query,
          'count': count,
          'language': 'ko',
          'format': 'json',
        },
      );

      if (response.statusCode == 200) {
        return GeocodingResult.fromOpenMeteoResponse(response.data);
      } else {
        throw WeatherApiException(
          'Geocoding 요청 실패: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw WeatherApiException(
        _getDioErrorMessage(e),
        e.response?.statusCode,
      );
    }
  }

  // 역 지오코딩 (좌표 → 주소) - Open-Meteo는 지원 안함, 로컬에서 처리
  Future<GeoLocation?> reverseGeocode(double latitude, double longitude) async {
    // Open-Meteo는 역 지오코딩을 지원하지 않음
    // 좌표 기반으로 기본 위치 정보만 반환
    return GeoLocation(
      latitude: latitude,
      longitude: longitude,
      name: '현재 위치',
    );
  }

  // 날짜 포맷팅
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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

class WeatherApiException implements Exception {
  final String message;
  final int? statusCode;

  WeatherApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'WeatherApiException: $message (code: $statusCode)';
}
