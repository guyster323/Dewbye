import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import 'glassmorphism_container.dart';

class LocationInputWidget extends StatelessWidget {
  final VoidCallback? onTap;
  final bool showCurrentLocationButton;
  final bool compact;

  const LocationInputWidget({
    super.key,
    this.onTap,
    this.showCurrentLocationButton = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locationProvider = context.watch<LocationProvider>();
    final hasLocation = locationProvider.currentLocation != null;

    if (compact) {
      return _buildCompact(context, theme, locationProvider, hasLocation);
    }

    return GlassmorphismContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 위치 표시 / 선택 버튼
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap ?? () => Navigator.pushNamed(context, '/location'),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _buildLocationIcon(theme, locationProvider.isLoading),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasLocation ? '현재 분석 위치' : '위치를 선택하세요',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            locationProvider.isLoading
                                ? '위치 확인 중...'
                                : locationProvider.currentLocation?.toString() ??
                                    '탭하여 위치 선택',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (hasLocation) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${locationProvider.currentLocation!.latitude.toStringAsFixed(4)}, ${locationProvider.currentLocation!.longitude.toStringAsFixed(4)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 현재 위치 버튼
          if (showCurrentLocationButton) ...[
            Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: locationProvider.isLoading
                    ? null
                    : () => locationProvider.getCurrentLocation(),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.my_location_rounded,
                        size: 18,
                        color: locationProvider.isLoading
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                            : theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '현재 위치 사용',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: locationProvider.isLoading
                              ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                              : theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompact(
    BuildContext context,
    ThemeData theme,
    LocationProvider locationProvider,
    bool hasLocation,
  ) {
    return GlassmorphismContainer(
      blur: 8,
      opacity: 0.15,
      borderRadius: BorderRadius.circular(12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () => Navigator.pushNamed(context, '/location'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Text(
                    locationProvider.isLoading
                        ? '확인 중...'
                        : locationProvider.currentLocation?.name ?? '위치 선택',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationIcon(ThemeData theme, bool isLoading) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.2),
            theme.colorScheme.primary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: isLoading
          ? Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
            )
          : Icon(
              Icons.location_on_rounded,
              color: theme.colorScheme.primary,
              size: 28,
            ),
    );
  }
}

class LocationSearchBar extends StatefulWidget {
  final ValueChanged<String>? onSearch;
  final VoidCallback? onClear;
  final String? hintText;

  const LocationSearchBar({
    super.key,
    this.onSearch,
    this.onClear,
    this.hintText,
  });

  @override
  State<LocationSearchBar> createState() => _LocationSearchBarState();
}

class _LocationSearchBarState extends State<LocationSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassmorphismContainer(
      blur: _hasFocus ? 15 : 10,
      opacity: _hasFocus ? 0.25 : 0.15,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: _hasFocus
            ? theme.colorScheme.primary.withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.2),
        width: _hasFocus ? 2 : 1,
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: widget.hintText ?? '주소 또는 장소 검색',
          hintStyle: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: _hasFocus
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _controller.clear();
                    widget.onClear?.call();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        onChanged: (value) {
          widget.onSearch?.call(value);
          setState(() {});
        },
        textInputAction: TextInputAction.search,
        onSubmitted: widget.onSearch,
      ),
    );
  }
}
