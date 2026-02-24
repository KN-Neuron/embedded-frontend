import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eeg_dashboard_app/core/constants.dart';
import 'dashboard/controls_card.dart';
import 'dashboard/analysis_bar.dart';
import 'dashboard/signal_view.dart';
import 'dashboard/analysis_drawer.dart';
import '../../logic/eeg_data_controller.dart';
import '../../logic/eeg_analysis_processor.dart';
import '../../logic/ai_analysis_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  bool _showAnalysisDrawer = true;

  @override
  Widget build(BuildContext context) {
    final playback = Provider.of<PlaybackController>(context);
    final analysis = Provider.of<EegAnalysisState>(context);
    final ai = Provider.of<AiAnalysisService>(context);

    double calculateTotalPower() {
      if (analysis.currentMetrics.bandPowers.isEmpty) return 0.0;
      return analysis.currentMetrics.bandPowers.values.reduce((a, b) => a + b);
    }

    Widget buildControlsCard(BuildContext context) {
      return ControlsCard(
        isRunning: playback.isRunning,
        onPickAndLoadFile: () async {
          try {
            FilePickerResult? result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['csv', 'txt'],
            );
            if (result != null && result.files.single.path != null) {
              final file = File(result.files.single.path!);
              final lines = await file.readAsLines();
              if (lines.isEmpty) return;
              final headers = lines.first.split(',');
              List<String> loadedChannels = [];
              List<int> channelIndices = [];
              for (int i = 0; i < headers.length; i++) {
                final h = headers[i].trim();
                if (h.isNotEmpty && h != 'Class' && h != 'ID') {
                  loadedChannels.add(h);
                  channelIndices.add(i);
                }
              }
              Map<String, List<double>> loadedData = {
                for (var ch in loadedChannels) ch: []
              };
              for (int i = 1; i < lines.length; i++) {
                final parts = lines[i].split(',');
                if (parts.length < headers.length) continue;
                for (int j = 0; j < loadedChannels.length; j++) {
                  final ch = loadedChannels[j];
                  final idx = channelIndices[j];
                  final val = (double.tryParse(parts[idx].trim()) ?? 0.0) / 100.0;
                  loadedData[ch]!.add(val);
                }
              }
              if (loadedChannels.isNotEmpty) {
                playback.loadFileData(loadedData, loadedChannels);
              }
            }
          } catch (e) {
            debugPrint('Error: $e');
          }
        },
        onUseMockData: playback.useMockData,
        onStartStopToggle: playback.togglePlayback,
        onOpenEducational: () => Navigator.pushNamed(context, '/educational'),
        onToggleAnalysisDrawer: () {
          setState(() {
            _showAnalysisDrawer = !_showAnalysisDrawer;
          });
        },
        showAnalysisDrawer: _showAnalysisDrawer,
      );
    }

    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: _showAnalysisDrawer ? 7 : 10,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buildControlsCard(context),
                  const SizedBox(height: 10),
                  if (_showAnalysisDrawer) AnalysisBar(
                    alpha: analysis.currentMetrics.bandPowers['Alpha'] ?? 0.0,
                    beta: analysis.currentMetrics.bandPowers['Beta'] ?? 0.0,
                    theta: analysis.currentMetrics.bandPowers['Theta'] ?? 0.0,
                    delta: analysis.currentMetrics.bandPowers['Delta'] ?? 0.0,
                    totalPower: calculateTotalPower(),
                  ),
                  if (_showAnalysisDrawer) const SizedBox(height: 10),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4, right: 12, top: 12, bottom: 4),
                        child: SignalView(
                          channels: playback.channels,
                          viewBuffer: playback.viewBuffer,
                          offsetStep: playback.offsetStep,
                          sampleRate: sampleRate,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showAnalysisDrawer)
            Expanded(
              flex: 3,
              child: AnalysisDrawer(
                channels: playback.channels,
                selectedChannel: analysis.selectedAnalysisChannel,
                onSelectChannel: analysis.setSelectedChannel,
                hjorthActivity: analysis.hjorthActivity,
                hjorthMobility: analysis.hjorthMobility,
                alphaPeakFreq: analysis.currentMetrics.dominantFrequency,
                apiKey: ai.apiKey,
                onSaveApiKey: ai.saveApiKey,
                onPerformAIAnalysis: () async {
                  final dataSummary = {
                    'Source': playback.isFromFile ? 'Loaded Dataset' : 'Mocked Synthetic Data',
                    'Analysis Channel': analysis.selectedAnalysisChannel,
                    'TotalPower': calculateTotalPower().toStringAsFixed(2),
                    'AlphaPower': (analysis.currentMetrics.bandPowers['Alpha'] ?? 0.0).toStringAsFixed(2),
                    'BetaPower': (analysis.currentMetrics.bandPowers['Beta'] ?? 0.0).toStringAsFixed(2),
                    'ThetaPower': (analysis.currentMetrics.bandPowers['Theta'] ?? 0.0).toStringAsFixed(2),
                    'DeltaPower': (analysis.currentMetrics.bandPowers['Delta'] ?? 0.0).toStringAsFixed(2),
                    'AlphaPeakFreq': analysis.currentMetrics.dominantFrequency.toStringAsFixed(2),
                    'HjorthActivity (Variance)': analysis.hjorthActivity.toStringAsFixed(4),
                    'HjorthMobility': analysis.hjorthMobility.toStringAsFixed(4),
                  };
                  await ai.performAIAnalysis(dataSummary);
                },
                aiAnalysisResult: ai.aiAnalysisResult,
                spectrum: analysis.currentMetrics.fftMagnitude,
                bufferLength: bufferLength,
                sampleRate: sampleRate,
              ),
            ),
        ],
      ),
    );
  }
}