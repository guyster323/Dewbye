import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// 위험도 게이지 위젯 (애니메이션 포함)
class RiskGauge extends StatefulWidget {
  final double riskScore;
  final double size;
  final bool showLabel;
  final bool showAnimation;
  final Duration animationDuration;
  final String? customLabel;

  const RiskGauge({
    super.key,
    required this.riskScore,
    this.size = 200,
    this.showLabel = true,
    this.showAnimation = true,
    this.animationDuration = const Duration(milliseconds: 1500),
    this.customLabel,
  });

  @override
  State<RiskGauge> createState() => _RiskGaugeState();
}

class _RiskGaugeState extends State<RiskGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousScore = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _animation = Tween<double>(
      begin: 0,
      end: widget.riskScore,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    if (widget.showAnimation) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(RiskGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.riskScore != widget.riskScore) {
      _previousScore = oldWidget.riskScore;
      _animation = Tween<double>(
        begin: _previousScore,
        end: widget.riskScore,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final score =
            widget.showAnimation ? _animation.value : widget.riskScore;

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 배경 원호
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _GaugeBackgroundPainter(
                  backgroundColor:
                      theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              // 값 원호
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _GaugeValuePainter(
                  value: score / 100,
                  color: AppTheme.getRiskColor(score),
                ),
              ),
              // 중앙 텍스트
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${score.toStringAsFixed(0)}%',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getRiskColor(score),
                    ),
                  ),
                  if (widget.showLabel)
                    Text(
                      widget.customLabel ?? _getRiskLabel(score),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              // 눈금
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _GaugeTicksPainter(
                  tickColor: theme.dividerColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getRiskLabel(double score) {
    if (score >= 75) return '위험';
    if (score >= 50) return '경고';
    if (score >= 25) return '주의';
    return '안전';
  }
}

class _GaugeBackgroundPainter extends CustomPainter {
  final Color backgroundColor;

  _GaugeBackgroundPainter({required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;
    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GaugeValuePainter extends CustomPainter {
  final double value;
  final Color color;

  _GaugeValuePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;
    const startAngle = math.pi * 0.75;
    final sweepAngle = math.pi * 1.5 * value.clamp(0, 1);

    // 그라데이션 효과
    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: [
        color.withValues(alpha: 0.7),
        color,
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );

    // 끝점에 빛나는 효과
    if (value > 0) {
      final endAngle = startAngle + sweepAngle;
      final endPoint = Offset(
        center.dx + radius * math.cos(endAngle),
        center.dy + radius * math.sin(endAngle),
      );

      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(endPoint, size.width * 0.05, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugeValuePainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.color != color;
  }
}

class _GaugeTicksPainter extends CustomPainter {
  final Color tickColor;

  _GaugeTicksPainter({required this.tickColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final innerRadius = size.width * 0.32;
    final outerRadius = size.width * 0.35;
    const startAngle = math.pi * 0.75;

    final paint = Paint()
      ..color = tickColor
      ..strokeWidth = 1;

    // 주요 눈금 (0, 25, 50, 75, 100)
    for (int i = 0; i <= 4; i++) {
      final angle = startAngle + (math.pi * 1.5 * i / 4);
      final innerPoint = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );
      final outerPoint = Offset(
        center.dx + outerRadius * math.cos(angle),
        center.dy + outerRadius * math.sin(angle),
      );
      canvas.drawLine(innerPoint, outerPoint, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 미니 위험도 게이지 (리스트 아이템용)
class MiniRiskGauge extends StatelessWidget {
  final double riskScore;
  final double size;

  const MiniRiskGauge({
    super.key,
    required this.riskScore,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppTheme.getRiskColor(riskScore);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 배경 원
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.dividerColor,
                width: 3,
              ),
            ),
          ),
          // 값 표시 원호
          CustomPaint(
            size: Size(size, size),
            painter: _MiniGaugePainter(
              value: riskScore / 100,
              color: color,
            ),
          ),
          // 값 텍스트
          Text(
            riskScore.toStringAsFixed(0),
            style: TextStyle(
              fontSize: size * 0.3,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniGaugePainter extends CustomPainter {
  final double value;
  final Color color;

  _MiniGaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    const startAngle = -math.pi / 2;
    final sweepAngle = math.pi * 2 * value.clamp(0, 1);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniGaugePainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.color != color;
  }
}

/// 수평 위험도 바
class RiskBar extends StatefulWidget {
  final double riskScore;
  final double height;
  final bool showLabel;
  final bool showAnimation;

  const RiskBar({
    super.key,
    required this.riskScore,
    this.height = 12,
    this.showLabel = true,
    this.showAnimation = true,
  });

  @override
  State<RiskBar> createState() => _RiskBarState();
}

class _RiskBarState extends State<RiskBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _animation = Tween<double>(
      begin: 0,
      end: widget.riskScore,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    if (widget.showAnimation) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(RiskBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.riskScore != widget.riskScore) {
      _animation = Tween<double>(
        begin: oldWidget.riskScore,
        end: widget.riskScore,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final score =
            widget.showAnimation ? _animation.value : widget.riskScore;
        final color = AppTheme.getRiskColor(score);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showLabel)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '위험도',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      '${score.toStringAsFixed(1)}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(widget.height / 2),
              ),
              child: Stack(
                children: [
                  // 위험 구간 표시 (배경)
                  Row(
                    children: [
                      Expanded(
                        flex: 25,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.riskLow.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(widget.height / 2),
                              bottomLeft: Radius.circular(widget.height / 2),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 25,
                        child: Container(
                          color: AppTheme.riskMedium.withValues(alpha: 0.2),
                        ),
                      ),
                      Expanded(
                        flex: 25,
                        child: Container(
                          color: AppTheme.riskHigh.withValues(alpha: 0.2),
                        ),
                      ),
                      Expanded(
                        flex: 25,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.riskCritical.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(widget.height / 2),
                              bottomRight: Radius.circular(widget.height / 2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // 현재 값 바
                  FractionallySizedBox(
                    widthFactor: (score / 100).clamp(0, 1),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withValues(alpha: 0.8),
                            color,
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(widget.height / 2),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
