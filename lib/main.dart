import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants.dart';
import 'logic/ai_analysis_service.dart';
import 'logic/eeg_data_controller.dart';
import 'ui/screens/educational_screen.dart';
import 'ui/screens/dashboard_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DataPipeline()),
        ChangeNotifierProvider(create: (_) => AiAnalysisService()),
      ],
      child: const EEGAnalyzerApp(),
    ),
  );
}

class EEGAnalyzerApp extends StatelessWidget {
  const EEGAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EEG Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF000000),
        cardColor: cardColor,
        colorScheme: const ColorScheme.dark(
          primary: primaryColor,
          secondary: secondaryColor,
          surface: Color(0xFF0A0A10),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const DashboardScreen(),
        '/educational': (context) => const EducationalScreen(),
      },
    );
  }
}