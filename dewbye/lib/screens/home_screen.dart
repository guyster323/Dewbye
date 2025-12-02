import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/location_provider.dart';
import '../providers/analysis_provider.dart';
import '../widgets/widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationProvider = context.read<LocationProvider>();
      if (locationProvider.currentLocation == null) {
        locationProvider.getCurrentLocation();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analysisProvider = context.watch<AnalysisProvider>();

    return Scaffold(
      body: WeatherBackground(
        condition: _getWeatherCondition(analysisProvider.currentRiskScore),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Glassmorphism 헤더
              const SliverToBoxAdapter(
                child: AppHeader(),
              ),

              // 위치 입력 위젯
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: LocationInputWidget(
                    onTap: () => Navigator.pushNamed(context, '/location'),
                  ),
                ),
              ),

              // 결로 위험도 카드 (애니메이션 포함)
              SliverToBoxAdapter(
                child: _buildStatusCard(theme, analysisProvider),
              ),

              // 빠른 액션 버튼
              SliverToBoxAdapter(
                child: _buildQuickActions(theme),
              ),

              // 최근 분석 결과
              SliverToBoxAdapter(
                child: _buildRecentAnalysis(theme, analysisProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  WeatherCondition _getWeatherCondition(double riskScore) {
    if (riskScore >= 75) return WeatherCondition.humid;
    if (riskScore >= 50) return WeatherCondition.foggy;
    if (riskScore >= 25) return WeatherCondition.cloudy;
    return WeatherCondition.clear;
  }

  Widget _buildStatusCard(ThemeData theme, AnalysisProvider analysisProvider) {
    final riskScore = analysisProvider.currentRiskScore;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GlassmorphismContainer(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              '현재 결로 위험도',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 기존 애니메이션
                CondensationAnimation(
                  riskScore: riskScore,
                  size: 140,
                  showLabel: false,
                ),
                const SizedBox(width: 16),
                // 새로운 게이지
                RiskGauge(
                  riskScore: riskScore,
                  size: 140,
                  showLabel: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 위험도 바
            RiskBar(
              riskScore: riskScore,
              height: 12,
            ),
            const SizedBox(height: 16),
            if (analysisProvider.results.isNotEmpty)
              Text(
                analysisProvider.results.first.recommendation,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _GlassActionCard(
              icon: Icons.analytics,
              label: '상세 분석',
              onTap: () => Navigator.pushNamed(context, '/analysis'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _GlassActionCard(
              icon: Icons.show_chart,
              label: '그래프',
              onTap: () => Navigator.pushNamed(context, '/graph'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _GlassActionCard(
              icon: Icons.settings,
              label: '설정',
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAnalysis(ThemeData theme, AnalysisProvider analysisProvider) {
    if (analysisProvider.results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: GlassmorphismContainer(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 48,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                '아직 분석 결과가 없습니다',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '상세 분석을 실행하여 결로 위험을 확인하세요',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              GlassmorphismButton(
                text: '분석 시작',
                icon: Icons.play_arrow,
                onPressed: () => Navigator.pushNamed(context, '/analysis'),
              ),
            ],
          ),
        ),
      );
    }

    // 위험한 결과만 필터링
    final dangerousResults = analysisProvider.results
        .where((r) => r.riskLevel == RiskLevel.danger)
        .toList();

    // 위험한 결과가 없으면 모든 결과 표시
    final displayResults = dangerousResults.isEmpty 
        ? analysisProvider.results.take(5).toList()
        : dangerousResults.take(5).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dangerousResults.isEmpty ? '최근 분석 결과' : '위험 경보 (${dangerousResults.length}건)',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: dangerousResults.isEmpty ? null : Colors.red,
                ),
              ),
              if (analysisProvider.results.length > 5)
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/analysis'),
                  child: const Text('전체보기'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...displayResults.map((result) {
            final riskColor = AppTheme.getRiskColor(result.riskScore);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: riskColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      result.riskScore.toStringAsFixed(0),
                      style: TextStyle(
                        color: riskColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  '${result.date.month}/${result.date.day} ${result.date.hour}:00',
                  style: theme.textTheme.titleSmall,
                ),
                subtitle: Text(
                  result.riskLevel.label,
                  style: TextStyle(color: riskColor),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(theme, '외기 온도', '${result.outdoorTemp.toStringAsFixed(1)}°C'),
                        _buildDetailRow(theme, '외기 습도', '${result.outdoorHumidity.toStringAsFixed(1)}%'),
                        _buildDetailRow(theme, '이슬점', '${result.dewPoint.toStringAsFixed(1)}°C'),
                        _buildDetailRow(theme, '실내 온도', '${result.indoorTemp.toStringAsFixed(1)}°C'),
                        _buildDetailRow(theme, '실내 습도', '${result.indoorHumidity.toStringAsFixed(1)}%'),
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
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _GlassActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GlassActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassmorphismContainer(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
