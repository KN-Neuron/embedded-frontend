import 'package:flutter/material.dart';
import '../../config/band_config.dart';

/// displays the power of each EEG band in a row of small cards
class BandPowerCards extends StatelessWidget {
  final Map<String, double> bandPowers;

  const BandPowerCards({super.key, required this.bandPowers});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: bandPowers.entries.map((entry) {
          final bandName = entry.key;
          final power = entry.value;

          final config = BandConfig.bands[bandName] ?? {'color': Colors.grey, 'description': 'N/A'};
          final color = config['color'] as Color;

          return Container(
            width: 150,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color, width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  bandName,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  power.toStringAsFixed(3),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Power',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}