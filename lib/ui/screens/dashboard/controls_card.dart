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
              _CyberButton(
                label: 'LOAD CSV',
                icon: Icons.upload_sharp,
                color: const Color(0xFF2D3436),
                borderColor: Colors.cyanAccent,
                onPressed: () => onPickAndLoadFile(),
              ),
              _CyberButton(
                label: 'MOCK DATA',
                icon: Icons.memory_sharp,
                color: const Color(0xFF2D3436),
                borderColor: secondaryColor,
                onPressed: onUseMockData,
              ),
              _MainActionToggle(
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

class _CyberButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color borderColor;
  final VoidCallback onPressed;

  const _CyberButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.borderColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(2),
        color: borderColor,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: color,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: borderColor, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MainActionToggle extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onTap;

  const _MainActionToggle({required this.isRunning, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final activeColor = isRunning ? Colors.redAccent : const Color(0xFF00FF41);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: activeColor,
          boxShadow: [
            BoxShadow(color: activeColor.withOpacity(0.4), blurRadius: 12),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          color: Colors.black,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isRunning ? Icons.stop_sharp : Icons.play_arrow_sharp, color: activeColor),
              const SizedBox(width: 10),
              Text(
                isRunning ? 'STOP' : 'START',
                style: TextStyle(
                  color: activeColor,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}