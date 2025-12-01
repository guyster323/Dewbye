import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/theme.dart';
import '../providers/analysis_provider.dart';

class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  int _selectedChartType = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analysisProvider = context.watch<AnalysisProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('그래프'),
      ),
      body: analysisProvider.results.isEmpty
          ? _buildEmptyState(theme)
          : Column(
              children: [
                // 차트 타입 선택
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(
                        value: 0,
                        label: Text('위험도'),
                        icon: Icon(Icons.warning),
                      ),
                      ButtonSegment(
                        value: 1,
                        label: Text('온습도'),
                        icon: Icon(Icons.thermostat),
                      ),
                      ButtonSegment(
                        value: 2,
                        label: Text('이슬점'),
                        icon: Icon(Icons.water_drop),
                      ),
                    ],
                    selected: {_selectedChartType},
                    onSelectionChanged: (Set<int> selection) {
                      setState(() {
                        _selectedChartType = selection.first;
                      });
                    },
                  ),
                ),

                // 차트
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildChart(theme, analysisProvider),
                      ),
                    ),
                  ),
                ),

                // 범례
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildLegend(theme),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '표시할 데이터가 없습니다',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '분석을 먼저 실행해주세요',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/analysis'),
            child: const Text('분석하러 가기'),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(ThemeData theme, AnalysisProvider provider) {
    switch (_selectedChartType) {
      case 0:
        return _buildRiskChart(theme, provider);
      case 1:
        return _buildTempHumidityChart(theme, provider);
      case 2:
        return _buildDewPointChart(theme, provider);
      default:
        return _buildRiskChart(theme, provider);
    }
  }

  Widget _buildRiskChart(ThemeData theme, AnalysisProvider provider) {
    final results = provider.results;
    final spots = results.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.riskScore);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.dividerColor,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 25,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: theme.textTheme.bodySmall,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (results.length / 5).ceilToDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < results.length) {
                  final date = results[index].date;
                  return Text(
                    '${date.hour}:00',
                    style: theme.textTheme.bodySmall,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.3),
                  theme.colorScheme.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final result = results[spot.x.toInt()];
                return LineTooltipItem(
                  '${result.date.hour}:00\n${result.riskScore.toStringAsFixed(1)}%',
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
    );
  }

  Widget _buildTempHumidityChart(ThemeData theme, AnalysisProvider provider) {
    final results = provider.results;
    final tempSpots = results.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.outdoorTemp);
    }).toList();
    final humiditySpots = results.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.outdoorHumidity);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.dividerColor,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}',
                  style: theme.textTheme.bodySmall,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (results.length / 5).ceilToDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < results.length) {
                  final date = results[index].date;
                  return Text(
                    '${date.hour}:00',
                    style: theme.textTheme.bodySmall,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: tempSpots,
            isCurved: true,
            color: Colors.orange,
            barWidth: 3,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: humiditySpots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildDewPointChart(ThemeData theme, AnalysisProvider provider) {
    final results = provider.results;
    final dewPointSpots = results.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.dewPoint);
    }).toList();
    final indoorTempSpots = results.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.indoorTemp);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.dividerColor,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}°C',
                  style: theme.textTheme.bodySmall,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (results.length / 5).ceilToDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < results.length) {
                  final date = results[index].date;
                  return Text(
                    '${date.hour}:00',
                    style: theme.textTheme.bodySmall,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: dewPointSpots,
            isCurved: true,
            color: AppTheme.riskHigh,
            barWidth: 3,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: indoorTempSpots,
            isCurved: true,
            color: AppTheme.riskLow,
            barWidth: 3,
            dashArray: [5, 5],
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(ThemeData theme) {
    List<_LegendItem> items;

    switch (_selectedChartType) {
      case 0:
        items = [
          _LegendItem(color: theme.colorScheme.primary, label: '결로 위험도 (%)'),
        ];
        break;
      case 1:
        items = [
          const _LegendItem(color: Colors.orange, label: '외기 온도 (°C)'),
          const _LegendItem(color: Colors.blue, label: '외기 습도 (%)'),
        ];
        break;
      case 2:
        items = [
          const _LegendItem(color: AppTheme.riskHigh, label: '이슬점 (°C)'),
          const _LegendItem(color: AppTheme.riskLow, label: '실내 온도 (°C)'),
        ];
        break;
      default:
        items = [];
    }

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 4,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(item.label, style: theme.textTheme.bodySmall),
          ],
        );
      }).toList(),
    );
  }
}

class _LegendItem {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});
}
