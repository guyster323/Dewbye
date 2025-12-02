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
// Web 전용 imports
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

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
        _downloadFileWeb(content, fileName, 'text/csv');
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
        _downloadFileWeb(content, fileName, 'text/csv');
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
            
            // Risk calculation method with detailed explanation
            _buildPdfSection('Risk Calculation Method', [
              pw.Text(
                'CONDENSATION RISK CALCULATION FORMULA',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Risk Score = Base Risk + Dew Point Risk + Humidity Risk + Building Factor'),
              pw.SizedBox(height: 10),
              pw.Text('DETAILED BREAKDOWN:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Bullet(text: '1. Base Risk (0-40 points):'),
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('   - Temperature-Dew Point Gap < 3C: High Risk (40 pts)'),
                    pw.Text('   - Gap 3-5C: Medium Risk (25 pts)'),
                    pw.Text('   - Gap > 5C: Low Risk (10 pts)'),
                  ],
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Bullet(text: '2. Dew Point Risk (0-30 points):'),
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('   - Dew Point > 20C: High (30 pts)'),
                    pw.Text('   - Dew Point 15-20C: Medium (20 pts)'),
                    pw.Text('   - Dew Point 10-15C: Low (10 pts)'),
                    pw.Text('   - Dew Point < 10C: Very Low (5 pts)'),
                  ],
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Bullet(text: '3. Humidity Risk (0-20 points):'),
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('   - Indoor/Outdoor Humidity Diff > 20%: High (20 pts)'),
                    pw.Text('   - Diff 10-20%: Medium (10 pts)'),
                    pw.Text('   - Diff < 10%: Low (5 pts)'),
                  ],
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Bullet(text: '4. Building Airtightness Factor:'),
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('   - Current Building Type: ${_getBuildingTypeName(buildingType)}'),
                    pw.Text('   - Airtightness Multiplier: ${buildingType.airtightness}'),
                    pw.Text('   - Final Risk = Base Score * (1 + Airtightness)'),
                  ],
                ),
              ),
            ]),
            pw.SizedBox(height: 20),

            // Basic Information
            _buildPdfSection('Basic Information', [
              _buildPdfInfoRow('Location', locationName),
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
              _buildPdfInfoRow('High Risk Periods', '$highRiskCount times'),
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

            // Top Risk Periods
            pw.Header(level: 1, text: 'Top High-Risk Periods'),
            pw.SizedBox(height: 10),
            _buildPdfTable(
              headers: ['Date/Time', 'Risk', 'Temp', 'Humidity', 'Dew Point'],
              rows: results
                  .where((r) => r.riskScore >= 50)
                  .take(10)
                  .map((r) => [
                    _dateFormat.format(r.date),
                    '${r.riskScore.toStringAsFixed(1)}%',
                    '${r.outdoorTemp.toStringAsFixed(1)}C',
                    '${r.outdoorHumidity.toStringAsFixed(0)}%',
                    '${r.dewPoint.toStringAsFixed(1)}C',
                  ])
                  .toList(),
            ),
            pw.SizedBox(height: 20),

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
        _downloadBinaryFileWeb(bytes, fileName, 'application/pdf');
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

  /// Web에서 파일 다운로드
  static void _downloadFileWeb(String content, String fileName, String mimeType) {
    if (!kIsWeb) return;
    
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  /// Web에서 바이너리 파일 다운로드 (PDF용)
  static void _downloadBinaryFileWeb(List<int> bytes, String fileName, String mimeType) {
    if (!kIsWeb) return;
    
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
