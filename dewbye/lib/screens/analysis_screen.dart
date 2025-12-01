import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../config/theme.dart';
import '../providers/location_provider.dart';
import '../providers/analysis_provider.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locationProvider = context.watch<LocationProvider>();
    final analysisProvider = context.watch<AnalysisProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('상세 분석'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 위치 정보
            _buildSectionTitle(theme, '분석 위치'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(
                  locationProvider.currentLocation?.toString() ?? '위치 선택 필요',
                ),
                trailing: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/location'),
                  child: const Text('변경'),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 기간 선택
            _buildSectionTitle(theme, '분석 기간'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _DateSelector(
                        label: '시작일',
                        date: _startDate,
                        onTap: () => _selectDate(context, true),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Icon(Icons.arrow_forward),
                    ),
                    Expanded(
                      child: _DateSelector(
                        label: '종료일',
                        date: _endDate,
                        onTap: () => _selectDate(context, false),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 건물 타입 선택
            _buildSectionTitle(theme, '건물 타입'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: BuildingType.values.map((type) {
                    final isSelected = analysisProvider.buildingType == type;
                    return RadioListTile<BuildingType>(
                      value: type,
                      groupValue: analysisProvider.buildingType,
                      onChanged: (value) {
                        if (value != null) {
                          analysisProvider.setBuildingType(value);
                        }
                      },
                      title: Text(type.label),
                      subtitle: Text('기밀도: ${(type.airtightness * 100).toStringAsFixed(0)}%'),
                      secondary: Icon(
                        _getBuildingIcon(type),
                        color: isSelected ? theme.colorScheme.primary : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 실내 조건
            _buildSectionTitle(theme, '실내 조건'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSlider(
                      theme: theme,
                      label: '실내 온도',
                      value: analysisProvider.indoorTemp,
                      min: 15,
                      max: 30,
                      unit: '°C',
                      onChanged: (value) {
                        analysisProvider.setIndoorConditions(temp: value);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildSlider(
                      theme: theme,
                      label: '실내 습도',
                      value: analysisProvider.indoorHumidity,
                      min: 20,
                      max: 80,
                      unit: '%',
                      onChanged: (value) {
                        analysisProvider.setIndoorConditions(humidity: value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 분석 버튼
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: analysisProvider.isLoading ||
                        locationProvider.currentLocation == null
                    ? null
                    : () => _runAnalysis(context),
                child: analysisProvider.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '분석 시작',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // 분석 결과
            if (analysisProvider.results.isNotEmpty) ...[
              _buildSectionTitle(theme, '분석 결과'),
              _buildAnalysisResults(theme, analysisProvider),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSlider({
    required ThemeData theme,
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodyLarge),
            Text(
              '${value.toStringAsFixed(1)}$unit',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) * 2).toInt(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  IconData _getBuildingIcon(BuildingType type) {
    switch (type) {
      case BuildingType.oldHouse:
        return Icons.cottage;
      case BuildingType.standard:
        return Icons.home;
      case BuildingType.modern:
        return Icons.apartment;
      case BuildingType.passive:
        return Icons.eco;
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate = isStart ? _startDate : _endDate;
    final firstDate = DateTime.now().subtract(const Duration(days: 365));
    final lastDate = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  Future<void> _runAnalysis(BuildContext context) async {
    final locationProvider = context.read<LocationProvider>();
    final analysisProvider = context.read<AnalysisProvider>();

    if (locationProvider.currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('위치를 먼저 선택해주세요')),
      );
      return;
    }

    await analysisProvider.analyzeHistorical(
      latitude: locationProvider.currentLocation!.latitude,
      longitude: locationProvider.currentLocation!.longitude,
      startDate: _startDate,
      endDate: _endDate,
    );

    if (analysisProvider.error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('분석 실패: ${analysisProvider.error}')),
        );
      }
    }
  }

  Widget _buildAnalysisResults(ThemeData theme, AnalysisProvider provider) {
    // 요약 통계
    final results = provider.results;
    final avgRisk = results.map((r) => r.riskScore).reduce((a, b) => a + b) / results.length;
    final maxRisk = results.map((r) => r.riskScore).reduce((a, b) => a > b ? a : b);
    final highRiskCount = results.where((r) => r.riskScore >= 50).length;

    return Column(
      children: [
        // 요약 카드
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: '평균 위험도',
                    value: '${avgRisk.toStringAsFixed(1)}%',
                    color: AppTheme.getRiskColor(avgRisk),
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: '최대 위험도',
                    value: '${maxRisk.toStringAsFixed(1)}%',
                    color: AppTheme.getRiskColor(maxRisk),
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: '주의 필요',
                    value: '$highRiskCount회',
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 상세 결과 리스트
        ...results.take(10).map((result) {
          final riskColor = AppTheme.getRiskColor(result.riskScore);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    result.riskScore.toStringAsFixed(0),
                    style: TextStyle(
                      color: riskColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              title: Text(
                '${result.date.month}/${result.date.day} ${result.date.hour}:00',
              ),
              subtitle: Text(result.riskLevel.label),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailRow('외기 온도', '${result.outdoorTemp.toStringAsFixed(1)}°C'),
                      _DetailRow('외기 습도', '${result.outdoorHumidity.toStringAsFixed(1)}%'),
                      _DetailRow('이슬점', '${result.dewPoint.toStringAsFixed(1)}°C'),
                      _DetailRow('실내 온도', '${result.indoorTemp.toStringAsFixed(1)}°C'),
                      _DetailRow('실내 습도', '${result.indoorHumidity.toStringAsFixed(1)}%'),
                      const Divider(),
                      Text(
                        result.recommendation,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),

        // 더보기
        if (results.length > 10)
          TextButton(
            onPressed: () {
              // TODO: 전체 결과 보기
            },
            child: Text('${results.length - 10}개 더 보기'),
          ),
      ],
    );
  }
}

class _DateSelector extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateSelector({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${date.year}/${date.month}/${date.day}',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
