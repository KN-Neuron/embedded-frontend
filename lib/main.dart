import 'package:flutter/material.dart';
import 'package:eeg_dashboard_app/pages/eeg_home.dart';
import 'package:eeg_dashboard_app/pages/brain_demo_page.dart';
import 'package:eeg_dashboard_app/utils/constants.dart';

void main() {
  runApp(const EEGAnalyzerApp());
}

class EEGAnalyzerApp extends StatelessWidget {
  const EEGAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EEG Realtime Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF000000),
          cardColor: cardColor,
          colorScheme: const ColorScheme.dark(
            primary: primaryColor,
            secondary: secondaryColor,
            background: Color(0xFF0A0A10),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: cardColor,
            elevation: 0,
          )
      ),
      routes: {
        '/educational': (context) => const BrainDemoPage(),
      },
      home: const EEGHome(),
    );
  }
}