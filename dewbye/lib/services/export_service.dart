import 'dart:io';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/analysis_provider.dart';
import '../config/constants.dart';
// Conditional web download import
import 'web_download.dart' as web_download;

/// 데이터 내보내기 서비스
class ExportService {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  static final DateFormat _fileNameFormat = DateFormat('yyyyMMdd_HHmmss');

  /// CSV 파일로 내보내기
  static Future<File?> exportToCsv({
    required List<AnalysisResult> results,
    String? customFileName,
  }) async {
    if (results.isEmpty) return null;

    try {
      final fileName = customFileName ??
          'dewbye_analysis_${_fileNameFormat.format(DateTime.now())}.csv';

      // CSV 헤더 (산출 로직 안내 포함)
      final headers = [
        'Date/Time',
        'Risk Score (%)',
        'Risk Level',
        'Outdoor Temp (C)',
        'Outdoor Humidity (%)',
        'Dew Point (C)',
        'Indoor Temp (C)',
        'Indoor Humidity (%)',
        'Recommendation',
      ];
      
      // 산출 로직 안내 행
      final logicInfo = [
        '=== RISK CALCULATION LOGIC ===',
        'Risk Score = Base Risk + Dew Point Risk + Humidity Risk',
        'Base Risk: Gap < 3C = High',
        'Dew Point Risk: Based on dew point temp',
        'Humidity Risk: Indoor/Outdoor difference',
        '',
        '',
        '',
      ];

      // CSV 데이터
      final rows = results.map((r) => [
        _dateFormat.format(r.date),
        r.riskScore.toStringAsFixed(1),
        r.riskLevel.label,
        r.outdoorTemp.toStringAsFixed(1),
        r.outdoorHumidity.toStringAsFixed(1),
        r.dewPoint.toStringAsFixed(1),
        r.indoorTemp.toStringAsFixed(1),
        r.indoorHumidity.toStringAsFixed(1),
        r.recommendation,
      ]).toList();

      // CSV 생성 (로직 설명 + 헤더 + 데이터)
      final csvData = const ListToCsvConverter().convert([logicInfo, [], headers, ...rows]);

      // UTF-8 BOM 추가 (Excel 한글 호환)
      final bom = '\uFEFF';
      final content = bom + csvData;

      if (kIsWeb) {
        // Web: 브라우저 다운로드
        web_download.downloadFileWeb(content, fileName, 'text/csv');
        return null; // Web에서는 File 객체 반환 불가
      } else {
        // Mobile: 파일 저장
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(content);
        return file;
      }
    } catch (e) {
      return null;
    }
  }

  /// 일별 요약 CSV 내보내기 (산출 로직 및 RAW 데이터 포함)
  static Future<File?> exportDailySummaryToCsv({
    required Map<DateTime, DailySummary> summaries,
    String? customFileName,
  }) async {
    if (summaries.isEmpty) return null;

    try {
      final fileName = customFileName ??
          'dewbye_daily_summary_${_fileNameFormat.format(DateTime.now())}.csv';

      // 산출 로직 안내
      final logicInfo = [
        '=== RISK CALCULATION LOGIC ===',
        'Risk Score = Base Risk + Dew Point Risk + Humidity Risk + Building Factor',
        'Base Risk: Temperature-Dew Point Gap Analysis (0-40 pts)',
        'Dew Point Risk: Based on dew point temperature (0-30 pts)',
        'Humidity Risk: Indoor/Outdoor humidity difference (0-20 pts)',
        'Building Factor: Airtightness multiplier',
        '',
        '',
      ];

      final headers = [
        'Date',
        'Max Risk (%)',
        'Avg Risk (%)',
        'Min Risk (%)',
        'High Risk Hours',
        'Max Risk Level',
        'Avg Outdoor Temp (C)',
        'Avg Outdoor Humidity (%)',
        'Avg Dew Point (C)',
        'Avg Indoor Temp (C)',
        'Avg Indoor Humidity (%)',
      ];

      final sortedDates = summaries.keys.toList()..sort();
      final rows = sortedDates.map((date) {
        final s = summaries[date]!;
        return [
          DateFormat('yyyy-MM-dd').format(date),
          s.maxRiskScore.toStringAsFixed(1),
          s.avgRiskScore.toStringAsFixed(1),
          s.minRiskScore.toStringAsFixed(1),
          s.highRiskHours.toString(),
          s.maxRiskLevel.label,
          // RAW 데이터 추가
          s.avgOutdoorTemp.toStringAsFixed(1),
          s.avgOutdoorHumidity.toStringAsFixed(1),
          s.avgDewPoint.toStringAsFixed(1),
          s.avgIndoorTemp.toStringAsFixed(1),
          s.avgIndoorHumidity.toStringAsFixed(1),
        ];
      }).toList();

      // CSV 생성 (로직 설명 + 헤더 + 데이터)
      final csvData = const ListToCsvConverter().convert([logicInfo, [], headers, ...rows]);
      final bom = '\uFEFF';
      final content = bom + csvData;

      if (kIsWeb) {
        // Web: 브라우저 다운로드
        web_download.downloadFileWeb(content, fileName, 'text/csv');
        return null;
      } else {
        // Mobile: 파일 저장
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(content);
        return file;
      }
    } catch (e) {
      return null;
    }
  }

