import 'package:geolocator/geolocator.dart';
import '../models/location.dart';
import 'weather_api.dart';
import 'kma_api.dart';

/// GPS 위치 서비스
class LocationService {
  final WeatherApiService _weatherApi;

  LocationService({WeatherApiService? weatherApi})
      : _weatherApi = weatherApi ?? WeatherApiService();

  /// 위치 권한 확인
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// 위치 권한 요청
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// 위치 서비스 활성화 여부 확인
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// 현재 위치 가져오기
  Future<Position> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    // 서비스 활성화 확인
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceException('위치 서비스가 비활성화되어 있습니다');
    }

    // 권한 확인
    LocationPermission permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationServiceException('위치 권한이 거부되었습니다');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationServiceException(
        '위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요.',
      );
    }

    // 현재 위치 가져오기
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: timeout,
      );
    } catch (e) {
      throw LocationServiceException('위치를 가져올 수 없습니다: $e');
    }
  }

  /// 위치를 GeoLocation으로 변환
  Future<GeoLocation> positionToGeoLocation(Position position) async {
    // Open-Meteo의 역 지오코딩은 지원하지 않으므로
    // 기본 위치 정보만 반환
    return GeoLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      name: '현재 위치',
    );
  }

  /// 현재 위치를 GeoLocation으로 가져오기
  Future<GeoLocation> getCurrentGeoLocation() async {
    final position = await getCurrentPosition();
    return await positionToGeoLocation(position);
  }

  /// 위치 스트림 (연속 위치 업데이트)
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 100,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// 두 위치 간 거리 계산 (미터)
  double calculateDistance(
    double startLat,
    double startLon,
    double endLat,
    double endLon,
  ) {
    return Geolocator.distanceBetween(startLat, startLon, endLat, endLon);
  }

  /// 위치 검색 (Open-Meteo Geocoding)
  Future<List<GeoLocation>> searchLocations(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      final result = await _weatherApi.searchLocation(query, count: 10);
      return result.results;
    } catch (e) {
      throw LocationServiceException('위치 검색 실패: $e');
    }
  }

  /// 위경도를 기상청 격자 좌표로 변환
  GridCoordinate toKmaGrid(double latitude, double longitude) {
    return KmaApiService.latLonToGrid(latitude, longitude);
  }

  /// 한국 내 위치인지 확인
  bool isInKorea(double latitude, double longitude) {
    // 한국 영역 대략적인 범위
    // 위도: 33° ~ 39°, 경도: 124° ~ 132°
    return latitude >= 33.0 &&
        latitude <= 39.0 &&
        longitude >= 124.0 &&
        longitude <= 132.0;
  }

  /// 위치 설정 열기 (권한 거부 시)
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// 앱 설정 열기 (권한 영구 거부 시)
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }
}

/// 위치 서비스 예외
class LocationServiceException implements Exception {
  final String message;

  LocationServiceException(this.message);

  @override
  String toString() => 'LocationServiceException: $message';
}
