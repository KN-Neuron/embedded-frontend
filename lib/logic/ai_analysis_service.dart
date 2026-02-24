import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class AiAnalysisService extends ChangeNotifier {
  static const String _keyFileName = 'gemini_api_key.txt';

  String _apiKey = '';
  String get apiKey => _apiKey;

  String _aiAnalysisResult = 'Waiting for analysis...';
  String get aiAnalysisResult => _aiAnalysisResult;

  AiAnalysisService() {
    _initApiKey();
  }

  Future<void> _initApiKey() async {
    _apiKey = await _loadApiKey();
    notifyListeners();
  }

  Future<String> _loadApiKey() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_keyFileName');
      if (await file.exists()) {
        return (await file.readAsString()).trim();
      }
    } catch (e) {}
    return '';
  }

  Future<void> saveApiKey(String key) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_keyFileName');
      await file.writeAsString(key.trim());
      _apiKey = key.trim();
      notifyListeners();
    } catch (e) {}
  }

  Future<void> performAIAnalysis(Map<String, String> dataSummary) async {
    if (_apiKey.isEmpty) {
      _aiAnalysisResult = 'error: API Key is not set';
      notifyListeners();
      return;
    }

    _aiAnalysisResult = 'Analyzing...';
    notifyListeners();

    final prompt = """
      You are an expert neuroscientist. Analyze the following EEG power metrics and time-domain features and provide a brief, professional summary (max 3 sentences) on the likely state of the subject.

      Metrics:
      ${dataSummary.entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}
      """;

    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'contents': [{'parts': [{'text': prompt}]}]}),
      );

      final jsonResponse = json.decode(response.body);

      if (jsonResponse is Map && jsonResponse['candidates'] is List && jsonResponse['candidates'].isNotEmpty) {
        final candidate = jsonResponse['candidates'][0];
        if (candidate is Map && candidate['content'] is Map && candidate['content']['parts'] is List && candidate['content']['parts'].isNotEmpty) {
          final text = candidate['content']['parts'][0]['text'];
          if (text is String) {
            _aiAnalysisResult = text;
            notifyListeners();
            return;
          }
        }
      }
      _aiAnalysisResult = 'error: Unexpected AI response format.';
    } catch (e) {
      _aiAnalysisResult = 'error connecting to AI: $e';
    }
    notifyListeners();
  }
}