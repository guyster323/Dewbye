import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:video_player/video_player.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../config/constants.dart';
import '../models/user_settings.dart';
import '../widgets/glassmorphism_container.dart';
import '../widgets/web_video_player.dart';
import '../services/cache_service.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  
  // 권한 상태
  bool _locationPermissionGranted = false;
  bool _storagePermissionGranted = false;
  bool _checkingPermissions = true;

  // 사용자 설정
  UserSettings _userSettings = UserSettings.defaultSettings;
  final _formKey = GlobalKey<FormState>();
  
  // 위치 정보
  bool _isLoadingLocation = false;
  String _locationDisplay = '현재 위치';
  
  // 캐시 서비스
  final CacheService _cacheService = CacheService();

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _initializeSettings();
  }

  /// 설정 초기화 (저장된 설정 로드 후 권한 확인)
  Future<void> _initializeSettings() async {
    await _loadSavedSettings();
    await _checkAndRequestPermissions();
  }

  /// 저장된 설정 불러오기
  Future<void> _loadSavedSettings() async {
    try {
      await _cacheService.openBoxes();
      final savedSettings = _cacheService.getUserSettings();
      if (savedSettings != null && mounted) {
        setState(() {
          _userSettings = savedSettings;
          if (savedSettings.locationName != null) {
            _locationDisplay = savedSettings.locationName!;
          }
        });
      }
    } catch (e) {
      debugPrint('설정 로드 오류: $e');
    }
  }

  /// 설정 저장
  Future<void> _saveSettings() async {
    try {
      await _cacheService.openBoxes();
      await _cacheService.saveUserSettings(_userSettings);
    } catch (e) {
      debugPrint('설정 저장 오류: $e');
    }
  }

  Future<void> _initializeVideo() async {
    if (kIsWeb) {
      // Web: WebVideoPlayer 위젯 사용 (별도 위젯에서 처리)
      setState(() {
        _isVideoInitialized = true;
      });
    } else {
      // Mobile: video_player 사용
      try {
        _videoController = VideoPlayerController.asset('assets/Intro.mp4');
        await _videoController!.initialize();
        _videoController!.setLooping(true);
        _videoController!.setVolume(0.3); // 30% 볼륨
        _videoController!.play();
        setState(() {
          _isVideoInitialized = true;
        });
      } catch (e) {
        debugPrint('모바일 비디오 초기화 오류: $e');
      }
    }
  }

  Future<void> _checkAndRequestPermissions() async {
    if (!mounted) return;

    setState(() {
      _checkingPermissions = true;
    });

    try {
      // 타임아웃을 설정하여 권한 확인이 무한 로딩되지 않도록 함
      await Future.any([
        _doCheckPermissions(),
        Future.delayed(const Duration(seconds: 10), () {
          debugPrint('권한 확인 타임아웃');
        }),
      ]);
    } catch (e) {
      debugPrint('권한 확인 오류: $e');
    } finally {
      // 항상 로딩 상태 해제 및 기본값 설정
      if (mounted) {
        setState(() {
          _checkingPermissions = false;
          // 권한 확인이 완료되지 않은 경우 기본값으로 설정
          if (!_locationPermissionGranted && !_storagePermissionGranted) {
            _locationPermissionGranted = true;
            _storagePermissionGranted = true;
          }
        });
      }
    }
  }

  Future<void> _doCheckPermissions() async {
    if (kIsWeb) {
      // Web에서는 브라우저가 직접 권한을 관리함
      _storagePermissionGranted = true;

      // Web에서 위치 권한 상태 확인
      try {
        final permission = await Geolocator.checkPermission()
            .timeout(const Duration(seconds: 5));
        if (permission == LocationPermission.denied) {
          final requested = await Geolocator.requestPermission()
              .timeout(const Duration(seconds: 5));
          _locationPermissionGranted = requested == LocationPermission.whileInUse ||
              requested == LocationPermission.always;
        } else {
          _locationPermissionGranted = permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always;
        }
      } catch (e) {
        debugPrint('Web 위치 권한 확인 오류: $e');
        _locationPermissionGranted = true;
      }

      // 위치 권한이 있고 저장된 위치가 없을 때만 자동으로 현재 위치 가져오기
      if (_locationPermissionGranted &&
          (_userSettings.latitude == null || _userSettings.longitude == null)) {
        try {
          await _getCurrentLocation();
        } catch (e) {
          debugPrint('Web 위치 가져오기 실패: $e');
        }
      }
    } else {
      // 모바일: 위치 권한 확인 및 요청
      try {
        var locationStatus = await Permission.location.status
            .timeout(const Duration(seconds: 5));
        if (!locationStatus.isGranted) {
          locationStatus = await Permission.location.request()
              .timeout(const Duration(seconds: 5));
        }
        _locationPermissionGranted = locationStatus.isGranted;
      } catch (e) {
        debugPrint('위치 권한 확인 오류: $e');
        _locationPermissionGranted = true; // 오류 시 기본 허용
      }

      // 저장소 권한 확인 및 요청
      try {
        // Android 버전에 따라 다른 권한 요청
        // Android 13+ (API 33+): photos, videos 권한 사용
        // Android 12 이하: storage 권한 사용
        final sdkInt = await _getAndroidSdkVersion();

        if (sdkInt >= 33) {
          // Android 13+: 미디어 권한 요청
          final photosStatus = await Permission.photos.status
              .timeout(const Duration(seconds: 3));
          if (!photosStatus.isGranted) {
            final results = await [
              Permission.photos,
              Permission.videos,
            ].request().timeout(const Duration(seconds: 5));

            _storagePermissionGranted =
                results[Permission.photos]?.isGranted == true ||
                results[Permission.videos]?.isGranted == true;
          } else {
            _storagePermissionGranted = true;
          }
        } else {
          // Android 12 이하: 저장소 권한 요청
          var storageStatus = await Permission.storage.status
              .timeout(const Duration(seconds: 3));
          if (!storageStatus.isGranted) {
            storageStatus = await Permission.storage.request()
                .timeout(const Duration(seconds: 5));
          }
          _storagePermissionGranted = storageStatus.isGranted;
        }

        debugPrint('저장소 권한 상태: $_storagePermissionGranted (SDK: $sdkInt)');
      } catch (e) {
        debugPrint('저장소 권한 확인 오류: $e');
        // 오류 시에도 앱 사용 가능하도록 허용
        _storagePermissionGranted = true;
      }

      // 위치 권한이 있고 저장된 위치가 없을 때만 자동으로 현재 위치 가져오기
      if (_locationPermissionGranted &&
          (_userSettings.latitude == null || _userSettings.longitude == null)) {
        try {
          await _getCurrentLocation();
        } catch (e) {
          debugPrint('위치 가져오기 실패: $e');
        }
      }
    }
  }

  /// Android SDK 버전 가져오기
  Future<int> _getAndroidSdkVersion() async {
    if (kIsWeb) return 0;

    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        debugPrint('Android SDK 버전: ${androidInfo.version.sdkInt}');
        return androidInfo.version.sdkInt;
      }
      return 0; // iOS 등 다른 플랫폼
    } catch (e) {
      debugPrint('SDK 버전 확인 오류: $e');
      return 33; // 오류 시 Android 13으로 가정
    }
  }

  Future<void> _getCurrentLocation() async {
    final messenger = ScaffoldMessenger.of(context);

    if (!_locationPermissionGranted && !kIsWeb) {
      messenger.showSnackBar(
        const SnackBar(content: Text('위치 권한이 필요합니다')),
      );
      return;
    }

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // 웹에서 위치 서비스 활성화 확인
      if (kIsWeb) {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          throw Exception('위치 서비스가 비활성화되어 있습니다. 브라우저 설정에서 위치 서비스를 활성화해주세요.');
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // 웹에서 타임아웃 설정
      );

      String locationName = '현재 위치 (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';

      // Geocoding 시도 (실패해도 계속 진행)
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final locality = place.locality ?? '';
          final subLocality = place.subLocality ?? '';
          final administrativeArea = place.administrativeArea ?? '';

          if (locality.isNotEmpty || subLocality.isNotEmpty) {
            locationName = '$locality $subLocality'.trim();
          } else if (administrativeArea.isNotEmpty) {
            locationName = administrativeArea;
          }
        }
      } catch (geocodingError) {
        debugPrint('Geocoding 오류 (계속 진행): $geocodingError');
        // Geocoding 실패해도 좌표는 사용
      }

      if (mounted) {
        setState(() {
          _userSettings = _userSettings.copyWith(
            latitude: position.latitude,
            longitude: position.longitude,
            locationName: locationName,
          );
          _locationDisplay = locationName;
        });

        // 위치 설정 즉시 저장
        await _saveSettings();

        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('위치 설정 완료: $locationName'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('위치 가져오기 오류: $e');
      if (mounted) {
        final errorMessage = e.toString();
        String userMessage;

        if (errorMessage.contains('denied') || errorMessage.contains('거부')) {
          userMessage = '위치 권한이 거부되었습니다. 브라우저 설정에서 위치 권한을 허용하거나, 아래에서 위치를 수동으로 선택해주세요.';
        } else if (errorMessage.contains('timeout') || errorMessage.contains('시간 초과')) {
          userMessage = '위치를 가져오는 데 시간이 오래 걸립니다. 위치를 수동으로 선택해주세요.';
        } else if (errorMessage.contains('unavailable') || errorMessage.contains('사용 불가')) {
          userMessage = '위치 서비스를 사용할 수 없습니다. 위치를 수동으로 선택해주세요.';
        } else {
          userMessage = '위치를 가져올 수 없습니다. 위치를 수동으로 선택해주세요.';
        }

        messenger.showSnackBar(
          SnackBar(
            content: Text(userMessage),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: '위치 선택',
              textColor: Colors.white,
              onPressed: () {
                _selectLocation();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _selectLocation() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // 위치 선택 화면으로 이동
    final result = await navigator.pushNamed('/location');
    if (result != null && result is Map<String, dynamic>) {
      final latitude = result['latitude'] as double?;
      final longitude = result['longitude'] as double?;
      final name = result['name'] as String?;

      if (latitude != null && longitude != null && mounted) {
        final locationName = name ?? '선택된 위치';

        // 위치 설정 업데이트
        setState(() {
          _userSettings = _userSettings.copyWith(
            latitude: latitude,
            longitude: longitude,
            locationName: locationName,
          );
          _locationDisplay = locationName;
        });

        // 위치 설정 즉시 저장
        await _saveSettings();

        // UI 갱신 확인을 위한 피드백
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('위치가 설정되었습니다: $locationName'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  void _startAnalysis() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      if (_userSettings.latitude == null || _userSettings.longitude == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('위치를 설정해주세요')),
        );
        return;
      }

      // 설정 저장 후 화면 이동
      await _saveSettings();

      // HomeScreen으로 이동하며 설정 전달
      if (mounted) {
        navigator.pushReplacementNamed(
          '/',
          arguments: _userSettings,
        );
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경 비디오 (투명도 60%, 무한 반복)
          if (_isVideoInitialized)
            Positioned.fill(
              child: kIsWeb
                  ? const WebVideoPlayer(
                      assetPath: 'assets/Intro.mp4',
                      opacity: 0.6,
                    )
                  : _videoController != null
                      ? Opacity(
                          opacity: 0.6,
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _videoController!.value.size.width,
                              height: _videoController!.value.size.height,
                              child: VideoPlayer(_videoController!),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
            ),
          
          // 그라데이션 오버레이
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
          ),

          // 컨텐츠
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 로고 및 타이틀
                  const SizedBox(height: 20),
                  const Text(
                    'Dewbye',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '결로 및 누전 위험 분석',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // 권한 상태 카드
                  _buildPermissionCard(),
                  const SizedBox(height: 24),

                  // 설정 입력 카드
                  _buildSettingsCard(),
                  const SizedBox(height: 32),

                  // 시작 버튼
                  _buildStartButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard() {
    return GlassmorphismContainer(
      blur: 10,
      opacity: 0.2,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.security, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  '앱 권한 상태',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_checkingPermissions)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            else ...[
              _buildPermissionItem(
                '위치 접근',
                _locationPermissionGranted,
                Icons.location_on,
                onTap: _locationPermissionGranted ? null : _checkAndRequestPermissions,
              ),
              const SizedBox(height: 12),
              _buildPermissionItem(
                '저장소 접근',
                _storagePermissionGranted,
                Icons.storage,
                onTap: _storagePermissionGranted ? null : _checkAndRequestPermissions,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem(
    String title,
    bool granted,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: granted
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: granted ? Colors.green : Colors.red,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: granted ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            Icon(
              granted ? Icons.check_circle : Icons.error,
              color: granted ? Colors.green : Colors.red,
            ),
            if (!granted) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.touch_app,
                color: Colors.white70,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return GlassmorphismContainer(
      blur: 10,
      opacity: 0.2,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.settings, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    '분석 설정',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 위치 선택
              const Text(
                '위치',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _isLoadingLocation ? null : () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    useSafeArea: true,
                    builder: (context) => SafeArea(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 드래그 핸들
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 12),
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[600],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            ListTile(
                              leading: const Icon(Icons.my_location, color: Colors.white),
                              title: const Text(
                                '현재 위치 사용',
                                style: TextStyle(color: Colors.white),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _getCurrentLocation();
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.search, color: Colors.white),
                              title: const Text(
                                '위치 검색',
                                style: TextStyle(color: Colors.white),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _selectLocation();
                              },
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                child: Container(
                  key: ValueKey('location_${_userSettings.latitude}_${_userSettings.longitude}'),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isLoadingLocation ? Icons.hourglass_empty : Icons.location_on,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isLoadingLocation 
                              ? '위치 확인 중...' 
                              : (_userSettings.locationName != null 
                                  ? _userSettings.locationName! 
                                  : (_locationDisplay.isNotEmpty ? _locationDisplay : '위치를 선택하세요')),
                          key: ValueKey('location_text_${_userSettings.locationName}_${_userSettings.latitude}_${_userSettings.longitude}'),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 건물 타입
              const Text(
                '건물 타입',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<BuildingType>(
                // ignore: deprecated_member_use
                value: _userSettings.buildingType,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                dropdownColor: Colors.grey[900],
                style: const TextStyle(color: Colors.white, fontSize: 16),
                items: BuildingType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _userSettings = _userSettings.copyWith(
                        buildingType: value,
                      );
                    });
                    // 건물 타입 변경 시 저장
                    _saveSettings();
                  }
                },
              ),
              const SizedBox(height: 20),

              // 실내 온도
              const Text(
                '실내 온도 (°C)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _userSettings.indoorTemperature,
                      min: 10,
                      max: 30,
                      divisions: 40,
                      label: '${_userSettings.indoorTemperature.toStringAsFixed(1)}°C',
                      activeColor: Colors.blue,
                      inactiveColor: Colors.blue.withValues(alpha: 0.3),
                      onChanged: (value) {
                        setState(() {
                          _userSettings = _userSettings.copyWith(
                            indoorTemperature: value,
                          );
                        });
                        // 온도 변경 시 저장
                        _saveSettings();
                      },
                    ),
                  ),
                  Container(
                    width: 70,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_userSettings.indoorTemperature.toStringAsFixed(1)}°C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 실내 습도
              const Text(
                '실내 습도 (%)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _userSettings.indoorHumidity,
                      min: 20,
                      max: 80,
                      divisions: 60,
                      label: '${_userSettings.indoorHumidity.toStringAsFixed(1)}%',
                      activeColor: Colors.cyan,
                      inactiveColor: Colors.cyan.withValues(alpha: 0.3),
                      onChanged: (value) {
                        setState(() {
                          _userSettings = _userSettings.copyWith(
                            indoorHumidity: value,
                          );
                        });
                        // 습도 변경 시 저장
                        _saveSettings();
                      },
                    ),
                  ),
                  Container(
                    width: 70,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_userSettings.indoorHumidity.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    // 웹에서는 저장소 권한이 항상 허용됨
    final allPermissionsGranted = kIsWeb 
        ? true 
        : (_locationPermissionGranted && _storagePermissionGranted);
    final hasLocation = _userSettings.latitude != null && _userSettings.longitude != null;

    // 웹에서는 위치 권한이 없어도 수동으로 위치를 설정할 수 있으면 시작 가능
    final canStart = kIsWeb
        ? (hasLocation && !_checkingPermissions)
        : (allPermissionsGranted && hasLocation && !_checkingPermissions);

    return ElevatedButton(
      onPressed: canStart ? _startAnalysis : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        disabledBackgroundColor: Colors.grey,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 8,
      ),
      child: Text(
        _checkingPermissions
            ? '권한 확인 중...'
            : !hasLocation
                ? '위치를 설정해주세요'
                : (kIsWeb || allPermissionsGranted)
                    ? '분석 시작'
                    : '권한을 허용해주세요',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}



