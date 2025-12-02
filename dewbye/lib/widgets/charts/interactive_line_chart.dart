import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// 인터랙티브 라인 차트 위젯
class InteractiveLineChart extends StatefulWidget {
  final List<ChartDataPoint> dataPoints;
  final String title;
  final String yAxisLabel;
  final String xAxisLabel;
  final double? minY;
  final double? maxY;
  final Color? lineColor;
  final Color? gradientStartColor;
  final Color? gradientEndColor;
  final bool showDots;
  final bool showArea;
  final bool showGrid;
  final List<ThresholdLine>? thresholdLines;
  final void Function(int index, ChartDataPoint point)? onPointTap;
  final String Function(DateTime)? xLabelFormatter;
  final String Function(double)? yLabelFormatter;

  const InteractiveLineChart({
    super.key,
    required this.dataPoints,
    this.title = '',
    this.yAxisLabel = '',
    this.xAxisLabel = '',
    this.minY,
    this.maxY,
    this.lineColor,
    this.gradientStartColor,
    this.gradientEndColor,
    this.showDots = false,
    this.showArea = true,
    this.showGrid = true,
    this.thresholdLines,
    this.onPointTap,
    this.xLabelFormatter,
    this.yLabelFormatter,
  });

  @override
  State<InteractiveLineChart> createState() => _InteractiveLineChartState();
}

