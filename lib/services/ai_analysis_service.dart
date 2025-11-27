import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../models/eeg_metrics.dart';

/// handles communication with the OpenAI API for AI-driven EEG interpretation
class AiAnalysisService {
  static const String _keyFileName = '.openai_api_key';
  static const String _chatUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _model = 'gpt-3.5-turbo';

  /// reads the OpenAI API key securely stored in the app's documents directory
  Future<String?> _getApiKey() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_keyFileName');
      if (await file.exists()) {
        return await file.readAsString();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// saves the API key to the secure file
  Future<void> saveApiKey(String key) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_keyFileName');
    await file.writeAsString(key);
  }

  /// generates a concise interpretation of the EEG metrics using OpenAI.
  Future<String> getAiInterpretation(EegMetrics metrics) async {
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return _getLocalFallbackAnalysis(metrics);
    }

    final prompt = _buildAnalysisPrompt(metrics);

    try {
      final response = await http.post(
        Uri.parse(_chatUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': 'You are a concise EEG analysis assistant. Provide a single paragraph interpretation of the metrics below, focusing on the dominant frequency and band power ratios.'},
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.5,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else {
        return 'API Error (${response.statusCode}): Could not get analysis. Using local fallback.';
      }
    } catch (e) {
      return 'Network Error: Could not reach API. Using local fallback.';
    }
  }

  String _buildAnalysisPrompt(EegMetrics metrics) {
    return '''
      EEG Analysis Metrics:
      - Dominant Frequency: ${metrics.dominantFrequency.toStringAsFixed(2)} Hz
      - Delta Power (0.5-4Hz): ${metrics.bandPowers['Delta']?.toStringAsFixed(4) ?? 'N/A'}
      - Theta Power (4-8Hz): ${metrics.bandPowers['Theta']?.toStringAsFixed(4) ?? 'N/A'}
      - Alpha Power (8-13Hz): ${metrics.bandPowers['Alpha']?.toStringAsFixed(4) ?? 'N/A'}
      - Beta Power (13-30Hz): ${metrics.bandPowers['Beta']?.toStringAsFixed(4) ?? 'N/A'}
      
      Interpret these findings.
    ''';
  }

  String _getLocalFallbackAnalysis(EegMetrics metrics) {
    if ((metrics.bandPowers['Alpha'] ?? 0) > 0.5) {
      return 'Local Analysis: Dominant activity is in the Alpha band (${metrics.dominantFrequency.toStringAsFixed(1)} Hz). This indicates a state of relaxed awareness.';
    }
    if ((metrics.bandPowers['Theta'] ?? 0) > 0.2) {
      return 'Local Analysis: Elevated Theta power suggests drowsiness or a deeply relaxed/meditative state.';
    }
    return 'Local Analysis: Signal activity is stable and within expected parameters for a synthetic baseline.';
  }
}