import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/eeg_data_controller.dart';
import '../../models/eeg_metrics.dart';
import '../../services/ai_analysis_service.dart';
import '../../widgets/eeg_signal_chart.dart';
import '../../widgets/band_power_cards.dart';
import '../../widgets/fft_spectrum_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AiAnalysisService _aiService = AiAnalysisService();
  bool _isAnalyzing = false;
  String _aiResult = '';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EegDataController>();
    final EegMetrics metrics = controller.currentMetrics;

    if (metrics.rawSamples.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('EEG Realtime Console'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key),
            tooltip: 'Enter OpenAI API Key',
            onPressed: () => _showApiKeyDialog(context),
          ),
          IconButton(
            icon: _isAnalyzing
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.psychology_alt),
            tooltip: 'Run AI Analysis',
            onPressed: _isAnalyzing ? null : () => _runAiAnalysis(metrics),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text('Raw EEG Signal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              height: 250,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: EegSignalChart(samples: metrics.rawSamples),
            ),

            const SizedBox(height: 20),

            const Text('Band Power Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            BandPowerCards(bandPowers: metrics.bandPowers),

            const SizedBox(height: 20),

            const Text('Frequency Spectrum (FFT)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              height: 250,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: FftSpectrumChart(
                magnitudes: metrics.fftMagnitude,
                frequencies: metrics.fftFrequencies,
              ),
            ),

            const SizedBox(height: 20),

            if (_aiResult.isNotEmpty) ...[
              const Text('AI Interpretation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.lightGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_aiResult, style: const TextStyle(fontSize: 14)),
              ),
              const SizedBox(height: 20),
            ],

            Text(
              'Dominant Frequency: ${metrics.dominantFrequency.toStringAsFixed(2)} Hz',
              style: const TextStyle(fontSize: 16, color: Colors.amber),
            ),
          ],
        ),
      ),
    );
  }

  /// trigger the AI analysis from the service
  Future<void> _runAiAnalysis(EegMetrics metrics) async {
    setState(() {
      _isAnalyzing = true;
      _aiResult = 'Analyzing...';
    });

    final analysis = await _aiService.getAiInterpretation(metrics);

    setState(() {
      _isAnalyzing = false;
      _aiResult = analysis;
    });
  }

  /// enter and save the OpenAI API key
  void _showApiKeyDialog(BuildContext context) {
    final keyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter OpenAI API Key'),
          content: TextField(
            controller: keyController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'sk-xxxxxxxxxxxxxxxxxxxx',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final key = keyController.text.trim();
                if (key.startsWith('sk-') && key.length > 20) {
                  await _aiService.saveApiKey(key);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('API Key saved successfully!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid Key Format')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}