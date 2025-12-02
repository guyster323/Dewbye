import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:video_player/video_player.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/user_settings.dart';
import '../widgets/glassmorphism_container.dart';

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
  late UserSettings _userSettings;
  final _formKey = GlobalKey<FormState>();
  
  // 위치 정보
  bool _isLoadingLocation = false;
  String _locationDisplay = '현재 위치';

  @override
  void initState() {
    super.initState();
    _userSettings = UserSettings.defaultSettings;
    if (!kIsWeb) {
      // 모바일에서만 비디오 초기화
      _initializeVideo();
    }
    _checkAndRequestPermissions();
  }

  Future<void> _initializeVideo() async {
    if (kIsWeb) {
      // Web에서는 비디오 사용 안 함
      return;
    }
    try {
      _videoController = VideoPlayerController.asset('assets/Intro.mp4');
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.play();
      setState(() {
        _isVideoInitialized = true;
      });
    } catch (e) {
      debugPrint('비디오 초기화 오류: $e');
    }
  }

  Future<void> _checkAndRequestPermissions() async {
    setState(() {
      _checkingPermissions = true;
    });

    try {
      if (kIsWeb) {
        // Web에서는 브라우저 권한 사용 (자동 승인)
        _locationPermissionGranted = true;
        _storagePermissionGranted = true; // Web Storage 자동 사용
        // Web에서 위치 가져오기 시도 (브라우저가 직접 권한 요청)
        try {
          await _getCurrentLocation();
        } catch (e) {
          debugPrint('Web 위치 가져오기: $e');
          // 실패해도 계속 진행
        }
      } else {
        // 모바일: 위치 권한 확인 및 요청
        var locationStatus = await Permission.location.status;
        if (!locationStatus.isGranted) {
          locationStatus = await Permission.location.request();
        }
        _locationPermissionGranted = locationStatus.isGranted;

        // 저장소 권한 확인 및 요청 (Android 12 이하)
        if (await Permission.storage.isRestricted == false) {
          var storageStatus = await Permission.storage.status;
          if (!storageStatus.isGranted) {
            storageStatus = await Permission.storage.request();
          }
          _storagePermissionGranted = storageStatus.isGranted;
        } else {
          _storagePermissionGranted = true; // Android 13+에서는 필요 없음
        }

        // 위치 권한이 있으면 자동으로 현재 위치 가져오기
        if (_locationPermissionGranted) {
          await _getCurrentLocation();
        }
      }
    } catch (e) {
      debugPrint('권한 확인 오류: $e');
      if (kIsWeb) {
        // Web에서는 권한 오류가 있어도 계속 진행
        _locationPermissionGranted = true;
        _storagePermissionGranted = true;
      }
    } finally {
      setState(() {
        _checkingPermissions = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!_locationPermissionGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('위치 권한이 필요합니다')),
      );
      return;
    }

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String locationName = '현재 위치';
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        locationName = '${place.locality ?? ''} ${place.subLocality ?? ''}'.trim();
        if (locationName.isEmpty) {
          locationName = '현재 위치';
        }
      }

      setState(() {
        _userSettings = _userSettings.copyWith(
          latitude: position.latitude,
          longitude: position.longitude,
          locationName: locationName,
        );
        _locationDisplay = locationName;
      });
    } catch (e) {
      debugPrint('위치 가져오기 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('위치를 가져올 수 없습니다: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _selectLocation() async {
    // 위치 선택 화면으로 이동 (나중에 구현)
    final result = await Navigator.of(context).pushNamed('/location');
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _userSettings = _userSettings.copyWith(
          latitude: result['latitude'] as double?,
          longitude: result['longitude'] as double?,
          locationName: result['name'] as String?,
        );
        _locationDisplay = result['name'] as String? ?? '선택된 위치';
      });
    }
  }

  void _startAnalysis() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      if (_userSettings.latitude == null || _userSettings.longitude == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치를 설정해주세요')),
        );
        return;
      }

      // HomeScreen으로 이동하며 설정 전달
      Navigator.of(context).pushReplacementNamed(
        '/',
        arguments: _userSettings,
      );
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
          // 배경 - Web에서는 그라데이션, 모바일에서는 비디오
          if (kIsWeb)
            // Web: 그라데이션 배경
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade900.withValues(alpha: 0.8),
                      Colors.cyan.shade700.withValues(alpha: 0.6),
                      Colors.blue.shade800.withValues(alpha: 0.9),
                    ],
                  ),
                ),
              ),
            )
          else
            // Mobile: 비디오 배경 (투명도 60%)
            if (_isVideoInitialized && _videoController != null)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.6,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController!.value.size.width,
                      height: _videoController!.value.size.height,
                      child: VideoPlayer(_videoController!),
                    ),
                  ),
                ),
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
                    builder: (context) => Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
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
                          _isLoadingLocation ? '위치 확인 중...' : _locationDisplay,
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
                initialValue: _userSettings.buildingType,
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
    final allPermissionsGranted = _locationPermissionGranted && _storagePermissionGranted;
    final hasLocation = _userSettings.latitude != null && _userSettings.longitude != null;

    return ElevatedButton(
      onPressed: (allPermissionsGranted && hasLocation && !_checkingPermissions)
          ? _startAnalysis
          : null,
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
            : !allPermissionsGranted
                ? '권한을 허용해주세요'
                : !hasLocation
                    ? '위치를 설정해주세요'
                    : '분석 시작',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}



