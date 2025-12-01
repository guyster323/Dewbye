import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/location_provider.dart';
import '../services/cache_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final CacheService _cacheService = CacheService();
  String _cacheSize = '계산 중...';

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  Future<void> _loadCacheSize() async {
    await _cacheService.openBoxes();
    final size = await _cacheService.getCacheSize();
    if (mounted) {
      setState(() {
        _cacheSize = _cacheService.formatCacheSize(size);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final locationProvider = context.watch<LocationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        children: [
          // 앱 정보
          _buildSection(
            theme,
            title: '앱 정보',
            children: [
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Dewbye'),
                subtitle: Text('버전 1.0.0'),
              ),
            ],
          ),

          // 테마 설정
          _buildSection(
            theme,
            title: '테마',
            children: [
              ListTile(
                leading: const Icon(Icons.brightness_6),
                title: const Text('테마 모드'),
                subtitle: Text(_getThemeModeText(themeProvider.themeMode)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemeDialog(context, themeProvider),
              ),
            ],
          ),

          // 데이터 관리
          _buildSection(
            theme,
            title: '데이터 관리',
            children: [
              ListTile(
                leading: const Icon(Icons.bookmark),
                title: const Text('저장된 위치'),
                subtitle: Text('${locationProvider.savedLocations.length}개 항목'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/location'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('캐시 삭제'),
                subtitle: Text(_cacheSize),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showClearCacheDialog(context),
              ),
            ],
          ),

          // 정보
          _buildSection(
            theme,
            title: '정보',
            children: [
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('이용 약관'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: 이용 약관 페이지
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('개인정보 처리방침'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: 개인정보 처리방침 페이지
                },
              ),
              ListTile(
                leading: const Icon(Icons.article_outlined),
                title: const Text('오픈소스 라이선스'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showLicensePage(
                    context: context,
                    applicationName: 'Dewbye',
                    applicationVersion: '1.0.0',
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 32),

          // 저작권
          Center(
            child: Text(
              '© 2025 Dewbye. All rights reserved.',
              style: theme.textTheme.bodySmall,
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return '시스템 설정';
      case ThemeMode.light:
        return '라이트 모드';
      case ThemeMode.dark:
        return '다크 모드';
    }
  }

  Widget _buildSection(
    ThemeData theme, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }

  Future<void> _showThemeDialog(
    BuildContext context,
    ThemeProvider themeProvider,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('테마 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.brightness_auto),
              title: const Text('시스템 설정'),
              trailing: themeProvider.themeMode == ThemeMode.system
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('라이트 모드'),
              trailing: themeProvider.themeMode == ThemeMode.light
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('다크 모드'),
              trailing: themeProvider.themeMode == ThemeMode.dark
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showClearCacheDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('캐시 삭제'),
        content: const Text('모든 캐시 데이터를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _cacheService.clearAllCache();
      await _loadCacheSize();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('캐시가 삭제되었습니다')),
        );
      }
    }
  }
}
