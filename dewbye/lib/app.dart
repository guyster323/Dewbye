import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/theme_provider.dart';
import 'screens/intro_screen.dart';
import 'screens/home_screen.dart';
import 'screens/location_select_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/graph_screen.dart';
import 'screens/settings_screen.dart';

class DewbyeApp extends StatelessWidget {
  const DewbyeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Dewbye',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      initialRoute: '/intro',
      routes: {
        '/intro': (context) => const IntroScreen(),
        '/': (context) => const HomeScreen(),
        '/location': (context) => const LocationSelectScreen(),
        '/analysis': (context) => const AnalysisScreen(),
        '/graph': (context) => const GraphScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