class _InteractiveLineChartState extends State<InteractiveLineChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lineColor = widget.lineColor ?? theme.colorScheme.primary;

    if (widget.dataPoints.isEmpty) {
      return Center(
        child: Text(
          '데이터가 없습니다',
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    final spots = widget.dataPoints.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    // Y축 범위 계산
    final values = widget.dataPoints.map((p) => p.value).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final padding = (maxValue - minValue) * 0.1;
    final minY = widget.minY ?? (minValue - padding).clamp(0, double.infinity);
    final maxY = widget.maxY ?? (maxValue + padding);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              widget.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        Expanded(
          child: InteractiveViewer(
            minScale: 1.0,
            maxScale: 5.0,
            panEnabled: true,
            scaleEnabled: true,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: widget.showGrid,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: theme.dividerColor.withValues(alpha: 0.5),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: _buildTitlesData(theme, minY, maxY),
                borderData: FlBorderData(show: false),
                minY: minY,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: lineColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: widget.showDots || _selectedIndex != null,
                      getDotPainter: (spot, percent, barData, index) {
                        final isSelected = index == _selectedIndex;
                        return FlDotCirclePainter(
                          radius: isSelected ? 8 : 4,
                          color: isSelected
                              ? lineColor
                              : lineColor.withValues(alpha: 0.7),
                          strokeWidth: isSelected ? 3 : 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: widget.showArea
                        ? BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                widget.gradientStartColor ??
                                    lineColor.withValues(alpha: 0.4),
                                widget.gradientEndColor ??
                                    lineColor.withValues(alpha: 0.0),
                              ],
                            ),
                          )
                        : null,
                  ),
                ],
                extraLinesData: _buildExtraLines(theme),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchCallback: (event, response) {
                    if (event is FlTapUpEvent && response?.lineBarSpots != null) {
                      final touchedSpot = response!.lineBarSpots!.first;
                      final index = touchedSpot.x.toInt();
                      setState(() {
                        _selectedIndex = index;
                      });
                      widget.onPointTap?.call(index, widget.dataPoints[index]);
                    }
                  },
                  touchTooltipData: LineTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final point = widget.dataPoints[spot.x.toInt()];
                      final yLabel = widget.yLabelFormatter?.call(point.value) ??
                          point.value.toStringAsFixed(1);
                      final xLabel = widget.xLabelFormatter?.call(point.time) ??
                          '${point.time.hour}:00';
                        return LineTooltipItem(
                          '$xLabel\n$yLabel',
                          TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
              duration: const Duration(milliseconds: 300),
            ),
          ),
        ),
        if (_selectedIndex != null)
          _buildSelectedInfo(theme, widget.dataPoints[_selectedIndex!]),
      ],
    );
  }

  FlTitlesData _buildTitlesData(ThemeData theme, double minY, double maxY) {
    final dataPoints = widget.dataPoints;
    final interval = (dataPoints.length / 5).ceil().toDouble().clamp(1.0, 100.0);

    return FlTitlesData(
      leftTitles: AxisTitles(
        axisNameWidget: widget.yAxisLabel.isNotEmpty
            ? Text(widget.yAxisLabel, style: theme.textTheme.bodySmall)
            : null,
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 45,
          interval: (maxY - minY) / 4,
          getTitlesWidget: (value, meta) {
            final label =
                widget.yLabelFormatter?.call(value) ?? value.toStringAsFixed(0);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                label,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.right,
              ),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        axisNameWidget: widget.xAxisLabel.isNotEmpty
            ? Text(widget.xAxisLabel, style: theme.textTheme.bodySmall)
            : null,
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: interval,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= dataPoints.length) {
              return const SizedBox.shrink();
            }
            final point = dataPoints[index];
            final label = widget.xLabelFormatter?.call(point.time) ??
                '${point.time.hour}:00';
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                label,
                style: theme.textTheme.bodySmall,
              ),
            );
          },
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  ExtraLinesData _buildExtraLines(ThemeData theme) {
    if (widget.thresholdLines == null || widget.thresholdLines!.isEmpty) {
      return ExtraLinesData(horizontalLines: []);
    }

    return ExtraLinesData(
      horizontalLines: widget.thresholdLines!.map((threshold) {
        return HorizontalLine(
          y: threshold.value,
          color: threshold.color ?? theme.colorScheme.error,
          strokeWidth: 2,
          dashArray: threshold.isDashed ? [5, 5] : null,
          label: threshold.label != null
              ? HorizontalLineLabel(
                  show: true,
                  labelResolver: (_) => threshold.label!,
                  style: TextStyle(
                    color: threshold.color ?? theme.colorScheme.error,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        );
      }).toList(),
    );
  }

  Widget _buildSelectedInfo(ThemeData theme, ChartDataPoint point) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            '${point.time.month}/${point.time.day} ${point.time.hour}:${point.time.minute.toString().padLeft(2, '0')}',
            style: theme.textTheme.bodyMedium,
          ),
          const Spacer(),
          Text(
            widget.yLabelFormatter?.call(point.value) ??
                point.value.toStringAsFixed(1),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          if (point.label != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: point.color?.withValues(alpha: 0.2) ??
                    theme.colorScheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                point.label!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: point.color ?? theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 차트 데이터 포인트
class ChartDataPoint {
  final DateTime time;
  final double value;
  final String? label;
  final Color? color;
  final Map<String, dynamic>? metadata;

  const ChartDataPoint({
    required this.time,
    required this.value,
    this.label,
    this.color,
    this.metadata,
  });
}

/// 임계선
class ThresholdLine {
  final double value;
  final Color? color;
  final String? label;
  final bool isDashed;

  const ThresholdLine({
    required this.value,
    this.color,
    this.label,
    this.isDashed = true,
  });
}

/// 멀티 라인 차트 위젯
class MultiLineChart extends StatefulWidget {
  final List<ChartSeries> series;
  final String title;
  final double? minY;
  final double? maxY;
  final bool showGrid;
  final bool showLegend;
  final String Function(DateTime)? xLabelFormatter;
  final bool enableZoom;

  const MultiLineChart({
    super.key,
    required this.series,
    this.title = '',
    this.minY,
    this.maxY,
    this.showGrid = true,
    this.showLegend = true,
    this.xLabelFormatter,
    this.enableZoom = true,
  });

  @override
  State<MultiLineChart> createState() => _MultiLineChartState();
}

class _MultiLineChartState extends State<MultiLineChart> {
  final Set<int> _hiddenSeries = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.series.isEmpty ||
        widget.series.every((s) => s.dataPoints.isEmpty)) {
      return Center(
        child: Text(
          '데이터가 없습니다',
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    // 모든 시리즈의 값을 수집하여 Y축 범위 계산
    final allValues = widget.series
        .where((s) => !_hiddenSeries.contains(widget.series.indexOf(s)))
        .expand((s) => s.dataPoints.map((p) => p.value))
        .toList();

    if (allValues.isEmpty) {
      return Center(
        child: Text(
          '표시할 데이터가 없습니다',
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    final minValue = allValues.reduce((a, b) => a < b ? a : b);
    final maxValue = allValues.reduce((a, b) => a > b ? a : b);
    final padding = (maxValue - minValue) * 0.1;
    final minY = widget.minY ?? (minValue - padding).clamp(0, double.infinity);
    final maxY = widget.maxY ?? (maxValue + padding);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (widget.showLegend)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildLegend(theme),
          ),
        Expanded(
          child: InteractiveViewer(
            minScale: 1.0,
            maxScale: 5.0,
            panEnabled: true,
            scaleEnabled: true,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: widget.showGrid,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: theme.dividerColor.withValues(alpha: 0.5),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: _buildTitlesData(theme, minY, maxY),
                borderData: FlBorderData(show: false),
                minY: minY,
                maxY: maxY,
                lineBarsData: widget.series.asMap().entries.map((entry) {
                  final index = entry.key;
                  final series = entry.value;
                  final isHidden = _hiddenSeries.contains(index);

                  final spots = series.dataPoints.asMap().entries.map((e) {
                    return FlSpot(e.key.toDouble(), e.value.value);
                  }).toList();

                  return LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: isHidden
                        ? Colors.transparent
                        : series.color ?? theme.colorScheme.primary,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    dashArray: series.isDashed ? [5, 5] : null,
                  );
                }).toList(),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final seriesIndex = spot.barIndex;
                        if (_hiddenSeries.contains(seriesIndex)) {
                          return null;
                        }
                        final series = widget.series[seriesIndex];
                        final pointIndex = spot.x.toInt();
                        if (pointIndex >= series.dataPoints.length) return null;
                        final point = series.dataPoints[pointIndex];
                        return LineTooltipItem(
                          '${series.name}: ${point.value.toStringAsFixed(1)}',
                          TextStyle(
                            color: series.color ?? theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
              duration: const Duration(milliseconds: 300),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(ThemeData theme) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: widget.series.asMap().entries.map((entry) {
        final index = entry.key;
        final series = entry.value;
        final isHidden = _hiddenSeries.contains(index);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isHidden) {
                _hiddenSeries.remove(index);
              } else {
                _hiddenSeries.add(index);
              }
            });
          },
          child: Opacity(
            opacity: isHidden ? 0.4 : 1.0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 4,
                  decoration: BoxDecoration(
                    color: series.color ?? theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  series.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    decoration: isHidden ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  FlTitlesData _buildTitlesData(ThemeData theme, double minY, double maxY) {
    // 가장 긴 시리즈 기준으로 X축 라벨
    final longestSeries = widget.series
        .reduce((a, b) => a.dataPoints.length > b.dataPoints.length ? a : b);
    final dataPoints = longestSeries.dataPoints;
    final interval = (dataPoints.length / 5).ceil().toDouble().clamp(1.0, 100.0);

    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 45,
          interval: (maxY - minY) / 4,
          getTitlesWidget: (value, meta) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                value.toStringAsFixed(0),
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.right,
              ),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: interval,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= dataPoints.length) {
              return const SizedBox.shrink();
            }
            final point = dataPoints[index];
            final label = widget.xLabelFormatter?.call(point.time) ??
                '${point.time.hour}:00';
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                label,
                style: theme.textTheme.bodySmall,
              ),
            );
          },
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }
}

/// 차트 시리즈
class ChartSeries {
  final String name;
  final List<ChartDataPoint> dataPoints;
  final Color? color;
  final bool isDashed;

  const ChartSeries({
    required this.name,
    required this.dataPoints,
    this.color,
    this.isDashed = false,
  });
}
