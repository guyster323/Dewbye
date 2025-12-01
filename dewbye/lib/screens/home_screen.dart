import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/theme_provider.dart';
import '../providers/location_provider.dart';
import '../providers/analysis_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 초기 위치 로드
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
    final themeProvider = context.watch<ThemeProvider>();
    final locationProvider = context.watch<LocationProvider>();
    final analysisProvider = context.watch<AnalysisProvider>();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 헤더
            SliverToBoxAdapter(
              child: _buildHeader(theme, themeProvider),
            ),

            // 위치 섹션
            SliverToBoxAdapter(
              child: _buildLocationSection(theme, locationProvider),
            ),

            // 현재 상태 카드
            SliverToBoxAdapter(
              child: _buildStatusCard(theme, analysisProvider),
            ),

            // 빠른 분석 버튼
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
    );
  }

  Widget _buildHeader(ThemeData theme, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dewbye',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '결로 위험 예측 분석',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          IconButton(
            onPressed: () => themeProvider.toggleTheme(),
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              size: 28,
            ),
            tooltip: themeProvider.isDarkMode ? '라이트 모드' : '다크 모드',
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(ThemeData theme, LocationProvider locationProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(context, '/location');
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locationProvider.isLoading
                            ? '위치 확인 중...'
                            : locationProvider.currentLocation?.toString() ?? '위치를 선택하세요',
                        style: theme.textTheme.titleMedium,
                      ),
                      if (locationProvider.currentLocation != null)
                        Text(
                          '${locationProvider.currentLocation!.latitude.toStringAsFixed(4)}, ${locationProvider.currentLocation!.longitude.toStringAsFixed(4)}',
                          style: theme.textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme, AnalysisProvider analysisProvider) {
    final riskScore = analysisProvider.currentRiskScore;
    final riskColor = AppTheme.getRiskColor(riskScore);
    final riskLabel = AppTheme.getRiskLabel(riskScore);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                '현재 결로 위험도',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: CircularProgressIndicator(
                      value: riskScore / 100,
                      strokeWidth: 12,
                      backgroundColor: theme.colorScheme.surface,
                      valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${riskScore.toStringAsFixed(0)}%',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: riskColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        riskLabel,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: riskColor,
                        ),
                      ),
                    ],
                  ),
                ],
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
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _ActionCard(
              icon: Icons.analytics,
              label: '상세 분석',
              onTap: () => Navigator.pushNamed(context, '/analysis'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionCard(
              icon: Icons.show_chart,
              label: '그래프',
              onTap: () => Navigator.pushNamed(context, '/graph'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionCard(
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
        child: Card(
          child: Padding(
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
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/analysis'),
                  child: const Text('분석 시작'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '최근 분석 결과',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ...analysisProvider.results.take(5).map((result) {
            final riskColor = AppTheme.getRiskColor(result.riskScore);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: riskColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${result.riskScore.toStringAsFixed(0)}',
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
                subtitle: Text(
                  '외기 ${result.outdoorTemp.toStringAsFixed(1)}°C / ${result.outdoorHumidity.toStringAsFixed(0)}%',
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: riskColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    result.riskLevel.label,
                    style: TextStyle(
                      color: riskColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
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
    );
  }
}
