import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/constants.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final String? name;
  final String? address;
  final DateTime timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.name,
    this.address,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'name': name,
        'address': address,
        'timestamp': timestamp.toIso8601String(),
      };

  factory LocationData.fromJson(Map<String, dynamic> json) => LocationData(
        latitude: json['latitude'] as double,
        longitude: json['longitude'] as double,
        name: json['name'] as String?,
        address: json['address'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  @override
  String toString() => name ?? address ?? '$latitude, $longitude';
}

class LocationProvider extends ChangeNotifier {
  static const String _locationKey = 'current_location';
  static const String _historyKey = 'location_history';
  late Box _box;

  LocationData? _currentLocation;
  List<LocationData> _locationHistory = [];
  bool _isLoading = false;
  String? _error;

  LocationData? get currentLocation => _currentLocation;
  List<LocationData> get locationHistory => _locationHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    _box = await Hive.openBox('location');
    _loadSavedLocation();
    _loadLocationHistory();
  }

  void _loadSavedLocation() {
    final saved = _box.get(_locationKey);
    if (saved != null) {
      _currentLocation = LocationData.fromJson(Map<String, dynamic>.from(saved));
      notifyListeners();
    }
  }

  void _loadLocationHistory() {
    final history = _box.get(_historyKey);
    if (history != null) {
      _locationHistory = (history as List)
          .map((e) => LocationData.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      notifyListeners();
    }
  }

  Future<void> getCurrentLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('위치 권한이 거부되었습니다.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요.');
      }

      // 위치 서비스 확인
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('위치 서비스가 비활성화되어 있습니다.');
      }

      // 현재 위치 가져오기
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentLocation = LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        name: '현재 위치',
      );

      await _saveCurrentLocation();
      await _addToHistory(_currentLocation!);
    } catch (e) {
      _error = e.toString();
      // 기본 위치 사용 (서울)
      _currentLocation = LocationData(
        latitude: AppConstants.defaultLatitude,
        longitude: AppConstants.defaultLongitude,
        name: '서울',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setLocation(LocationData location) {
    _currentLocation = location;
    _saveCurrentLocation();
    _addToHistory(location);
    notifyListeners();
  }

  Future<void> _saveCurrentLocation() async {
    if (_currentLocation != null) {
      await _box.put(_locationKey, _currentLocation!.toJson());
    }
  }

  Future<void> _addToHistory(LocationData location) async {
    // 중복 제거
    _locationHistory.removeWhere(
      (l) => l.latitude == location.latitude && l.longitude == location.longitude,
    );
    // 앞에 추가
    _locationHistory.insert(0, location);
    // 최대 10개 유지
    if (_locationHistory.length > 10) {
      _locationHistory = _locationHistory.sublist(0, 10);
    }
    await _box.put(_historyKey, _locationHistory.map((l) => l.toJson()).toList());
  }

  void clearHistory() {
    _locationHistory.clear();
    _box.delete(_historyKey);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
