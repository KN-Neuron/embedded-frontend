import 'package:flutter/material.dart';
import 'metric_row.dart';
import 'spectrum_chart.dart';
import 'package:eeg_dashboard_app/core/constants.dart';

class AnalysisDrawer extends StatelessWidget {
  final List<String> channels;
  final String selectedChannel;
  final ValueChanged<String> onSelectChannel;
  final double hjorthActivity;
  final double hjorthMobility;
  final double alphaPeakFreq;
  final String apiKey;
  final Future<void> Function(String) onSaveApiKey;
  final Future<void> Function() onPerformAIAnalysis;
  final String aiAnalysisResult;
  final List<double> spectrum;
  final int bufferLength;
  final int sampleRate;

  const AnalysisDrawer({
    Key? key,
    required this.channels,
    required this.selectedChannel,
    required this.onSelectChannel,
    required this.hjorthActivity,
    required this.hjorthMobility,
    required this.alphaPeakFreq,
    required this.apiKey,
    required this.onSaveApiKey,
    required this.onPerformAIAnalysis,
    required this.aiAnalysisResult,
    required this.spectrum,
    required this.bufferLength,
    required this.sampleRate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cardColor.withAlpha((0.5 * 255).round()),
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Card(
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Analyze Channel:', style: Theme.of(context).textTheme.titleMedium!.copyWith(color: primaryColor)),
                      DropdownButton<String>(
                        value: selectedChannel,
                        dropdownColor: cardColor,
                        underline: Container(height: 1, color: primaryColor),
                        items: channels.map((String ch) {
                          return DropdownMenuItem<String>(
                            value: ch,
                            child: Text(ch, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) onSelectChannel(newValue);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  MetricRow(label: 'Hjorth Activity:', value: hjorthActivity.toStringAsFixed(4)),
                  MetricRow(label: 'Hjorth Mobility:', value: hjorthMobility.toStringAsFixed(4)),
                  MetricRow(label: 'Alpha Peak Freq:', value: '${alphaPeakFreq.toStringAsFixed(2)} Hz'),
                ],
              ),
            ),
          ),
          Card(
            color: cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0).copyWith(bottom: 0),
                  child: Text('FFT Power Spectrum (PSD)', style: Theme.of(context).textTheme.titleMedium!.copyWith(color: primaryColor)),
                ),
                AspectRatio(
                  aspectRatio: 1.5,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SpectrumChart(spectrum: spectrum, bufferLength: bufferLength, sampleRate: sampleRate),
                  ),
                ),
              ],
            ),
          ),
          Card(
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gemini AI Analysis', style: Theme.of(context).textTheme.titleMedium!.copyWith(color: secondaryColor)),
                  const SizedBox(height: 10),
                  TextField(
                    onSubmitted: onSaveApiKey,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: apiKey.isNotEmpty ? 'API Key Set' : 'Enter Gemini API Key',
                      border: const OutlineInputBorder(),
                      suffixIcon: Icon(apiKey.isNotEmpty ? Icons.check_circle : Icons.vpn_key),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onPerformAIAnalysis,
                      icon: const Icon(Icons.auto_fix_high),
                      label: const Text('analyze with AI'),
                      style: ElevatedButton.styleFrom(backgroundColor: secondaryColor),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(aiAnalysisResult, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ].expand((widget) => [widget, const SizedBox(height: 10)]).toList(),
      ),
    );
  }
}