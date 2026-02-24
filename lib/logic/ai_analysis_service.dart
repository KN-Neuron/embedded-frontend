import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Centralized AI service that performs AI-driven EEG interpretation.
class AiAnalysisService {
  static const String _keyFileName = 'gemini_api_key.txt';

  Future<String> loadApiKey() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_keyFileName');
      if (await file.exists()) {
        return (await file.readAsString()).trim();
      }
    } catch (e) {
      // swallow and return empty string for caller to handle
    }
    return '';
  }

  Future<void> saveApiKey(String key) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_keyFileName');
      await file.writeAsString(key.trim());
    } catch (e) {
      // ignore storage failures here; caller may show UI feedback
    }
  }

  Future<String> analyzeWithGemini(Map<String, String> dataSummary, {required String apiKey}) async {
    if (apiKey.isEmpty) return 'error: API Key is not set';

    final prompt = """
      You are an expert neuroscientist. Analyze the following EEG power metrics and time-domain features and provide a brief, professional summary (max 3 sentences) on the likely state of the subject.

      Metrics:
      ${dataSummary.entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}
      """;

    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'contents': [{'parts': [{'text': prompt}]}]}),
      );

      final jsonResponse = json.decode(response.body);

      if (jsonResponse is Map && jsonResponse['candidates'] is List && jsonResponse['candidates'].isNotEmpty) {
        final candidate = jsonResponse['candidates'][0];
        if (candidate is Map && candidate['content'] is Map && candidate['content']['parts'] is List && candidate['content']['parts'].isNotEmpty) {
          final text = candidate['content']['parts'][0]['text'];
          if (text is String) return text;
        }
      }

      return 'AI Analysis Error: Unexpected response format from Gemini';
    } catch (e) {
      return 'AI Analysis Error: $e';
    }
  }
}