  /// PDF 리포트 생성
  static Future<File?> exportToPdf({
    required List<AnalysisResult> results,
    required String locationName,
    required BuildingType buildingType,
    String? locationNameEnglish,
    double? latitude,
    double? longitude,
    String? customFileName,
  }) async {
    if (results.isEmpty) return null;

    try {
      final fileName = customFileName ??
          'dewbye_report_${_fileNameFormat.format(DateTime.now())}.pdf';

      final pdf = pw.Document();

      // 통계 계산
      final avgRisk = results.map((r) => r.riskScore).reduce((a, b) => a + b) / results.length;
      final maxRisk = results.map((r) => r.riskScore).reduce((a, b) => a > b ? a : b);
      final minRisk = results.map((r) => r.riskScore).reduce((a, b) => a < b ? a : b);
      final highRiskCount = results.where((r) => r.riskScore >= 50).length;

      // 기간 계산
      final sortedResults = List<AnalysisResult>.from(results)
        ..sort((a, b) => a.date.compareTo(b.date));
      final startDate = sortedResults.first.date;
      final endDate = sortedResults.last.date;

      // 90% 이상 위험일 찾기 (일별 최대 위험도 기준)
      final dailyMaxRisk = <DateTime, double>{};
      for (final r in sortedResults) {
        final dayKey = DateTime(r.date.year, r.date.month, r.date.day);
        if (!dailyMaxRisk.containsKey(dayKey) || dailyMaxRisk[dayKey]! < r.riskScore) {
          dailyMaxRisk[dayKey] = r.riskScore;
        }
      }
      final highRiskDays = dailyMaxRisk.entries
          .where((e) => e.value >= 90)
          .map((e) => e.key)
          .toList()
        ..sort();

      // 마지막 날 데이터
      final lastDay = DateTime(endDate.year, endDate.month, endDate.day);

      // 영문 주소 (좌표 포함)
      String locationDisplay = locationNameEnglish ?? locationName;
      if (latitude != null && longitude != null) {
        locationDisplay += ' (${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)})';
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            // 제목
            pw.Header(
              level: 0,
              child: pw.Text(
                'Dewbye Analysis Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),

            // Basic Information
            _buildPdfSection('Basic Information', [
              _buildPdfInfoRow('Location', locationDisplay),
              _buildPdfInfoRow('Building Type', _getBuildingTypeName(buildingType)),
              _buildPdfInfoRow('Analysis Period',
                '${DateFormat('yyyy-MM-dd').format(startDate)} ~ ${DateFormat('yyyy-MM-dd').format(endDate)}'),
              _buildPdfInfoRow('Data Points', '${results.length} records'),
              _buildPdfInfoRow('Report Generated', _dateFormat.format(DateTime.now())),
            ]),
            pw.SizedBox(height: 20),

            // Summary Statistics
            _buildPdfSection('Analysis Summary', [
              _buildPdfInfoRow('Average Risk Score', '${avgRisk.toStringAsFixed(1)}%'),
              _buildPdfInfoRow('Maximum Risk Score', '${maxRisk.toStringAsFixed(1)}%'),
              _buildPdfInfoRow('Minimum Risk Score', '${minRisk.toStringAsFixed(1)}%'),
              _buildPdfInfoRow('High Risk Periods (>=50%)', '$highRiskCount times'),
              _buildPdfInfoRow('Critical Risk Days (>=90%)', '${highRiskDays.length} days'),
            ]),
            pw.SizedBox(height: 20),

            // Risk Level Distribution
            _buildPdfSection('Risk Level Distribution', [
              _buildPdfInfoRow('Safe (0-25%)',
                '${results.where((r) => r.riskScore < 25).length} records'),
              _buildPdfInfoRow('Caution (25-50%)',
                '${results.where((r) => r.riskScore >= 25 && r.riskScore < 50).length} records'),
              _buildPdfInfoRow('Warning (50-75%)',
                '${results.where((r) => r.riskScore >= 50 && r.riskScore < 75).length} records'),
              _buildPdfInfoRow('Danger (75-100%)',
                '${results.where((r) => r.riskScore >= 75).length} records'),
            ]),
            pw.SizedBox(height: 20),

            // Risk calculation method
            _buildPdfSection('Risk Calculation Method', [
              pw.Text('Risk Score = Base Risk + Dew Point Risk + Humidity Risk + Building Factor'),
              pw.SizedBox(height: 5),
              pw.Text('- Base Risk: Temperature-Dew Point Gap Analysis (0-40 pts)'),
              pw.Text('- Dew Point Risk: Based on dew point temperature (0-30 pts)'),
              pw.Text('- Humidity Risk: Indoor/Outdoor humidity difference (0-20 pts)'),
              pw.Text('- Building Factor: ${_getBuildingTypeName(buildingType)} (x${buildingType.airtightness})'),
            ]),
            pw.SizedBox(height: 20),

            // Top High-Risk Days (90% 이상)
            pw.Header(level: 1, text: 'Top High-Risk Days (Risk >= 90%)'),
            pw.SizedBox(height: 10),
            if (highRiskDays.isEmpty)
              pw.Text('No days with risk >= 90% during the analysis period.',
                  style: const pw.TextStyle(color: PdfColors.grey700))
            else
              _buildPdfTable(
                headers: ['Date', 'Max Risk', 'Avg Temp', 'Avg Humidity', 'Avg Dew Point'],
                rows: highRiskDays.take(10).map((day) {
                  final dayResults = sortedResults.where((r) =>
                      r.date.year == day.year &&
                      r.date.month == day.month &&
                      r.date.day == day.day).toList();
                  final maxR = dayResults.map((r) => r.riskScore).reduce((a, b) => a > b ? a : b);
                  final avgTemp = dayResults.map((r) => r.outdoorTemp).reduce((a, b) => a + b) / dayResults.length;
                  final avgHum = dayResults.map((r) => r.outdoorHumidity).reduce((a, b) => a + b) / dayResults.length;
                  final avgDew = dayResults.map((r) => r.dewPoint).reduce((a, b) => a + b) / dayResults.length;
                  return [
                    DateFormat('yyyy-MM-dd').format(day),
                    '${maxR.toStringAsFixed(1)}%',
                    '${avgTemp.toStringAsFixed(1)}C',
                    '${avgHum.toStringAsFixed(0)}%',
                    '${avgDew.toStringAsFixed(1)}C',
                  ];
                }).toList(),
              ),
            pw.SizedBox(height: 20),

            // 고위험 일자별 24시간 차트
            ...highRiskDays.take(5).expand((day) => [
              pw.Header(level: 2, text: 'Daily Analysis: ${DateFormat('yyyy-MM-dd').format(day)}'),
              pw.SizedBox(height: 10),
              _buildDailyCharts(sortedResults, day),
              pw.SizedBox(height: 20),
            ]),

            // 마지막 날 24시간 차트 (고위험일이 아닌 경우에만)
            if (!highRiskDays.contains(lastDay)) ...[
              pw.Header(level: 2, text: 'Last Day Analysis: ${DateFormat('yyyy-MM-dd').format(lastDay)}'),
              pw.SizedBox(height: 10),
              _buildDailyCharts(sortedResults, lastDay),
              pw.SizedBox(height: 20),
            ],

            // Recommendations
            _buildPdfSection('Recommendations', [
              if (maxRisk >= 75)
                pw.Bullet(text: 'Immediate ventilation or dehumidification required'),
              if (avgRisk >= 50)
                pw.Bullet(text: 'Strengthen indoor humidity management'),
              if (highRiskCount > results.length * 0.3)
                pw.Bullet(text: 'Establish regular ventilation schedule'),
              pw.Bullet(text: 'Inspect windows and thermal insulation weak points'),
              if (buildingType.airtightness < 0.5)
                pw.Bullet(text: 'Consider improving building airtightness'),
              if (highRiskDays.isNotEmpty)
                pw.Bullet(text: 'Pay special attention to ${highRiskDays.length} critical risk day(s)'),
            ]),
          ],
          footer: (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Dewbye - Weather-HVAC Analytics | Page ${context.pageNumber}/${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ),
      );

      final bytes = await pdf.save();

      if (kIsWeb) {
        // Web: 브라우저 다운로드
        web_download.downloadBinaryFileWeb(bytes, fileName, 'application/pdf');
        return null;
      } else {
        // Mobile: 파일 저장
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes);
        return file;
      }
    } catch (e) {
      return null;
    }
  }

  /// 일별 24시간 차트 생성
  static pw.Widget _buildDailyCharts(List<AnalysisResult> allResults, DateTime day) {
    final dayResults = allResults.where((r) =>
        r.date.year == day.year &&
        r.date.month == day.month &&
        r.date.day == day.day).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (dayResults.isEmpty) {
      return pw.Text('No data available for this day.');
    }

    // 시간별 데이터 테이블
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // 위험도 차트 (텍스트 기반)
        pw.Text('Risk Score (24h):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        _buildHourlyBarChart(dayResults, (r) => r.riskScore, '%', maxValue: 100),
        pw.SizedBox(height: 15),

        // 온습도 + 이슬점 테이블
        pw.Text('Temperature & Humidity (24h):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        _buildPdfTable(
          headers: ['Hour', 'Outdoor Temp', 'Humidity', 'Dew Point', 'Indoor Temp', 'Risk'],
          rows: dayResults.map((r) => [
            '${r.date.hour.toString().padLeft(2, '0')}:00',
            '${r.outdoorTemp.toStringAsFixed(1)}C',
            '${r.outdoorHumidity.toStringAsFixed(0)}%',
            '${r.dewPoint.toStringAsFixed(1)}C',
            '${r.indoorTemp.toStringAsFixed(1)}C',
            '${r.riskScore.toStringAsFixed(0)}%',
          ]).toList(),
        ),
      ],
    );
  }

