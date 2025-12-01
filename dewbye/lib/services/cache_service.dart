import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/weather_data.dart';
import '../models/location.dart';

/// Hive 캐시 서비스
class CacheService {
  static const String _weatherBoxName = 'weather_cache';
  static const String _locationBoxName = 'saved_locations';
  static const String _settingsBoxName = 'app_settings';
  static const String _analysisBoxName = 'analysis_cache';

  Box? _weatherBox;
  Box? _locationBox;
  Box? _settingsBox;
  Box? _analysisBox;

  /// Hive 초기화
  static Future<void> initialize() async {
    await Hive.initFlutter();
  }

  /// 박스 열기
  Future<void> openBoxes() async {
    _weatherBox = await Hive.openBox(_weatherBoxName);
    _locationBox = await Hive.openBox(_locationBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _analysisBox = await Hive.openBox(_analysisBoxName);
  }

  /// 박스 닫기
  Future<void> closeBoxes() async {
    await _weatherBox?.close();
    await _locationBox?.close();
    await _settingsBox?.close();
    await _analysisBox?.close();
  }

  // ==================== 날씨 캐시 ====================

  /// 날씨 데이터 캐시 저장
  Future<void> cacheWeatherForecast(
    String locationKey,
    WeatherForecast forecast,
  ) async {
    final box = _weatherBox;
    if (box == null) return;

    await box.put(locationKey, jsonEncode(forecast.toJson()));
    await box.put('${locationKey}_timestamp', DateTime.now().toIso8601String());
  }

  /// 날씨 데이터 캐시 조회
  Future<WeatherForecast?> getCachedWeatherForecast(String locationKey) async {
    final box = _weatherBox;
    if (box == null) return null;

    final cached = box.get(locationKey);
    if (cached == null) return null;

    try {
      final json = jsonDecode(cached as String);
      return WeatherForecast.fromJson(json as Map<String, dynamic>);
    } catch (e) {
      // 캐시 데이터가 손상된 경우 삭제
      await box.delete(locationKey);
      return null;
    }
  }

  /// 날씨 캐시 유효성 검사 (기본 1시간)
  Future<bool> isWeatherCacheValid(
    String locationKey, {
    Duration maxAge = const Duration(hours: 1),
  }) async {
    final box = _weatherBox;
    if (box == null) return false;

    final timestampStr = box.get('${locationKey}_timestamp');
    if (timestampStr == null) return false;

    try {
      final timestamp = DateTime.parse(timestampStr as String);
      return DateTime.now().difference(timestamp) < maxAge;
    } catch (e) {
      return false;
    }
  }

  /// 위치 기반 캐시 키 생성
  String getLocationCacheKey(double latitude, double longitude) {
    // 소수점 2자리까지만 사용 (약 1km 정확도)
    final lat = latitude.toStringAsFixed(2);
    final lon = longitude.toStringAsFixed(2);
    return 'weather_${lat}_$lon';
  }

  /// 날씨 캐시 삭제
  Future<void> clearWeatherCache() async {
    await _weatherBox?.clear();
  }

  // ==================== 위치 저장 ====================

  /// 위치 저장
  Future<void> saveLocation(SavedLocation location) async {
    final box = _locationBox;
    if (box == null) return;

    final key = _getLocationKey(location.location);
    await box.put(key, jsonEncode(location.toJson()));
  }

  /// 저장된 위치 목록 조회
  Future<List<SavedLocation>> getSavedLocations() async {
    final box = _locationBox;
    if (box == null) return [];

    final List<SavedLocation> locations = [];
    for (final key in box.keys) {
      try {
        final json = jsonDecode(box.get(key) as String);
        locations.add(SavedLocation.fromJson(json as Map<String, dynamic>));
      } catch (e) {
        // 손상된 데이터 무시
      }
    }

    // 즐겨찾기 우선, 최근 저장순 정렬
    locations.sort((a, b) {
      if (a.isFavorite != b.isFavorite) {
        return a.isFavorite ? -1 : 1;
      }
      return b.savedAt.compareTo(a.savedAt);
    });

    return locations;
  }

  /// 위치 삭제
  Future<void> deleteLocation(GeoLocation location) async {
    final box = _locationBox;
    if (box == null) return;

    final key = _getLocationKey(location);
    await box.delete(key);
  }

  /// 즐겨찾기 위치 목록 조회
  Future<List<SavedLocation>> getFavoriteLocations() async {
    final locations = await getSavedLocations();
    return locations.where((l) => l.isFavorite).toList();
  }

  /// 위치 즐겨찾기 토글
  Future<void> toggleFavorite(GeoLocation location) async {
    final locations = await getSavedLocations();
    final index = locations.indexWhere(
      (l) => l.location == location,
    );

    if (index != -1) {
      final updated = locations[index].copyWith(
        isFavorite: !locations[index].isFavorite,
      );
      await saveLocation(updated);
    }
  }

  String _getLocationKey(GeoLocation location) {
    return 'loc_${location.latitude.toStringAsFixed(4)}_${location.longitude.toStringAsFixed(4)}';
  }

  // ==================== 앱 설정 ====================

  /// 설정 값 저장
  Future<void> setSetting(String key, dynamic value) async {
    final box = _settingsBox;
    if (box == null) return;

    if (value is Map || value is List) {
      await box.put(key, jsonEncode(value));
    } else {
      await box.put(key, value);
    }
  }

  /// 설정 값 조회
  T? getSetting<T>(String key, {T? defaultValue}) {
    final box = _settingsBox;
    if (box == null) return defaultValue;

    final value = box.get(key);
    if (value == null) return defaultValue;

    return value as T?;
  }

  /// 설정 값 조회 (JSON)
  Map<String, dynamic>? getSettingJson(String key) {
    final box = _settingsBox;
    if (box == null) return null;

    final value = box.get(key);
    if (value == null) return null;

    try {
      return jsonDecode(value as String) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// 테마 모드 저장
  Future<void> setDarkMode(bool isDark) async {
    await setSetting('dark_mode', isDark);
  }

  /// 테마 모드 조회
  bool getDarkMode() {
    return getSetting<bool>('dark_mode', defaultValue: false) ?? false;
  }

  /// 마지막 선택 위치 저장
  Future<void> setLastLocation(GeoLocation location) async {
    await setSetting('last_location', location.toJson());
  }

  /// 마지막 선택 위치 조회
  GeoLocation? getLastLocation() {
    final json = getSettingJson('last_location');
    if (json == null) return null;
    return GeoLocation.fromJson(json);
  }

  /// 알림 설정 저장 (기본)
  Future<void> setNotificationEnabled(bool enabled) async {
    await setSetting('notification_enabled', enabled);
  }

  /// 알림 설정 조회 (기본)
  bool getNotificationEnabled() {
    return getSetting<bool>('notification_enabled', defaultValue: true) ?? true;
  }

  /// 알림 설정 전체 저장
  Future<void> saveNotificationSettings(dynamic settings) async {
    await setSetting('notification_settings', settings.toJson());
  }

  /// 알림 설정 전체 조회
  Future<dynamic> getNotificationSettings() async {
    final json = getSettingJson('notification_settings');
    return json;
  }

  /// 기상청 API 키 저장
  Future<void> setKmaApiKey(String? apiKey) async {
    await setSetting('kma_api_key', apiKey);
  }

  /// 기상청 API 키 조회
  String? getKmaApiKey() {
    return getSetting<String>('kma_api_key');
  }

  // ==================== 분석 결과 캐시 ====================

  /// 분석 결과 저장
  Future<void> cacheAnalysisResults(
    String locationKey,
    List<Map<String, dynamic>> results,
  ) async {
    final box = _analysisBox;
    if (box == null) return;

    await box.put(locationKey, jsonEncode(results));
    await box.put('${locationKey}_timestamp', DateTime.now().toIso8601String());
  }

  /// 분석 결과 조회
  Future<List<Map<String, dynamic>>?> getCachedAnalysisResults(
    String locationKey,
  ) async {
    final box = _analysisBox;
    if (box == null) return null;

    final cached = box.get(locationKey);
    if (cached == null) return null;

    try {
      final list = jsonDecode(cached as String) as List;
      return list.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      return null;
    }
  }

  /// 분석 캐시 삭제
  Future<void> clearAnalysisCache() async {
    await _analysisBox?.clear();
  }

  // ==================== 전체 캐시 ====================

  /// 모든 캐시 삭제
  Future<void> clearAllCache() async {
    await clearWeatherCache();
    await clearAnalysisCache();
  }

  /// 캐시 크기 조회 (바이트)
  Future<int> getCacheSize() async {
    int size = 0;

    for (final box in [_weatherBox, _analysisBox]) {
      if (box != null) {
        for (final key in box.keys) {
          final value = box.get(key);
          if (value is String) {
            size += value.length * 2; // UTF-16
          }
        }
      }
    }

    return size;
  }

  /// 캐시 크기 포맷팅
  String formatCacheSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
