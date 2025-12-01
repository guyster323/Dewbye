import '../config/constants.dart';
import '../models/weather_data.dart';
import '../providers/analysis_provider.dart';
import 'hvac_analytics.dart';

/// 일별 요약 리포트
class DailyReport {
  final DateTime date;
  final double maxTemperature;
  final double minTemperature;
  final double avgTemperature;
  final double maxHumidity;
  final double minHumidity;
  final double avgHumidity;
  final double maxRiskScore;
  final double minRiskScore;
  final double avgRiskScore;
  final int highRiskHours;
  final int mediumRiskHours;
  final int lowRiskHours;
  final RiskLevel overallRiskLevel;
  final List<VulnerableTimeSlot> vulnerableSlots;
  final List<String> recommendations;

  DailyReport({
    required this.date,
    required this.maxTemperature,
    required this.minTemperature,
    required this.avgTemperature,
    required this.maxHumidity,
    required this.minHumidity,
    required this.avgHumidity,
    required this.maxRiskScore,
    required this.minRiskScore,
    required this.avgRiskScore,
    required this.highRiskHours,
    required this.mediumRiskHours,
    required this.lowRiskHours,
    required this.overallRiskLevel,
    required this.vulnerableSlots,
    required this.recommendations,
  });

  String get dateString =>
      '${date.year}년 ${date.month}월 ${date.day}일';

  String get temperatureRange =>
      '${minTemperature.toStringAsFixed(1)}°C ~ ${maxTemperature.toStringAsFixed(1)}°C';

  String get humidityRange =>
      '${minHumidity.toStringAsFixed(0)}% ~ ${maxHumidity.toStringAsFixed(0)}%';
}

/// 주별 요약 리포트
class WeeklyReport {
  final DateTime startDate;
  final DateTime endDate;
  final List<DailyReport> dailyReports;
  final double weekAvgTemperature;
  final double weekAvgHumidity;
  final double weekAvgRiskScore;
  final double weekMaxRiskScore;
  final int totalHighRiskHours;
  final int totalVulnerableSlots;
  final RiskLevel overallRiskLevel;
  final List<String> weeklyTrends;
  final List<String> recommendations;

  WeeklyReport({
    required this.startDate,
    required this.endDate,
    required this.dailyReports,
    required this.weekAvgTemperature,
    required this.weekAvgHumidity,
    required this.weekAvgRiskScore,
    required this.weekMaxRiskScore,
    required this.totalHighRiskHours,
    required this.totalVulnerableSlots,
    required this.overallRiskLevel,
    required this.weeklyTrends,
    required this.recommendations,
  });

  String get periodString =>
      '${startDate.month}/${startDate.day} ~ ${endDate.month}/${endDate.day}';

  int get daysCount => dailyReports.length;
}

/// 리포트 생성기
class ReportGenerator {
  /// 일별 리포트 생성
  static DailyReport generateDailyReport(
    DateTime date,
    List<WeatherData> hourlyData,
    List<AnalysisResult> analysisResults,
    BuildingType buildingType,
  ) {
    if (hourlyData.isEmpty || analysisResults.isEmpty) {
      return _emptyDailyReport(date);
    }

    // 온도 통계
    final temps = hourlyData.map((d) => d.temperature).toList();
    final maxTemp = temps.reduce((a, b) => a > b ? a : b);
    final minTemp = temps.reduce((a, b) => a < b ? a : b);
    final avgTemp = temps.reduce((a, b) => a + b) / temps.length;

    // 습도 통계
    final humidities = hourlyData.map((d) => d.humidity).toList();
    final maxHumidity = humidities.reduce((a, b) => a > b ? a : b);
    final minHumidity = humidities.reduce((a, b) => a < b ? a : b);
    final avgHumidity = humidities.reduce((a, b) => a + b) / humidities.length;

    // 위험도 통계
    final risks = analysisResults.map((r) => r.riskScore).toList();
    final maxRisk = risks.reduce((a, b) => a > b ? a : b);
    final minRisk = risks.reduce((a, b) => a < b ? a : b);
    final avgRisk = risks.reduce((a, b) => a + b) / risks.length;

    // 위험 시간대 카운트
    int highRiskHours = 0;
    int mediumRiskHours = 0;
    int lowRiskHours = 0;

    for (final result in analysisResults) {
      if (result.riskScore >= 75) {
        highRiskHours++;
      } else if (result.riskScore >= 50) {
        mediumRiskHours++;
      } else if (result.riskScore >= 25) {
        lowRiskHours++;
      }
    }

    // 취약 시간대 감지
    final vulnerableSlots = HVACModeDetector.detectVulnerableTimeSlots(
      hourlyData,
      buildingType,
    );

    // 전체 위험 수준
    final overallRisk = RiskLevel.fromScore(avgRisk);

    // 권장 사항 생성
    final recommendations = _generateDailyRecommendations(
      avgRisk,
      maxRisk,
      highRiskHours,
      vulnerableSlots,
      buildingType,
    );

    return DailyReport(
      date: date,
      maxTemperature: maxTemp,
      minTemperature: minTemp,
      avgTemperature: avgTemp,
      maxHumidity: maxHumidity,
      minHumidity: minHumidity,
      avgHumidity: avgHumidity,
      maxRiskScore: maxRisk,
      minRiskScore: minRisk,
      avgRiskScore: avgRisk,
      highRiskHours: highRiskHours,
      mediumRiskHours: mediumRiskHours,
      lowRiskHours: lowRiskHours,
      overallRiskLevel: overallRisk,
      vulnerableSlots: vulnerableSlots,
      recommendations: recommendations,
    );
  }

