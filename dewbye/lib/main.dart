import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'providers/theme_provider.dart';
import 'providers/location_provider.dart';
import 'providers/analysis_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive 초기화
  await Hive.initFlutter();

  // 시스템 UI 설정
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Provider 초기화
  final themeProvider = ThemeProvider();
  final locationProvider = LocationProvider();
  final analysisProvider = AnalysisProvider();

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
