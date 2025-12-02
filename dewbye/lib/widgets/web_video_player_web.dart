// Web implementation
import 'package:flutter/material.dart';
// Web 전용 imports
import 'dart:ui_web' as ui_web show platformViewRegistry;
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
      _videoElement = html.VideoElement()
        ..src = widget.assetPath
        ..autoplay = true
        ..loop = true
        ..muted = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.opacity = widget.opacity.toString();

      // Platform view 등록
      // ignore: undefined_prefixed_name
      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int viewId) => _videoElement!,
      );

      debugPrint('Web 비디오 초기화 완료: ${widget.assetPath}');
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

