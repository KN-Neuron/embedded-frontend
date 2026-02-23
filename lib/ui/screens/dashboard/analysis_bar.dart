import 'package:flutter/material.dart';
import 'package:eeg_dashboard_app/core/constants.dart';

class AnalysisBar extends StatelessWidget {
  final double alpha;
  final double beta;
  final double theta;
  final double delta;
  final double totalPower;

  const AnalysisBar({
    Key? key,
    required this.alpha,
    required this.beta,
    required this.theta,
    required this.delta,
    required this.totalPower,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bands = {
      'Alpha': alpha,
      'Beta': beta,
      'Theta': theta,
      'Delta': delta,
    };
    final sortedBands = bands.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: sortedBands.map((e) {
            final percentage = (totalPower > 0 ? e.value / totalPower : 0.0) * 100;
            return Column(
              children: [
                Text(e.key, style: Theme.of(context).textTheme.titleSmall!.copyWith(color: bandColors[e.key]!)),
                const SizedBox(height: 4),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(color: bandColors[e.key]!),
                ),
                Text(
                  'Power: ${e.value.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}