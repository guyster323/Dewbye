import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/location_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Dewbye'),
                subtitle: const Text('버전 1.0.0'),
              ),
            ],
          ),

          // 테마 설정
          _buildSection(
            theme,
            title: '테마',
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('시스템 설정'),
                subtitle: const Text('기기 설정에 따름'),
                value: ThemeMode.system,
                groupValue: themeProvider.themeMode,
                onChanged: (value) => themeProvider.setThemeMode(value!),
              ),
              RadioListTile<ThemeMode>(
                title: const Text('라이트 모드'),
                value: ThemeMode.light,
                groupValue: themeProvider.themeMode,
                onChanged: (value) => themeProvider.setThemeMode(value!),
              ),
              RadioListTile<ThemeMode>(
                title: const Text('다크 모드'),
                value: ThemeMode.dark,
                groupValue: themeProvider.themeMode,
                onChanged: (value) => themeProvider.setThemeMode(value!),
              ),
            ],
          ),

          // 데이터 관리
          _buildSection(
            theme,
            title: '데이터 관리',
            children: [
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('위치 기록 삭제'),
                subtitle: Text('${locationProvider.locationHistory.length}개 항목'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showClearHistoryDialog(context, locationProvider),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('캐시 삭제'),
                subtitle: const Text('임시 데이터 삭제'),
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

  Future<void> _showClearHistoryDialog(
    BuildContext context,
    LocationProvider locationProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('위치 기록 삭제'),
        content: const Text('모든 위치 기록을 삭제하시겠습니까?'),
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
      locationProvider.clearHistory();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치 기록이 삭제되었습니다')),
        );
      }
    }
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
      // TODO: 캐시 삭제 구현
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('캐시가 삭제되었습니다')),
        );
      }
    }
  }
}
