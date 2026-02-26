import 'package:flutter/material.dart';

class MainActionToggle extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onTap;

  const MainActionToggle({super.key, required this.isRunning, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final activeColor = isRunning ? const Color(0xFFFF003C) : const Color(0xFF00FF41);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: activeColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: activeColor.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isRunning ? Icons.power_settings_new : Icons.play_arrow,
                  color: activeColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  isRunning ? 'STOP' : 'PLAY',
                  style: TextStyle(
                    color: activeColor,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}