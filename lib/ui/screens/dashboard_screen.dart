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
    final pipeline = Provider.of<DataPipeline>(context);
    final ai = Provider.of<AiAnalysisService>(context);

    double calculateTotalPower() {
      if (pipeline.currentMetrics.bandPowers.isEmpty) return 0.0;
      return pipeline.currentMetrics.bandPowers.values.reduce((a, b) => a + b);
    }

    Widget buildControlsCard(BuildContext context) {
      return ControlsCard(
        isRunning: pipeline.isRunning,
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
                pipeline.loadFileData(loadedData, loadedChannels);
              }
            }
          } catch (e) {
            debugPrint('Error: $e');
          }
        },
        onUseMockData: pipeline.useMockData,
        onStartStopToggle: pipeline.togglePlayback,
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
                    alpha: pipeline.currentMetrics.bandPowers['Alpha'] ?? 0.0,
                    beta: pipeline.currentMetrics.bandPowers['Beta'] ?? 0.0,
                    theta: pipeline.currentMetrics.bandPowers['Theta'] ?? 0.0,
                    delta: pipeline.currentMetrics.bandPowers['Delta'] ?? 0.0,
                    totalPower: calculateTotalPower(),
                  ),
                  if (_showAnalysisDrawer) const SizedBox(height: 10),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4, right: 12, top: 12, bottom: 4),
                        child: SignalView(
                          channels: pipeline.channels,
                          viewBuffer: pipeline.viewBuffer,
                          offsetStep: pipeline.offsetStep,
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
                channels: pipeline.channels,
                selectedChannel: pipeline.selectedAnalysisChannel,
                onSelectChannel: pipeline.setSelectedChannel,
                hjorthActivity: pipeline.hjorthActivity,
                hjorthMobility: pipeline.hjorthMobility,
                alphaPeakFreq: pipeline.currentMetrics.dominantFrequency,
                apiKey: ai.apiKey,
                onSaveApiKey: ai.saveApiKey,
                onPerformAIAnalysis: () async {
                  final dataSummary = {
                    'Source': pipeline.isFromFile ? 'Loaded Dataset' : 'Mocked Synthetic Data',
                    'Analysis Channel': pipeline.selectedAnalysisChannel,
                    'TotalPower': calculateTotalPower().toStringAsFixed(2),
                    'AlphaPower': (pipeline.currentMetrics.bandPowers['Alpha'] ?? 0.0).toStringAsFixed(2),
                    'BetaPower': (pipeline.currentMetrics.bandPowers['Beta'] ?? 0.0).toStringAsFixed(2),
                    'ThetaPower': (pipeline.currentMetrics.bandPowers['Theta'] ?? 0.0).toStringAsFixed(2),
                    'DeltaPower': (pipeline.currentMetrics.bandPowers['Delta'] ?? 0.0).toStringAsFixed(2),
                    'AlphaPeakFreq': pipeline.currentMetrics.dominantFrequency.toStringAsFixed(2),
                    'HjorthActivity (Variance)': pipeline.hjorthActivity.toStringAsFixed(4),
                    'HjorthMobility': pipeline.hjorthMobility.toStringAsFixed(4),
                  };
                  await ai.performAIAnalysis(dataSummary);
                },
                aiAnalysisResult: ai.aiAnalysisResult,
                spectrum: pipeline.currentMetrics.fftMagnitude,
                bufferLength: bufferLength,
                sampleRate: sampleRate,
              ),
            ),
        ],
      ),
    );
  }
}