import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';

class LocationSelectScreen extends StatefulWidget {
  const LocationSelectScreen({super.key});

  @override
  State<LocationSelectScreen> createState() => _LocationSelectScreenState();
}

class _LocationSelectScreenState extends State<LocationSelectScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locationProvider = context.watch<LocationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('위치 선택'),
      ),
      body: Column(
        children: [
          // 검색 바
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '주소 또는 장소 검색',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          locationProvider.clearSearchResults();
                        },
                      )
                    : null,
              ),
              onChanged: (query) {
                // 입력 즉시 검색 (트림 처리는 provider에서)
                locationProvider.searchLocation(query);
              },
              onSubmitted: (query) {
                // Enter 키 입력 시에도 검색
                locationProvider.searchLocation(query);
              },
            ),
          ),

          // 현재 위치 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.my_location,
                    color: theme.colorScheme.primary,
                  ),
                ),
                title: const Text('현재 위치 사용'),
                subtitle: locationProvider.isLoading
                    ? const Text('위치 확인 중...')
                    : const Text('GPS를 사용하여 현재 위치 가져오기'),
                trailing: locationProvider.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: locationProvider.isLoading
                    ? null
                    : () async {
                        await locationProvider.getCurrentLocation();
                        if (mounted && locationProvider.currentLocation != null) {
                          final loc = locationProvider.currentLocation!;
                          // 현재 위치 정보를 반환
                          Navigator.pop(context, {
                            'latitude': loc.latitude,
                            'longitude': loc.longitude,
                            'name': loc.displayName,
                          });
                        }
                      },
              ),
            ),
          ),

          // 에러 메시지
          if (locationProvider.error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          locationProvider.error!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => locationProvider.clearError(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 검색 결과 또는 저장된 위치
          Expanded(
            child: locationProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : locationProvider.searchResults.isNotEmpty
                    ? _buildSearchResults(theme, locationProvider)
                    : _buildSavedLocations(theme, locationProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(ThemeData theme, LocationProvider locationProvider) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: locationProvider.searchResults.length,
      itemBuilder: (context, index) {
        final result = locationProvider.searchResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.location_on,
                color: theme.colorScheme.secondary,
              ),
            ),
            title: Text(result.shortName),
            subtitle: Text(result.displayName),
            trailing: IconButton(
              icon: const Icon(Icons.bookmark_border),
              onPressed: () => locationProvider.saveLocation(result),
            ),
            onTap: () {
              locationProvider.selectLocation(result);
              // 선택한 위치 정보를 반환
              Navigator.pop(context, {
                'latitude': result.latitude,
                'longitude': result.longitude,
                'name': result.displayName,
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildSavedLocations(ThemeData theme, LocationProvider locationProvider) {
    if (locationProvider.savedLocations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '저장된 위치가 없습니다',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '위치를 검색하고 저장하세요',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '저장된 위치',
            style: theme.textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: locationProvider.savedLocations.length,
            itemBuilder: (context, index) {
              final saved = locationProvider.savedLocations[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: saved.isFavorite
                          ? theme.colorScheme.primary.withValues(alpha: 0.1)
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      saved.isFavorite ? Icons.star : Icons.bookmark,
                      color: saved.isFavorite
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  title: Text(saved.displayName),
                  subtitle: Text(
                    '${saved.location.latitude.toStringAsFixed(4)}, ${saved.location.longitude.toStringAsFixed(4)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          saved.isFavorite ? Icons.star : Icons.star_border,
                          color: saved.isFavorite
                              ? theme.colorScheme.primary
                              : null,
                        ),
                        onPressed: () =>
                            locationProvider.toggleFavorite(saved.location),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            locationProvider.deleteLocation(saved.location),
                      ),
                    ],
                  ),
                  onTap: () {
                    locationProvider.selectLocation(saved.location);
                    // 선택한 위치 정보를 반환
                    Navigator.pop(context, {
                      'latitude': saved.location.latitude,
                      'longitude': saved.location.longitude,
                      'name': saved.displayName,
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
