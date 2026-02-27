import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/eeg_metrics.dart';

class AiAnalysisService with ChangeNotifier {
  String _aiAnalysisResult = '';
  bool _isAnalyzing = false;

  String get aiAnalysisResult => _aiAnalysisResult;
  bool get isAnalyzing => _isAnalyzing;

  Future<void> performAIAnalysis({
    required EegMetrics metrics,
    required bool isFromFile,
    required String channelName,
    required double hjorthActivity,
    required double hjorthMobility,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

    if (apiKey.isEmpty) {
      _aiAnalysisResult = 'API Key not found in .env file.';
      notifyListeners();
      return;
    }

    _isAnalyzing = true;
    _aiAnalysisResult = 'Analyzing EEG patterns...';
    notifyListeners();

    try {
      final prompt = '''
      Please provide a detailed clinical interpretation of the following EEG metrics:
      
      Source: ${isFromFile ? 'Loaded Dataset' : 'Mock Data'}
      Channel: $channelName
      Dominant Frequency: ${metrics.dominantFrequency.toStringAsFixed(2)} Hz
      Alpha Power: ${metrics.bandPowers['Alpha']?.toStringAsFixed(2) ?? '0.0'}
      Beta Power: ${metrics.bandPowers['Beta']?.toStringAsFixed(2) ?? '0.0'}
      Theta Power: ${metrics.bandPowers['Theta']?.toStringAsFixed(2) ?? '0.0'}
      Delta Power: ${metrics.bandPowers['Delta']?.toStringAsFixed(2) ?? '0.0'}
      Hjorth Activity: ${hjorthActivity.toStringAsFixed(2)}
      Hjorth Mobility: ${hjorthMobility.toStringAsFixed(2)}
      
      Provide a detailed, professional analysis explaining specific patterns, discrepancies, and individual metrics. 
      Structure your response using a numbered list (1., 2., 3., etc.) with clear titles for each point (e.g., "1. Dominant Slow-Wave Activity:").
      
      IMPORTANT: Use plain text only. Do NOT use markdown asterisks (** or *) for bolding or bullet points.
      ''';

      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
      final response = await model.generateContent([Content.text(prompt)]);

      String rawText = response.text ?? 'Analysis failed to return a valid response.';
      _aiAnalysisResult = rawText.replaceAll('**', '').replaceAll('* ', '- ');
    } catch (e) {
      _aiAnalysisResult = 'Error during analysis: $e';
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }
}