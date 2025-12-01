import 'package:flutter/material.dart';
import '../config/constants.dart';

/// 알림 서비스 (로컬 알림)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _initialized = false;
  final List<NotificationListener> _listeners = [];

  /// 초기화
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
  }

  /// 리스너 등록
  void addListener(NotificationListener listener) {
    _listeners.add(listener);
  }

  /// 리스너 제거
  void removeListener(NotificationListener listener) {
    _listeners.remove(listener);
  }

  /// 위험도 기반 알림 체크
  RiskNotification? checkRiskLevel(double riskScore, {DateTime? time}) {
    final level = RiskLevel.fromScore(riskScore);
    final now = time ?? DateTime.now();

    switch (level) {
      case RiskLevel.danger:
        return RiskNotification(
          id: 'danger_${now.millisecondsSinceEpoch}',
          title: '결로 위험 경고',
          body: '현재 결로 위험도가 ${riskScore.toStringAsFixed(0)}%입니다. 즉시 환기 또는 제습이 필요합니다.',
          level: level,
          riskScore: riskScore,
          time: now,
          priority: NotificationPriority.high,
        );
      case RiskLevel.warning:
        return RiskNotification(
          id: 'warning_${now.millisecondsSinceEpoch}',
          title: '결로 주의',
          body: '결로 위험도가 ${riskScore.toStringAsFixed(0)}%로 상승했습니다. 습도 관리가 필요합니다.',
          level: level,
          riskScore: riskScore,
          time: now,
          priority: NotificationPriority.medium,
        );
      case RiskLevel.caution:
        return RiskNotification(
          id: 'caution_${now.millisecondsSinceEpoch}',
          title: '결로 모니터링',
          body: '결로 위험도가 ${riskScore.toStringAsFixed(0)}%입니다. 상황을 모니터링하세요.',
          level: level,
          riskScore: riskScore,
          time: now,
          priority: NotificationPriority.low,
        );
      case RiskLevel.safe:
        return null; // 안전 수준에서는 알림 없음
    }
  }

  /// HVAC 모드 전환 알림
  RiskNotification createHvacModeNotification({
    required String fromMode,
    required String toMode,
    required DateTime time,
    double? riskChange,
  }) {
    String body = 'HVAC가 $fromMode에서 $toMode 모드로 전환되었습니다.';
    if (riskChange != null) {
      final changeText = riskChange > 0 ? '+${riskChange.toStringAsFixed(0)}' : riskChange.toStringAsFixed(0);
      body += ' 위험도 변화: $changeText%';
    }

    return RiskNotification(
      id: 'hvac_${time.millisecondsSinceEpoch}',
      title: 'HVAC 모드 전환',
      body: body,
      level: RiskLevel.caution,
      riskScore: 0,
      time: time,
      priority: NotificationPriority.low,
    );
  }

  /// 결로 예측 알림
  RiskNotification createCondensationPredictionNotification({
    required DateTime predictedTime,
    required double probability,
  }) {
    final hoursUntil = predictedTime.difference(DateTime.now()).inHours;
    String urgency;
    NotificationPriority priority;

    if (hoursUntil <= 1) {
      urgency = '1시간 이내';
      priority = NotificationPriority.high;
    } else if (hoursUntil <= 3) {
      urgency = '3시간 이내';
      priority = NotificationPriority.high;
    } else if (hoursUntil <= 6) {
      urgency = '6시간 이내';
      priority = NotificationPriority.medium;
    } else {
      urgency = '$hoursUntil시간 후';
      priority = NotificationPriority.low;
    }

    return RiskNotification(
      id: 'condensation_${predictedTime.millisecondsSinceEpoch}',
      title: '결로 발생 예측',
      body: '$urgency 결로 발생 가능성 ${probability.toStringAsFixed(0)}%. 사전 조치를 취하세요.',
      level: probability >= 75 ? RiskLevel.danger : RiskLevel.warning,
      riskScore: probability,
      time: DateTime.now(),
      priority: priority,
    );
  }

  /// 알림 전송 (리스너에게)
  void sendNotification(RiskNotification notification) {
    for (final listener in _listeners) {
      listener.onNotification(notification);
    }
  }

  /// 모든 알림 삭제
  void clearAll() {
    // 로컬 알림 정리 로직
  }
}

