import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'logic/eeg_data_controller.dart';
import 'logic/ai_analysis_service.dart';
import 'ui/screens/dashboard_screen.dart';
import 'ui/screens/educational_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  runApp(const EEGAnalyzerApp());
}

class EEGAnalyzerApp extends StatelessWidget {
  const EEGAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DataPipeline()),
        ChangeNotifierProvider(create: (_) => AiAnalysisService()),
      ],
      child: MaterialApp(
        title: 'EEG Dashboard App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const DashboardScreen(),
          '/educational': (context) => const EducationalScreen(),
        },
      ),
    );
  }
}