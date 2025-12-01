import 'dart:math';
import 'package:flutter/material.dart';

class CondensationAnimation extends StatefulWidget {
  final double riskScore;
  final double size;
  final bool showLabel;

  const CondensationAnimation({
    super.key,
    required this.riskScore,
    this.size = 200,
    this.showLabel = true,
  });

  @override
  State<CondensationAnimation> createState() => _CondensationAnimationState();
}

class _CondensationAnimationState extends State<CondensationAnimation>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _dropletController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _dropletAnimation;

  final List<_WaterDroplet> _droplets = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _dropletController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _dropletAnimation = Tween<double>(begin: 0, end: 1).animate(_dropletController);

    _generateDroplets();

    _dropletController.addListener(() {
      if (_dropletController.value > 0.95) {
        _generateDroplets();
      }
    });
  }

  void _generateDroplets() {
    final dropletCount = (widget.riskScore / 20).ceil().clamp(1, 8);

    _droplets.clear();
    for (int i = 0; i < dropletCount; i++) {
      _droplets.add(_WaterDroplet(
        startX: _random.nextDouble() * 0.6 + 0.2,
        startY: _random.nextDouble() * 0.3,
        size: _random.nextDouble() * 8 + 4,
        speed: _random.nextDouble() * 0.3 + 0.7,
        delay: _random.nextDouble() * 0.5,
      ));
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _dropletController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CondensationAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.riskScore != oldWidget.riskScore) {
      _generateDroplets();
    }
  }

  Color _getRiskColor() {
    if (widget.riskScore < 25) return Colors.green;
    if (widget.riskScore < 50) return Colors.orange;
    if (widget.riskScore < 75) return Colors.deepOrange;
    return Colors.red;
  }

  String _getRiskLabel() {
    if (widget.riskScore < 25) return '안전';
    if (widget.riskScore < 50) return '주의';
    if (widget.riskScore < 75) return '경고';
    return '위험';
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor();

    return SizedBox(
      width: widget.size,
      height: widget.size + (widget.showLabel ? 60 : 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 애니메이션 영역
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: AnimatedBuilder(
              animation: Listenable.merge([_pulseAnimation, _dropletAnimation]),
              builder: (context, child) {
                return CustomPaint(
                  painter: _CondensationPainter(
                    riskScore: widget.riskScore,
                    riskColor: riskColor,
                    pulseValue: _pulseAnimation.value,
                    dropletValue: _dropletAnimation.value,
                    droplets: _droplets,
                  ),
                  child: Center(
                    child: ScaleTransition(
                      scale: _pulseAnimation,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${widget.riskScore.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: widget.size * 0.2,
                              fontWeight: FontWeight.bold,
                              color: riskColor,
                            ),
                          ),
                          Icon(
                            _getIcon(),
                            size: widget.size * 0.15,
                            color: riskColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 라벨
          if (widget.showLabel) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: riskColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: riskColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                _getRiskLabel(),
                style: TextStyle(
                  color: riskColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getIcon() {
    if (widget.riskScore < 25) return Icons.check_circle_outline;
    if (widget.riskScore < 50) return Icons.info_outline;
    if (widget.riskScore < 75) return Icons.warning_amber_outlined;
    return Icons.dangerous_outlined;
  }
}

class _WaterDroplet {
  final double startX;
  final double startY;
  final double size;
  final double speed;
  final double delay;

  _WaterDroplet({
    required this.startX,
    required this.startY,
    required this.size,
    required this.speed,
    required this.delay,
  });
}

class _CondensationPainter extends CustomPainter {
  final double riskScore;
  final Color riskColor;
  final double pulseValue;
  final double dropletValue;
  final List<_WaterDroplet> droplets;

  _CondensationPainter({
    required this.riskScore,
    required this.riskColor,
    required this.pulseValue,
    required this.dropletValue,
    required this.droplets,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    // 배경 원 (그라데이션)
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          riskColor.withValues(alpha: 0.1),
          riskColor.withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const [0.3, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.5));

    canvas.drawCircle(center, radius * 1.5, bgPaint);

    // 진행률 원
    final progressPaint = Paint()
      ..color = riskColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * (riskScore / 100),
      false,
      progressPaint,
    );

    // 배경 트랙
    final trackPaint = Paint()
      ..color = riskColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    canvas.drawCircle(center, radius, trackPaint);

    // 물방울 애니메이션 (위험도가 높을 때)
    if (riskScore >= 50) {
      for (final droplet in droplets) {
        final progress = ((dropletValue - droplet.delay) / droplet.speed).clamp(0.0, 1.0);
        if (progress <= 0) continue;

        final dropX = size.width * droplet.startX;
        final dropY = size.height * (droplet.startY + progress * 0.7);
        final opacity = progress < 0.8 ? 1.0 : (1.0 - progress) * 5;

        final dropPaint = Paint()
          ..color = Colors.lightBlue.withValues(alpha: opacity * 0.6)
          ..style = PaintingStyle.fill;

        // 물방울 모양
        final path = Path();
        final dropSize = droplet.size * (1 - progress * 0.3);
        path.moveTo(dropX, dropY - dropSize);
        path.quadraticBezierTo(
          dropX + dropSize,
          dropY,
          dropX,
          dropY + dropSize,
        );
        path.quadraticBezierTo(
          dropX - dropSize,
          dropY,
          dropX,
          dropY - dropSize,
        );

        canvas.drawPath(path, dropPaint);
      }
    }

    // 글로우 효과 (펄스)
    if (riskScore >= 75) {
      final glowPaint = Paint()
        ..color = riskColor.withValues(alpha: 0.2 * (pulseValue - 0.95) * 10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(center, radius * pulseValue, glowPaint);
    }
  }

  @override
  bool shouldRepaint(_CondensationPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.dropletValue != dropletValue ||
        oldDelegate.riskScore != riskScore;
  }
}

class WaterDropIcon extends StatefulWidget {
  final double size;
  final Color? color;
  final bool animate;

  const WaterDropIcon({
    super.key,
    this.size = 24,
    this.color,
    this.animate = true,
  });

  @override
  State<WaterDropIcon> createState() => _WaterDropIconState();
}

class _WaterDropIconState extends State<WaterDropIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _WaterDropPainter(
            color: color,
            animationValue: widget.animate ? _controller.value : 0.5,
          ),
        );
      },
    );
  }
}

class _WaterDropPainter extends CustomPainter {
  final Color color;
  final double animationValue;

  _WaterDropPainter({
    required this.color,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final dropHeight = size.height * 0.8;
    final dropWidth = size.width * 0.6;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(centerX, centerY - dropHeight / 2);
    path.quadraticBezierTo(
      centerX + dropWidth / 2,
      centerY + dropHeight * 0.2,
      centerX,
      centerY + dropHeight / 2,
    );
    path.quadraticBezierTo(
      centerX - dropWidth / 2,
      centerY + dropHeight * 0.2,
      centerX,
      centerY - dropHeight / 2,
    );

    canvas.drawPath(path, paint);

    // 하이라이트
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3 + animationValue * 0.2)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX - dropWidth * 0.15, centerY - dropHeight * 0.1),
        width: dropWidth * 0.2,
        height: dropHeight * 0.15,
      ),
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(_WaterDropPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color;
  }
}