  /// 시간별 막대 차트 (텍스트 기반)
  static pw.Widget _buildHourlyBarChart(
    List<AnalysisResult> results,
    double Function(AnalysisResult) getValue,
    String unit, {
    double maxValue = 100,
  }) {
    const barWidth = 15.0;
    const maxBarHeight = 60.0;

    return pw.Container(
      height: maxBarHeight + 30,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: results.map((r) {
          final value = getValue(r);
          final barHeight = (value / maxValue) * maxBarHeight;
          final color = value >= 90
              ? PdfColors.red
              : value >= 75
                  ? PdfColors.orange
                  : value >= 50
                      ? PdfColors.yellow800
                      : value >= 25
                          ? PdfColors.green
                          : PdfColors.blue;

          return pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                value.toStringAsFixed(0),
                style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
              ),
              pw.Container(
                width: barWidth,
                height: barHeight.clamp(2, maxBarHeight),
                color: color,
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                '${r.date.hour}',
                style: const pw.TextStyle(fontSize: 6),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  static String _getBuildingTypeName(BuildingType type) {
    switch (type) {
      case BuildingType.oldHouse:
        return 'Old House';
      case BuildingType.standard:
        return 'Standard Building';
      case BuildingType.modern:
        return 'Modern Building';
      case BuildingType.passive:
        return 'Passive House';
    }
  }

  static pw.Widget _buildPdfSection(String title, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Header(level: 1, text: title),
        pw.SizedBox(height: 10),
        ...children,
      ],
    );
  }

  static pw.Widget _buildPdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text(value),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfTable({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: headers.map((h) => pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          )).toList(),
        ),
        ...rows.map((row) => pw.TableRow(
          children: row.map((cell) => pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(cell),
          )).toList(),
        )),
      ],
    );
  }

  /// 파일 공유
  static Future<void> shareFile(File? file) async {
    if (kIsWeb) {
      // Web에서는 이미 다운로드 완료
      return;
    }
    
    if (file == null) return;
    
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Dewbye 분석 데이터',
    );
  }

  /// 여러 파일 공유
  static Future<void> shareFiles(List<File> files) async {
    if (kIsWeb) {
      // Web에서는 이미 다운로드 완료
      return;
    }
    
    await Share.shareXFiles(
      files.map((f) => XFile(f.path)).toList(),
      subject: 'Dewbye 분석 데이터',
    );
  }
}
