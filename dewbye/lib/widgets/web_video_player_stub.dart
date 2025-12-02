// Stub for non-web platforms
import 'package:flutter/material.dart';

class WebVideoPlayer extends StatelessWidget {
  final String assetPath;
  final double opacity;

  const WebVideoPlayer({
    super.key,
    required this.assetPath,
    this.opacity = 0.6,
  });

  @override
  Widget build(BuildContext context) {
    // Non-web platforms should not use this widget
    return const SizedBox.shrink();
  }
}


