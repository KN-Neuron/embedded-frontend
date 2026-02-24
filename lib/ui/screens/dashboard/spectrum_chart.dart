import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:eeg_dashboard_app/core/band_config.dart';

class SpectrumChart extends StatelessWidget {
  final List<double> spectrum;
  final int bufferLength;
  final int sampleRate;

  const SpectrumChart({Key? key, required this.spectrum, required this.bufferLength, required this.sampleRate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (spectrum.length < 2) return const Center(child: Text('awaiting EEG data...'));

    int fftSize = 1;
    while (fftSize < bufferLength) fftSize <<= 1;
    final df = sampleRate / fftSize;

    final nonDcMagnitude = spectrum.sublist(1);
    final maxVal = nonDcMagnitude.reduce(max);

    return BarChart(
      BarChartData(
        maxY: maxVal * 1.2,
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 10)))),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 25,
              getTitlesWidget: (value, meta) {
                final freq = value * df;
                if (freq % 5 == 0 && freq <= 30 && freq > 0) {
                  return SideTitleWidget(
                    meta: meta,
                    child: Text('${freq.toInt()}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(spectrum.length, (i) {
          if (i == 0) return BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 0, width: 0)]);

          final freq = i * df;
          final band = BandConfig.findByFrequency(freq);
          final color = band?.color ?? Colors.grey.withAlpha(75);

          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: spectrum[i],
                color: color,
                width: 1,
                borderRadius: BorderRadius.zero,
              ),
            ],
          );
        }),
      ),
    );
  }
}