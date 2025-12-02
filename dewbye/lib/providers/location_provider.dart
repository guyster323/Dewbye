import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../models/location.dart';
import '../services/location_service.dart';
import '../services/cache_service.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService;
  final CacheService _cacheService;

  GeoLocation? _currentLocation;
  List<SavedLocation> _savedLocations = [];
  List<GeoLocation> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  LocationProvider({
    LocationService? locationService,
    CacheService? cacheService,
  })  : _locationService = locationService ?? LocationService(),
        _cacheService = cacheService ?? CacheService();

  GeoLocation? get currentLocation => _currentLocation;
  List<SavedLocation> get savedLocations => _savedLocations;
  List<GeoLocation> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 초기화
  Future<void> init() async {
    await _cacheService.openBoxes();
    await _loadSavedLocations();
    _loadLastLocation();
  }

  /// 마지막 위치 불러오기
  void _loadLastLocation() {
    _currentLocation = _cacheService.getLastLocation();
    if (_currentLocation != null) {
      notifyListeners();
    }
  }

  /// 저장된 위치 목록 불러오기
  Future<void> _loadSavedLocations() async {
    _savedLocations = await _cacheService.getSavedLocations();
    notifyListeners();
  }

  /// GPS로 현재 위치 가져오기
  Future<void> getCurrentLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final geoLocation = await _locationService.getCurrentGeoLocation();
      _currentLocation = geoLocation;
      await _cacheService.setLastLocation(geoLocation);
    } catch (e) {
      _error = e.toString();
      // 기본 위치 사용 (서울)
      _currentLocation = GeoLocation(
        latitude: AppConstants.defaultLatitude,
        longitude: AppConstants.defaultLongitude,
        name: '서울',
        country: '대한민국',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 위치 선택
  Future<void> selectLocation(GeoLocation location) async {
    _currentLocation = location;
    await _cacheService.setLastLocation(location);

    // 검색 결과 초기화
    _searchResults = [];
    notifyListeners();
  }

  /// 위치 검색
  Future<void> searchLocation(String query) async {
    // 공백 제거 후 빈 문자열 체크
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 검색어에서 불필요한 공백 제거하고 검색
      _searchResults = await _locationService.searchLocations(trimmedQuery);
    } catch (e) {
      _error = e.toString();
      _searchResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 검색 결과 초기화
  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  /// 위치 저장
  Future<void> saveLocation(GeoLocation location, {String? alias}) async {
    final savedLocation = SavedLocation(
      location: location,
      alias: alias,
    );
    await _cacheService.saveLocation(savedLocation);
    await _loadSavedLocations();
  }

  /// 위치 삭제
  Future<void> deleteLocation(GeoLocation location) async {
    await _cacheService.deleteLocation(location);
    await _loadSavedLocations();
  }

  /// 즐겨찾기 토글
  Future<void> toggleFavorite(GeoLocation location) async {
    await _cacheService.toggleFavorite(location);
    await _loadSavedLocations();
  }

  /// 한국 내 위치 여부 확인
  bool isCurrentLocationInKorea() {
    if (_currentLocation == null) return false;
    return _locationService.isInKorea(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
    );
  }

  /// 에러 초기화
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
