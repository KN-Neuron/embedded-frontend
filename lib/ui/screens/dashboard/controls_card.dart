import 'package:flutter/material.dart';
import 'package:eeg_dashboard_app/core/constants.dart';

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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            Text(
              'EEG Dashboard',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => onPickAndLoadFile(),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Load CSV'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blueGrey,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onUseMockData,
                  icon: const Icon(Icons.shuffle),
                  label: const Text('Mock Data'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.deepPurple,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onStartStopToggle,
                  icon: Icon(isRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(isRunning ? 'Pause' : 'Start'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: isRunning ? Colors.red : primaryColor,
                  ),
                ),
                IconButton(
                  onPressed: onOpenEducational,
                  icon: const Icon(Icons.school, color: Colors.amber),
                  tooltip: 'Learn 10-20 System',
                ),
                IconButton(
                  onPressed: onToggleAnalysisDrawer,
                  icon: Icon(showAnalysisDrawer ? Icons.bar_chart : Icons.bar_chart_outlined, color: Colors.teal),
                  tooltip: 'Toggle Analysis Drawer',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}