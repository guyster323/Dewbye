import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';

/// 이벤트 타임라인 위젯
class EventTimeline extends StatelessWidget {
  final List<TimelineEvent> events;
  final bool showConnector;
  final ScrollController? scrollController;

  const EventTimeline({
    super.key,
    required this.events,
    this.showConnector = true,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              '이벤트가 없습니다',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: events.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final event = events[index];
        final isFirst = index == 0;
        final isLast = index == events.length - 1;

        return _TimelineItem(
          event: event,
          isFirst: isFirst,
          isLast: isLast,
          showConnector: showConnector,
        );
      },
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final TimelineEvent event;
  final bool isFirst;
  final bool isLast;
  final bool showConnector;

  const _TimelineItem({
    required this.event,
    required this.isFirst,
    required this.isLast,
    required this.showConnector,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = event.color ?? _getDefaultColor(event.type, theme);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타임라인 인디케이터
          SizedBox(
            width: 60,
            child: Column(
              children: [
                // 상단 연결선
                if (showConnector && !isFirst)
                  Container(
                    width: 2,
                    height: 12,
                    color: theme.dividerColor,
                  ),
                // 인디케이터
                _EventIndicator(
                  type: event.type,
                  color: color,
                  isHighlighted: event.isHighlighted,
                ),
                // 하단 연결선
                if (showConnector && !isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: theme.dividerColor,
                    ),
                  ),
              ],
            ),
          ),
          // 이벤트 카드
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                right: 16,
                bottom: 16,
              ),
              child: _EventCard(event: event, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDefaultColor(TimelineEventType type, ThemeData theme) {
    switch (type) {
      case TimelineEventType.warning:
        return AppTheme.riskHigh;
      case TimelineEventType.danger:
        return AppTheme.riskCritical;
      case TimelineEventType.info:
        return theme.colorScheme.primary;
      case TimelineEventType.success:
        return AppTheme.riskLow;
      case TimelineEventType.hvacChange:
        return Colors.orange;
      case TimelineEventType.condensation:
        return Colors.blue;
    }
  }
}

class _EventIndicator extends StatelessWidget {
  final TimelineEventType type;
  final Color color;
  final bool isHighlighted;

  const _EventIndicator({
    required this.type,
    required this.color,
    required this.isHighlighted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isHighlighted ? 28 : 24,
      height: isHighlighted ? 28 : 24,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: color,
          width: isHighlighted ? 3 : 2,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Icon(
        _getIcon(type),
        size: 14,
        color: color,
      ),
    );
  }

  IconData _getIcon(TimelineEventType type) {
    switch (type) {
      case TimelineEventType.warning:
        return Icons.warning_amber;
      case TimelineEventType.danger:
        return Icons.error;
      case TimelineEventType.info:
        return Icons.info;
      case TimelineEventType.success:
        return Icons.check;
      case TimelineEventType.hvacChange:
        return Icons.hvac;
      case TimelineEventType.condensation:
        return Icons.water_drop;
    }
  }
}

class _EventCard extends StatelessWidget {
  final TimelineEvent event;
  final Color color;

  const _EventCard({required this.event, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: event.isHighlighted
            ? color.withValues(alpha: 0.1)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: event.isHighlighted ? color : theme.dividerColor,
          width: event.isHighlighted ? 2 : 1,
        ),
        boxShadow: event.isHighlighted
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: event.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 시간 및 타입
                Row(
                  children: [
                    Text(
                      _formatTime(event.time),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    if (event.badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          event.badge!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // 제목
                Text(
                  event.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (event.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    event.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // 메트릭스
                if (event.metrics != null && event.metrics!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: event.metrics!.entries.map((entry) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${entry.key}:',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            entry.value,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

/// 타임라인 이벤트 타입
enum TimelineEventType {
  warning,
  danger,
  info,
  success,
  hvacChange,
  condensation,
}

/// 타임라인 이벤트 데이터
class TimelineEvent {
  final DateTime time;
  final String title;
  final String? description;
  final TimelineEventType type;
  final Color? color;
  final String? badge;
  final Map<String, String>? metrics;
  final bool isHighlighted;
  final VoidCallback? onTap;

  const TimelineEvent({
    required this.time,
    required this.title,
    this.description,
    this.type = TimelineEventType.info,
    this.color,
    this.badge,
    this.metrics,
    this.isHighlighted = false,
    this.onTap,
  });

  /// AnalysisResult에서 TimelineEvent 생성
  factory TimelineEvent.fromRiskScore({
    required DateTime time,
    required double riskScore,
    required String recommendation,
    VoidCallback? onTap,
  }) {
    final riskLevel = RiskLevel.fromScore(riskScore);
    TimelineEventType type;
    bool isHighlighted = false;

    switch (riskLevel) {
      case RiskLevel.safe:
        type = TimelineEventType.success;
        break;
      case RiskLevel.caution:
        type = TimelineEventType.info;
        break;
      case RiskLevel.warning:
        type = TimelineEventType.warning;
        isHighlighted = true;
        break;
      case RiskLevel.danger:
        type = TimelineEventType.danger;
        isHighlighted = true;
        break;
    }

    return TimelineEvent(
      time: time,
      title: riskLevel.label,
      description: recommendation,
      type: type,
      badge: '${riskScore.toStringAsFixed(0)}%',
      isHighlighted: isHighlighted,
      onTap: onTap,
    );
  }

  /// HVAC 모드 전환 이벤트
  factory TimelineEvent.hvacModeChange({
    required DateTime time,
    required String fromMode,
    required String toMode,
    double? riskBefore,
    double? riskAfter,
    VoidCallback? onTap,
  }) {
    return TimelineEvent(
      time: time,
      title: 'HVAC 모드 전환',
      description: '$fromMode → $toMode',
      type: TimelineEventType.hvacChange,
      metrics: {
        if (riskBefore != null) '전환 전': '${riskBefore.toStringAsFixed(0)}%',
        if (riskAfter != null) '전환 후': '${riskAfter.toStringAsFixed(0)}%',
      },
      onTap: onTap,
    );
  }

  /// 결로 예측 이벤트
  factory TimelineEvent.condensationPrediction({
    required DateTime time,
    required double probability,
    String? location,
    VoidCallback? onTap,
  }) {
    return TimelineEvent(
      time: time,
      title: '결로 발생 예측',
      description: location != null ? '예상 위치: $location' : null,
      type: TimelineEventType.condensation,
      badge: '${probability.toStringAsFixed(0)}%',
      isHighlighted: probability >= 70,
      onTap: onTap,
    );
  }
}

/// 그룹화된 타임라인 (날짜별)
class GroupedTimeline extends StatelessWidget {
  final Map<DateTime, List<TimelineEvent>> groupedEvents;

  const GroupedTimeline({
    super.key,
    required this.groupedEvents,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedDates = groupedEvents.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final events = groupedEvents[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _formatDate(date),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${events.length}개 이벤트',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // 이벤트 목록
            ...events.map((event) => _TimelineItem(
                  event: event,
                  isFirst: events.indexOf(event) == 0,
                  isLast: events.indexOf(event) == events.length - 1,
                  showConnector: true,
                )),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return '오늘';
    } else if (dateOnly == yesterday) {
      return '어제';
    } else {
      return '${date.month}월 ${date.day}일';
    }
  }
}
