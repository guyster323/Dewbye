import 'dart:async';
import 'package:flutter/material.dart';
import '../config/constants.dart';

class BackgroundSlideshow extends StatefulWidget {
  final List<BackgroundImage> images;
  final Duration interval;
  final Duration transitionDuration;
  final Widget child;
  final double opacity;
  final BoxFit fit;
  final bool showGradientOverlay;

  const BackgroundSlideshow({
    super.key,
    required this.images,
    required this.child,
    this.interval = AppConstants.slideshowInterval,
    this.transitionDuration = const Duration(milliseconds: 800),
    this.opacity = 0.3,
    this.fit = BoxFit.cover,
    this.showGradientOverlay = true,
  });

  @override
  State<BackgroundSlideshow> createState() => _BackgroundSlideshowState();
}

class _BackgroundSlideshowState extends State<BackgroundSlideshow> {
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.images.length > 1) {
      _startSlideshow();
    }
  }

  void _startSlideshow() {
    _timer = Timer.periodic(widget.interval, (timer) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % widget.images.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return widget.child;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // 배경 이미지
        AnimatedSwitcher(
          duration: widget.transitionDuration,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: _buildBackgroundImage(widget.images[_currentIndex]),
        ),

        // 그라데이션 오버레이
        if (widget.showGradientOverlay) _buildGradientOverlay(context),

        // 컨텐츠
        widget.child,
      ],
    );
  }

  Widget _buildBackgroundImage(BackgroundImage image) {
    Widget imageWidget;

    if (image.isAsset) {
      imageWidget = Image.asset(
        image.path,
        key: ValueKey(image.path),
        fit: widget.fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else if (image.isNetwork) {
      imageWidget = Image.network(
        image.path,
        key: ValueKey(image.path),
        fit: widget.fit,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else {
      imageWidget = _buildPlaceholder();
    }

    return Opacity(
      opacity: widget.opacity,
      child: imageWidget,
    );
  }

  Widget _buildPlaceholder() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1a1a2e),
                  const Color(0xFF16213e),
                  const Color(0xFF0f3460),
                ]
              : [
                  const Color(0xFFe3f2fd),
                  const Color(0xFFbbdefb),
                  const Color(0xFF90caf9),
                ],
        ),
      ),
    );
  }

  Widget _buildGradientOverlay(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.5),
                  Colors.black.withValues(alpha: 0.8),
                ]
              : [
                  Colors.white.withValues(alpha: 0.8),
                  Colors.white.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.4),
                  Colors.white.withValues(alpha: 0.9),
                ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
    );
  }
}

class BackgroundImage {
  final String path;
  final bool isAsset;
  final bool isNetwork;

  const BackgroundImage.asset(this.path)
      : isAsset = true,
        isNetwork = false;

  const BackgroundImage.network(this.path)
      : isAsset = false,
        isNetwork = true;
}

class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  final List<List<Color>> gradients;
  final Duration duration;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  const AnimatedGradientBackground({
    super.key,
    required this.child,
    required this.gradients,
    this.duration = const Duration(seconds: 5),
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % widget.gradients.length;
          });
          _controller.reset();
          _controller.forward();
        }
      });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.gradients.isEmpty) {
      return widget.child;
    }

    final currentColors = widget.gradients[_currentIndex];
    final nextColors =
        widget.gradients[(_currentIndex + 1) % widget.gradients.length];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: widget.begin,
              end: widget.end,
              colors: List.generate(
                currentColors.length,
                (index) => Color.lerp(
                  currentColors[index],
                  nextColors[index],
                  _controller.value,
                )!,
              ),
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class WeatherBackground extends StatelessWidget {
  final Widget child;
  final WeatherCondition condition;
  final bool animate;

  const WeatherBackground({
    super.key,
    required this.child,
    this.condition = WeatherCondition.clear,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 배경 그라데이션
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _getBackgroundColors(isDark),
            ),
          ),
        ),

        // 날씨 애니메이션 (향후 구현)
        if (animate) _buildWeatherAnimation(),

        // 오버레이
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                (isDark ? Colors.black : Colors.white).withValues(alpha: 0.5),
              ],
            ),
          ),
        ),

        // 컨텐츠
        child,
      ],
    );
  }

  List<Color> _getBackgroundColors(bool isDark) {
    switch (condition) {
      case WeatherCondition.clear:
        return isDark
            ? [const Color(0xFF0d1b2a), const Color(0xFF1b263b)]
            : [const Color(0xFF87ceeb), const Color(0xFFe0f4ff)];
      case WeatherCondition.cloudy:
        return isDark
            ? [const Color(0xFF2d3436), const Color(0xFF636e72)]
            : [const Color(0xFFbdc3c7), const Color(0xFFecf0f1)];
      case WeatherCondition.rainy:
        return isDark
            ? [const Color(0xFF2c3e50), const Color(0xFF34495e)]
            : [const Color(0xFF7f8c8d), const Color(0xFFbdc3c7)];
      case WeatherCondition.humid:
        return isDark
            ? [const Color(0xFF1a5276), const Color(0xFF2e86de)]
            : [const Color(0xFF74b9ff), const Color(0xFFdfe6e9)];
      case WeatherCondition.foggy:
        return isDark
            ? [const Color(0xFF4a4a4a), const Color(0xFF6b6b6b)]
            : [const Color(0xFFd5d5d5), const Color(0xFFf0f0f0)];
    }
  }

  Widget _buildWeatherAnimation() {
    // 향후 날씨별 파티클 애니메이션 구현
    return const SizedBox.shrink();
  }
}

enum WeatherCondition {
  clear,
  cloudy,
  rainy,
  humid,
  foggy,
}
