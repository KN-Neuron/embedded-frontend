import 'package:flutter/material.dart';

class MainActionToggle extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onTap;

  const MainActionToggle({
    Key? key,
    required this.isRunning,
    required this.onTap
  }) : super(key: key);

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
              Icon(
                  isRunning ? Icons.stop_sharp : Icons.play_arrow_sharp,
                  color: activeColor
              ),
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