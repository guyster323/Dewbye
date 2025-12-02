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

  /// 일별 요약 CSV 내보내기
  static Future<File?> exportDailySummaryToCsv({
    required Map<DateTime, DailySummary> summaries,
    String? customFileName,
  }) async {
    if (summaries.isEmpty) return null;

    try {
      final fileName = customFileName ??
          'dewbye_daily_summary_${_fileNameFormat.format(DateTime.now())}.csv';

      final headers = [
        '날짜',
        '최대 위험도 (%)',
        '평균 위험도 (%)',
        '최소 위험도 (%)',
        '주의 시간 (시간)',
        '최대 위험 등급',
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
        ];
      }).toList();

      final csvData = const ListToCsvConverter().convert([headers, ...rows]);
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
            
            // 위험도 산출 로직 안내
            _buildPdfSection('Risk Calculation Method', [
              pw.Text('Risk Score = Base Risk + Dew Point Risk + Humidity Risk'),
              pw.SizedBox(height: 5),
              pw.Bullet(text: 'Base Risk: Temperature-Dew Point Gap < 3C = High Risk'),
              pw.Bullet(text: 'Dew Point Risk: Based on dew point temperature'),
              pw.Bullet(text: 'Humidity Risk: Indoor/Outdoor humidity difference'),
              pw.Bullet(text: 'Building Airtightness Factor: ${buildingType.airtightness}'),
            ]),
            pw.SizedBox(height: 20),

            // 기본 정보
            _buildPdfSection('Basic Information', [
              _buildPdfInfoRow('위치', locationName),
              _buildPdfInfoRow('건물 유형', buildingType.label),
              _buildPdfInfoRow('분석 기간',
                '${DateFormat('yyyy-MM-dd').format(startDate)} ~ ${DateFormat('yyyy-MM-dd').format(endDate)}'),
              _buildPdfInfoRow('데이터 수', '${results.length}건'),
              _buildPdfInfoRow('생성 일시', _dateFormat.format(DateTime.now())),
            ]),
            pw.SizedBox(height: 20),

            // 요약 통계
            _buildPdfSection('분석 요약', [
              _buildPdfInfoRow('평균 위험도', '${avgRisk.toStringAsFixed(1)}%'),
              _buildPdfInfoRow('최대 위험도', '${maxRisk.toStringAsFixed(1)}%'),
              _buildPdfInfoRow('최소 위험도', '${minRisk.toStringAsFixed(1)}%'),
              _buildPdfInfoRow('주의 필요 시간', '$highRiskCount회'),
            ]),
            pw.SizedBox(height: 20),

            // 위험 등급별 분포
            _buildPdfSection('위험 등급별 분포', [
              _buildPdfInfoRow('안전 (0-25%)',
                '${results.where((r) => r.riskScore < 25).length}건'),
              _buildPdfInfoRow('주의 (25-50%)',
                '${results.where((r) => r.riskScore >= 25 && r.riskScore < 50).length}건'),
              _buildPdfInfoRow('경고 (50-75%)',
                '${results.where((r) => r.riskScore >= 50 && r.riskScore < 75).length}건'),
              _buildPdfInfoRow('위험 (75-100%)',
                '${results.where((r) => r.riskScore >= 75).length}건'),
            ]),
            pw.SizedBox(height: 20),

            // 상위 위험 시간대
            pw.Header(level: 1, text: '상위 위험 시간대'),
            pw.SizedBox(height: 10),
            _buildPdfTable(
              headers: ['날짜/시간', '위험도', '외기온도', '습도', '이슬점'],
              rows: results
                  .where((r) => r.riskScore >= 50)
                  .take(10)
                  .map((r) => [
                    _dateFormat.format(r.date),
                    '${r.riskScore.toStringAsFixed(1)}%',
                    '${r.outdoorTemp.toStringAsFixed(1)}°C',
                    '${r.outdoorHumidity.toStringAsFixed(0)}%',
                    '${r.dewPoint.toStringAsFixed(1)}°C',
                  ])
                  .toList(),
            ),
            pw.SizedBox(height: 20),

            // 권장 조치
            _buildPdfSection('권장 조치', [
              if (maxRisk >= 75)
                pw.Bullet(text: '즉시 환기 또는 제습이 필요합니다.'),
              if (avgRisk >= 50)
                pw.Bullet(text: '실내 습도 관리를 강화하세요.'),
              if (highRiskCount > results.length * 0.3)
                pw.Bullet(text: '정기적인 환기 스케줄을 수립하세요.'),
              pw.Bullet(text: '창문 및 단열 취약 부위를 점검하세요.'),
              if (buildingType.airtightness < 0.5)
                pw.Bullet(text: '건물 기밀성 개선을 고려하세요.'),
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