  /// 주별 리포트 생성
  static WeeklyReport generateWeeklyReport(
    List<DailyReport> dailyReports,
  ) {
    if (dailyReports.isEmpty) {
      return _emptyWeeklyReport();
    }

    final startDate = dailyReports.first.date;
    final endDate = dailyReports.last.date;

    // 주간 평균 계산
    final weekAvgTemp = dailyReports
        .map((r) => r.avgTemperature)
        .reduce((a, b) => a + b) / dailyReports.length;

    final weekAvgHumidity = dailyReports
        .map((r) => r.avgHumidity)
        .reduce((a, b) => a + b) / dailyReports.length;

    final weekAvgRisk = dailyReports
        .map((r) => r.avgRiskScore)
        .reduce((a, b) => a + b) / dailyReports.length;

    final weekMaxRisk = dailyReports
        .map((r) => r.maxRiskScore)
        .reduce((a, b) => a > b ? a : b);

    // 총 위험 시간
    final totalHighRisk = dailyReports
        .map((r) => r.highRiskHours)
        .reduce((a, b) => a + b);

    final totalVulnerable = dailyReports
        .map((r) => r.vulnerableSlots.length)
        .reduce((a, b) => a + b);

    // 트렌드 분석
    final trends = _analyzeWeeklyTrends(dailyReports);

    // 권장 사항
    final recommendations = _generateWeeklyRecommendations(
      weekAvgRisk,
      weekMaxRisk,
      totalHighRisk,
      trends,
    );

    return WeeklyReport(
      startDate: startDate,
      endDate: endDate,
      dailyReports: dailyReports,
      weekAvgTemperature: weekAvgTemp,
      weekAvgHumidity: weekAvgHumidity,
      weekAvgRiskScore: weekAvgRisk,
      weekMaxRiskScore: weekMaxRisk,
      totalHighRiskHours: totalHighRisk,
      totalVulnerableSlots: totalVulnerable,
      overallRiskLevel: RiskLevel.fromScore(weekAvgRisk),
      weeklyTrends: trends,
      recommendations: recommendations,
    );
  }

  /// 분석 결과에서 일별 리포트 일괄 생성
  static List<DailyReport> generateDailyReportsFromAnalysis(
    List<WeatherData> weatherData,
    List<AnalysisResult> analysisResults,
    BuildingType buildingType,
  ) {
    // 날짜별로 그룹화
    final Map<DateTime, List<WeatherData>> weatherByDate = {};
    final Map<DateTime, List<AnalysisResult>> resultsByDate = {};

    for (final data in weatherData) {
      final dateKey = DateTime(data.time.year, data.time.month, data.time.day);
      weatherByDate.putIfAbsent(dateKey, () => []).add(data);
    }

    for (final result in analysisResults) {
      final dateKey = DateTime(result.date.year, result.date.month, result.date.day);
      resultsByDate.putIfAbsent(dateKey, () => []).add(result);
    }

    // 일별 리포트 생성
    final reports = <DailyReport>[];
    final sortedDates = weatherByDate.keys.toList()..sort();

    for (final date in sortedDates) {
      final dayWeather = weatherByDate[date] ?? [];
      final dayResults = resultsByDate[date] ?? [];

      if (dayWeather.isNotEmpty && dayResults.isNotEmpty) {
        reports.add(generateDailyReport(
          date,
          dayWeather,
          dayResults,
          buildingType,
        ));
      }
    }

    return reports;
  }

