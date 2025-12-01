import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/analysis_provider.dart';
import '../widgets/charts/charts.dart';

class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _selectedDataIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analysisProvider = context.watch<AnalysisProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('분석 그래프'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.show_chart), text: '위험도'),
            Tab(icon: Icon(Icons.thermostat), text: '온습도'),
            Tab(icon: Icon(Icons.water_drop), text: '이슬점'),
            Tab(icon: Icon(Icons.timeline), text: '타임라인'),
          ],
        ),
      ),
      body: analysisProvider.results.isEmpty
          ? _buildEmptyState(theme)
          : Column(
              children: [
                // 현재 위험도 게이지
                if (_tabController.index != 3)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        RiskGauge(
                          riskScore: analysisProvider.currentRiskScore,
                          size: 120,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '현재 상태',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              RiskBar(
                                riskScore: analysisProvider.currentRiskScore,
                                height: 10,
                                showLabel: false,
                              ),
                              const SizedBox(height: 8),
                              if (analysisProvider.results.isNotEmpty)
                                Text(
                                  analysisProvider.results.first.recommendation,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                // 탭 콘텐츠
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRiskChart(theme, analysisProvider),
                      _buildTempHumidityChart(theme, analysisProvider),
                      _buildDewPointChart(theme, analysisProvider),
                      _buildTimeline(theme, analysisProvider),
                    ],
                  ),
                ),
                // 선택된 데이터 정보
                if (_selectedDataIndex != null &&
                    _selectedDataIndex! < analysisProvider.results.length)
                  _buildSelectedDataInfo(
                    theme,
                    analysisProvider.results[_selectedDataIndex!],
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
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/analysis'),
            icon: const Icon(Icons.analytics),
            label: const Text('분석하러 가기'),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskChart(ThemeData theme, AnalysisProvider provider) {
    final results = provider.results.reversed.toList();
    final dataPoints = results.map((r) {
      return ChartDataPoint(
        time: r.date,
        value: r.riskScore,
        label: r.riskLevel.label,
        color: AppTheme.getRiskColor(r.riskScore),
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: InteractiveLineChart(
            title: '결로 위험도 추이',
            dataPoints: dataPoints,
            minY: 0,
            maxY: 100,
            lineColor: theme.colorScheme.primary,
            yLabelFormatter: (value) => '${value.toStringAsFixed(0)}%',
            thresholdLines: [
              ThresholdLine(
                value: 75,
                color: AppTheme.riskCritical,
                label: '위험',
                isDashed: true,
              ),
              ThresholdLine(
                value: 50,
                color: AppTheme.riskHigh,
                label: '경고',
                isDashed: true,
              ),
              ThresholdLine(
                value: 25,
                color: AppTheme.riskMedium,
                label: '주의',
                isDashed: true,
              ),
            ],
            onPointTap: (index, point) {
              setState(() {
                _selectedDataIndex = results.length - 1 - index;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTempHumidityChart(ThemeData theme, AnalysisProvider provider) {
    final results = provider.results.reversed.toList();

    final tempPoints = results.map((r) {
      return ChartDataPoint(
        time: r.date,
        value: r.outdoorTemp,
      );
    }).toList();

    final humidityPoints = results.map((r) {
      return ChartDataPoint(
        time: r.date,
        value: r.outdoorHumidity,
      );
    }).toList();

    final indoorTempPoints = results.map((r) {
      return ChartDataPoint(
        time: r.date,
        value: r.indoorTemp,
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: MultiLineChart(
            title: '온도 및 습도 추이',
            series: [
              ChartSeries(
                name: '외기 온도 (°C)',
                dataPoints: tempPoints,
                color: Colors.orange,
              ),
              ChartSeries(
                name: '외기 습도 (%)',
                dataPoints: humidityPoints,
                color: Colors.blue,
              ),
              ChartSeries(
                name: '실내 온도 (°C)',
                dataPoints: indoorTempPoints,
                color: Colors.green,
                isDashed: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDewPointChart(ThemeData theme, AnalysisProvider provider) {
    final results = provider.results.reversed.toList();

    final dewPointPoints = results.map((r) {
      return ChartDataPoint(
        time: r.date,
        value: r.dewPoint,
      );
    }).toList();

    final indoorTempPoints = results.map((r) {
      return ChartDataPoint(
        time: r.date,
        value: r.indoorTemp,
      );
    }).toList();

    final outdoorTempPoints = results.map((r) {
      return ChartDataPoint(
        time: r.date,
        value: r.outdoorTemp,
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: MultiLineChart(
            title: '이슬점 분석',
            series: [
              ChartSeries(
                name: '이슬점 (°C)',
                dataPoints: dewPointPoints,
                color: AppTheme.riskHigh,
              ),
              ChartSeries(
                name: '실내 온도 (°C)',
                dataPoints: indoorTempPoints,
                color: AppTheme.riskLow,
                isDashed: true,
              ),
              ChartSeries(
                name: '외기 온도 (°C)',
                dataPoints: outdoorTempPoints,
                color: Colors.orange,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline(ThemeData theme, AnalysisProvider provider) {
    // 주요 이벤트만 필터링 (위험도 50% 이상 또는 급격한 변화)
    final events = <TimelineEvent>[];
    final results = provider.results;

    for (int i = 0; i < results.length; i++) {
      final result = results[i];

      // 위험도 높은 시점
      if (result.riskScore >= 50) {
        events.add(TimelineEvent.fromRiskScore(
          time: result.date,
          riskScore: result.riskScore,
          recommendation: result.recommendation,
          onTap: () {
            setState(() {
              _selectedDataIndex = i;
            });
          },
        ));
      }

      // 급격한 변화 감지
      if (i > 0) {
        final prevResult = results[i - 1];
        final riskChange = result.riskScore - prevResult.riskScore;
        if (riskChange.abs() >= 20) {
          events.add(TimelineEvent(
            time: result.date,
            title: riskChange > 0 ? '위험도 급상승' : '위험도 급감소',
            description:
                '${prevResult.riskScore.toStringAsFixed(0)}% → ${result.riskScore.toStringAsFixed(0)}%',
            type: riskChange > 0
                ? TimelineEventType.warning
                : TimelineEventType.success,
            badge: '${riskChange > 0 ? '+' : ''}${riskChange.toStringAsFixed(0)}%',
            onTap: () {
              setState(() {
                _selectedDataIndex = i;
              });
            },
          ));
        }
      }
    }

    // HVAC 모드 전환 이벤트 추가
    final modeTransitions = provider.getModeTransitions();
    for (final transition in modeTransitions) {
      events.add(TimelineEvent.hvacModeChange(
        time: transition.time,
        fromMode: transition.previousMode.name,
        toMode: transition.newMode.name,
        riskBefore: transition.riskBefore,
        riskAfter: transition.riskAfter,
      ));
    }

    // 결로 예측 이벤트 추가
    final condensationPrediction = provider.getCondensationPrediction();
    if (condensationPrediction != null) {
      final predictedTime = condensationPrediction.predictedTime;
      if (predictedTime != null) {
        events.add(TimelineEvent.condensationPrediction(
          time: predictedTime,
          probability: condensationPrediction.probability,
        ));
      }
    }

    // 시간순 정렬
    events.sort((a, b) => b.time.compareTo(a.time));

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '주요 이벤트가 없습니다',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '분석 기간 동안 위험도가 안정적이었습니다',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: EventTimeline(events: events),
    );
  }

  Widget _buildSelectedDataInfo(ThemeData theme, AnalysisResult result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                MiniRiskGauge(riskScore: result.riskScore),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${result.date.month}/${result.date.day} ${result.date.hour}:00',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        result.riskLevel.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.getRiskColor(result.riskScore),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _selectedDataIndex = null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.thermostat,
                  label: '외기',
                  value: '${result.outdoorTemp.toStringAsFixed(1)}°C',
                ),
                _InfoChip(
                  icon: Icons.water_drop,
                  label: '습도',
                  value: '${result.outdoorHumidity.toStringAsFixed(0)}%',
                ),
                _InfoChip(
                  icon: Icons.dew_point,
                  label: '이슬점',
                  value: '${result.dewPoint.toStringAsFixed(1)}°C',
                ),
                _InfoChip(
                  icon: Icons.home,
                  label: '실내',
                  value: '${result.indoorTemp.toStringAsFixed(1)}°C',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
