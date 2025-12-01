import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../providers/analysis_provider.dart';

/// 상세 분석 테이블 위젯
class AnalysisDataTable extends StatefulWidget {
  final List<AnalysisResult> results;
  final int initialRowsPerPage;
  final void Function(AnalysisResult)? onRowTap;
  final bool showSummary;

  const AnalysisDataTable({
    super.key,
    required this.results,
    this.initialRowsPerPage = 10,
    this.onRowTap,
    this.showSummary = true,
  });

  @override
  State<AnalysisDataTable> createState() => _AnalysisDataTableState();
}

class _AnalysisDataTableState extends State<AnalysisDataTable> {
  late int _rowsPerPage;
  int _sortColumnIndex = 0;
  bool _sortAscending = false;
  late List<AnalysisResult> _sortedResults;

  @override
  void initState() {
    super.initState();
    _rowsPerPage = widget.initialRowsPerPage;
    _sortedResults = List.from(widget.results);
    _sortResults();
  }

  @override
  void didUpdateWidget(AnalysisDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.results != widget.results) {
      _sortedResults = List.from(widget.results);
      _sortResults();
    }
  }

  void _sortResults() {
    _sortedResults.sort((a, b) {
      int compare;
      switch (_sortColumnIndex) {
        case 0:
          compare = a.date.compareTo(b.date);
          break;
        case 1:
          compare = a.riskScore.compareTo(b.riskScore);
          break;
        case 2:
          compare = a.outdoorTemp.compareTo(b.outdoorTemp);
          break;
        case 3:
          compare = a.outdoorHumidity.compareTo(b.outdoorHumidity);
          break;
        case 4:
          compare = a.dewPoint.compareTo(b.dewPoint);
          break;
        default:
          compare = 0;
      }
      return _sortAscending ? compare : -compare;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_chart_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '분석 데이터가 없습니다',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showSummary) _buildSummaryCards(theme),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: PaginatedDataTable(
              header: Text(
                '분석 결과 (${widget.results.length}건)',
                style: theme.textTheme.titleMedium,
              ),
              columns: [
                DataColumn(
                  label: const Text('시간'),
                  onSort: (columnIndex, ascending) {
                    setState(() {
                      _sortColumnIndex = columnIndex;
                      _sortAscending = ascending;
                      _sortResults();
                    });
                  },
                ),
                DataColumn(
                  label: const Text('위험도'),
                  numeric: true,
                  onSort: (columnIndex, ascending) {
                    setState(() {
                      _sortColumnIndex = columnIndex;
                      _sortAscending = ascending;
                      _sortResults();
                    });
                  },
                ),
                DataColumn(
                  label: const Text('외기온도'),
                  numeric: true,
                  onSort: (columnIndex, ascending) {
                    setState(() {
                      _sortColumnIndex = columnIndex;
                      _sortAscending = ascending;
                      _sortResults();
                    });
                  },
                ),
                DataColumn(
                  label: const Text('외기습도'),
                  numeric: true,
                  onSort: (columnIndex, ascending) {
                    setState(() {
                      _sortColumnIndex = columnIndex;
                      _sortAscending = ascending;
                      _sortResults();
                    });
                  },
                ),
                DataColumn(
                  label: const Text('이슬점'),
                  numeric: true,
                  onSort: (columnIndex, ascending) {
                    setState(() {
                      _sortColumnIndex = columnIndex;
                      _sortAscending = ascending;
                      _sortResults();
                    });
                  },
                ),
                const DataColumn(label: Text('상태')),
              ],
              source: _AnalysisDataSource(
                results: _sortedResults,
                onRowTap: widget.onRowTap,
              ),
              rowsPerPage: _rowsPerPage,
              availableRowsPerPage: const [5, 10, 25, 50],
              onRowsPerPageChanged: (value) {
                setState(() {
                  _rowsPerPage = value ?? _rowsPerPage;
                });
              },
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              showCheckboxColumn: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(ThemeData theme) {
    final results = widget.results;
    final avgRisk =
        results.map((r) => r.riskScore).reduce((a, b) => a + b) / results.length;
    final maxRisk =
        results.map((r) => r.riskScore).reduce((a, b) => a > b ? a : b);
    final minRisk =
        results.map((r) => r.riskScore).reduce((a, b) => a < b ? a : b);
    final highRiskCount = results.where((r) => r.riskScore >= 50).length;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: '평균 위험도',
            value: '${avgRisk.toStringAsFixed(1)}%',
            icon: Icons.analytics,
            color: AppTheme.getRiskColor(avgRisk),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            title: '최대 위험도',
            value: '${maxRisk.toStringAsFixed(1)}%',
            icon: Icons.arrow_upward,
            color: AppTheme.getRiskColor(maxRisk),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            title: '최소 위험도',
            value: '${minRisk.toStringAsFixed(1)}%',
            icon: Icons.arrow_downward,
            color: AppTheme.getRiskColor(minRisk),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            title: '주의 횟수',
            value: '$highRiskCount회',
            icon: Icons.warning_amber,
            color: theme.colorScheme.error,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisDataSource extends DataTableSource {
  final List<AnalysisResult> results;
  final void Function(AnalysisResult)? onRowTap;

  _AnalysisDataSource({
    required this.results,
    this.onRowTap,
  });

  @override
  DataRow getRow(int index) {
    final result = results[index];
    final riskColor = AppTheme.getRiskColor(result.riskScore);

    return DataRow.byIndex(
      index: index,
      onSelectChanged: onRowTap != null ? (_) => onRowTap!(result) : null,
      cells: [
        DataCell(Text(
          '${result.date.month}/${result.date.day} ${result.date.hour}:00',
        )),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${result.riskScore.toStringAsFixed(1)}%',
              style: TextStyle(
                color: riskColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        DataCell(Text('${result.outdoorTemp.toStringAsFixed(1)}°C')),
        DataCell(Text('${result.outdoorHumidity.toStringAsFixed(1)}%')),
        DataCell(Text('${result.dewPoint.toStringAsFixed(1)}°C')),
        DataCell(
          Chip(
            label: Text(
              result.riskLevel.label,
              style: TextStyle(
                fontSize: 12,
                color: riskColor,
              ),
            ),
            backgroundColor: riskColor.withValues(alpha: 0.1),
            side: BorderSide.none,
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => results.length;

  @override
  int get selectedRowCount => 0;
}

/// 간단한 분석 리스트 위젯 (카드 형식)
class AnalysisCardList extends StatelessWidget {
  final List<AnalysisResult> results;
  final int? maxItems;
  final void Function(AnalysisResult)? onItemTap;
  final VoidCallback? onSeeAll;

  const AnalysisCardList({
    super.key,
    required this.results,
    this.maxItems,
    this.onItemTap,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayResults =
        maxItems != null ? results.take(maxItems!).toList() : results;

    if (results.isEmpty) {
      return Center(
        child: Text(
          '분석 결과가 없습니다',
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    return Column(
      children: [
        ...displayResults.map((result) => _AnalysisCard(
              result: result,
              onTap: onItemTap != null ? () => onItemTap!(result) : null,
            )),
        if (maxItems != null && results.length > maxItems!)
          TextButton.icon(
            onPressed: onSeeAll,
            icon: const Icon(Icons.expand_more),
            label: Text('${results.length - maxItems!}개 더 보기'),
          ),
      ],
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final AnalysisResult result;
  final VoidCallback? onTap;

  const _AnalysisCard({
    required this.result,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final riskColor = AppTheme.getRiskColor(result.riskScore);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 위험도 인디케이터
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      result.riskScore.toStringAsFixed(0),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: riskColor,
                      ),
                    ),
                    Text(
                      '%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: riskColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // 상세 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${result.date.month}/${result.date.day} ${result.date.hour}:00',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: riskColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            result.riskLevel.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: riskColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _MetricChip(
                          icon: Icons.thermostat,
                          label: '${result.outdoorTemp.toStringAsFixed(1)}°C',
                        ),
                        const SizedBox(width: 8),
                        _MetricChip(
                          icon: Icons.water_drop,
                          label: '${result.outdoorHumidity.toStringAsFixed(0)}%',
                        ),
                        const SizedBox(width: 8),
                        _MetricChip(
                          icon: Icons.dew_point,
                          label: '${result.dewPoint.toStringAsFixed(1)}°C',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 화살표
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// 일별 요약 테이블
class DailySummaryTable extends StatelessWidget {
  final Map<DateTime, DailySummary> summaries;

  const DailySummaryTable({
    super.key,
    required this.summaries,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedDates = summaries.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    if (summaries.isEmpty) {
      return Center(
        child: Text(
          '요약 데이터가 없습니다',
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    return ListView.builder(
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final summary = summaries[date]!;
        final maxRiskColor = AppTheme.getRiskColor(summary.maxRiskScore);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 날짜
                SizedBox(
                  width: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${date.month}/${date.day}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getWeekday(date.weekday),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // 위험도 게이지
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '최대 ${summary.maxRiskScore.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: maxRiskColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '평균 ${summary.avgRiskScore.toStringAsFixed(0)}%',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: summary.maxRiskScore / 100,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(maxRiskColor),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // 주의 시간
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: summary.highRiskHours > 0
                        ? theme.colorScheme.errorContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${summary.highRiskHours}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: summary.highRiskHours > 0
                              ? theme.colorScheme.onErrorContainer
                              : null,
                        ),
                      ),
                      Text(
                        '시간',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: summary.highRiskHours > 0
                              ? theme.colorScheme.onErrorContainer
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getWeekday(int weekday) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays[weekday - 1];
  }
}
