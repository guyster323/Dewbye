// Web implementation
import 'package:flutter/material.dart';
// Web 전용 imports
import 'dart:ui_web' as ui_web show platformViewRegistry;
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

class WebVideoPlayer extends StatefulWidget {
  final String assetPath;
  final double opacity;

  const WebVideoPlayer({
    super.key,
    required this.assetPath,
    this.opacity = 0.6,
  });

  @override
  State<WebVideoPlayer> createState() => _WebVideoPlayerState();
}

class _WebVideoPlayerState extends State<WebVideoPlayer> {
  late final String _viewType;
  html.VideoElement? _videoElement;

  @override
  void initState() {
    super.initState();
    _viewType = 'video-player-${DateTime.now().millisecondsSinceEpoch}';
    _initializeVideo();
  }

  void _initializeVideo() {
    try {
      // Flutter 웹 빌드에서 assets 경로는 'assets/assets/파일명' 형태로 변환됨
      // 전달받은 경로가 'assets/Intro.mp4' 형태이면 'assets/assets/Intro.mp4'로 변환
      String videoSrc = widget.assetPath;
      if (videoSrc.startsWith('assets/') && !videoSrc.startsWith('assets/assets/')) {
        videoSrc = 'assets/${widget.assetPath}';
      }
      
      _videoElement = html.VideoElement()
        ..src = videoSrc
        ..autoplay = true
        ..loop = true
        ..muted = false  // 소리 재생 활성화
        ..volume = 0.3   // 30% 볼륨
        ..setAttribute('playsinline', 'true')  // iOS Safari 지원
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.opacity = widget.opacity.toString();

      // 비디오 로드 이벤트 리스너 추가
      _videoElement!.onLoadedData.listen((_) {
        debugPrint('Web 비디오 로드 완료');
        _videoElement!.volume = 0.3;  // 볼륨 재확인
        _videoElement!.play().catchError((e) {
          // 자동재생이 차단된 경우 음소거 후 재생
          debugPrint('자동재생 차단, 음소거 후 재생: $e');
          _videoElement!.muted = true;
          _videoElement!.play();
        });
      });
      
      _videoElement!.onError.listen((event) {
        debugPrint('Web 비디오 로드 오류: ${_videoElement!.error?.message}');
      });

      // Platform view 등록
      // ignore: undefined_prefixed_name
      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int viewId) => _videoElement!,
      );

      debugPrint('Web 비디오 초기화 완료: $videoSrc');
    } catch (e) {
      debugPrint('Web 비디오 초기화 오류: $e');
    }
  }

  @override
  void dispose() {
    _videoElement?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}

