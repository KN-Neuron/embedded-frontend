import 'package:flutter/material.dart';
import 'package:eeg_dashboard_app/core/constants.dart';
import 'package:eeg_dashboard_app/ui/widgets/cyber_button.dart';
import 'package:eeg_dashboard_app/ui/widgets/main_action_toggle.dart';

class ControlsCard extends StatelessWidget {
  final bool isRunning;
  final Future<void> Function() onPickAndLoadFile;
  final VoidCallback onUseMockData;
  final VoidCallback onStartStopToggle;
  final VoidCallback onOpenEducational;
  final VoidCallback onToggleAnalysisDrawer;
  final bool showAnalysisDrawer;

  const ControlsCard({
    Key? key,
    required this.isRunning,
    required this.onPickAndLoadFile,
    required this.onUseMockData,
    required this.onStartStopToggle,
    required this.onOpenEducational,
    required this.onToggleAnalysisDrawer,
    required this.showAnalysisDrawer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: primaryColor.withOpacity(0.5), width: 2),
      ),
      padding: const EdgeInsets.all(12.0),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          Text(
            'EEG DASHBOARD',
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: 2,
              color: primaryColor,
              shadows: [
                Shadow(color: secondaryColor, offset: const Offset(2, 2)),
              ],
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CyberButton(
                label: 'LOAD CSV',
                icon: Icons.upload_sharp,
                color: const Color(0xFF2D3436),
                borderColor: Colors.cyanAccent,
                onPressed: () => onPickAndLoadFile(),
              ),
              CyberButton(
                label: 'MOCK DATA',
                icon: Icons.memory_sharp,
                color: const Color(0xFF2D3436),
                borderColor: secondaryColor,
                onPressed: onUseMockData,
              ),
              MainActionToggle(
                isRunning: isRunning,
                onTap: onStartStopToggle,
              ),
              IconButton(
                onPressed: onOpenEducational,
                icon: const Icon(Icons.school, color: Colors.amber, size: 28),
                tooltip: 'Learn 10-20 System',
              ),
              IconButton(
                onPressed: onToggleAnalysisDrawer,
                icon: Icon(
                  showAnalysisDrawer ? Icons.sensors : Icons.sensors_off,
                  color: Colors.tealAccent,
                  size: 28,
                ),
                tooltip: 'Toggle Analysis Drawer',
              ),
            ],
          ),
        ],
      ),
    );
  }
}