import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/theme_provider.dart';
import 'providers/location_provider.dart';
import 'providers/analysis_provider.dart';
import 'services/cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive 초기화
  await CacheService.initialize();

  // 시스템 UI 설정
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // 서비스 인스턴스 생성 (공유)
  final cacheService = CacheService();
  await cacheService.openBoxes();

  // Provider 초기화
  final themeProvider = ThemeProvider();
  final locationProvider = LocationProvider(cacheService: cacheService);
  final analysisProvider = AnalysisProvider(cacheService: cacheService);

  await themeProvider.init();
  await locationProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: locationProvider),
        ChangeNotifierProvider.value(value: analysisProvider),
      ],
      child: const DewbyeApp(),
    ),
  );
}
