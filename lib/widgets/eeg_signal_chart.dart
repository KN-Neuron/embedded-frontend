import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// renders a LineChart of the raw time-series EEG samples
class EegSignalChart extends StatelessWidget {
  final List<double> samples;

  const EegSignalChart({super.key, required this.samples});

  @override
  Widget build(BuildContext context) {
    final spots = List.generate(samples.length, (i) {
      return FlSpot(i.toDouble(), samples[i]);
    });

    final minY = samples.reduce((a, b) => a < b ? a : b);
    final maxY = samples.reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        minY: minY - 0.1,
        maxY: maxY + 0.1,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: Colors.cyan,
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
      //swapAnimationDuration: const Duration(milliseconds: 150), // nice update animation
      //but its not working well with rapid data updates and causes flickering aaaaa
    );
  }
}