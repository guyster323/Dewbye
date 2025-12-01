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
  List<LocationSearchResult> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // TODO: 실제 Geocoding API 호출 (Phase 3에서 구현)
    await Future.delayed(const Duration(milliseconds: 500));

    // 샘플 검색 결과
    setState(() {
      _searchResults = [
        LocationSearchResult(
          name: '$query 시청',
          address: '$query시 중구',
          latitude: 37.5665,
          longitude: 126.9780,
        ),
        LocationSearchResult(
          name: '$query역',
          address: '$query시 역전동',
          latitude: 37.5547,
          longitude: 126.9707,
        ),
      ];
      _isSearching = false;
    });
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
                          setState(() {
                            _searchResults = [];
                          });
                        },
                      )
                    : null,
              ),
              onChanged: _search,
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
                          Navigator.pop(context);
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

          // 검색 결과 또는 히스토리
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isNotEmpty
                    ? _buildSearchResults(theme)
                    : _buildLocationHistory(theme, locationProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
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
            title: Text(result.name),
            subtitle: Text(result.address),
            onTap: () {
              final locationProvider = context.read<LocationProvider>();
              locationProvider.setLocation(LocationData(
                latitude: result.latitude,
                longitude: result.longitude,
                name: result.name,
                address: result.address,
              ));
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  Widget _buildLocationHistory(ThemeData theme, LocationProvider locationProvider) {
    if (locationProvider.locationHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '검색 기록이 없습니다',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '위치를 검색하거나 현재 위치를 사용하세요',
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '최근 위치',
                style: theme.textTheme.titleMedium,
              ),
              TextButton(
                onPressed: () => locationProvider.clearHistory(),
                child: const Text('전체 삭제'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: locationProvider.locationHistory.length,
            itemBuilder: (context, index) {
              final location = locationProvider.locationHistory[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.history),
                  ),
                  title: Text(location.name ?? location.address ?? '알 수 없는 위치'),
                  subtitle: Text(
                    '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                  ),
                  onTap: () {
                    locationProvider.setLocation(location);
                    Navigator.pop(context);
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

class LocationSearchResult {
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  LocationSearchResult({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}
