import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// renders a LineChart of the FFT magnitude spectrum (Frequency Domain)
class FftSpectrumChart extends StatelessWidget {
  final List<double> magnitudes;
  final List<double> frequencies;

  const FftSpectrumChart({
    super.key,
    required this.magnitudes,
    required this.frequencies,
  });

  @override
  Widget build(BuildContext context) {
    const double maxDisplayFreq = 40.0;

    final spots = <FlSpot>[];
    for (int i = 0; i < frequencies.length; i++) {
      if (frequencies[i] > maxDisplayFreq) break;
      spots.add(FlSpot(frequencies[i], magnitudes[i]));
    }

    final maxY = magnitudes.reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxDisplayFreq,
        minY: 0,
        maxY: maxY * 1.1,
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 0.05,
        ),
        borderData: FlBorderData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            axisNameWidget: const Text('Frequency (Hz)', style: TextStyle(fontWeight: FontWeight.bold)),
            sideTitles: SideTitles(
              showTitles: true,
              interval: 10,
              getTitlesWidget: (value, meta) => Text(value.toInt().toString()),
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: const Text('Magnitude', style: TextStyle(fontWeight: FontWeight.bold)),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: maxY / 4,
              getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(2)),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.pinkAccent,
            barWidth: 2.0,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }
}