  static DailyReport _emptyDailyReport(DateTime date) {
    return DailyReport(
      date: date,
      maxTemperature: 0,
      minTemperature: 0,
      avgTemperature: 0,
      maxHumidity: 0,
      minHumidity: 0,
      avgHumidity: 0,
      maxRiskScore: 0,
      minRiskScore: 0,
      avgRiskScore: 0,
      highRiskHours: 0,
      mediumRiskHours: 0,
      lowRiskHours: 0,
      overallRiskLevel: RiskLevel.safe,
      vulnerableSlots: [],
      recommendations: ['데이터 없음'],
    );
  }

  static WeeklyReport _emptyWeeklyReport() {
    return WeeklyReport(
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      dailyReports: [],
      weekAvgTemperature: 0,
      weekAvgHumidity: 0,
      weekAvgRiskScore: 0,
      weekMaxRiskScore: 0,
      totalHighRiskHours: 0,
      totalVulnerableSlots: 0,
      overallRiskLevel: RiskLevel.safe,
      weeklyTrends: ['데이터 없음'],
      recommendations: ['데이터 없음'],
    );
  }

  static List<String> _generateDailyRecommendations(
    double avgRisk,
    double maxRisk,
    int highRiskHours,
    List<VulnerableTimeSlot> vulnerableSlots,
    BuildingType buildingType,
  ) {
    final recommendations = <String>[];

    if (maxRisk >= 75) {
      recommendations.add('오늘 결로 위험이 높은 시간대가 있습니다.');
      if (highRiskHours > 3) {
        recommendations.add('$highRiskHours시간 동안 고위험 상태 지속. 제습 장치 가동을 권장합니다.');
      }
    }

    if (vulnerableSlots.isNotEmpty) {
      for (final slot in vulnerableSlots.take(3)) {
        recommendations.add('${slot.timeRange}: ${slot.recommendation}');
      }
    }

    if (avgRisk >= 50) {
      recommendations.add('전반적인 습도 관리가 필요합니다.');
      if (buildingType.airtightness < 0.5) {
        recommendations.add('저기밀 구조로 외기 습도 유입이 빠릅니다. 창문/문 틈새 점검을 권장합니다.');
      }
    } else if (avgRisk >= 25) {
      recommendations.add('습도 모니터링을 유지하세요.');
    } else {
      recommendations.add('오늘은 결로 위험이 낮습니다.');
    }

    return recommendations;
  }

  static List<String> _analyzeWeeklyTrends(List<DailyReport> reports) {
    final trends = <String>[];

    if (reports.length < 2) {
      trends.add('트렌드 분석을 위한 데이터가 부족합니다.');
      return trends;
    }

    // 위험도 트렌드
    final firstHalfAvg = reports.take(reports.length ~/ 2)
        .map((r) => r.avgRiskScore)
        .reduce((a, b) => a + b) / (reports.length ~/ 2);

    final secondHalfAvg = reports.skip(reports.length ~/ 2)
        .map((r) => r.avgRiskScore)
        .reduce((a, b) => a + b) / (reports.length - reports.length ~/ 2);

    if (secondHalfAvg > firstHalfAvg + 10) {
      trends.add('주 후반으로 갈수록 결로 위험이 증가하는 추세입니다.');
    } else if (secondHalfAvg < firstHalfAvg - 10) {
      trends.add('주 후반으로 갈수록 결로 위험이 감소하는 추세입니다.');
    } else {
      trends.add('주간 결로 위험도가 비교적 안정적입니다.');
    }

    // 고위험 일수 확인
    final highRiskDays = reports.where((r) => r.maxRiskScore >= 75).length;
    if (highRiskDays > 0) {
      trends.add('이번 주 $highRiskDays일간 고위험 시간대가 발생했습니다.');
    }

    // 습도 트렌드
    final avgHumidity = reports.map((r) => r.avgHumidity).reduce((a, b) => a + b) / reports.length;
    if (avgHumidity >= 70) {
      trends.add('평균 습도가 높습니다 (${avgHumidity.toStringAsFixed(0)}%). 제습 관리가 필요합니다.');
    } else if (avgHumidity <= 35) {
      trends.add('평균 습도가 낮습니다 (${avgHumidity.toStringAsFixed(0)}%). 가습을 고려하세요.');
    }

    return trends;
  }

