import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eeg_dashboard_app/core/constants.dart';
import 'package:eeg_dashboard_app/ui/screens/educational_screen.dart';

import 'dashboard/controls_card.dart';
import 'dashboard/analysis_bar.dart';
import 'dashboard/signal_view.dart';
import 'dashboard/analysis_drawer.dart';
import '../../logic/eeg_data_controller.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  bool _showAnalysisDrawer = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<EegDataController>(context);

    Widget _controlsCard(BuildContext context) {
      return ControlsCard(
        isRunning: controller.isRunning,
        onPickAndLoadFile: () async {
          try {
            FilePickerResult? result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['csv', 'txt'],
            );

            if (result != null && result.files.single.path != null) {
              final success = await controller.loadCsvFromPath(result.files.single.path!);
              controller.stopRealtime();
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Loaded ${controller.channels.length} channels from CSV')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load file')));
              }
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load file: $e')));
          }
        },
        onUseMockData: () {
          controller.useMockData();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Switched to Mock Data')));
        },
        onStartStopToggle: () { controller.toggleRealtime(); },
        onOpenEducational: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const EducationalScreen())),
        onToggleAnalysisDrawer: () => setState(() { _showAnalysisDrawer = !_showAnalysisDrawer; }),
        showAnalysisDrawer: _showAnalysisDrawer,
      );
    }

    Widget _analysisBar(BuildContext context) {
      if (controller.channels.isEmpty) return const SizedBox.shrink();
      return AnalysisBar(alpha: controller.alphaPower, beta: controller.betaPower, theta: controller.thetaPower, delta: controller.deltaPower, totalPower: controller.totalPower);
    }

    Widget _signalView(BuildContext context) {
      return SignalView(
        channels: controller.channels,
        viewBuffer: controller.viewBuffer,
        offsetStep: controller.offsetStep,
        sampleRate: sampleRate,
      );
    }

    Widget _analysisDrawerWidget(BuildContext context) {
      return AnalysisDrawer(
        channels: controller.channels,
        selectedChannel: controller.selectedAnalysisChannel,
        onSelectChannel: (s) { controller.setSelectedChannel(s); },
        hjorthActivity: controller.hjorthActivity,
        hjorthMobility: controller.hjorthMobility,
        alphaPeakFreq: controller.alphaPeakFreq,
        apiKey: controller.apiKey,
        onSaveApiKey: (k) => controller.saveApiKey(k),
        onPerformAIAnalysis: () => controller.performAIAnalysis(),
        aiAnalysisResult: controller.aiAnalysisResult,
        spectrum: controller.spectrum,
        bufferLength: bufferLength,
        sampleRate: sampleRate,
      );
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                controller.isRunning ? 'RUNNING' : 'PAUSED',
                style: TextStyle(
                  color: controller.isRunning ? primaryColor : Colors.white54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: _showAnalysisDrawer ? 7 : 10,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _controlsCard(context),
                  const SizedBox(height: 10),
                  if (_showAnalysisDrawer) _analysisBar(context),
                  if (_showAnalysisDrawer) const SizedBox(height: 10),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4, right: 12, top: 12, bottom: 4),
                        child: _signalView(context),
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
              child: _analysisDrawerWidget(context),
            ),
        ],
      ),
    );
  }
}