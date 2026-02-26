import 'package:flutter/material.dart';
import 'package:eeg_dashboard_app/core/constants.dart';
import 'package:eeg_dashboard_app/ui/widgets/cyber_button.dart';
import 'package:eeg_dashboard_app/ui/widgets/main_action_toggle.dart';
import 'package:eeg_dashboard_app/ui/widgets/pixel_border_painter.dart';

class ControlsCard extends StatelessWidget {
  final bool isRunning;
  final Future<void> Function() onPickAndLoadFile;
  final VoidCallback onUseMockData;
  final VoidCallback onStartStopToggle;
  final VoidCallback onOpenEducational;
  final VoidCallback onToggleAnalysisDrawer;
  final bool showAnalysisDrawer;

  const ControlsCard({
    super.key,
    required this.isRunning,
    required this.onPickAndLoadFile,
    required this.onUseMockData,
    required this.onStartStopToggle,
    required this.onOpenEducational,
    required this.onToggleAnalysisDrawer,
    required this.showAnalysisDrawer,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: PixelBorderPainter(color: primaryColor),
      child: Container(
        color: cardColor.withOpacity(0.9),
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EEG',
                  style: TextStyle(
                    color: secondaryColor,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    fontSize: 20,
                  ),
                ),
                Text(
                  'DASHBOARD',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    color: primaryColor,
                    letterSpacing: -1,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                CyberButton(
                  label: 'IMPORT',
                  icon: Icons.downloading,
                  color: const Color(0xFF1A1A1A),
                  borderColor: Colors.cyanAccent,
                  onPressed: () => onPickAndLoadFile(),
                ),
                CyberButton(
                  label: 'SIMULATE',
                  icon: Icons.terminal,
                  color: const Color(0xFF1A1A1A),
                  borderColor: secondaryColor,
                  onPressed: onUseMockData,
                ),
                MainActionToggle(
                  isRunning: isRunning,
                  onTap: onStartStopToggle,
                ),
                _PixelIconButton(
                  onPressed: onOpenEducational,
                  icon: Icons.school,
                  color: Colors.amber,
                ),
                _PixelIconButton(
                  onPressed: onToggleAnalysisDrawer,
                  icon: showAnalysisDrawer ? Icons.visibility : Icons.visibility_off,
                  color: Colors.tealAccent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PixelIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color color;

  const _PixelIconButton({required this.onPressed, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Container(
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.5), width: 1),
        ),
        padding: const EdgeInsets.all(4),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}