  static List<String> _generateWeeklyRecommendations(
    double avgRisk,
    double maxRisk,
    int totalHighRiskHours,
    List<String> trends,
  ) {
    final recommendations = <String>[];

    if (totalHighRiskHours > 20) {
      recommendations.add('이번 주 총 $totalHighRiskHours시간 고위험 상태. 제습 시스템 점검을 권장합니다.');
    }

    if (avgRisk >= 50) {
      recommendations.add('주간 평균 위험도가 높습니다. 습도 관리 계획을 세우세요.');
      recommendations.add('제습기 24시간 자동 운전을 고려하세요.');
    }

    if (maxRisk >= 90) {
      recommendations.add('결로 발생 가능성이 매우 높았던 시간대가 있습니다.');
      recommendations.add('창문, 벽면 결로 여부를 확인하세요.');
    }

    if (recommendations.isEmpty) {
      recommendations.add('이번 주는 결로 위험이 낮았습니다.');
      recommendations.add('현재 상태를 유지하세요.');
    }

    return recommendations;
  }
}

/// 리포트 포맷터 (텍스트 출력용)
class ReportFormatter {
  /// 일별 리포트를 텍스트로 변환
  static String formatDailyReport(DailyReport report) {
    final buffer = StringBuffer();

    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('  ${report.dateString} 일일 리포트');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln();
    buffer.writeln('📊 기상 요약');
    buffer.writeln('  온도: ${report.temperatureRange}');
    buffer.writeln('  습도: ${report.humidityRange}');
    buffer.writeln();
    buffer.writeln('⚠️ 결로 위험도');
    buffer.writeln('  평균: ${report.avgRiskScore.toStringAsFixed(1)}%');
    buffer.writeln('  최대: ${report.maxRiskScore.toStringAsFixed(1)}%');
    buffer.writeln('  위험 수준: ${report.overallRiskLevel.label}');
    buffer.writeln();
    buffer.writeln('⏰ 시간대별 분포');
    buffer.writeln('  고위험: ${report.highRiskHours}시간');
    buffer.writeln('  중위험: ${report.mediumRiskHours}시간');
    buffer.writeln('  저위험: ${report.lowRiskHours}시간');
    buffer.writeln();

    if (report.vulnerableSlots.isNotEmpty) {
      buffer.writeln('🔴 주의 시간대');
      for (final slot in report.vulnerableSlots) {
        buffer.writeln('  • ${slot.timeRange} (${slot.formattedDuration})');
      }
      buffer.writeln();
    }

    buffer.writeln('💡 권장 사항');
    for (final rec in report.recommendations) {
      buffer.writeln('  • $rec');
    }

    return buffer.toString();
  }

  /// 주별 리포트를 텍스트로 변환
  static String formatWeeklyReport(WeeklyReport report) {
    final buffer = StringBuffer();

    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('  ${report.periodString} 주간 리포트');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln();
    buffer.writeln('📊 주간 요약 (${report.daysCount}일)');
    buffer.writeln('  평균 온도: ${report.weekAvgTemperature.toStringAsFixed(1)}°C');
    buffer.writeln('  평균 습도: ${report.weekAvgHumidity.toStringAsFixed(0)}%');
    buffer.writeln('  평균 위험도: ${report.weekAvgRiskScore.toStringAsFixed(1)}%');
    buffer.writeln('  최대 위험도: ${report.weekMaxRiskScore.toStringAsFixed(1)}%');
    buffer.writeln();
    buffer.writeln('⏰ 위험 시간 통계');
    buffer.writeln('  총 고위험 시간: ${report.totalHighRiskHours}시간');
    buffer.writeln('  취약 시간대: ${report.totalVulnerableSlots}회');
    buffer.writeln();
    buffer.writeln('📈 트렌드 분석');
    for (final trend in report.weeklyTrends) {
      buffer.writeln('  • $trend');
    }
    buffer.writeln();
    buffer.writeln('💡 주간 권장 사항');
    for (final rec in report.recommendations) {
      buffer.writeln('  • $rec');
    }
    buffer.writeln();
    buffer.writeln('───────────────────────────────────────');
    buffer.writeln('  일별 상세');
    buffer.writeln('───────────────────────────────────────');

    for (final daily in report.dailyReports) {
      final riskIcon = daily.overallRiskLevel == RiskLevel.danger
          ? '🔴'
          : daily.overallRiskLevel == RiskLevel.warning
              ? '🟠'
              : daily.overallRiskLevel == RiskLevel.caution
                  ? '🟡'
                  : '🟢';

      buffer.writeln(
        '  ${daily.date.month}/${daily.date.day} $riskIcon '
        '${daily.avgRiskScore.toStringAsFixed(0)}% '
        '(${daily.temperatureRange})',
      );
    }

    return buffer.toString();
  }
}