/// 알림 리스너 인터페이스
abstract class NotificationListener {
  void onNotification(RiskNotification notification);
}

/// 위험도 알림 데이터
class RiskNotification {
  final String id;
  final String title;
  final String body;
  final RiskLevel level;
  final double riskScore;
  final DateTime time;
  final NotificationPriority priority;
  final Map<String, dynamic>? payload;

  RiskNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.level,
    required this.riskScore,
    required this.time,
    this.priority = NotificationPriority.medium,
    this.payload,
  });

  /// 알림 색상
  Color get color {
    switch (level) {
      case RiskLevel.danger:
        return const Color(0xFFE53935);
      case RiskLevel.warning:
        return const Color(0xFFFF9800);
      case RiskLevel.caution:
        return const Color(0xFFFFC107);
      case RiskLevel.safe:
        return const Color(0xFF4CAF50);
    }
  }

  /// 알림 아이콘
  IconData get icon {
    switch (level) {
      case RiskLevel.danger:
        return Icons.error;
      case RiskLevel.warning:
        return Icons.warning;
      case RiskLevel.caution:
        return Icons.info;
      case RiskLevel.safe:
        return Icons.check_circle;
    }
  }
}

/// 알림 우선순위
enum NotificationPriority {
  high,
  medium,
  low,
}

/// 알림 설정
class NotificationSettings {
  bool enabled;
  bool dangerAlerts;
  bool warningAlerts;
  bool cautionAlerts;
  bool hvacAlerts;
  bool condensationPrediction;
  int quietHoursStart; // 0-23
  int quietHoursEnd;

  NotificationSettings({
    this.enabled = true,
    this.dangerAlerts = true,
    this.warningAlerts = true,
    this.cautionAlerts = false,
    this.hvacAlerts = true,
    this.condensationPrediction = true,
    this.quietHoursStart = 22,
    this.quietHoursEnd = 7,
  });

  /// 현재 시간이 알림 가능 시간인지 확인
  bool isNotificationAllowed() {
    if (!enabled) return false;

    final now = DateTime.now().hour;
    if (quietHoursStart <= quietHoursEnd) {
      // 예: 22시 ~ 07시 (자정 안 넘음)
      return now < quietHoursStart || now >= quietHoursEnd;
    } else {
      // 예: 22시 ~ 07시 (자정 넘음)
      return now >= quietHoursEnd && now < quietHoursStart;
    }
  }

  /// 특정 레벨의 알림이 허용되는지 확인
  bool isLevelAllowed(RiskLevel level) {
    switch (level) {
      case RiskLevel.danger:
        return dangerAlerts;
      case RiskLevel.warning:
        return warningAlerts;
      case RiskLevel.caution:
        return cautionAlerts;
      case RiskLevel.safe:
        return false;
    }
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'dangerAlerts': dangerAlerts,
    'warningAlerts': warningAlerts,
    'cautionAlerts': cautionAlerts,
    'hvacAlerts': hvacAlerts,
    'condensationPrediction': condensationPrediction,
    'quietHoursStart': quietHoursStart,
    'quietHoursEnd': quietHoursEnd,
  };

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enabled: json['enabled'] ?? true,
      dangerAlerts: json['dangerAlerts'] ?? true,
      warningAlerts: json['warningAlerts'] ?? true,
      cautionAlerts: json['cautionAlerts'] ?? false,
      hvacAlerts: json['hvacAlerts'] ?? true,
      condensationPrediction: json['condensationPrediction'] ?? true,
      quietHoursStart: json['quietHoursStart'] ?? 22,
      quietHoursEnd: json['quietHoursEnd'] ?? 7,
    );
  }
}

/// 인앱 알림 표시 위젯
class InAppNotificationBanner extends StatelessWidget {
  final RiskNotification notification;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;

  const InAppNotificationBanner({
    super.key,
    required this.notification,
    this.onDismiss,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.color.withValues(alpha: 0.1),
            border: Border.all(color: notification.color),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(notification.icon, color: notification.color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: notification.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onDismiss,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
